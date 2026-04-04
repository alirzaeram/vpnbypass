import Foundation

/// Chooses the concrete `PrivilegedRouteExecuting` implementation from `AppPrivilegedRoutingConfiguration`.
enum RoutePrivilegedExecutorFactory {
    static func makeDefault() -> any PrivilegedRouteExecuting {
        if AppPrivilegedRoutingConfiguration.usePrivilegedHelper {
            return PrivilegedHelperClient()
        }
        return ScriptRunner()
    }
}
