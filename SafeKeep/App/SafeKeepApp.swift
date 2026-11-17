import SwiftUI

@main
struct SafeKeepApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var session = VaultSession.live()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(session)
        }
    }
}
