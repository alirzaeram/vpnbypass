import Foundation

/// A hostname the user (or default list) tracks for VPN bypass routing.
struct DomainRecord: Codable, Identifiable, Equatable, Hashable {
    var id: UUID
    /// Lowercased, trimmed hostname (no scheme, no path).
    var hostname: String
    var createdAt: Date
    /// When false, DNS refresh and route application skip this domain (UI toggle).
    var isIncludedInRoutes: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case hostname
        case createdAt
        case isIncludedInRoutes
    }

    init(id: UUID = UUID(), hostname: String, createdAt: Date = Date(), isIncludedInRoutes: Bool = true) {
        self.id = id
        self.hostname = hostname
        self.createdAt = createdAt
        self.isIncludedInRoutes = isIncludedInRoutes
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        hostname = try c.decode(String.self, forKey: .hostname)
        createdAt = try c.decode(Date.self, forKey: .createdAt)
        isIncludedInRoutes = try c.decodeIfPresent(Bool.self, forKey: .isIncludedInRoutes) ?? true
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(hostname, forKey: .hostname)
        try c.encode(createdAt, forKey: .createdAt)
        try c.encode(isIncludedInRoutes, forKey: .isIncludedInRoutes)
    }
}
