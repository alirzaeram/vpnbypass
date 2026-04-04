import Foundation

/// XPC client for `VPNBypassRouteHelper`. Does **not** use `osascript`; elevation is expected to live
/// in the already-installed helper process.
final class PrivilegedHelperClient: PrivilegedRouteExecuting {
    enum PrivilegedHelperClientError: LocalizedError {
        case connectionInvalidated
        case connectionInterrupted
        case badProxy
        case emptyReply
        case timeout(seconds: TimeInterval)
        case helperRejected(message: String, code: Int32?)
        case decodeFailure

        var errorDescription: String? {
            switch self {
            case .connectionInvalidated:
                return "Lost connection to the route helper. Is it installed and registered with launchd?"
            case .connectionInterrupted:
                return "The route helper stopped responding."
            case .badProxy:
                return "Could not create an XPC proxy to the route helper."
            case .emptyReply:
                return "The route helper returned an empty response."
            case .timeout(let seconds):
                return "The route helper did not respond within \(Int(seconds)) seconds."
            case .helperRejected(let message, _):
                return message
            case .decodeFailure:
                return "Could not read the route helper response."
            }
        }
    }

    private static let requestTimeout: TimeInterval = 120

    func fetchDefaultGatewayOutput() async throws -> String {
        try await Self.withTimeout(seconds: Self.requestTimeout) {
            try await Self.performXPC(RouteXPCRequestBody.gatewayProbe())
        }
    }

    func applyRoutes(gateway: String, ipv4: [String]) async throws -> String {
        try await Self.withTimeout(seconds: Self.requestTimeout) {
            try await Self.performXPC(RouteXPCRequestBody.applyRoutes(gateway: gateway, ipv4: ipv4))
        }
    }

    func removeRoutes(ipv4: [String]) async throws -> String {
        try await Self.withTimeout(seconds: Self.requestTimeout) {
            try await Self.performXPC(RouteXPCRequestBody.removeRoutes(ipv4: ipv4))
        }
    }

    // MARK: - XPC + timeout

    private static func withTimeout(seconds: TimeInterval, _ operation: @escaping () async throws -> String) async throws -> String {
        try await withThrowingTaskGroup(of: String.self) { group in
            group.addTask {
                try await operation()
            }
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw PrivilegedHelperClientError.timeout(seconds: seconds)
            }
            defer { group.cancelAll() }
            guard let first = try await group.next() else {
                throw PrivilegedHelperClientError.emptyReply
            }
            return first
        }
    }

    private static func performXPC(_ body: RouteXPCRequestBody) async throws -> String {
        let payload = try RouteXPCEncoder.encodeRequest(body)
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
            let connection = NSXPCConnection(machServiceName: RouteXPCConstants.machServiceName, options: .privileged)
            connection.remoteObjectInterface = NSXPCInterface(with: RouteHelperXPCProtocol.self)

            var completed = false
            func finish(_ result: Result<String, Error>) {
                guard !completed else { return }
                completed = true
                continuation.resume(with: result)
                connection.invalidate()
            }

            connection.invalidationHandler = {
                finish(.failure(PrivilegedHelperClientError.connectionInvalidated))
            }
            connection.interruptionHandler = {
                finish(.failure(PrivilegedHelperClientError.connectionInterrupted))
            }

            connection.resume()

            guard let proxy = connection.remoteObjectProxyWithErrorHandler({ error in
                finish(.failure(error))
            }) as? RouteHelperXPCProtocol else {
                finish(.failure(PrivilegedHelperClientError.badProxy))
                return
            }

            proxy.executeRequest(payload) { replyData, replyError in
                if let replyError {
                    finish(.failure(replyError))
                    return
                }
                guard let replyData else {
                    finish(.failure(PrivilegedHelperClientError.emptyReply))
                    return
                }
                do {
                    let decoded = try RouteXPCEncoder.decodeResult(replyData)
                    if decoded.success {
                        finish(.success(mergedText(from: decoded)))
                    } else {
                        let msg = decoded.errorMessage ?? "The helper reported a failure."
                        finish(.failure(PrivilegedHelperClientError.helperRejected(message: msg, code: decoded.exitCode)))
                    }
                } catch {
                    finish(.failure(PrivilegedHelperClientError.decodeFailure))
                }
            }
        }
    }

    private static func mergedText(from result: RouteXPCResultBody) -> String {
        result.combinedOutput.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
