import Foundation

/// Mach service name must match the `MachServices` entry in the helper’s launchd property list
/// and the identifier used with `SMJobBless` / Service Management registration.
enum RouteXPCConstants {
    static let machServiceName = "com.vpnbypass.VPNBypass.route-helper"
}

/// XPC surface between `PrivilegedHelperClient` (app) and the helper executable.
/// Single entry point keeps the Obj‑C runtime export small and lets Swift own payload evolution via `RouteXPCRequestBody`.
@objc(RouteHelperXPCProtocol)
protocol RouteHelperXPCProtocol {
    func executeRequest(_ requestData: Data, withReply reply: @escaping (Data?, NSError?) -> Void)
}
