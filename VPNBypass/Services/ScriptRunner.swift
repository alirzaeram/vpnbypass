import Foundation

/// Runs the bundled `bypass_routes.sh` either directly (gateway probe) or via a one-shot admin prompt.
///
/// **Legacy / fallback path** — implements `PrivilegedRouteExecuting` using AppleScript elevation.
///
/// **Why this prompts every time:** `osascript` runs `do shell script … with administrator privileges`,
/// which triggers Authorization Services for *that single shell invocation*. macOS does not hand the app
/// a long-lived root session, so each `apply` / `remove` is a new admin prompt.
///
/// **To avoid repeated prompts:** set `AppPrivilegedRoutingConfiguration.usePrivilegedHelper = true` and
/// complete `SMJobBless` + signing so `PrivilegedHelperClient` talks to `VPNBypassRouteHelper` instead.
///
/// **Privileged operations are isolated behind `PrivilegedRouteExecuting`** so UI code stays unchanged.
final class ScriptRunner {
    enum ScriptError: LocalizedError {
        case missingBundledScript
        case processFailed(code: Int32, stderr: String)
        case emptyGateway
        case userCancelledAdmin

        var errorDescription: String? {
            switch self {
            case .missingBundledScript:
                return "The bundled routing script is missing from the app."
            case .processFailed(let code, let stderr):
                let tail = stderr.trimmingCharacters(in: .whitespacesAndNewlines)
                if tail.isEmpty {
                    return "The script exited with code \(code)."
                }
                return "The script exited with code \(code): \(tail)"
            case .emptyGateway:
                return "Could not read your default IPv4 gateway (is Wi‑Fi/Ethernet up?)."
            case .userCancelledAdmin:
                return "Administrator permission is required to change routes. You can try again when ready."
            }
        }
    }

    private let appSupportSubdirectory = "com.vpnbypass.VPNBypass"
    private let installedScriptName = "bypass_routes.sh"

    /// Copies the bundled script into Application Support and ensures it is executable.
    func preparedScriptURL() throws -> URL {
        guard let bundled = Bundle.main.url(forResource: "bypass_routes", withExtension: "sh") else {
            throw ScriptError.missingBundledScript
        }

        let fm = FileManager.default
        let support = try fm.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let dir = support.appendingPathComponent(appSupportSubdirectory, isDirectory: true)
        try fm.createDirectory(at: dir, withIntermediateDirectories: true)

        let destination = dir.appendingPathComponent(installedScriptName)
        if !fm.fileExists(atPath: destination.path) {
            try fm.copyItem(at: bundled, to: destination)
        } else {
            // Refresh if the bundle version changed (compare sizes + bundle short version as a simple signal).
            let bAttr = try fm.attributesOfItem(atPath: bundled.path)
            let dAttr = try fm.attributesOfItem(atPath: destination.path)
            let bSize = (bAttr[.size] as? NSNumber)?.int64Value
            let dSize = (dAttr[.size] as? NSNumber)?.int64Value
            if bSize != dSize {
                let tmp = destination.appendingPathExtension("new")
                try? fm.removeItem(at: tmp)
                try fm.copyItem(at: bundled, to: tmp)
                try fm.removeItem(at: destination)
                try fm.moveItem(at: tmp, to: destination)
            }
        }

        try fm.setAttributes([.posixPermissions: NSNumber(value: 0o755)], ofItemAtPath: destination.path)
        return destination
    }

    /// Reads the default IPv4 gateway using the same script the privileged path will execute (consistency).
    func fetchDefaultGatewayOutput() async throws -> String {
        let script = try preparedScriptURL()
        let (out, err, code) = try await runDirect(script: script, arguments: ["gateway"])
        guard code == 0 else {
            throw ScriptError.processFailed(code: code, stderr: err)
        }
        let gw = out.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !gw.isEmpty else { throw ScriptError.emptyGateway }
        return gw
    }

