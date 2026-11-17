import SwiftUI
import UIKit

enum Palette {
    static let brand = Color(light: 0x2563EB, dark: 0x3B82F6)
    static let safe = Color(light: 0x16A34A, dark: 0x4ADE80)
    static let caution = Color(light: 0xD97706, dark: 0xFBBF24)

    static let lockGradient = LinearGradient(
        colors: [Color(hex: 0x2F6BFF), Color(hex: 0x1739B5)],
        startPoint: .top,
        endPoint: .bottom
    )

    static let statusGradient = LinearGradient(
        colors: [Color(light: 0x3B7BFF, dark: 0x2552D9), Color(light: 0x1D4ED8, dark: 0x1A3AA8)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let mascotBand = Color(light: 0xDCE7FD, dark: 0x1A2747)
    static let bubble = Color(light: 0xFFFFFF, dark: 0x1C1F26)
    static let bubbleStroke = Color(light: 0xD5E0F7, dark: 0x2C3A5C)

    static let iconGradient = LinearGradient(
        colors: [Color(hex: 0x4F7DFF), Color(hex: 0x1D3FD8)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
}

enum Radius {
    static let field: CGFloat = 12
    static let card: CGFloat = 20
}

// MARK: - Color helpers

extension Color {
    init(hex: UInt32) {
        self.init(uiColor: UIColor(hex: hex))
    }

    init(light: UInt32, dark: UInt32) {
        self.init(uiColor: UIColor { traits in
            UIColor(hex: traits.userInterfaceStyle == .dark ? dark : light)
        })
    }

    init?(hexString: String) {
        let cleaned = hexString.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        guard cleaned.count == 6, let value = UInt32(cleaned, radix: 16) else { return nil }
        self.init(hex: value)
    }
}

extension UIColor {
    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}
