import SwiftUI

struct PasscodeEntryView: View {
    let heading: String
    var pose: MascotPose = .curled
    var detail: String?
    var isLocked = false
    var biometric: BiometricKind = .none
    var onBiometric: (() -> Void)?
    var onCancel: (() -> Void)?
    let onComplete: (String) async -> Bool

    @State private var entered = ""
    @State private var failures = 0
    @State private var isBusy = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Palette.lockGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                Spacer(minLength: Spacing.md)
                header
                dots
                    .padding(.top, Spacing.xl)
                Text(detail ?? " ")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.88))
                    .multilineTextAlignment(.center)
                    .frame(minHeight: 40, alignment: .top)
                    .padding(.top, Spacing.md)
                    .contentTransition(.opacity)
                Spacer(minLength: Spacing.md)
                keypad
                biometricButton
                    .padding(.top, Spacing.lg)
                Spacer(minLength: Spacing.md)
            }
            .padding(.horizontal, Spacing.xl)
        }
        .sensoryFeedback(.error, trigger: failures)
        .sensoryFeedback(.selection, trigger: entered.count)
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
    }

    // MARK: - Sections

    @ViewBuilder
    private var topBar: some View {
        HStack {
            if let onCancel {
                Button("Cancel", action: onCancel)
                    .foregroundStyle(.white)
                    .frame(minHeight: 44)
            }
            Spacer()
        }
        .frame(height: 44)
    }

    private var header: some View {
        VStack(spacing: Spacing.md) {
            MascotImage(pose: pose, height: 104)
            Text("SafeKeep")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
            Text(heading)
                .font(.body)
                .foregroundStyle(.white.opacity(0.92))
                .padding(.top, Spacing.lg)
                .multilineTextAlignment(.center)
        }
    }

    private var dots: some View {
        ZStack {
            HStack(spacing: 18) {
                ForEach(0..<PasscodeRules.length, id: \.self) { index in
                    Circle()
                        .strokeBorder(.white, lineWidth: 1.5)
                        .background(Circle().fill(index < entered.count ? .white : .clear))
                        .frame(width: 14, height: 14)
                }
            }
            .opacity(isBusy ? 0 : 1)
            .modifier(ShakeEffect(travel: reduceMotion ? 0 : 10, shakes: CGFloat(failures)))

            if isBusy {
                ProgressView().tint(.white)
            }
        }
        .frame(height: 20)
        .animation(.snappy(duration: 0.15), value: entered)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Passcode")
        .accessibilityValue("\(entered.count) of \(PasscodeRules.length) digits entered")
    }

    private var keypad: some View {
        let rows = [["1", "2", "3"], ["4", "5", "6"], ["7", "8", "9"]]
        return VStack(spacing: Spacing.lg) {
            ForEach(rows, id: \.self) { row in
                HStack(spacing: Spacing.xl) {
                    ForEach(row, id: \.self) { digit in digitButton(digit) }
                }
            }
            HStack(spacing: Spacing.xl) {
                Color.clear.frame(width: 76, height: 76)
                digitButton("0")
                Button(action: deleteLast) {
                    Image(systemName: "delete.left")
                        .font(.title2)
                        .foregroundStyle(.white)
                        .frame(width: 76, height: 76)
                        .contentShape(Circle())
                }
                .opacity(entered.isEmpty ? 0 : 1)
                .disabled(entered.isEmpty)
                .accessibilityLabel("Delete")
            }
        }
        .disabled(isLocked || isBusy)
        .opacity(isLocked ? 0.4 : 1)
    }

    @ViewBuilder
    private var biometricButton: some View {
        if biometric != .none, let onBiometric {
            Button(action: onBiometric) {
                VStack(spacing: Spacing.xs) {
                    Image(systemName: biometric.symbol)
                        .font(.title)
                    Text("Use \(biometric.title)")
                        .font(.footnote)
                }
                .foregroundStyle(.white)
                .frame(minWidth: 44, minHeight: 44)
            }
            .disabled(isBusy)
        } else {
            Color.clear.frame(height: 56)
        }
    }

    private func digitButton(_ digit: String) -> some View {
        Button(digit) { append(digit) }
            .buttonStyle(KeypadButtonStyle())
            .accessibilityLabel(digit)
    }

    // MARK: - Input

    private func append(_ digit: String) {
        guard entered.count < PasscodeRules.length else { return }
        entered.append(digit)
        guard entered.count == PasscodeRules.length else { return }
        let code = entered
        isBusy = true
        Task {
            let accepted = await onComplete(code)
            isBusy = false
            entered = ""
            if !accepted {
                withAnimation(.linear(duration: 0.45)) { failures += 1 }
            }
        }
    }

    private func deleteLast() {
        guard !entered.isEmpty else { return }
        entered.removeLast()
    }
}

private struct KeypadButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 32, weight: .regular))
            .foregroundStyle(.white)
            .frame(width: 76, height: 76)
            .background(Circle().fill(.white.opacity(configuration.isPressed ? 0.36 : 0.16)))
            .contentShape(Circle())
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

private struct ShakeEffect: GeometryEffect {
    var travel: CGFloat
    var shakes: CGFloat

    var animatableData: CGFloat {
        get { shakes }
        set { shakes = newValue }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: travel * sin(shakes * .pi * 4), y: 0))
    }
}
