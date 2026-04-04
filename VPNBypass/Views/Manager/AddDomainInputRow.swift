import SwiftUI

struct AddDomainInputRow: View {
    @Binding var text: String
    var isWorking: Bool
    var isBypassing: Bool
    var onAdd: () -> Void

    private var canAdd: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isWorking && !isBypassing
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                TextField("Enter domain (e.g., example.com)", text: $text)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(ManagerDesignTokens.surfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: ManagerDesignTokens.cornerRadius, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: ManagerDesignTokens.cornerRadius, style: .continuous)
                            .stroke(ManagerDesignTokens.border, lineWidth: 1)
                    )
                    .foregroundStyle(.white)
                    .disabled(isWorking || isBypassing)
                    .opacity(isWorking || isBypassing ? 0.5 : 1.0)
                    .onSubmit { onAdd() }
                    

                Button(action: onAdd) {
                    Label("Add Domain", systemImage: "plus")
                        .font(.subheadline.weight(.semibold))
                        .labelStyle(.titleAndIcon)
                        .frame(minHeight: 36)
                        .padding(.horizontal, 14)
                }
                .buttonStyle(.bordered)
                .tint(ManagerDesignTokens.accentBlue)
                .disabled(!canAdd)
            }
        }
    }
}
