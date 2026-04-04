import Foundation
import Network

/// Observes network path updates and applies a **practical VPN heuristic** (not a guaranteed VPN API).
///
/// macOS does not offer a simple public API that says “VPN connected” for all vendors. Many VPNs expose
/// a `utun` interface, tunnel devices (`tun`/`tap`), or legacy `ppp`/`ipsec` interfaces. We treat the path
/// as “VPN likely” when those interface names appear while the path is satisfied.
///
/// **Limitations:** false positives/negatives are possible; users can still tap “Apply VPN Bypass” manually.
@MainActor
final class VPNMonitor: ObservableObject {
    @Published private(set) var isVPNLikelyActive: Bool = false
    @Published private(set) var activeInterfaceSummary: String = ""

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.vpnbypass.vpnmonitor")
    private var didStart = false

    func start() {
        guard !didStart else { return }
        didStart = true
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            let summary = path.availableInterfaces.map(\.name).sorted().joined(separator: ", ")
            let vpnGuess = Self.heuristicVPNLikely(path: path)
            Task { @MainActor in
                self.activeInterfaceSummary = summary
                self.isVPNLikelyActive = vpnGuess
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }

    /// Pure function: safe to call from `NWPathMonitor`'s queue (not MainActor-isolated).
    nonisolated static func heuristicVPNLikely(path: NWPath) -> Bool {
        guard path.status == .satisfied else { return false }
        return path.availableInterfaces.contains { interface in
            let name = interface.name.lowercased()
            if name.hasPrefix("utun") { return true }
            if name.hasPrefix("ppp") { return true }
            if name.contains("ipsec") { return true }
            if name.contains("tun") || name.contains("tap") { return true }
            return false
        }
    }
}
