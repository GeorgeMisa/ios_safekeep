import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {
    // Third-party keyboards can log keystrokes, so only the system keyboard is allowed.
    func application(
        _ application: UIApplication,
        shouldAllowExtensionPointIdentifier extensionPointIdentifier: UIApplication.ExtensionPointIdentifier
    ) -> Bool {
        extensionPointIdentifier != .keyboard
    }
}
