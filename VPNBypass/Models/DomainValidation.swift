import Foundation

enum DomainValidationError: LocalizedError, Equatable {
    case empty
    case tooLong
    case invalidCharacters
    case invalidStructure

    var errorDescription: String? {
        switch self {
        case .empty:
            return "Enter a domain name (for example, example.com)."
        case .tooLong:
            return "That name is too long to be a valid hostname."
        case .invalidCharacters:
            return "Only letters, numbers, dots, and hyphens are allowed in each part."
        case .invalidStructure:
            return "That does not look like a valid domain name."
        }
    }
}

enum DomainValidation {
    /// Normalizes user input: trim whitespace, lowercase, strip trailing dot.
    static func normalizedHostname(_ raw: String) -> String {
        var s = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if s.hasSuffix(".") {
            s.removeLast()
        }
        return s
    }

    /// Validates a hostname per a practical subset of RFC 1035 / common DNS usage.
    static func validate(_ raw: String) -> Result<String, DomainValidationError> {
        let host = normalizedHostname(raw)
        if host.isEmpty { return .failure(.empty) }
        if host.count > 253 { return .failure(.tooLong) }

        let labels = host.split(separator: ".", omittingEmptySubsequences: false)
        if labels.contains(where: { $0.isEmpty }) { return .failure(.invalidStructure) }
        if labels.count < 1 { return .failure(.invalidStructure) }

        for label in labels {
            if label.count > 63 { return .failure(.tooLong) }
            let ls = String(label)
            if ls == "-" || ls.hasPrefix("-") || ls.hasSuffix("-") {
                return .failure(.invalidStructure)
            }
            let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789-")
            if ls.unicodeScalars.contains(where: { !allowed.contains($0) }) {
                return .failure(.invalidCharacters)
            }
        }

        // Reject obvious URL/path mistakes.
        if host.contains("/") || host.contains(":") || host.contains(" ") {
            return .failure(.invalidStructure)
        }

        return .success(host)
    }
}
