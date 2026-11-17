import UIKit
import UniformTypeIdentifiers

@MainActor
enum SecureClipboard {
    static let lifetime: TimeInterval = 30

    // localOnly keeps the value off Universal Clipboard; the expiration clears it automatically.
    static func copy(_ value: String) {
        UIPasteboard.general.setItems(
            [[UTType.utf8PlainText.identifier: value]],
            options: [.localOnly: true, .expirationDate: Date.now.addingTimeInterval(lifetime)]
        )
    }
}
