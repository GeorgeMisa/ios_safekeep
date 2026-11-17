import SwiftUI

struct AccountDetailView: View {
    let accountID: Account.ID

    @Environment(VaultSession.self) private var session
    @Environment(\.dismiss) private var dismiss
    @State private var isRevealed = false
    @State private var isEditing = false
    @State private var isConfirmingDelete = false
    @State private var toast: String?
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if let account = session.account(id: accountID) {
                content(account)
            } else {
                ContentUnavailableView("Account Removed", systemImage: "trash")
            }
        }
        .navigationTitle("Account Details")
        .navigationBarTitleDisplayMode(.inline)
        .overlay(alignment: .bottom) {
            if let toast {
                CopyToast(text: toast)
            }
        }
        .animation(.snappy, value: toast)
        .sensoryFeedback(.success, trigger: toast) { _, new in new != nil }
        .alert("Couldn't Delete", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
        .onDisappear { isRevealed = false }
    }

    // MARK: - Content

    private func content(_ account: Account) -> some View {
        List {
            Section {
                VStack(spacing: Spacing.md) {
                    BrandIconView(brandID: account.brandID, name: account.serviceName, category: account.category, size: 72)
                    VStack(spacing: Spacing.xs) {
                        Text(account.serviceName)
                            .font(.title2.bold())
                            .multilineTextAlignment(.center)
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: account.category.symbol)
                            Text(account.category.title)
                        }
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.sm)
            }
            .listRowBackground(Color.clear)

            Section {
                if !account.username.isEmpty {
                    DetailFieldRow(label: "Username") {
                        Text(account.username)
                            .textSelection(.enabled)
                    } actions: {
                        copyButton(account.username, label: "Username copied", accessibility: "Copy username")
                    }
                }

                DetailFieldRow(label: "Password") {
                    Text(isRevealed ? account.password : String(repeating: "•", count: 10))
                        .font(isRevealed ? .body.monospaced() : .body)
                        .privacySensitive()
                        .contentTransition(.opacity)
                } actions: {
                    Button {
                        withAnimation(.snappy) { isRevealed.toggle() }
                    } label: {
                        Image(systemName: isRevealed ? "eye.slash" : "eye")
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel(isRevealed ? "Hide password" : "Show password")
                    copyButton(account.password, label: "Password copied · clears in 30s", accessibility: "Copy password")
                }

                if !account.website.isEmpty {
                    DetailFieldRow(label: "Website") {
                        Text(account.website)
                            .lineLimit(1)
                    } actions: {
                        if let url = account.websiteURL {
                            Link(destination: url) {
                                Image(systemName: "arrow.up.right.square")
                                    .frame(width: 44, height: 44)
                            }
                            .accessibilityLabel("Open website")
                        }
                    }
                }

                if !account.notes.isEmpty {
                    DetailFieldRow(label: "Notes") {
                        Text(account.notes)
                    } actions: {
                        EmptyView()
                    }
                }
            }

            Section {
                Button("Delete Account", role: .destructive) { isConfirmingDelete = true }
                    .frame(maxWidth: .infinity)
            } footer: {
                Text("Last updated \(account.updatedAt.formatted(.relative(presentation: .named)))")
            }
        }
        .listStyle(.insetGrouped)
        .buttonStyle(.borderless)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") { isEditing = true }
            }
        }
        .sheet(isPresented: $isEditing) {
            AccountEditorView(existing: account)
        }
        .confirmationDialog(
            "Delete \(account.serviceName)?",
            isPresented: $isConfirmingDelete,
            titleVisibility: .visible
        ) {
            Button("Delete Account", role: .destructive) { delete(account) }
        } message: {
            Text("This removes the saved login from SafeKeep. It can't be undone.")
        }
    }

    private func copyButton(_ value: String, label: String, accessibility: String) -> some View {
        Button {
            SecureClipboard.copy(value)
            show(label)
        } label: {
            Image(systemName: "doc.on.doc")
                .frame(width: 44, height: 44)
        }
        .accessibilityLabel(accessibility)
        .disabled(value.isEmpty)
    }

    private func show(_ message: String) {
        toast = message
        Task {
            try? await Task.sleep(for: .seconds(2))
            if toast == message { toast = nil }
        }
    }

    private func delete(_ account: Account) {
        do {
            try session.deleteAccount(id: account.id)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct DetailFieldRow<Value: View, Actions: View>: View {
    let label: String
    @ViewBuilder let value: Value
    @ViewBuilder let actions: Actions

    var body: some View {
        HStack(spacing: Spacing.sm) {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                value
            }
            Spacer(minLength: 0)
            actions
                .foregroundStyle(.tint)
        }
        .padding(.vertical, 2)
    }
}
