import Foundation
@testable import SafeKeep

enum TestSupport {
    static let fastIterations = 1_000

    static func keychain() -> KeychainStore {
        KeychainStore(service: "com.safekeep.tests.\(UUID().uuidString)")
    }

    static func keyManager(_ keychain: KeychainStore = keychain()) -> VaultKeyManager {
        VaultKeyManager(keychain: keychain, iterations: { fastIterations })
    }

    static func temporaryVaultURL() -> URL {
        FileManager.default.temporaryDirectory
            .appending(path: "SafeKeep Tests \(UUID().uuidString)")
            .appending(path: "vault.sealed")
    }

    static func account(_ name: String, password: String = "Xq7!vR2#pL9$wM4@", username: String = "me@example.com") -> Account {
        Account(serviceName: name, username: username, password: password, category: .other)
    }
}
