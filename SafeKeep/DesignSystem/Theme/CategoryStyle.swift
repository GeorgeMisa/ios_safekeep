import SwiftUI

extension AccountCategory {
    var tint: Color {
        switch self {
        case .email: Color(hex: 0xE5484D)
        case .social: Color(hex: 0x3E63DD)
        case .entertainment: Color(hex: 0x8E4EC6)
        case .finance: Color(hex: 0x30A46C)
        case .shopping: Color(hex: 0xF76B15)
        case .work: Color(hex: 0x5B5BD6)
        case .developer: Color(hex: 0x60646C)
        case .gaming: Color(hex: 0xD6409F)
        case .other: Color(hex: 0x12A594)
        }
    }
}

extension StrengthLevel {
    var color: Color {
        switch self {
        case .empty: .secondary
        case .weak: .red
        case .fair: .orange
        case .good: Palette.brand
        case .strong: Palette.safe
        }
    }
}
