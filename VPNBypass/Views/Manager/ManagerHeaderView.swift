import SwiftUI
import AppKit

struct ManagerHeaderView: View {
    private var versionText: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "-"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "-"
        return "Version \(version) (\(build))"
    }
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("VPN Bypass Manager")
                    .font(.system(size: 22, weight: .bold, design: .default))
                    .foregroundStyle(.white)
                Text("Manage domains and IPs that bypass your VPN connection")
                    .font(.subheadline)
                    .foregroundStyle(ManagerDesignTokens.secondaryLabel)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            
            Divider()
                
            VStack(alignment: .trailing) {
                Text(versionText)
                    .font(.caption)
                    .foregroundStyle(ManagerDesignTokens.secondaryLabel)
                Button {
                    if let url = URL(string: "https://github.com/alirzaeram/vpnbypass") {
                        NSWorkspace.shared.open(url)
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image("github")
                            .resizable()
                            .renderingMode(.template)
                            .foregroundStyle(.white)
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                        Text("GitHub Repo")
                            .font(.caption2)
                            .foregroundStyle(.white)
                            .fixedSize(horizontal: true, vertical: true)
                    }
                    
                }
                .buttonStyle(.link)
            }
            
        }
    }
}
