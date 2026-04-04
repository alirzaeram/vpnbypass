import AppKit
import SwiftUI

struct LogsPanelView: View {
    @Binding var logs: [LogEntry]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(logs.reversed()) { entry in
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.timestamp.formatted(date: .abbreviated, time: .standard))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(entry.message)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                }
                .padding(.vertical, 2)
                .listRowSeparator(.visible)
            }
            .navigationTitle("Activity Log")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Copy All") {
                        let text = logs.map { entry in
                            "[\(entry.timestamp.formatted())] \(entry.severity.rawValue.uppercased()): \(entry.message)"
                        }.joined(separator: "\n")
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(text, forType: .string)
                    }
                }
            }
        }
        .frame(minWidth: 520, minHeight: 420)
    }
}
