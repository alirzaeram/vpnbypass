import Foundation

/// Runs `bypass_routes.sh` with root-equivalent privileges **inside the helper** (no `osascript`).
enum RouteHelperCommandHandler {
    enum RouteHelperError: LocalizedError {
        case missingScript
        case unsupportedVersion

        var errorDescription: String? {
            switch self {
            case .missingScript:
                return "The bundled routing script is missing from the helper."
            case .unsupportedVersion:
                return "Unsupported XPC protocol version."
            }
        }
    }

    static func run(request: RouteXPCRequestBody) -> RouteXPCResultBody {
        guard request.version == RouteXPCRequestBody.currentVersion else {
            return .failure(message: RouteHelperError.unsupportedVersion.localizedDescription, code: nil)
        }

        let script: URL
        do {
            script = try scriptURL()
        } catch {
            return .failure(message: error.localizedDescription, code: nil)
        }

        switch request.operation {
        case .gateway:
            return runGateway(script: script)
        case .apply:
            guard let gw = request.gateway, !gw.isEmpty else {
                return .failure(message: "apply: missing gateway", code: nil)
            }
            let ips = request.ipv4 ?? []
            guard !ips.isEmpty else {
                return .failure(message: "apply: no IPs provided", code: 2)
            }
            return runApply(script: script, gateway: gw, ipv4: ips)
        case .remove:
            let ips = request.ipv4 ?? []
            guard !ips.isEmpty else {
                return .failure(message: "remove: no IPs provided", code: 2)
            }
            return runRemove(script: script, ipv4: ips)
        }
    }

    // MARK: - Script location

    private static func scriptURL() throws -> URL {
        let fm = FileManager.default
        if let u = Bundle.main.url(forResource: "bypass_routes", withExtension: "sh") {
            return u
        }
        let exe = URL(fileURLWithPath: ProcessInfo.processInfo.arguments[0])
        let sibling = exe.deletingLastPathComponent().appendingPathComponent("bypass_routes.sh")
        if fm.fileExists(atPath: sibling.path) {
            return sibling
        }
        throw RouteHelperError.missingScript
    }

    // MARK: - Commands

    private static func runGateway(script: URL) -> RouteXPCResultBody {
        do {
            let (out, err, code) = try RouteScriptProcessRunner.runBash(script: script, arguments: ["gateway"])
            guard code == 0 else {
                return merge(stdout: out, stderr: err, code: code)
            }
            let gw = out.trimmingCharacters(in: .whitespacesAndNewlines)
            if gw.isEmpty {
                return .failure(message: "Could not read your default IPv4 gateway (is Wi‑Fi/Ethernet up?).", code: nil)
            }
            return .ok(gw)
        } catch {
            return .failure(message: error.localizedDescription, code: nil)
        }
    }

    private static func runApply(script: URL, gateway: String, ipv4: [String]) -> RouteXPCResultBody {
        do {
            let (out, err, code) = try RouteScriptProcessRunner.runBash(
                script: script,
                arguments: ["apply", gateway] + ipv4
            )
            return merge(stdout: out, stderr: err, code: code)
        } catch {
            return .failure(message: error.localizedDescription, code: nil)
        }
    }

    private static func runRemove(script: URL, ipv4: [String]) -> RouteXPCResultBody {
        do {
            let (out, err, code) = try RouteScriptProcessRunner.runBash(
                script: script,
                arguments: ["remove"] + ipv4
            )
            return merge(stdout: out, stderr: err, code: code)
        } catch {
            return .failure(message: error.localizedDescription, code: nil)
        }
    }

    private static func merge(stdout: String, stderr: String, code: Int32) -> RouteXPCResultBody {
        guard code == 0 else {
            let tail = stderr.trimmingCharacters(in: .whitespacesAndNewlines)
            let msg: String
            if tail.isEmpty {
                msg = "The script exited with code \(code)."
            } else {
                msg = "The script exited with code \(code): \(tail)"
            }
            return .failure(message: msg, code: code)
        }
        let o = stdout.trimmingCharacters(in: .whitespacesAndNewlines)
        let e = stderr.trimmingCharacters(in: .whitespacesAndNewlines)
        let combined: String
        if !e.isEmpty, !o.isEmpty {
            combined = o + "\n" + e
        } else if !e.isEmpty {
            combined = e
        } else {
            combined = o
        }
        return .ok(combined)
    }
}
