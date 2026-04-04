import Foundation

/// Root persistence document stored as JSON under Application Support.
/// Kept `Codable` and free of UI types so it stays easy to test and evolve.
struct AppPersistence: Codable, Equatable {
    var domains: [DomainRecord]
    var routeState: RouteApplicationState
    var runAtLogin: Bool
    var runWhenVPNConnected: Bool

    static let `default` = AppPersistence(
        domains: [],
        routeState: .inactive,
        runAtLogin: false,
        runWhenVPNConnected: false
    )
}
