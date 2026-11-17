import SwiftUI

struct RootView: View {
    @Environment(VaultSession.self) private var session
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage(PreferenceKey.appearance) private var appearance = AppearanceOption.system
    @AppStorage(PreferenceKey.autoLock) private var autoLock = AutoLockOption.immediately
    @State private var autoLockMonitor = AutoLockMonitor()
    @State private var captureMonitor = ScreenCaptureMonitor()
    @State private var onboardingShowsKeypad = false

    private var interfaceStyle: UIUserInterfaceStyle {
        switch session.phase {
        case .locked: .dark
        case .onboarding where onboardingShowsKeypad: .dark
        default: appearance.interfaceStyle
        }
    }

    var body: some View {
        ZStack {
            switch session.phase {
            case .onboarding:
                OnboardingFlow(showsKeypad: $onboardingShowsKeypad)
                    .transition(.opacity)
            case .locked:
                LockView()
                    .transition(.opacity)
            case .unlocked:
                MainTabView()
                    .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.25), value: session.phase)
        .overlay {
            if captureMonitor.isCaptured {
                PrivacyShield(message: "Hidden while your screen is being recorded or mirrored.")
            } else if scenePhase != .active {
                PrivacyShield()
            }
        }
        .onAppear { WindowAppearance.apply(interfaceStyle) }
        .onChange(of: interfaceStyle) { _, style in
            WindowAppearance.apply(style)
        }
        .onChange(of: scenePhase) { _, phase in
            handle(phase)
        }
    }

    // MARK: - Auto-lock

    private func handle(_ phase: ScenePhase) {
        switch phase {
        case .background:
            autoLockMonitor.didEnterBackground()
            if autoLock == .immediately { session.lock() }
        case .active:
            if autoLockMonitor.shouldLockOnReturn(option: autoLock) { session.lock() }
            session.refreshBiometricAvailability()
            captureMonitor.refresh()
        default:
            break
        }
    }
}
