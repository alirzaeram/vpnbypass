import Foundation

/// Coordinates gateway discovery and route mutations. Privileged work is delegated to `PrivilegedRouteExecuting`
/// (`ScriptRunner` or `PrivilegedHelperClient`, chosen by `RoutePrivilegedExecutorFactory`).
@MainActor
final class RouteManager {
    private let privilegedExecutor: any PrivilegedRouteExecuting

    init(privilegedExecutor: (any PrivilegedRouteExecuting)? = nil) {
        self.privilegedExecutor = privilegedExecutor ?? RoutePrivilegedExecutorFactory.makeDefault()
    }

    func currentGateway() async throws -> String {
        try await privilegedExecutor.fetchDefaultGatewayOutput()
    }

    func apply(gateway: String, ipv4: [String]) async throws -> String {
        let unique = Array(Set(ipv4)).sorted()
        guard !unique.isEmpty else {
            return "No IPv4 addresses to add — try Refresh after your network is ready."
        }
        return try await privilegedExecutor.applyRoutes(gateway: gateway, ipv4: unique)
    }

    func remove(ipv4: [String]) async throws -> String {
        let unique = Array(Set(ipv4)).sorted()
        guard !unique.isEmpty else {
            return "There are no saved routes to remove."
        }
        return try await privilegedExecutor.removeRoutes(ipv4: unique)
    }
}
