import Foundation

enum StrengthLevel: Int, Comparable, CaseIterable, Sendable {
    case empty, weak, fair, good, strong

    static func < (lhs: StrengthLevel, rhs: StrengthLevel) -> Bool { lhs.rawValue < rhs.rawValue }

    var title: String {
        switch self {
        case .empty: "Empty"
        case .weak: "Weak"
        case .fair: "Fair"
        case .good: "Good"
        case .strong: "Strong"
        }
    }
}

enum PasswordStrength {
    static func entropyBits(_ password: String) -> Double {
        guard !password.isEmpty else { return 0 }
        var pool = 0
        if password.contains(where: \.isLowercase) { pool += 26 }
        if password.contains(where: \.isUppercase) { pool += 26 }
        if password.contains(where: \.isNumber) { pool += 10 }
        if password.contains(where: { !$0.isLetter && !$0.isNumber }) { pool += 33 }

        let uniqueRatio = Double(Set(password).count) / Double(password.count)
        let repetitionFactor = min(1, 0.5 + uniqueRatio / 2)
        return Double(password.count) * log2(Double(max(pool, 1))) * repetitionFactor
    }

    static func level(for password: String) -> StrengthLevel {
        guard !password.isEmpty else { return .empty }
        switch entropyBits(password) {
        case ..<40: return .weak
        case ..<60: return .fair
        case ..<80: return .good
        default: return .strong
        }
    }
}

enum PasscodeRules {
    static let length = 6

    static func isTooSimple(_ code: String) -> Bool {
        let digits = code.compactMap(\.wholeNumberValue)
        guard digits.count == length else { return true }
        if Set(digits).count == 1 { return true }
        let steps = zip(digits, digits.dropFirst()).map { $1 - $0 }
        return steps.allSatisfy { $0 == 1 } || steps.allSatisfy { $0 == -1 }
    }
}
