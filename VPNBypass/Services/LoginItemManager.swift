import Foundation
import ServiceManagement

/// Wraps the modern login-item API (`SMAppService`) available starting in macOS 13.
///
/// **Compatibility:** There is no Apple-supported “launch at login” API for sandboxed Mac App Store apps
/// that also need to modify system routes. This project targets a **non-sandboxed** utility build where
/// `SMAppService` is the recommended path. Older macOS versions are not supported by this target.
enum LoginItemManager {
    enum LoginItemError: LocalizedError {
        case unsupported

        var errorDescription: String? {
            "Login items require macOS 13 or newer (SMAppService)."
        }
    }

    @available(macOS 13.0, *)
    static func setEnabled(_ enabled: Bool) throws {
        if enabled {
            try SMAppService.mainApp.register()
        } else {
            try SMAppService.mainApp.unregister()
        }
    }

    @available(macOS 13.0, *)
    static var status: SMAppService.Status {
        SMAppService.mainApp.status
    }

    @available(macOS 13.0, *)
    static var statusLine: String {
        switch SMAppService.mainApp.status {
        case .notFound:
            return "Not registered"
        case .enabled:
            return "Enabled"
        case .requiresApproval:
            return "Waiting for approval in System Settings → General → Login Items"
        case .notRegistered:
            return "Not registered"
        @unknown default:
            return "Unknown status"
        }
    }
}
