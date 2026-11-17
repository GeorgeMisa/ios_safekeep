import SwiftUI

struct PrivacyShield: View {
    var message: String?
    var pose: MascotPose = .curled

    var body: some View {
        ZStack {
            Palette.lockGradient.ignoresSafeArea()
            VStack(spacing: Spacing.lg) {
                MascotImage(pose: pose, height: 150)
                if let message {
                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.xxl)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(message ?? "SafeKeep is hidden")
    }
}

struct AppMark: View {
    var size: CGFloat = 64
    var onDarkBackground = true

    var body: some View {
        RoundedRectangle(cornerRadius: size * 0.26, style: .continuous)
            .fill(onDarkBackground ? AnyShapeStyle(.white.opacity(0.18)) : AnyShapeStyle(Palette.iconGradient))
            .frame(width: size, height: size)
            .overlay {
                Image(systemName: "lock.fill")
                    .font(.system(size: size * 0.44, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .accessibilityHidden(true)
    }
}
