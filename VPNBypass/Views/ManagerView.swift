import SwiftUI

struct ManagerView: View {
    @ObservedObject var viewModel: DomainListViewModel
    @State private var activityLogExpanded = false
    @State private var settingExpanded = false
    @State private var managedDomainExpanded = true

    private var includedRows: [DomainRowDisplay] {
        viewModel.rows.filter(\.isIncludedInRoutes)
    }

    private var resolvedInListCount: Int {
        viewModel.rows.filter { row in
            guard row.isIncludedInRoutes else { return false }
            if case .resolved(let ips) = row.resolution { return !ips.isEmpty }
            return false
        }.count
    }

    private var canApplyBypass: Bool {
        includedRows.contains { row in
            if case .resolved(let ips) = row.resolution { return !ips.isEmpty }
            return false
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ManagerHeaderView()

                BypassStatusBanner(
                    isBypassing: viewModel.isBypassing,
                    resolvedIncludedCount: resolvedInListCount,
                    includedCount: viewModel.rows.count
                )

                if let error = viewModel.userFacingError {
                    Divider()
                    errorBanner(error)
                }
                
                Divider()
                
                ManagedDomainsSection(
                        text: $viewModel.newDomainText,
                        rows: viewModel.rows,
                        isWorking: viewModel.isWorking,
                        isBypassing: viewModel.isBypassing,
                        onRemove: { viewModel.removeDomain(id: $0) },
                        onToggleChange: { viewModel.setDomainIncludedInRoutes(id: $0, included: $1) },
                        onNewDomain: { viewModel.addDomain() },
                        isExpanded: $managedDomainExpanded)
                

                Divider()
                
                ManagerActionFooter(
                    isWorking: viewModel.isWorking,
                    isBypassing: viewModel.isBypassing,
                    canApply: canApplyBypass && !viewModel.rows.isEmpty,
                    onResolve: { Task { await viewModel.refreshAll() } },
                    onApplyBypass: { Task { await viewModel.applyBypass() } },
                    onTurnOffBypass: { Task { await viewModel.turnOffBypass() } }
                )
                
                Divider()
                
                ManagerSetting(
                    isWorking: viewModel.isWorking,
                    vpnMonitor: viewModel.vpnMonitor,
                    isRunAtLogin: viewModel.runAtLoginEnabled,
                    isRunOnVPN: viewModel.runWhenVPNConnectedEnabled,
                    onToggleRunAtLogin: { viewModel.setRunAtLogin($0) },
                    onToggleRunOnVPN: { viewModel.setRunWhenVPNConnected($0) },
                    isExpanded: $settingExpanded)

                Divider()
                
                ManagerActivityLogSection(logs: viewModel.logs, isExpanded: $activityLogExpanded)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ManagerDesignTokens.background)
        .preferredColorScheme(.dark)
        .onAppear {
            viewModel.onAppear()
        }
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.octagon.fill")
                .foregroundStyle(ManagerDesignTokens.pendingYellow)
            Text(message)
                .font(.callout)
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 8)
            Button("Dismiss") {
                viewModel.clearUserError()
            }
            .buttonStyle(.borderless)
            .foregroundStyle(ManagerDesignTokens.accentBlue)
        }
        .padding(12)
        .background(ManagerDesignTokens.pendingYellow.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: ManagerDesignTokens.cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: ManagerDesignTokens.cornerRadius, style: .continuous)
                .stroke(ManagerDesignTokens.pendingYellow.opacity(0.35), lineWidth: 1)
        )
    }
}
