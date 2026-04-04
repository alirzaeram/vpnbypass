import Foundation

/// Tracks what the app last pushed into the kernel routing table so we can remove it later.
struct RouteApplicationState: Codable, Equatable {
    /// True after a successful "Apply" until "Turn Off" (or failed apply clears it).
    var bypassActive: Bool
    /// IPv4 addresses that were included in the last apply command.
    var appliedIPv4Addresses: [String]
    /// Gateway string passed to `route add` (informational / future diagnostics).
    var lastGatewayUsed: String?
    var lastAppliedAt: Date?

    static let inactive = RouteApplicationState(
        bypassActive: false,
        appliedIPv4Addresses: [],
        lastGatewayUsed: nil,
        lastAppliedAt: nil
    )
}
