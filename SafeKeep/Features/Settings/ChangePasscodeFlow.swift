import SwiftUI

struct ChangePasscodeFlow: View {
    private enum Step: Equatable {
        case verify
        case create
        case confirm(String)
        case done
    }

    @Environment(VaultSession.self) private var session
    @Environment(\.dismiss) private var dismiss
    @State private var step = Step.verify
    @State private var detail: String?
    @State private var now = Date.now

    var body: some View {
        ZStack {
            switch step {
            case .verify:
                let remaining = session.lockoutRemaining(at: now)
                PasscodeEntryView(
                    heading: "Enter your current passcode",
                    pose: remaining > 0 ? .sleepy : .standard,
                    detail: remaining > 0 ? LockoutText.message(remaining: remaining) : detail,
                    isLocked: remaining > 0,
                    onCancel: { dismiss() }
                ) { code in
                    await verify(code)
                }
            case .create:
                PasscodeEntryView(
                    heading: "Enter a new 6-digit passcode",
                    pose: .key,
                    detail: detail,
                    onCancel: { dismiss() }
                ) { code in
                    guard !PasscodeRules.isTooSimple(code) else {
                        detail = "Avoid repeated or sequential digits."
                        return false
                    }
                    detail = nil
                    step = .confirm(code)
                    return true
                }
                .transition(.move(edge: .trailing))
            case .confirm(let first):
                PasscodeEntryView(
                    heading: "Confirm your new passcode",
                    pose: .key,
                    detail: detail,
                    onCancel: { dismiss() }
                ) { code in
                    await confirm(code, matching: first)
                }
                .transition(.move(edge: .trailing))
            case .done:
                PrivacyShield(message: "Passcode changed", pose: .celebrating)
                    .task {
                        try? await Task.sleep(for: .seconds(1))
                        dismiss()
                    }
            }
        }
        .animation(.snappy, value: step)
        .sensoryFeedback(.success, trigger: step) { _, new in new == .done }
        .preferredColorScheme(.dark)
    }

    private func verify(_ code: String) async -> Bool {
        let outcome = await session.verifyPasscode(code)
        now = .now
        switch outcome {
        case .success:
            detail = nil
            step = .create
            return true
        case .wrongPasscode(let attemptsLeft):
            detail = LockoutText.wrongPasscode(attemptsLeft: attemptsLeft)
        case .lockedOut:
            detail = nil
        case .failed(let message):
            detail = message
        }
        return false
    }

    private func confirm(_ code: String, matching first: String) async -> Bool {
        guard code == first else {
            detail = "Passcodes didn't match. Try again."
            step = .create
            return false
        }
        do {
            try await session.changePasscode(to: code)
            step = .done
            return true
        } catch {
            detail = error.localizedDescription
            return false
        }
    }
}
