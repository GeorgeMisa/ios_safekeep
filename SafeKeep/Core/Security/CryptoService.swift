import CommonCrypto
import CryptoKit
import Foundation
import Security

enum CryptoError: Error, Equatable {
    case randomGenerationFailed
    case keyDerivationFailed
    case sealFailed
    case openFailed
}

enum CryptoService {
    static let minimumIterations = 600_000
    static let maximumIterations = 10_000_000

    // MARK: - Randomness

    static func randomBytes(count: Int) throws -> Data {
        var data = Data(count: count)
        let status = data.withUnsafeMutableBytes { buffer in
            SecRandomCopyBytes(kSecRandomDefault, count, buffer.baseAddress!)
        }
        guard status == errSecSuccess else { throw CryptoError.randomGenerationFailed }
        return data
    }

    // MARK: - Key derivation

    static func deriveKey(from secret: String, salt: Data, iterations: Int) throws -> SymmetricKey {
        let password = Data(secret.utf8)
        var derived = Data(count: 32)
        defer { derived.resetBytes(in: 0..<derived.count) }

        let status = derived.withUnsafeMutableBytes { derivedBuffer in
            salt.withUnsafeBytes { saltBuffer in
                password.withUnsafeBytes { passwordBuffer in
                    CCKeyDerivationPBKDF(
                        CCPBKDFAlgorithm(kCCPBKDF2),
                        passwordBuffer.baseAddress?.assumingMemoryBound(to: Int8.self),
                        password.count,
                        saltBuffer.baseAddress?.assumingMemoryBound(to: UInt8.self),
                        salt.count,
                        CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
                        UInt32(iterations),
                        derivedBuffer.baseAddress?.assumingMemoryBound(to: UInt8.self),
                        32
                    )
                }
            }
        }
        guard status == kCCSuccess else { throw CryptoError.keyDerivationFailed }
        return SymmetricKey(data: derived)
    }

    static func calibratedIterations(targetMilliseconds: UInt32 = 500) -> Int {
        let rounds = CCCalibratePBKDF(
            CCPBKDFAlgorithm(kCCPBKDF2), 6, 16,
            CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256), 32, targetMilliseconds
        )
        return min(max(Int(rounds), minimumIterations), maximumIterations)
    }

    // MARK: - Authenticated encryption

    // The context string is bound as associated data so a blob sealed for one purpose can't be swapped in for another.
    static func seal(_ plaintext: Data, using key: SymmetricKey, context: String) throws -> Data {
        guard let combined = try AES.GCM.seal(plaintext, using: key, authenticating: Data(context.utf8)).combined else {
            throw CryptoError.sealFailed
        }
        return combined
    }

    static func open(_ sealed: Data, using key: SymmetricKey, context: String) throws -> Data {
        do {
            let box = try AES.GCM.SealedBox(combined: sealed)
            return try AES.GCM.open(box, using: key, authenticating: Data(context.utf8))
        } catch {
            throw CryptoError.openFailed
        }
    }
}

extension SymmetricKey {
    var rawData: Data { withUnsafeBytes { Data($0) } }
}
