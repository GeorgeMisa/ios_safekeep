import Foundation
import Security

struct SecureRandomGenerator: RandomNumberGenerator {
    mutating func next() -> UInt64 {
        var value: UInt64 = 0
        let status = withUnsafeMutableBytes(of: &value) { buffer in
            SecRandomCopyBytes(kSecRandomDefault, buffer.count, buffer.baseAddress!)
        }
        precondition(status == errSecSuccess, "Secure random generation failed")
        return value
    }
}

enum PasswordGenerator {
    struct Options: Equatable, Sendable {
        var length = 20
        var includeUppercase = true
        var includeDigits = true
        var includeSymbols = true
    }

    static let lengthRange = 12...64

    // Visually ambiguous characters (l, I, O, 0, 1) are left out so passwords can be read and retyped.
    static let lowercase = Array("abcdefghijkmnopqrstuvwxyz")
    static let uppercase = Array("ABCDEFGHJKLMNPQRSTUVWXYZ")
    static let digits = Array("23456789")
    static let symbols = Array("!@#$%^&*-_=+?")

    static func generate(_ options: Options) -> String {
        var rng = SecureRandomGenerator()
        var pools = [lowercase]
        if options.includeUppercase { pools.append(uppercase) }
        if options.includeDigits { pools.append(digits) }
        if options.includeSymbols { pools.append(symbols) }

        let length = min(max(options.length, lengthRange.lowerBound), lengthRange.upperBound)
        let combined = pools.flatMap { $0 }
        var characters = pools.map { $0.randomElement(using: &rng)! }
        while characters.count < length {
            characters.append(combined.randomElement(using: &rng)!)
        }
        characters.shuffle(using: &rng)
        return String(characters)
    }
}
