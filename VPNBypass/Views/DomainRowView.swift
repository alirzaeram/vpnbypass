import SwiftUI

struct DomainRowView: View {
    let row: DomainRowDisplay

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(row.hostname)
                    .font(.headline)
                Spacer()
                resolutionBadge
                bypassBadge
            }

            switch row.resolution {
            case .idle:
                Text("Not checked yet — tap Refresh.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            case .resolving:
                HStack(spacing: 6) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Looking up addresses…")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            case .resolved(let ips):
                Text(ips.joined(separator: ", "))
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
            case .failed(let reason):
                Text(reason)
                    .font(.subheadline)
                    .foregroundStyle(.red)
            }

            if let checked = row.lastChecked {
                Text("Last checked: \(checked.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private var resolutionBadge: some View {
        let isBypassActive = row.globalBypassActive && row.bypassCoversThisDomain
        let resolvedColor: Color = isBypassActive ? .green : .gray
        let failedColor: Color = isBypassActive ? .orange : .gray
        let resolvingColor: Color = isBypassActive ? .blue : .gray
        let idleColor: Color = isBypassActive ? .secondary : .gray

        return Group {
            switch row.resolution {
            case .resolved:
                Label("Resolved", systemImage: "checkmark.circle.fill")
                    .labelStyle(.iconOnly)
                    .foregroundStyle(resolvedColor)
                    .help("Resolved to IPv4")
            case .failed:
                Label("Error", systemImage: "exclamationmark.triangle.fill")
                    .labelStyle(.iconOnly)
                    .foregroundStyle(failedColor)
                    .help("Lookup failed")
            case .resolving:
                Label("Resolving", systemImage: "arrow.triangle.2.circlepath")
                    .labelStyle(.iconOnly)
                    .foregroundStyle(resolvingColor)
                    .help("Resolving")
            case .idle:
                Label("Unknown", systemImage: "questionmark.circle")
                    .labelStyle(.iconOnly)
                    .foregroundStyle(idleColor)
                    .help("Not checked")
            }
        }
    }

    private var bypassBadge: some View {
        let active = row.globalBypassActive && row.bypassCoversThisDomain
        return HStack(spacing: 4) {
            Image(systemName: active ? "lock.open.display" : "lock.fill")
            Text(active ? "Bypass active" : "Bypass off")
                .font(.caption)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(active ? Color.green.opacity(0.15) : Color.secondary.opacity(0.12))
        .clipShape(Capsule())
        .foregroundStyle(active ? Color.green : Color.secondary)
    }
}
