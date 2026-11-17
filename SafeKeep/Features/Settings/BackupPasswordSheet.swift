import SwiftUI

struct BackupPasswordSheet: View {
    enum Mode {
        case export, `import`
    }

    let mode: Mode
    let onSubmit: (String) async throws -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var password = ""
    @State private var confirmation = ""
    @State private var isWorking = false
    @State private var errorMessage: String?
    @FocusState private var isFocused: Bool

    private var isValid: Bool {
        switch mode {
        case .export: password.count >= BackupService.minimumPasswordLength && password == confirmation
        case .import: !password.isEmpty
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("Backup password", text: $password)
                        .focused($isFocused)
                        .vaultSecretField()
                    if mode == .export {
                        SecureField("Confirm password", text: $confirmation)
                            .vaultSecretField()
                        StrengthMeter(password: password)
                            .padding(.vertical, Spacing.xs)
                    }
                } footer: {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(footer)
                        if let errorMessage {
                            Text(errorMessage).foregroundStyle(.red)
                        } else if mode == .export, !confirmation.isEmpty, password != confirmation {
                            Text("Passwords don't match.").foregroundStyle(.red)
                        }
                    }
                }
            }
            .disabled(isWorking)
            .submitLabel(.done)
            .onSubmit { if isValid, !isWorking { submit() } }
            .navigationTitle(mode == .export ? "Backup Password" : "Unlock Backup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isWorking {
                        ProgressView()
                    } else {
                        Button(mode == .export ? "Export" : "Import", action: submit)
                            .fontWeight(.semibold)
                            .disabled(!isValid)
                    }
                }
            }
            .onAppear { isFocused = true }
        }
        .interactiveDismissDisabled(isWorking)
    }

    private var footer: String {
        switch mode {
        case .export:
            "Use at least \(BackupService.minimumPasswordLength) characters, different from your passcode. You'll need it to restore. SafeKeep can't recover it."
        case .import:
            "Enter the password that was set when this backup was exported."
        }
    }

    private func submit() {
        isWorking = true
        errorMessage = nil
        Task {
            do {
                try await onSubmit(password)
                dismiss()
            } catch {
                errorMessage = (error as? LocalizedError)?.errorDescription ?? "Something went wrong. Try again."
            }
            isWorking = false
        }
    }
}
