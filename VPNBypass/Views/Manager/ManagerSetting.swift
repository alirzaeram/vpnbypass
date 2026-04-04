
import SwiftUI

struct ManagerSetting: View {
    var isWorking: Bool
    var vpnMonitor: VPNMonitor
    var isRunAtLogin: Bool
    var isRunOnVPN: Bool
    var onToggleRunAtLogin: (Bool) -> Void
    var onToggleRunOnVPN: (Bool) -> Void

    @Binding var isExpanded: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
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
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Color.white.opacity(0.82))
                        }

                        Text("Settings")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color.white.opacity(0.92))
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
                VStack(alignment: .leading, spacing: 18) {
                    ManagerSettingCard(
                        title: "Run at Login",
                        description: "Automatically start VPN Bypass Manager when you log in to your computer. This ensures your bypass rules are always active.",
                        iconName: "play",
                        iconColor: Color.blue,
                        isOn: isRunAtLogin,
                        isDisabled: isWorking,
                        action: onToggleRunAtLogin
                    )

                    ManagerSettingCard(
                        title: "Run When VPN Connected",
                        description: "Automatically activate bypass rules when a VPN connection is detected. This helps maintain access to local services.",
                        iconName: "wifi",
                        iconColor: Color.purple,
                        isOn: isRunOnVPN,
                        isDisabled: isWorking,
                        action: onToggleRunOnVPN
                    )

//                    VPNStatusCard(vpnMonitor: vpnMonitor)
                }
                .padding(.vertical, 4)
            }
        }
    }
}

private struct ManagerSettingCard: View {
    let title: String
    let description: String
    let iconName: String
    let iconColor: Color
    let isOn: Bool
    let isDisabled: Bool
    let action: (Bool) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Toggle("", isOn: Binding(
                    get: { isOn },
                    set: { action($0) }
                ))
                .labelsHidden()
                .toggleStyle(.checkbox)
                .disabled(isDisabled)
                .padding(.top, 1)

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Image(systemName: iconName)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(iconColor)
                            .frame(width: 14)

                        Text(title)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.white.opacity(0.94))
                    }

                    Text(description)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(Color.white.opacity(0.5))
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            HStack {
                Text(isOn ? "✓  Enabled" : "Disabled")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(isOn ? Color(red: 0.26, green: 0.93, blue: 0.71) : Color.white.opacity(0.6))

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isOn ? Color(red: 0.05, green: 0.22, blue: 0.18) : Color.white.opacity(0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isOn ? Color(red: 0.12, green: 0.50, blue: 0.38) : Color.white.opacity(0.06), lineWidth: 1)
            )
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.03))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.07), lineWidth: 1)
        )
        .onTapGesture {
            action(!isOn)
        }
    }
}

private struct VPNStatusCard: View {
    let vpnMonitor: VPNMonitor

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(red: 0.09, green: 0.30, blue: 0.22))
                        .frame(width: 36, height: 36)

                    Image(systemName: vpnMonitor.isVPNLikelyActive ? "network.badge.shield.half.filled" : "network")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color(red: 0.26, green: 0.93, blue: 0.71))
                }
                .padding(.top, 1)

                VStack(alignment: .leading, spacing: 4) {
                    Text(vpnMonitor.isVPNLikelyActive ? "VPN Network Interface Active" : "VPN Network Interface Inactive")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color(red: 0.26, green: 0.93, blue: 0.71))

                    Text(
                        vpnMonitor.isVPNLikelyActive
                            ? "A VPN-style network interface appears active on your system."
                            : "No VPN-style network interface appears active on your system."
                    )
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(Color.white.opacity(0.72))
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                }
            }

            HStack(alignment: .top, spacing: 10) {
                Text("Interfaces:")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.5))

                if interfaceList.isEmpty {
                    Text("None")
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.75))
                } else {
                    FlexibleTagRow(tags: interfaceList)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.05, green: 0.18, blue: 0.14),
                            Color(red: 0.05, green: 0.12, blue: 0.14)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color(red: 0.07, green: 0.55, blue: 0.43), lineWidth: 1)
        )
    }

    private var interfaceList: [String] {
        vpnMonitor.activeInterfaceSummary
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}

private struct FlexibleTagRow: View {
    let tags: [String]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(tags, id: \.self) { tag in
                Text(tag)
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color(red: 0.26, green: 0.93, blue: 0.71))
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}
