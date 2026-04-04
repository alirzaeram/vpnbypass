import SwiftUI

struct ManagedDomainCardView: View {
    let row: DomainRowDisplay
    var isWorking: Bool
    var isBypassing: Bool
    var onRemove: () -> Void
    var isOn: Bool
    var onToggleChanged: (Bool) -> Void

    private var accent: Color {
        switch row.resolution {
        case .failed:
            return ManagerDesignTokens.errorRed
        case .resolved:
            return ManagerDesignTokens.successGreen
        case .idle, .resolving:
            return ManagerDesignTokens.pendingYellow
        }
    }

    private var statusPill: (String, Color, Color) {
        switch row.resolution {
        case .failed:
            return ("Error", ManagerDesignTokens.errorRed.opacity(0.22), ManagerDesignTokens.errorRed)
        case .resolved:
            return ("Active", ManagerDesignTokens.successGreen.opacity(0.2), ManagerDesignTokens.successGreen)
        case .idle, .resolving:
            return (
                "Pending Resolution",
                ManagerDesignTokens.pendingYellow.opacity(0.18),
                ManagerDesignTokens.pendingYellow
            )
        }
    }

    private var subtitle: String {
        switch row.resolution {
        case .failed(let reason):
            return reason
        case .resolved(let ips):
            return ips.isEmpty ? "—" : ips.joined(separator: ", ")
        case .resolving:
            return "Looking up addresses…"
        case .idle:
            return "Awaiting IP resolution"
        }
    }
    
    private var lastCheck: String {
        guard let lastChecked = row.lastChecked else { return "never checked yet" }

        let seconds = Int(Date().timeIntervalSince(lastChecked))
        let text = "Checked"

        if seconds < 60 {
            return "\(text) less than a min ago"
        } else if seconds < 3600 {
            let minutes = seconds / 60
            return "\(text) \(minutes) min ago"
        } else if seconds < 86400 {
            let hours = seconds / 3600
            return "\(text) \(hours)h ago"
        } else {
            let days = seconds / 86400
            return "\(text) \(days)d ago"
        }
    }

    private var leadingSymbol: String {
        switch row.resolution {
        case .failed:
            return "xmark"
        case .resolved:
            return "checkmark"
        case .idle, .resolving:
            return "exclamationmark"
        }
    }

    var body: some View {
        let pill = statusPill

        HStack(alignment: .center, spacing: 12) {
            ZStack {
                Circle()
                    .fill(accent.opacity(0.22))
                    .frame(width: 36, height: 36)
                Image(systemName: leadingSymbol)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(accent)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(row.hostname)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(row.resolution.isFailed ? ManagerDesignTokens.errorRed : ManagerDesignTokens.secondaryLabel)
                    .lineLimit(2)
                
                Text(lastCheck)
                    .font(.caption)
                    .foregroundStyle(row.resolution.isFailed ? ManagerDesignTokens.errorRed : ManagerDesignTokens.secondaryLabel)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            Text(isBypassing && row.isIncludedInRoutes ? pill.0 : "inactive")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(isBypassing && row.isIncludedInRoutes ? pill.2 : .white.opacity(0.6))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(isBypassing && row.isIncludedInRoutes ? pill.1 : .white.opacity(0.06))
                .clipShape(Capsule())
            
            Toggle("", isOn: Binding(
                get: { isOn },
                set: { onToggleChanged($0 ) }
            ))
            .labelsHidden()
            .toggleStyle(.switch)
            .disabled(isWorking)
                

            Button(action: onRemove) {
                Image(systemName: "trash")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(ManagerDesignTokens.secondaryLabel)
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Remove domain")
            .disabled(isWorking)
        }
        .padding(12)
        .background(ManagerDesignTokens.surface)
        .clipShape(RoundedRectangle(cornerRadius: ManagerDesignTokens.cardRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: ManagerDesignTokens.cardRadius, style: .continuous)
                .stroke(accent.opacity(0.45), lineWidth: 1)
        )
        .allowsHitTesting(!isBypassing)
        .opacity(isBypassing ? 0.6 : 1.0)
    }
}

private extension ResolutionDisplayState {
    var isFailed: Bool {
        if case .failed = self { return true }
        return false
    }
}
