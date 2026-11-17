import SwiftUI

struct LockView: View {
    @Environment(VaultSession.self) private var session
    @Environment(\.scenePhase) private var scenePhase
    @State private var detail: String?
    @State private var hasAutoPrompted = false
    @State private var now = Date.now

    var body: some View {
        let remaining = session.lockoutRemaining(at: now)

        PasscodeEntryView(
            heading: "Enter your passcode",
            pose: remaining > 0 ? .sleepy : .curled,
            detail: remaining > 0 ? LockoutText.message(remaining: remaining) : detail,
            isLocked: remaining > 0,
            biometric: session.unlockBiometric,
            onBiometric: { Task { await unlockWithBiometrics() } }
        ) { code in
            await unlock(code)
        }
        .task(id: remaining > 0) {
            while session.lockoutRemaining(at: .now) > 0, !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                now = .now
            }
        }
        .task { await autoPrompt() }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .background:
                hasAutoPrompted = false
                session.allowBiometricAutoPrompt()
            case .active: Task { await autoPrompt() }
            default: break
            }
        }
    }

    // MARK: - Unlock

    private func unlock(_ code: String) async -> Bool {
        let outcome = await session.unlock(passcode: code)
        now = .now
        switch outcome {
        case .success:
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

    private func autoPrompt() async {
        guard scenePhase == .active, !hasAutoPrompted, session.autoPromptsBiometrics,
              session.unlockBiometric != .none
        else { return }
        hasAutoPrompted = true
        await unlockWithBiometrics()
    }

    private func unlockWithBiometrics() async {
        do {
            try await session.unlockWithBiometrics()
        } catch VaultKeyError.biometricsCancelled {
            detail = nil
        } catch {
            detail = error.localizedDescription
        }
    }
}

enum LockoutText {
    static func message(remaining: TimeInterval) -> String {
        let duration = Duration.seconds(Int(remaining.rounded(.up)))
        return "Too many attempts. Try again in \(duration.formatted(.time(pattern: .minuteSecond)))."
    }

    static func wrongPasscode(attemptsLeft: Int) -> String {
        switch attemptsLeft {
        case 0: "Wrong passcode. Another mistake starts a timeout."
        case 1: "Wrong passcode. 1 attempt left before a timeout."
        default: "Wrong passcode. \(attemptsLeft) attempts left before a timeout."
        }
    }
}
