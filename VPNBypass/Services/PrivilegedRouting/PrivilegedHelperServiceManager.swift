import Foundation
import ServiceManagement

/// Skeleton for installing / registering the privileged helper with **Service Management**.
///
/// **Production path:** use `SMJobBless` (Security.framework + Authorization Services) so the user
/// authorizes **once**; launchd then starts `VPNBypassRouteHelper` as the Mach service named
/// `RouteXPCConstants.machServiceName`.
///
/// **`SMAppService` (macOS 13+):** `SMAppService.daemon(plistName:)` is appropriate for daemons
/// bundled inside the app that run **without** root. It does **not** grant `route` privileges.
/// Do not assume `SMAppService` alone replaces `SMJobBless` for this routing helper.
///
/// This type intentionally returns stub values so the project compiles before you wire signing,
/// `launchd` plists, and `SMJobBless` in Xcode.
enum PrivilegedHelperServiceManager {
    enum RegistrationState {
        case notAttempted
        case requiresManualSMJobBless
    }

    /// Placeholder: returns `.requiresManualSMJobBless`. Replace with real `SMJobBless` flow.
    static func currentRegistrationState() -> RegistrationState {
        .requiresManualSMJobBless
    }

    /// Placeholder for a future `SMAppService`-based flow (non-root daemon only).
    static func registerBundledDaemonStub(plistName: String) -> Bool {
        _ = plistName
        // Example only (would register a **non-privileged** bundled plist):
        // let svc = SMAppService.daemon(plistName: plistName)
        // try? svc.register()
        return false
    }
}
