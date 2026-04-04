import Foundation

/// Loads/saves `AppPersistence` from disk and merges bundled defaults once.
@MainActor
final class DomainStore: ObservableObject {
    @Published private(set) var persistence: AppPersistence

    private let fileURL: URL
    private let defaultsLoader: DefaultDomainsLoader
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(
        fileManager: FileManager = .default,
        defaultsLoader: DefaultDomainsLoader = DefaultDomainsLoader()
    ) {
        self.defaultsLoader = defaultsLoader
        self.encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        self.decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let support = try! fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let dir = support.appendingPathComponent("com.vpnbypass.VPNBypass", isDirectory: true)
        try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        self.fileURL = dir.appendingPathComponent("state.json")

        var initial = AppPersistence.default
        if let data = try? Data(contentsOf: fileURL),
           let loaded = try? decoder.decode(AppPersistence.self, from: data) {
            initial = loaded
        }
        // Re-merge bundle defaults on every launch so new preset hostnames appear without wiping user data.
        defaultsLoader.mergeBundledDefaultsIfNeeded(into: &initial)
        self.persistence = initial
        try? save()
    }

    func save() throws {
        let data = try encoder.encode(persistence)
        try data.write(to: fileURL, options: [.atomic])
    }

    func addDomain(hostname: String) throws {
        let normalized = DomainValidation.normalizedHostname(hostname)
        guard !persistence.domains.contains(where: { $0.hostname == normalized }) else {
            throw DomainStoreError.duplicate
        }
        persistence.domains.append(DomainRecord(hostname: normalized))
        persistence.domains.sort { $0.hostname < $1.hostname }
        try save()
    }

    func removeDomain(id: UUID) throws {
        persistence.domains.removeAll { $0.id == id }
        try save()
    }

    func setDomainIncludedInRoutes(id: UUID, included: Bool) throws {
        guard let index = persistence.domains.firstIndex(where: { $0.id == id }) else { return }
        persistence.domains[index].isIncludedInRoutes = included
        try save()
    }

    func updateRouteState(_ state: RouteApplicationState) throws {
        persistence.routeState = state
        try save()
    }

    func setRunAtLogin(_ enabled: Bool) throws {
        persistence.runAtLogin = enabled
        try save()
    }

    func setRunWhenVPNConnected(_ enabled: Bool) throws {
        persistence.runWhenVPNConnected = enabled
        try save()
    }
}

enum DomainStoreError: LocalizedError {
    case duplicate

    var errorDescription: String? {
        switch self {
        case .duplicate:
            return "That domain is already in your list."
        }
    }
}

/// Loads `default_domains.json` from the bundle and seeds the list on first run.
struct DefaultDomainsLoader {
    func mergeBundledDefaultsIfNeeded(into persistence: inout AppPersistence) {
        guard let url = Bundle.main.url(forResource: "default_domains", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let root = try? JSONDecoder().decode(DefaultDomainsFile.self, from: data) else {
            return
        }
        // Only add hostnames that are not already present (idempotent).
        let existing = Set(persistence.domains.map(\.hostname))
        for host in root.domains {
            let normalized = DomainValidation.normalizedHostname(host)
            if case .success(let valid) = DomainValidation.validate(normalized), !existing.contains(valid) {
                persistence.domains.append(DomainRecord(hostname: valid))
            }
        }
        persistence.domains.sort { $0.hostname < $1.hostname }
    }

    private struct DefaultDomainsFile: Decodable {
        let domains: [String]
    }
}
