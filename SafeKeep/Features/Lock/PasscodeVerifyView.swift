import SwiftUI

struct PasscodeVerifyView: View {
    let heading: String
    var pose: MascotPose = .standard
    let onVerified: () -> Void

    @Environment(VaultSession.self) private var session
    @Environment(\.dismiss) private var dismiss
    @State private var detail: String?
    @State private var now = Date.now

    var body: some View {
        let remaining = session.lockoutRemaining(at: now)

        PasscodeEntryView(
            heading: heading,
            pose: remaining > 0 ? .sleepy : pose,
            detail: remaining > 0 ? LockoutText.message(remaining: remaining) : detail,
            isLocked: remaining > 0,
            onCancel: { dismiss() }
        ) { code in
            let outcome = await session.verifyPasscode(code)
            now = .now
            switch outcome {
            case .success:
                onVerified()
                dismiss()
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
        .task(id: remaining > 0) {
            while session.lockoutRemaining(at: .now) > 0, !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                now = .now
            }
        }
        .preferredColorScheme(.dark)
    }
}
