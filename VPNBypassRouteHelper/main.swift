import Foundation

/// Standalone Mach service entry point. launchd starts this executable and hands it the Mach service
/// name from the plist (`MachServices` → `com.vpnbypass.VPNBypass.route-helper`).
let listener = NSXPCListener(machServiceName: RouteXPCConstants.machServiceName)
let delegate = RouteHelperXPCListenerDelegate()
listener.delegate = delegate
listener.resume()
RunLoop.main.run()
