import SwiftUI

struct TourPage: Identifiable, Equatable {
    let pose: MascotPose
    let title: String
    let message: String

    var id: MascotPose { pose }

    static let all: [TourPage] = [
        TourPage(
            pose: .waving,
            title: "Meet \(Mascot.name)",
            message: "Hi! I'm \(Mascot.name), the squirrel who looks after your vault. I stash your passwords where only you can reach them."
        ),
        TourPage(
            pose: .curled,
            title: "It all stays on this iPhone",
            message: "Your vault is encrypted with AES-256 and never leaves this device. No account, no cloud, no tracking."
        ),
        TourPage(
            pose: .key,
            title: "Your passcode is the key",
            message: "A 6-digit passcode opens the vault, and Face ID makes it a glance. Forget it and nobody can recover it. Not even me."
        ),
        TourPage(
            pose: .searching,
            title: "I keep watch",
            message: "I'll point out weak or reused passwords and make strong new ones whenever you need them."
        ),
        TourPage(
            pose: .box,
            title: "Back up your stash",
            message: "Export an encrypted backup file anytime, so a lost phone doesn't mean lost passwords."
        ),
    ]
}

struct WelcomeTourView: View {
    enum Mode {
        case firstRun, replay
    }

    let mode: Mode
    let onFinish: () -> Void

    @State private var page = 0

    private let pages = TourPage.all
    private var isLastPage: Bool { page == pages.count - 1 }

    var body: some View {
        VStack(spacing: 0) {
            topBar

            TabView(selection: $page) {
                ForEach(Array(pages.enumerated()), id: \.element.id) { index, item in
                    pageContent(item)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            PageIndicator(count: pages.count, current: page)
                .padding(.bottom, Spacing.xl)

            Button(action: advance) {
                Text(isLastPage ? finalTitle : "Next")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 34)
                    .contentTransition(.opacity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, Spacing.xl)
            .padding(.bottom, Spacing.lg)
        }
        .background(Color(.systemBackground))
        .animation(.snappy, value: page)
        .sensoryFeedback(.selection, trigger: page)
    }

    // MARK: - Sections

    private var topBar: some View {
        HStack {
            Spacer()
            Button(mode == .firstRun ? "Skip" : "Close") { onFinish() }
                .frame(minHeight: 44)
                .opacity(isLastPage && mode == .firstRun ? 0 : 1)
                .disabled(isLastPage && mode == .firstRun)
        }
        .padding(.horizontal, Spacing.xl)
        .frame(height: 44)
    }

    private func pageContent(_ item: TourPage) -> some View {
        VStack(spacing: Spacing.xl) {
            Spacer(minLength: Spacing.md)
            MascotStage(pose: item.pose, height: 230)
                .padding(.horizontal, Spacing.xl)
            VStack(spacing: Spacing.md) {
                Text(item.title)
                    .font(.title.bold())
                    .multilineTextAlignment(.center)
                Text(item.message)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, Spacing.xxl)
            Spacer(minLength: Spacing.md)
        }
        .accessibilityElement(children: .combine)
    }

    private var finalTitle: String {
        mode == .firstRun ? "Create Passcode" : "Done"
    }

    private func advance() {
        if isLastPage {
            onFinish()
        } else {
            page += 1
        }
    }
}

private struct PageIndicator: View {
    let count: Int
    let current: Int

    var body: some View {
        HStack(spacing: Spacing.sm) {
            ForEach(0..<count, id: \.self) { index in
                Capsule()
                    .fill(index == current ? Palette.brand : Color(.tertiarySystemFill))
                    .frame(width: index == current ? 22 : 8, height: 8)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Page \(current + 1) of \(count)")
    }
}
