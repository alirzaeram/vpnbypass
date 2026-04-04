import SwiftUI

struct BypassStatusBanner: View {
    let isBypassing: Bool
    let resolvedIncludedCount: Int
    let includedCount: Int

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            Image(systemName: isBypassing ? "shield.lefthalf.filled" : "shield")
                .font(.system(size: 28, weight: .regular))
                .foregroundStyle(isBypassing ? ManagerDesignTokens.successGreen : ManagerDesignTokens.secondaryLabel)
                .symbolRenderingMode(.hierarchical)

            VStack(alignment: .leading, spacing: 4) {
                Text(isBypassing ? "VPN Bypass Active" : "VPN Bypass Inactive")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
                Text(
                    isBypassing
                        ? "Bypass rules are applied for resolved domains."
                        : "No bypass rules are currently applied."
                )
                .font(.caption)
                .foregroundStyle(ManagerDesignTokens.secondaryLabel)
            }

            Spacer(minLength: 8)

            Text(
                includedCount == 0
                    ? "0 / 0"
                    : "\(resolvedIncludedCount) / \(includedCount)"
            )
                .font(.caption.monospacedDigit())
                .foregroundStyle(ManagerDesignTokens.secondaryLabel)
        }
        .padding(14)
        .background(ManagerDesignTokens.surface)
        .clipShape(RoundedRectangle(cornerRadius: ManagerDesignTokens.cardRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: ManagerDesignTokens.cardRadius, style: .continuous)
                .stroke(ManagerDesignTokens.border, lineWidth: 1)
        )
    }
}
