import Foundation

/// Abstraction for gateway discovery and privileged route mutations.
/// UI and `RouteManager` depend only on this protocol; implementations may use:
/// - **Legacy:** `ScriptRunner` (`osascript` + administrator prompt per elevated call).
/// - **Helper:** `PrivilegedHelperClient` (XPC into a root-capable tool installed via Service Management).
protocol PrivilegedRouteExecuting: AnyObject {
    func fetchDefaultGatewayOutput() async throws -> String
    func applyRoutes(gateway: String, ipv4: [String]) async throws -> String
    func removeRoutes(ipv4: [String]) async throws -> String
}
