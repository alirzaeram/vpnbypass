import Combine
import Foundation

@MainActor
final class DomainListViewModel: ObservableObject {
    @Published private(set) var rows: [DomainRowDisplay] = []
    @Published var newDomainText = ""
    @Published var selection = Set<UUID>()
    @Published var userFacingError: String?
    @Published var logs: [LogEntry] = []
    @Published var isWorking = false
    @Published var isBypassing = false
    @Published var showLogsSheet = false

    let store: DomainStore
    let vpnMonitor = VPNMonitor()

    private let resolver = ResolverService()
    private let routeManager = RouteManager()
    private var resolutionCache: [UUID: ResolutionCacheEntry] = [:]
    private var lastVPNLikelyFlag = false
    private var cancellables = Set<AnyCancellable>()

    private struct ResolutionCacheEntry {
        var state: ResolutionDisplayState
        var lastChecked: Date?
    }

    var runAtLoginEnabled: Bool { store.persistence.runAtLogin }
    var runWhenVPNConnectedEnabled: Bool { store.persistence.runWhenVPNConnected }

    init(store: DomainStore) {
        self.store = store
        vpnMonitor.start()
        lastVPNLikelyFlag = vpnMonitor.isVPNLikelyActive

        appendLog("Welcome to VPN Bypass. Add domains, refresh, then apply routes when you are on Wi‑Fi/Ethernet.", .info)
        
        store.$persistence
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.rebuildRows()
            }
            .store(in: &cancellables)

        vpnMonitor.$isVPNLikelyActive
            .receive(on: DispatchQueue.main)
            .sink { [weak self] now in
                self?.handleVPNHeuristicTransition(now: now)
            }
            .store(in: &cancellables)

