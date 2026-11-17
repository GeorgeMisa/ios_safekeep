import SwiftUI

struct MascotImage: View {
    static let aspectRatio: CGFloat = 600.0 / 570.0

    let pose: MascotPose
    var height: CGFloat = 140

    var body: some View {
        Image(pose.assetName)
            .resizable()
            .interpolation(.high)
            .scaledToFit()
            .frame(height: height)
            .contentTransition(.opacity)
            .accessibilityHidden(true)
    }
}

// MARK: - Header

// Mascot standing on a tinted band, drawn over the left edge of its speech bubble.
struct MascotHeader: View {
    let pose: MascotPose
    let message: String
    var mascotHeight: CGFloat = 132

    private var mascotWidth: CGFloat { mascotHeight * MascotImage.aspectRatio }
    private var overlap: CGFloat { mascotWidth * 0.14 }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .fill(Palette.mascotBand)
                .frame(height: mascotHeight * 0.52)

            HStack(spacing: 0) {
                Color.clear.frame(width: mascotWidth - overlap)
                SpeechBubble(title: Mascot.name, message: message, leadingInset: overlap)
            }
            .padding(.trailing, Spacing.md)
            .padding(.bottom, Spacing.md)
            .frame(minHeight: mascotHeight, alignment: .bottom)

            MascotImage(pose: pose, height: mascotHeight)
                .padding(.leading, Spacing.xs)
        }
        .animation(.snappy, value: pose)
        .animation(.snappy, value: message)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(Mascot.name) says: \(message)")
    }
}

struct SpeechBubble: View {
    let title: String
    let message: String
    var leadingInset: CGFloat = 0

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(title)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Palette.brand)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
                .contentTransition(.opacity)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, leadingInset + Spacing.md)
        .padding([.trailing, .vertical], Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .fill(Palette.bubble)
                .shadow(color: .black.opacity(0.06), radius: 10, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .strokeBorder(Palette.bubbleStroke, lineWidth: 1)
        )
    }
}

// MARK: - Stage

// A larger mascot standing on a rounded band, used for full-screen moments.
struct MascotStage: View {
    let pose: MascotPose
    var height: CGFloat = 220

    var body: some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: Radius.card * 1.4, style: .continuous)
                .fill(Palette.mascotBand)
                .frame(height: height * 0.5)
            MascotImage(pose: pose, height: height)
                .id(pose)
                .transition(.opacity.combined(with: .scale(scale: 0.94, anchor: .bottom)))
        }
        .frame(height: height)
        .animation(.snappy, value: pose)
    }
}

// MARK: - Empty state

struct MascotEmptyState<Actions: View>: View {
    let pose: MascotPose
    let title: String
    let message: String
    @ViewBuilder var actions: Actions

    var body: some View {
        VStack(spacing: Spacing.md) {
            MascotImage(pose: pose, height: 130)
            Text(title)
                .font(.title3.weight(.semibold))
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            actions
                .padding(.top, Spacing.xs)
        }
        .padding(.horizontal, Spacing.xxl)
        .accessibilityElement(children: .contain)
    }
}

extension MascotEmptyState where Actions == EmptyView {
    init(pose: MascotPose, title: String, message: String) {
        self.init(pose: pose, title: title, message: message) { EmptyView() }
    }
}
