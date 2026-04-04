import SwiftUI

struct ManagerActionFooter: View {
    var isWorking: Bool
    var isBypassing: Bool
    var canApply: Bool
    var onResolve: () -> Void
    var onApplyBypass: () -> Void
    var onTurnOffBypass: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            Button(action: onResolve) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 14, weight: .medium))
                    Text("Resolve IPs")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundStyle(Color.white.opacity(0.78))
                .padding(.horizontal, 18)
                .frame(height: 38)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.white.opacity(0.07))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .frame(width: 140)
            .disabled(isWorking)
            .opacity(isWorking ? 0.6 : 1)

            Spacer()

            if isBypassing {
                Button(action: onTurnOffBypass) {
                    HStack(spacing: 10) {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .bold))
                        Text("Turn Off VPN Bypass")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(minWidth: 290)
                    .frame(height: 38)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 1.0, green: 0.0, blue: 0.07),
                                        Color(red: 0.92, green: 0.05, blue: 0.53)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Color.white.opacity(0.18), lineWidth: 1)
                    )
                    .shadow(color: Color(red: 1.0, green: 0.15, blue: 0.35).opacity(0.35), radius: 14, x: 0, y: 6)
                }
                .buttonStyle(.plain)
                .disabled(isWorking)
                .opacity(isWorking ? 0.7 : 1)
            } else {
                Button(action: onApplyBypass) {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 13, weight: .bold))
                        Text("Apply VPN Bypass")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundStyle(Color.white.opacity(canApply ? 0.96 : 0.58))
                    .frame(minWidth: 290)
                    .frame(height: 38)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: canApply
                                        ? [
                                            Color(red: 0.04, green: 0.58, blue: 1.0),
                                            Color(red: 0.10, green: 0.35, blue: 1.0)
                                        ]
                                        : [
                                            Color.white.opacity(0.08),
                                            Color.white.opacity(0.05)
                                        ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(
                                canApply
                                    ? Color.white.opacity(0.16)
                                    : Color.white.opacity(0.07),
                                lineWidth: 1
                            )
                    )
                    .shadow(
                        color: canApply
                            ? ManagerDesignTokens.accentBlue.opacity(0.28)
                            : Color.clear,
                        radius: 14,
                        x: 0,
                        y: 6
                    )
                }
                .buttonStyle(.plain)
                .disabled(isWorking || !canApply)
                .opacity(isWorking ? 0.7 : 1)
            }
        }
    }
}
