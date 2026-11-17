import CryptoKit
import Foundation
import Testing
@testable import SafeKeep

@Suite(.serialized)
struct VaultKeyManagerTests {
    @Test func correctPasscodeUnwrapsSameKey() throws {
        let manager = TestSupport.keyManager()
        defer { manager.eraseAll() }
        let key = try manager.createVaultKey(passcode: "482913")
        #expect(manager.hasVault)
        #expect(try manager.unlock(passcode: "482913").rawData == key.rawData)
    }

    @Test func wrongPasscodeCannotUnwrap() throws {
        let manager = TestSupport.keyManager()
        defer { manager.eraseAll() }
        _ = try manager.createVaultKey(passcode: "482913")
        #expect(throws: VaultKeyError.wrongPasscode) {
            try manager.unlock(passcode: "482914")
        }
    }

    @Test func changingPasscodeKeepsVaultKey() throws {
        let manager = TestSupport.keyManager()
        defer { manager.eraseAll() }
        let key = try manager.createVaultKey(passcode: "482913")
        try manager.storePasscodeWrap(for: key, passcode: "605172")
        #expect(throws: VaultKeyError.wrongPasscode) { try manager.unlock(passcode: "482913") }
        #expect(try manager.unlock(passcode: "605172").rawData == key.rawData)
    }

    @Test func unlockWithoutVaultFails() {
        let manager = TestSupport.keyManager()
        #expect(!manager.hasVault)
        #expect(throws: VaultKeyError.notSetUp) { try manager.unlock(passcode: "482913") }
    }

    @Test func eraseRemovesEverything() throws {
        let manager = TestSupport.keyManager()
        _ = try manager.createVaultKey(passcode: "482913")
        manager.eraseAll()
        #expect(!manager.hasVault)
    }

    @Test func keychainStoresOnlyCiphertext() throws {
        let keychain = TestSupport.keychain()
        let manager = TestSupport.keyManager(keychain)
        defer { manager.eraseAll() }
        let key = try manager.createVaultKey(passcode: "482913")
        let stored = try #require(try keychain.read("vault.key.passcode"))
        #expect(stored.range(of: key.rawData) == nil)
    }
}
