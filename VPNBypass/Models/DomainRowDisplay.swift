import Foundation

/// Resolution outcome for UI badges and IP display.
enum ResolutionDisplayState: Equatable {
    case idle
    case resolving
    case resolved([String])
    case failed(String)
}

/// One row in the domain list (persisted hostname + ephemeral resolution + bypass hint).
struct DomainRowDisplay: Identifiable, Equatable {
    let id: UUID
    let hostname: String
    let resolution: ResolutionDisplayState
    let lastChecked: Date?
    /// Whether this domain's current IPv4 set is fully covered by the last applied route batch.
    let bypassCoversThisDomain: Bool
    /// Global bypass switch from persistence (routes were applied and not turned off).
    let globalBypassActive: Bool
    /// Included in resolve/apply when true.
    let isIncludedInRoutes: Bool
}
