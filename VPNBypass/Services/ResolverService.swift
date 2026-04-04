import Foundation
#if canImport(Darwin)
import Darwin
#endif

enum ResolverError: LocalizedError {
    case emptyHost
    case resolutionFailed(String)

    var errorDescription: String? {
        switch self {
        case .emptyHost:
            return "No hostname to look up."
        case .resolutionFailed(let message):
            return message
        }
    }
}

/// Resolves hostnames to IPv4 using system DNS (`getaddrinfo`). Keeps shell `dig` out of the hot path.
struct ResolverService {
    /// Returns unique IPv4 dotted-quads, stable-sorted for display.
    func resolveIPv4(hostname: String) async throws -> [String] {
        let host = DomainValidation.normalizedHostname(hostname)
        guard !host.isEmpty else { throw ResolverError.emptyHost }

        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let ips = try Self.syncResolveIPv4(host: host)
                    continuation.resume(returning: ips)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private static func syncResolveIPv4(host: String) throws -> [String] {
        var hints = addrinfo(
            ai_flags: AI_ADDRCONFIG,
            ai_family: AF_INET,
            ai_socktype: SOCK_STREAM,
            ai_protocol: IPPROTO_TCP,
            ai_addrlen: 0,
            ai_canonname: nil,
            ai_addr: nil,
            ai_next: nil
        )

        var result: UnsafeMutablePointer<addrinfo>?
        let err = getaddrinfo(host, nil, &hints, &result)
        defer { if let result { freeaddrinfo(result) } }

        guard err == 0, let first = result else {
            let message = String(cString: gai_strerror(err))
            throw ResolverError.resolutionFailed(message)
        }

        var ips: Set<String> = []
        var ptr: UnsafeMutablePointer<addrinfo>? = first
        while let node = ptr {
            if let sockaddr = node.pointee.ai_addr {
                let ipv4 = sockaddr.withMemoryRebound(to: sockaddr_in.self, capacity: 1) { sin in
                    var addr = sin.pointee.sin_addr
                    var buffer = [CChar](repeating: 0, count: Int(INET_ADDRSTRLEN))
                    let p = inet_ntop(AF_INET, &addr, &buffer, socklen_t(INET_ADDRSTRLEN))
                    return p.map { String(cString: $0) }
                }
                if let ipv4 {
                    ips.insert(ipv4)
                }
            }
            ptr = node.pointee.ai_next
        }

        if ips.isEmpty {
            throw ResolverError.resolutionFailed("No IPv4 addresses were returned for \(host).")
        }

        return ips.sorted()
    }
}
