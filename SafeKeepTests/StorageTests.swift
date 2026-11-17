import CryptoKit
import Foundation
import Testing
@testable import SafeKeep

struct VaultRepositoryTests {
    @Test func savedVaultIsCiphertextAndRoundTrips() throws {
        let repository = VaultRepository(fileURL: TestSupport.temporaryVaultURL())
        defer { repository.delete() }
        let key = SymmetricKey(size: .bits256)
        let payload = VaultPayload(displayName: "Alex", accounts: [TestSupport.account("Netflix", username: "alex@example.com")])

        try repository.save(payload, using: key)

        let onDisk = try Data(contentsOf: repository.fileURL)
        #expect(onDisk.range(of: Data("Netflix".utf8)) == nil)
        #expect(onDisk.range(of: Data("alex@example.com".utf8)) == nil)
        #expect(try repository.load(using: key) == payload)
    }

    @Test func vaultIsExcludedFromBackup() throws {
        let repository = VaultRepository(fileURL: TestSupport.temporaryVaultURL())
        defer { repository.delete() }
        try repository.save(VaultPayload(), using: SymmetricKey(size: .bits256))
        let values = try repository.fileURL.resourceValues(forKeys: [.isExcludedFromBackupKey])
        #expect(values.isExcludedFromBackup == true)
    }

    @Test func wrongKeyCannotLoad() throws {
        let repository = VaultRepository(fileURL: TestSupport.temporaryVaultURL())
        defer { repository.delete() }
        try repository.save(VaultPayload(accounts: [TestSupport.account("Gmail")]), using: SymmetricKey(size: .bits256))
        #expect(throws: CryptoError.openFailed) {
            try repository.load(using: SymmetricKey(size: .bits256))
        }
    }

    @Test func existingVaultIsFoundInPathWithSpaces() throws {
        let repository = VaultRepository(fileURL: TestSupport.temporaryVaultURL())
        defer { repository.delete() }
        let key = SymmetricKey(size: .bits256)
        try repository.save(VaultPayload(accounts: [TestSupport.account("Gmail")]), using: key)
        #expect(repository.fileURL.path(percentEncoded: false).contains(" "))
        #expect(repository.exists)
        #expect(try repository.load(using: key).accounts.count == 1)
    }

    @Test func missingFileLoadsEmptyVault() throws {
        let repository = VaultRepository(fileURL: TestSupport.temporaryVaultURL())
        #expect(try repository.load(using: SymmetricKey(size: .bits256)) == VaultPayload())
    }
}

struct BackupServiceTests {
    private let payload = VaultPayload(
        displayName: "Alex",
        accounts: [TestSupport.account("Gmail"), TestSupport.account("Spotify", password: "another-Strong-pass-42")]
    )

    @Test func exportImportRoundTrip() throws {
        let data = try BackupService.export(payload, password: "long backup password", iterations: TestSupport.fastIterations)
        #expect(data.range(of: Data("Gmail".utf8)) == nil)
        #expect(try BackupService.decrypt(data, password: "long backup password") == payload)
    }

    @Test func wrongPasswordIsRejected() throws {
        let data = try BackupService.export(payload, password: "long backup password", iterations: TestSupport.fastIterations)
        #expect(throws: BackupError.wrongPassword) {
            try BackupService.decrypt(data, password: "wrong backup password")
        }
    }

    @Test func shortPasswordIsRefused() {
        #expect(throws: BackupError.passwordTooShort) {
            try BackupService.export(payload, password: "short", iterations: TestSupport.fastIterations)
        }
    }

    @Test func garbageIsRejected() {
        #expect(throws: BackupError.invalidFile) {
            try BackupService.decrypt(Data("not a backup".utf8), password: "long backup password")
        }
    }

    @Test func absurdIterationCountIsRejected() throws {
        let data = try BackupService.export(payload, password: "long backup password", iterations: TestSupport.fastIterations)
        var json = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        json["iterations"] = 4_000_000_000
        let tampered = try JSONSerialization.data(withJSONObject: json)
        #expect(throws: BackupError.invalidFile) {
            try BackupService.decrypt(tampered, password: "long backup password")
        }
    }

    @Test func mergeSkipsDuplicates() {
        let existing = [TestSupport.account("Gmail")]
        var sameLogin = TestSupport.account("gmail")
        sameLogin.id = UUID()
        let incoming = [existing[0], sameLogin, TestSupport.account("Netflix")]

        let result = BackupService.merge(incoming, into: existing)
        #expect(result.added == 1)
        #expect(result.skipped == 2)
        #expect(result.accounts.map(\.serviceName) == ["Gmail", "Netflix"])
    }
}
