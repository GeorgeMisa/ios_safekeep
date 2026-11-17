import SwiftUI

struct OnboardingFlow: View {
    private enum Step: Equatable {
        case welcome
        case create
        case confirm(String)
        case biometrics
    }

    @Binding var showsKeypad: Bool

    @Environment(VaultSession.self) private var session
    @State private var step = Step.welcome
    @State private var createDetail: String?
    @State private var confirmDetail: String?

    var body: some View {
        ZStack {
            switch step {
            case .welcome:
                WelcomeTourView(mode: .firstRun) { step = .create }
                    .transition(.opacity)
            case .create:
                PasscodeEntryView(
                    heading: "Create a 6-digit passcode",
                    pose: .key,
                    detail: createDetail ?? "You'll use it to unlock SafeKeep.",
                    onCancel: { step = .welcome }
                ) { code in
                    guard !PasscodeRules.isTooSimple(code) else {
                        createDetail = "Avoid repeated or sequential digits."
                        return false
                    }
                    createDetail = nil
                    step = .confirm(code)
                    return true
                }
                .transition(.move(edge: .trailing))
            case .confirm(let first):
                PasscodeEntryView(
                    heading: "Confirm your passcode",
                    pose: .key,
                    detail: confirmDetail ?? "Enter it once more.",
                    onCancel: { step = .create }
                ) { code in
                    await confirm(code, matching: first)
                }
                .transition(.move(edge: .trailing))
            case .biometrics:
                BiometricOfferView(kind: session.biometricHardware) {
                    session.finishOnboarding()
                }
                .transition(.opacity)
            }
        }
        .animation(.snappy, value: step)
        .onChange(of: step, initial: true) { _, step in
            switch step {
            case .create, .confirm: showsKeypad = true
            case .welcome, .biometrics: showsKeypad = false
            }
        }
    }

    private func confirm(_ code: String, matching first: String) async -> Bool {
        guard code == first else {
            createDetail = "Passcodes didn't match. Try again."
            step = .create
            return false
        }
        do {
            try await session.setUp(passcode: code)
            if session.isBiometricsAvailable {
                step = .biometrics
            } else {
                session.finishOnboarding()
            }
            return true
        } catch {
            confirmDetail = "Couldn't create your vault. Try again."
            return false
        }
    }
}
