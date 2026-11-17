import SwiftUI

struct BiometricOfferView: View {
    let kind: BiometricKind
    let onFinish: () -> Void

    @Environment(VaultSession.self) private var session
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: Spacing.lg) {
                MascotStage(pose: .proud, height: 200)
                    .padding(.horizontal, Spacing.xl)
                Label("Unlock with \(kind.title)?", systemImage: kind.symbol)
                    .font(.title2.bold())
                Text("Your vault key is held by the Secure Enclave and released only after \(kind.title) recognizes you. Your passcode always works too.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xl)
                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }
            }
            Spacer()
            VStack(spacing: Spacing.md) {
                Button {
                    do {
                        try session.enableBiometrics()
                        onFinish()
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                } label: {
                    Text("Use \(kind.title)")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 34)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button("Not Now", action: onFinish)
                    .frame(minHeight: 44)
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.bottom, Spacing.lg)
        }
        .background(Color(.systemBackground))
    }
}
