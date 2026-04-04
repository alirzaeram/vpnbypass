import SwiftUI

struct MainView: View {
    @ObservedObject var viewModel: DomainListViewModel

    var body: some View {
        NavigationSplitView {
            domainSidebar
                .navigationSplitViewColumnWidth(min: 320, ideal: 380, max: 520)
        } detail: {
            detailPanel
        }
        .sheet(isPresented: $viewModel.showLogsSheet) {
            LogsPanelView(logs: $viewModel.logs)
        }
        .onAppear {
            viewModel.onAppear()
        }
    }

    private var domainSidebar: some View {
        VStack(alignment: .leading, spacing: 12) {
            GroupBox("Domains") {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .center, spacing: 8) {
                        TextField("example.com", text: $viewModel.newDomainText)
                            .textFieldStyle(.roundedBorder)
                            .onSubmit { viewModel.addDomain() }

                        Button("Add") {
                            viewModel.addDomain()
                        }
                        .keyboardShortcut(.defaultAction)
                        .disabled(viewModel.newDomainText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }

                    HStack(spacing: 8) {
                        Button {
                            Task { await viewModel.refreshAll() }
                        } label: {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }
                        .disabled(viewModel.isWorking)

                        Spacer()

                        Button {
                            viewModel.showLogsSheet = true
                        } label: {
                            Label("Logs", systemImage: "doc.text")
                        }
                        .disabled(viewModel.logs.isEmpty)
                    }
                    .controlSize(.regular)

                    if let error = viewModel.userFacingError {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "exclamationmark.octagon.fill")
                                .foregroundStyle(.orange)
                            Text(error)
                                .font(.callout)
                            Spacer(minLength: 0)
                            Button("Dismiss") {
                                viewModel.clearUserError()
                            }
                            .buttonStyle(.borderless)
                        }
                        .padding(10)
                        .background(Color.orange.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    List(selection: $viewModel.selection) {
                        ForEach(viewModel.rows) { row in
                            DomainRowView(row: row)
                                .tag(row.id)
                        }
                    }
                    .listStyle(.inset(alternatesRowBackgrounds: true))

                    HStack {
                        Button(role: .destructive) {
                            viewModel.removeSelectedDomains()
                        } label: {
                            Label("Remove Selected", systemImage: "trash")
                        }
                        .disabled(viewModel.selection.isEmpty || viewModel.isWorking)

                        Spacer()
                    }
                }
                .padding(.vertical, 4)
            }

            GroupBox("Startup & VPN") {
                VStack(alignment: .leading, spacing: 10) {
                    Toggle(
                        "Run at Login",
                        isOn: Binding(
                            get: { viewModel.runAtLoginEnabled },
                            set: { viewModel.setRunAtLogin($0) }
                        )
                    )
                    .disabled(viewModel.isWorking)

                    if #available(macOS 13.0, *) {
                        Text(LoginItemManager.statusLine)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Divider()

                    Toggle(
                        "Run when VPN connected",
                        isOn: Binding(
                            get: { viewModel.runWhenVPNConnectedEnabled },
                            set: { viewModel.setRunWhenVPNConnected($0) }
                        )
                    )
                    .disabled(viewModel.isWorking)

                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: viewModel.vpnMonitor.isVPNLikelyActive ? "network.badge.shield.half.filled" : "network")
                            .foregroundStyle(viewModel.vpnMonitor.isVPNLikelyActive ? .green : .secondary)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(
                                viewModel.vpnMonitor.isVPNLikelyActive
                                    ? "A VPN-style network interface appears active."
                                    : "No VPN-style interface detected (heuristic)."
                            )
                            .font(.callout)
                            if !viewModel.vpnMonitor.activeInterfaceSummary.isEmpty {
                                Text("Interfaces: \(viewModel.vpnMonitor.activeInterfaceSummary)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .textSelection(.enabled)
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .navigationTitle("VPN Bypass")
    }

    private var detailPanel: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                
                HStack {
                    Spacer()
                    
                    Button {
                        Task { await viewModel.applyBypass() }
                    } label: {
                        Label("Apply VPN Bypass", systemImage: "bolt.horizontal.circle")
                    }
                    .disabled(viewModel.isWorking || viewModel.store.persistence.domains.isEmpty || viewModel.isBypassing)
                    .keyboardShortcut("a", modifiers: [.command, .shift])
                    
                    Button(role: .destructive) {
                        Task { await viewModel.turnOffBypass() }
                    } label: {
                        Label("Turn Off Bypass", systemImage: "xmark.circle")
                    }
                    .disabled(viewModel.isWorking || !viewModel.isBypassing)
                }
                
                Text("How it works")
                    .font(.title2.weight(.semibold))

                VStack(alignment: .leading, spacing: 8) {
                    Label("Add domains you want to reach through your normal internet connection instead of the VPN tunnel.", systemImage: "1.circle.fill")
                    Label("Tap Refresh to look up their IPv4 addresses.", systemImage: "2.circle.fill")
                    Label("Tap Apply VPN Bypass to pin those addresses to your current Wi‑Fi/Ethernet gateway.", systemImage: "3.circle.fill")
                    Label("Use Turn Off Bypass to remove the routes when you are done.", systemImage: "4.circle.fill")
                }
                .font(.body)
                .foregroundStyle(.primary)

                Divider()

                Text("Permissions")
                    .font(.title3.weight(.semibold))
                Text("Changing routes uses macOS administrator privileges. The app bundles a small script, copies it to Application Support for a stable path, and runs it after you approve the password prompt.")
                    .foregroundStyle(.secondary)

                Divider()

                HStack {
                    Text("Recent activity")
                        .font(.title3.weight(.semibold))
                    
                    Spacer()
                    
                    Button {
                        viewModel.logs.removeAll()
                    } label: {
                        Label("Remove All Logs", systemImage: "trash")
                    }
                    .disabled(viewModel.logs.isEmpty)
                }
                

                if viewModel.logs.isEmpty {
                    Text("No log lines yet.")
                        .foregroundStyle(.secondary)
                } else {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(Array(viewModel.logs.suffix(8).reversed())) { entry in
                            HStack(alignment: .top, spacing: 8) {
                                Text(entry.timestamp, style: .time)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .frame(width: 72, alignment: .leading)
                                Text(entry.message)
                                    .font(.callout)
                            }
                        }
                    }
                }

                Button("Open full log…") {
                    viewModel.showLogsSheet = true
                }
                .buttonStyle(.link)
                .disabled(viewModel.logs.isEmpty)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