    /// Applies host routes (prompts for admin).
    func applyRoutes(gateway: String, ipv4: [String]) async throws -> String {
        let script = try preparedScriptURL()
        return try await runElevated(script: script, arguments: ["apply", gateway] + ipv4)
    }

    /// Removes host routes (prompts for admin).
    func removeRoutes(ipv4: [String]) async throws -> String {
        let script = try preparedScriptURL()
        return try await runElevated(script: script, arguments: ["remove"] + ipv4)
    }

    // MARK: - Process execution

    private func runDirect(script: URL, arguments: [String]) async throws -> (stdout: String, stderr: String, code: Int32) {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let result = try Self.runProcess(
                        executable: URL(fileURLWithPath: "/bin/bash"),
                        arguments: [script.path] + arguments
                    )
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func runElevated(script: URL, arguments: [String]) async throws -> String {
        // Each call goes through AppleScript’s one-shot admin elevation, so the user sees a password
        // prompt every time — unlike an SMJobBless’d helper, which runs privileged work in a long-lived process.
        // Build a tiny wrapper shell script that invokes our bundled script with fixed arguments.
        // This avoids brittle nested quoting inside a single `osascript -e` line.
        let wrapper = try writeWrapper(script: script, arguments: arguments)
        defer { try? FileManager.default.removeItem(at: wrapper) }

        let appleScript = Self.appleScriptToRunBashScript(at: wrapper)

        let (out, err, code) = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<(String, String, Int32), Error>) in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let result = try Self.runProcess(
                        executable: URL(fileURLWithPath: "/usr/bin/osascript"),
                        arguments: ["-e", appleScript]
                    )
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }

        // osascript returns -128 when the user cancels the admin prompt.
        if code == -128 || code == 255 {
            let combined = (out + "\n" + err).lowercased()
            if combined.contains("canceled") || combined.contains("cancelled") || code == -128 {
                throw ScriptError.userCancelledAdmin
            }
        }

        guard code == 0 else {
            throw ScriptError.processFailed(code: code, stderr: err.isEmpty ? out : err)
        }

        let trimmedOut = out.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedErr = err.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedErr.isEmpty, !trimmedOut.isEmpty {
            return trimmedOut + "\n" + trimmedErr
        }
        if !trimmedErr.isEmpty { return trimmedErr }
        return trimmedOut
    }

    private func writeWrapper(script: URL, arguments: [String]) throws -> URL {
        var parts: [String] = [script.path.shellSingleQuoted]
        for arg in arguments {
            parts.append(arg.shellSingleQuoted)
        }
        let body = "#!/bin/bash\nset -euo pipefail\nexec /bin/bash " + parts.joined(separator: " ") + "\n"

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("vpnbypass-admin-\(UUID().uuidString).sh")
        try body.data(using: .utf8)?.write(to: url, options: [.atomic])
        try FileManager.default.setAttributes([.posixPermissions: NSNumber(value: 0o700)], ofItemAtPath: url.path)
        return url
    }

    private static func appleScriptToRunBashScript(at url: URL) -> String {
        let path = url.path.appleScriptStringLiteral
        return "do shell script quoted form of \"/bin/bash\" & \" \" & quoted form of \"\(path)\" with administrator privileges"
    }

    private static func runProcess(executable: URL, arguments: [String]) throws -> (stdout: String, stderr: String, code: Int32) {
        try RouteScriptProcessRunner.run(executable: executable, arguments: arguments)
    }
}

extension ScriptRunner: PrivilegedRouteExecuting {}

private extension String {
    /// Safe single-quoted literal for bash: 'foo' with embedded ' escaped as '\''
    var shellSingleQuoted: String {
        "'" + replacingOccurrences(of: "'", with: "'\\''") + "'"
    }

    /// Escape for AppleScript string literal inside Swift.
    var appleScriptStringLiteral: String {
        replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
    }
}
