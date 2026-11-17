import CryptoKit
import Foundation
import LocalAuthentication

enum VaultKeyError: Error, Equatable {
    case notSetUp
    case wrongPasscode
    case biometricsCancelled
    case biometricsFailed
    case biometricsInvalidated
}

extension VaultKeyError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .biometricsFailed: "Face ID didn't recognize you. Use your passcode."
        default: nil
        }
    }
}

struct VaultKeyManager: Sendable {
    private enum Item {
        static let passcodeWrap = "vault.key.passcode"
        static let biometricKey = "vault.key.biometric"
    }

    private struct PasscodeWrap: Codable {
        let salt: Data
        let iterations: Int
        let sealedKey: Data
    }

    private static let wrapContext = "safekeep.vault-key.v1"

    let keychain: KeychainStore
    var iterations: @Sendable () -> Int = { CryptoService.calibratedIterations() }

    var hasVault: Bool { (try? keychain.read(Item.passcodeWrap)) != nil }

    var passcodeIterations: Int? { (try? loadWrap())?.iterations }

    // MARK: - Passcode

    func createVaultKey(passcode: String) throws -> SymmetricKey {
        let key = SymmetricKey(size: .bits256)
        try storePasscodeWrap(for: key, passcode: passcode)
        return key
    }

    func storePasscodeWrap(for key: SymmetricKey, passcode: String) throws {
        let salt = try CryptoService.randomBytes(count: 16)
        let rounds = iterations()
        let wrappingKey = try CryptoService.deriveKey(from: passcode, salt: salt, iterations: rounds)
        let sealed = try CryptoService.seal(key.rawData, using: wrappingKey, context: Self.wrapContext)
        let wrap = PasscodeWrap(salt: salt, iterations: rounds, sealedKey: sealed)
        try keychain.set(JSONEncoder().encode(wrap), account: Item.passcodeWrap)
    }

    func unlock(passcode: String) throws -> SymmetricKey {
        guard let wrap = try loadWrap() else { throw VaultKeyError.notSetUp }
        let wrappingKey = try CryptoService.deriveKey(from: passcode, salt: wrap.salt, iterations: wrap.iterations)
        do {
            return SymmetricKey(data: try CryptoService.open(wrap.sealedKey, using: wrappingKey, context: Self.wrapContext))
        } catch {
            throw VaultKeyError.wrongPasscode
        }
    }

    private func loadWrap() throws -> PasscodeWrap? {
        guard let data = try keychain.read(Item.passcodeWrap) else { return nil }
        return try JSONDecoder().decode(PasscodeWrap.self, from: data)
    }

    // MARK: - Biometrics

    // The Secure Enclave releases this item only after a successful Face ID / Touch ID match,
    // and invalidates it if the enrolled faces or fingers change.
    func enableBiometrics(for key: SymmetricKey) throws {
        try keychain.set(key.rawData, account: Item.biometricKey, protection: .biometryCurrentSet)
    }

    func disableBiometrics() {
        try? keychain.delete(Item.biometricKey)
    }

    // Face ID is evaluated explicitly first, then the same authenticated context is handed to the
    // Keychain, whose access control re-checks it in the Secure Enclave before releasing the key.
    func unlockWithBiometrics(reason: String) async throws -> SymmetricKey {
        let context = LAContext()
        context.localizedFallbackTitle = ""
        do {
            try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason)
        } catch let error as LAError where [.userCancel, .appCancel, .systemCancel, .userFallback].contains(error.code) {
            throw VaultKeyError.biometricsCancelled
        } catch {
            throw VaultKeyError.biometricsFailed
        }

        do {
            guard let data = try keychain.read(Item.biometricKey, context: context) else {
                throw VaultKeyError.biometricsInvalidated
            }
            return SymmetricKey(data: data)
        } catch KeychainError.authenticationFailed {
            throw VaultKeyError.biometricsCancelled
        }
    }

    // MARK: - Erase

    func eraseAll() {
        keychain.deleteAll()
    }
}
