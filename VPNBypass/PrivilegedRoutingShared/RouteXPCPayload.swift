import Foundation

// MARK: - XPC wire format (JSON)

/// Operation sent from the app to the privileged helper over XPC.
/// Kept Codable + versioned so the contract can evolve without Obj‑C class sprawl.
struct RouteXPCRequestBody: Codable {
    enum Operation: String, Codable {
        case gateway
        case apply
        case remove
    }

    /// Bump when adding fields or changing semantics.
    var version: Int
    var operation: Operation
    var gateway: String?
    var ipv4: [String]?

    static let currentVersion = 1

    static func gatewayProbe() -> RouteXPCRequestBody {
        RouteXPCRequestBody(version: currentVersion, operation: .gateway, gateway: nil, ipv4: nil)
    }

    static func applyRoutes(gateway: String, ipv4: [String]) -> RouteXPCRequestBody {
        RouteXPCRequestBody(version: currentVersion, operation: .apply, gateway: gateway, ipv4: ipv4)
    }

    static func removeRoutes(ipv4: [String]) -> RouteXPCRequestBody {
        RouteXPCRequestBody(version: currentVersion, operation: .remove, gateway: nil, ipv4: ipv4)
    }
}

/// Normalized result returned from the helper (mirrors stdout-oriented script output where possible).
struct RouteXPCResultBody: Codable {
    var success: Bool
    var combinedOutput: String
    var exitCode: Int32?
    var errorMessage: String?

    static func ok(_ text: String) -> RouteXPCResultBody {
        RouteXPCResultBody(success: true, combinedOutput: text, exitCode: 0, errorMessage: nil)
    }

    static func failure(message: String, code: Int32?) -> RouteXPCResultBody {
        RouteXPCResultBody(success: false, combinedOutput: "", exitCode: code, errorMessage: message)
    }
}

enum RouteXPCEncoder {
    static func encodeRequest(_ body: RouteXPCRequestBody) throws -> Data {
        try JSONEncoder().encode(body)
    }

    static func decodeRequest(_ data: Data) throws -> RouteXPCRequestBody {
        try JSONDecoder().decode(RouteXPCRequestBody.self, from: data)
    }

    static func encodeResult(_ body: RouteXPCResultBody) throws -> Data {
        try JSONEncoder().encode(body)
    }

    static func decodeResult(_ data: Data) throws -> RouteXPCResultBody {
        try JSONDecoder().decode(RouteXPCResultBody.self, from: data)
    }
}
