import Foundation

/*
 -----------------------------------------------------------------------------
 PRIVILEGED ROUTING — MIGRATION NOTES (README-style)
 -----------------------------------------------------------------------------

 **Legacy path (default)** — `usePrivilegedHelper == false`
 - `RoutePrivilegedExecutorFactory` returns `ScriptRunner`.
 - Elevated work uses `/usr/bin/osascript` with AppleScript
   `do shell script … with administrator privileges`.
 - **Why it prompts every time:** each elevated invocation is a *new* Authorization Services
   workflow; macOS does not grant your app a persistent root token. AppleScript explicitly
   requests admin rights for that one shell invocation, so the user sees the password dialog
   whenever routes are applied or removed.

 **Helper path (optional)** — `usePrivilegedHelper == true`
 - `RoutePrivilegedExecutorFactory` returns `PrivilegedHelperClient`.
 - The app sends JSON requests over XPC to `VPNBypassRouteHelper`, which runs the same
   `bypass_routes.sh` **inside the helper** as root (after install), **without** `osascript`
   from the app.
 - **Why repeated prompts stop (once installed):** the helper process is installed as a
   launchd Mach service running with the privileges it was blessed with; routine route
   changes are handled inside that already-privileged process, not via per-call AppleScript
   elevation from the GUI app.

 **Switching implementations**
 - Toggle `AppPrivilegedRoutingConfiguration.usePrivilegedHelper` below (single source of truth).
 - Rebuild. No UI changes required; `RouteManager` always uses `PrivilegedRouteExecuting`.

 **What is still manual / incomplete in this repo**
 - Code signing with a **paid Apple Developer** team, matching Team ID on app + helper.
 - `SMJobBless` (or an equivalent blessed install flow): copy helper + launchd plist into
   system locations, run the Authorization UI **once** at install time.
 - `SMAppService` registers **Login Items / non-privileged** daemons; it does **not** replace
   `SMJobBless` for a **root** routing helper. A future revision could wrap *registration UI*
   or ship a non-root helper where appropriate; the skeleton `PrivilegedHelperServiceManager`
   documents intended integration points.
 - Embedding `VPNBypassRouteHelper` under `Contents/Library/LaunchServices/` and installing
   the launchd plist — Xcode target + Copy Files phase are scaffolded; you must finish
   signing, entitlements, and `SMJobBless` wiring for production.

 -----------------------------------------------------------------------------
*/

/// Central feature flag for privileged route execution strategy.
enum AppPrivilegedRoutingConfiguration {
    /// Set to `true` to use XPC + `VPNBypassRouteHelper` once Service Management install is complete.
    /// Keep `false` for the existing `osascript` behavior (no helper required).
    static let usePrivilegedHelper = false
}
