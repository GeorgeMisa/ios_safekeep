import SwiftUI

struct DisplayNameView: View {
    @Environment(VaultSession.self) private var session
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var errorMessage: String?

    var body: some View {
        Form {
            Section {
                TextField("Your name", text: $name)
                    .textContentType(.name)
                    .submitLabel(.done)
                    .onSubmit(save)
            } footer: {
                Text(errorMessage ?? "Shown in Settings only. It's encrypted with the rest of your vault.")
                    .foregroundStyle(errorMessage == nil ? Color.secondary : Color.red)
            }
        }
        .navigationTitle("Name")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save", action: save)
                    .disabled(name == session.payload.displayName)
            }
        }
        .onAppear { name = session.payload.displayName }
    }

    private func save() {
        do {
            try session.updateDisplayName(name)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
