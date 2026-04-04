import SwiftUI

struct ManagedDomainsSection: View {
    @Binding var text: String
    let rows: [DomainRowDisplay]
    let isWorking: Bool
    let isBypassing: Bool
    
    let onRemove: (UUID) -> Void
    let onToggleChange: (UUID, Bool) -> Void
    let onNewDomain: () -> Void
    
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
                            Image(systemName: "globe")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Color.white.opacity(0.82))
                        }

                        Text("Managed Domains (\(rows.count) domains)")
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
                AddDomainInputRow(
                    text: $text,
                    isWorking: isWorking,
                    isBypassing: isBypassing,
                    onAdd: { onNewDomain() }
                )
                
                if rows.isEmpty {
                    VStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.07),
                                            Color.white.opacity(0.03)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 52, height: 52)

                            Image(systemName: "globe")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(Color.white.opacity(0.78))
                        }

                        VStack(spacing: 6) {
                            Text("No managed domains yet")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(Color.white.opacity(0.92))

                            Text("Add a domain above to start building your VPN bypass list. Once added, you can quickly include or remove it from active routes.")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundStyle(Color.white.opacity(0.52))
                                .multilineTextAlignment(.center)
                                .lineSpacing(3)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color.white.opacity(0.03))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.white.opacity(0.07), lineWidth: 1)
                    )
                } else {
                    VStack(spacing: 10) {
                        ForEach(rows) { row in
                            ManagedDomainCardView(row: row,
                                                  isWorking: isWorking,
                                                  isBypassing: isBypassing,
                                                  onRemove: {
                                onRemove(row.id)
                            },
                                                  isOn: row.isIncludedInRoutes,
                                                  onToggleChanged: { isOn in
                                onToggleChange(row.id, isOn)
                                
                            })
                            
                        }
                    }
                }
            }
        }
    }
}
