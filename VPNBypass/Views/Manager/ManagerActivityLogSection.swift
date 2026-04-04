import SwiftUI

struct ManagerActivityLogSection: View {
    let logs: [LogEntry]
    @Binding var isExpanded: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    HStack(spacing: 10) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.white.opacity(0.06))
                                .frame(width: 28, height: 28)
                            Text(">_")
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                .foregroundStyle(Color.white.opacity(0.82))
                        }

                        Text("Activity Log")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color.white.opacity(0.92))

                        Text("\(logs.count) entries")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(ManagerDesignTokens.secondaryLabel)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    }
                    Spacer()
                    Image(systemName: "chevron.up")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.45))
                        .rotationEffect(.degrees(isExpanded ? 0 : 180))
                }
                .padding(.horizontal, 2)
                .padding(.vertical, 10)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        let visibleLogs = Array(logs.reversed().prefix(200))

                        ForEach(Array(visibleLogs.enumerated()), id: \.element.id) { index, entry in
                            ManagerLogLineView(entry: entry)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)

                            if index < visibleLogs.count - 1 {
                                Divider()
                                    .overlay(Color.white.opacity(0.08))
                                    .padding(.horizontal, 0)
                            }
                        }
                    }
                }
                .frame(minHeight: 120, maxHeight: 240)
                .background(Color.black.opacity(0.62))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
            }
        }
    }
}

private struct ManagerLogLineView: View {
    let entry: LogEntry

    private var iconName: String {
        switch entry.severity {
        case .info: return "info.circle"
        case .success: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .error: return "xmark.octagon.fill"
        }
    }

    private var iconColor: Color {
        switch entry.severity {
        case .info: return .blue
        case .success: return ManagerDesignTokens.successGreen
        case .warning: return ManagerDesignTokens.pendingYellow
        case .error: return ManagerDesignTokens.errorRed
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text(entry.timestamp.formatted(date: .omitted, time: .standard))
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(Color.white.opacity(0.28))
                .frame(width: 78, alignment: .leading)
                .padding(.top, 1)

            Image(systemName: iconName)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(iconColor)
                .frame(width: 16)
                .padding(.top, 1)

            Text(entry.message)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(Color.white.opacity(0.9))
                .lineSpacing(3)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
