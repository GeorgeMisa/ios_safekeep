import SwiftUI

struct SettingsView: View {
    @Environment(VaultSession.self) private var session
    @AppStorage(PreferenceKey.appearance) private var appearance = AppearanceOption.system
    @AppStorage(PreferenceKey.autoLock) private var autoLock = AutoLockOption.immediately
    @State private var isChangingPasscode = false
    @State private var isShowingTour = false
    @State private var isConfirmingErase = false
    @State private var isVerifyingErase = false
    @State private var eraseVerified = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        DisplayNameView()
                    } label: {
                        ProfileRow(name: session.payload.displayName, count: session.payload.accounts.count)
                    }
                }

                securitySection

                Section("Preferences") {
                    Picker(selection: $appearance) {
                        ForEach(AppearanceOption.allCases) { Text($0.title).tag($0) }
                    } label: {
                        SettingsRowLabel(title: "Appearance", symbol: "circle.lefthalf.filled", color: .indigo)
                    }
                }

                Section("Data") {
                    NavigationLink {
                        BackupView()
                    } label: {
                        SettingsRowLabel(title: "Backup & Restore", symbol: "arrow.up.arrow.down", color: .teal)
                    }
                }

                Section("Support") {
                    Button {
                        isShowingTour = true
                    } label: {
                        SettingsRowLabel(title: "Welcome Tour", symbol: "sparkles", color: .purple, showsChevron: true)
                    }
                    .tint(.primary)
                    NavigationLink {
                        HelpView()
                    } label: {
                        SettingsRowLabel(title: "Help & Support", symbol: "questionmark", color: .orange)
                    }
                    NavigationLink {
                        AboutView()
                    } label: {
                        SettingsRowLabel(title: "About", symbol: "info", color: .gray)
                    }
                }

                Section {
                    Button("Erase Vault", role: .destructive) { isConfirmingErase = true }
                        .frame(maxWidth: .infinity)
                } footer: {
                    Text("Deletes every saved account and your passcode from this iPhone. It can't be undone.")
                }
            }
            .listStyle(.insetGrouped)
            .contentMargins(.top, Spacing.sm, for: .scrollContent)
            .navigationTitle("Settings")
            .toolbarTitleDisplayMode(.inlineLarge)
            .fullScreenCover(isPresented: $isChangingPasscode) {
                ChangePasscodeFlow()
            }
            .fullScreenCover(isPresented: $isShowingTour) {
                WelcomeTourView(mode: .replay) { isShowingTour = false }
            }
            .confirmationDialog("Erase everything in SafeKeep?", isPresented: $isConfirmingErase, titleVisibility: .visible) {
                Button("Erase Vault", role: .destructive) { isVerifyingErase = true }
            } message: {
                Text("All \(session.payload.accounts.count) saved accounts will be permanently deleted. Export a backup first if you might need them.")
            }
            .fullScreenCover(isPresented: $isVerifyingErase, onDismiss: {
                if eraseVerified { session.eraseVault() }
            }) {
                PasscodeVerifyView(heading: "Enter your passcode to erase the vault", pose: .concerned) {
                    eraseVerified = true
                }
            }
            .alert("Face ID", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    // MARK: - Security

    private var securitySection: some View {
        Section {
            Button {
                isChangingPasscode = true
            } label: {
                SettingsRowLabel(title: "Change Passcode", symbol: "lock.fill", color: .blue, showsChevron: true)
            }
            .tint(.primary)

            if session.biometricHardware != .none {
                Toggle(isOn: biometricBinding) {
                    SettingsRowLabel(
                        title: session.biometricHardware.title,
                        symbol: session.biometricHardware.symbol,
                        color: .green
                    )
                }
                .disabled(!session.isBiometricsAvailable && !session.isBiometricsEnabled)
            }

            Picker(selection: $autoLock) {
                ForEach(AutoLockOption.allCases) { Text($0.title).tag($0) }
            } label: {
                SettingsRowLabel(title: "Auto-Lock", symbol: "timer", color: .red)
            }
        } header: {
            Text("Security")
        } footer: {
            if session.biometricHardware != .none, !session.isBiometricsAvailable {
                Text("Turn on \(session.biometricHardware.title) for this iPhone in the Settings app to use it here.")
            }
        }
    }

    private var biometricBinding: Binding<Bool> {
        Binding {
            session.isBiometricsEnabled
        } set: { enabled in
            if enabled {
                do { try session.enableBiometrics() } catch { errorMessage = error.localizedDescription }
            } else {
                session.disableBiometrics()
            }
        }
    }
}

private struct ProfileRow: View {
    let name: String
    let count: Int

    var body: some View {
        HStack(spacing: Spacing.md) {
            Circle()
                .fill(Palette.iconGradient)
                .frame(width: 52, height: 52)
                .overlay {
                    if let initial = name.first {
                        Text(String(initial).uppercased())
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(.white)
                    } else {
                        Image(systemName: "person.fill")
                            .font(.title2)
                            .foregroundStyle(.white)
                    }
                }
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(name.isEmpty ? "Your Vault" : name)
                    .font(.headline)
                Text("\(count) \(count == 1 ? "account" : "accounts") · stored on this iPhone")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, Spacing.xs)
    }
}