        rebuildRows()
        isBypassing = store.persistence.routeState.bypassActive
    }

    func onAppear() {
        if #available(macOS 13.0, *) {
            if store.persistence.runAtLogin, LoginItemManager.status != .enabled {
                try? LoginItemManager.setEnabled(true)
            }
        }
        Task { await refreshAll() }
    }

    // MARK: - Domain editing

    func addDomain() {
        userFacingError = nil
        switch DomainValidation.validate(newDomainText) {
        case .success(let host):
            do {
                try store.addDomain(hostname: host)
                newDomainText = ""
                appendLog("Added \(host) to your list.", .success)
                Task { await refreshAll() }
            } catch {
                userFacingError = error.localizedDescription
            }
        case .failure(let failure):
            userFacingError = failure.localizedDescription
        }
    }

    func removeSelectedDomains() {
        guard !selection.isEmpty else { return }
        let ids = selection
        for id in ids {
            try? store.removeDomain(id: id)
            resolutionCache.removeValue(forKey: id)
        }
        selection.subtract(ids)
        appendLog("Removed \(ids.count) domain(s).", .info)
        rebuildRows()
    }

    func removeDomain(id: UUID) {
        guard !isWorking else { return }
        let host = store.persistence.domains.first(where: { $0.id == id })?.hostname
        try? store.removeDomain(id: id)
        resolutionCache.removeValue(forKey: id)
        selection.remove(id)
        if let host {
            appendLog("Removed \(host) from your list.", .info)
        } else {
            appendLog("Removed domain from your list.", .info)
        }
        rebuildRows()
    }

    // MARK: - Refresh / routing

    func refreshAll() async {
        guard !isWorking else { return }
        isWorking = true
        defer { isWorking = false }

        appendLog("Refreshing DNS lookups…", .info)
        let records = store.persistence.domains.sorted { $0.hostname < $1.hostname }

        for record in records {
            resolutionCache[record.id] = ResolutionCacheEntry(state: .resolving, lastChecked: nil)
            rebuildRows()

            do {
                let ips = try await resolver.resolveIPv4(hostname: record.hostname)
                resolutionCache[record.id] = ResolutionCacheEntry(state: .resolved(ips), lastChecked: Date())
            } catch {
                resolutionCache[record.id] = ResolutionCacheEntry(
                    state: .failed(error.localizedDescription),
                    lastChecked: Date()
                )
            }
            rebuildRows()
        }

        appendLog("Refresh finished.", .success)
    }

    func applyBypass() async {
        guard !isWorking else { return }
        isWorking = true
        defer { isWorking = false }
        userFacingError = nil

        do {
            appendLog("Resolving domains before applying routes…", .info)
            var collected: [String] = []

            for record in store.persistence.domains.sorted(by: { $0.hostname < $1.hostname }) {
                guard record.isIncludedInRoutes else { continue }
                let ips: [String]
                if case .resolved(let existing) = resolutionCache[record.id]?.state {
                    ips = existing
                } else {
                    ips = try await resolver.resolveIPv4(hostname: record.hostname)
                }
                collected.append(contentsOf: ips)
                resolutionCache[record.id] = ResolutionCacheEntry(state: .resolved(ips), lastChecked: Date())
                rebuildRows()
            }

            let unique = Array(Set(collected)).sorted()
            guard !unique.isEmpty else {
                let message = "No IPv4 addresses were found. Check your domains or network, then try Refresh."
                userFacingError = message
                appendLog(message, .warning)
                return
            }

            appendLog("Reading default IPv4 gateway…", .info)
            let gateway = try await routeManager.currentGateway()
            appendLog("Using gateway \(gateway) for \(unique.count) address(es).", .info)

            appendLog("Updating routes — your Mac may ask for an administrator password.", .info)
            let output = try await routeManager.apply(gateway: gateway, ipv4: unique)
            if !output.isEmpty {
                appendLog(output, .info)
            }

            let state = RouteApplicationState(
                bypassActive: true,
                appliedIPv4Addresses: unique,
                lastGatewayUsed: gateway,
                lastAppliedAt: Date()
            )
            try store.updateRouteState(state)
            isBypassing = true
            appendLog("Bypass routes are now active.", .success)
        } catch {
            userFacingError = error.localizedDescription
            appendLog(error.localizedDescription, .error)
        }

        rebuildRows()
    }

    func turnOffBypass() async {
        guard !isWorking else { return }
        isWorking = true
        defer { isWorking = false }
        userFacingError = nil

        let ips = store.persistence.routeState.appliedIPv4Addresses
        guard !ips.isEmpty else {
            appendLog("There are no saved routes to remove.", .warning)
            try? store.updateRouteState(.inactive)
            isBypassing = false
            rebuildRows()
            return
        }

        do {
            appendLog("Removing routes — your Mac may ask for an administrator password.", .info)
            let output = try await routeManager.remove(ipv4: ips)
            if !output.isEmpty {
                appendLog(output, .info)
            }
            try store.updateRouteState(.inactive)
            isBypassing = false
            appendLog("Bypass routes have been removed.", .success)
        } catch {
            userFacingError = error.localizedDescription
            appendLog(error.localizedDescription, .error)
        }

        rebuildRows()
    }

    // MARK: - Settings

    func setRunAtLogin(_ enabled: Bool) {
        userFacingError = nil
        guard #available(macOS 13.0, *) else {
            userFacingError = LoginItemManager.LoginItemError.unsupported.localizedDescription
            appendLog("Login items require macOS 13 or newer.", .error)
            return
        }

        do {
            try LoginItemManager.setEnabled(enabled)
            try store.setRunAtLogin(enabled)
            appendLog(enabled ? "Login item registered." : "Login item removed.", .success)
            if LoginItemManager.status == .requiresApproval {
                appendLog("Open System Settings → General → Login Items and allow VPN Bypass if prompted.", .warning)
            }
        } catch {
            userFacingError = error.localizedDescription
            appendLog(error.localizedDescription, .error)
        }
        objectWillChange.send()
    }

    func setRunWhenVPNConnected(_ enabled: Bool) {
        userFacingError = nil
        do {
            try store.setRunWhenVPNConnected(enabled)
            appendLog(
                enabled
                    ? "Auto-apply enabled: when a VPN-style interface appears, routes will be applied automatically."
                    : "Auto-apply on VPN detection is off.",
                .info
            )
        } catch {
            userFacingError = error.localizedDescription
        }
        objectWillChange.send()
    }

    func clearUserError() {
        userFacingError = nil
    }

    func clearLogs() {
        logs.removeAll()
    }

    // MARK: - Internals

    private func handleVPNHeuristicTransition(now: Bool) {
        let previous = lastVPNLikelyFlag
        lastVPNLikelyFlag = now
        guard store.persistence.runWhenVPNConnected else { return }
        guard previous == false, now == true else { return }
        appendLog("Network change: VPN-style interface detected — applying bypass automatically.", .info)
        Task { await applyBypass() }
    }

    private func rebuildRows() {
        let applied = Set(store.persistence.routeState.appliedIPv4Addresses)
        let global = store.persistence.routeState.bypassActive

        rows = store.persistence.domains
            .sorted { $0.hostname < $1.hostname }
            .map { record in
                let snap = resolutionCache[record.id] ?? ResolutionCacheEntry(state: .idle, lastChecked: nil)
                let ips: [String]
                switch snap.state {
                case .resolved(let values):
                    ips = values
                default:
                    ips = []
                }

                let covers = global && !ips.isEmpty && Set(ips).isSubset(of: applied)

                return DomainRowDisplay(
                    id: record.id,
                    hostname: record.hostname,
                    resolution: snap.state,
                    lastChecked: snap.lastChecked,
                    bypassCoversThisDomain: covers,
                    globalBypassActive: global,
                    isIncludedInRoutes: record.isIncludedInRoutes
                )
            }
    }

    func setDomainIncludedInRoutes(id: UUID, included: Bool) {
        userFacingError = nil
        do {
            try store.setDomainIncludedInRoutes(id: id, included: included)
            if let host = store.persistence.domains.first(where: { $0.id == id })?.hostname {
                appendLog(
                    included ? "Included \(host) in bypass operations." : "Excluded \(host) from bypass operations.",
                    .info
                )
            }
            rebuildRows()
        } catch {
            userFacingError = error.localizedDescription
        }
    }

    private func appendLog(_ message: String, _ severity: LogEntry.Severity) {
        let entry = LogEntry(message: message, severity: severity)
        logs.append(entry)
        if logs.count > 500 {
            logs.removeFirst(logs.count - 500)
        }
    }
}
