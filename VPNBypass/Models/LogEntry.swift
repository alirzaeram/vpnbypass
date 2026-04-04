import Foundation

/// Single line in the in-app activity log (stdout/stderr + app messages).
struct LogEntry: Identifiable, Equatable {
    let id: UUID
    let timestamp: Date
    let message: String
    let severity: Severity

    enum Severity: String {
        case info
        case success
        case warning
        case error
    }

    init(id: UUID = UUID(), timestamp: Date = Date(), message: String, severity: Severity = .info) {
        self.id = id
        self.timestamp = timestamp
        self.message = message
        self.severity = severity
    }
}
