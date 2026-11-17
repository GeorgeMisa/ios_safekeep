import CryptoKit
import Foundation

struct VaultRepository: Sendable {
    private static let context = "safekeep.vault.v1"

    static var live: VaultRepository { VaultRepository(fileURL: FileLocations.vaultFile) }

    let fileURL: URL

    var exists: Bool { FileManager.default.fileExists(atPath: fileURL.path(percentEncoded: false)) }

    // MARK: - Read

    func load(using key: SymmetricKey) throws -> VaultPayload {
        guard exists else { return VaultPayload() }
        let sealed = try Data(contentsOf: fileURL)
        let plaintext = try CryptoService.open(sealed, using: key, context: Self.context)
        return try JSONDecoder().decode(VaultPayload.self, from: plaintext)
    }

    // MARK: - Write

    // Complete file protection keeps the ciphertext unreadable while the device is locked;
    // the backup exclusion keeps it out of iCloud and Finder backups (encrypted export is the backup path).
    func save(_ payload: VaultPayload, using key: SymmetricKey) throws {
        let directory = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true,
            attributes: [.protectionKey: FileProtectionType.complete]
        )
        let plaintext = try JSONEncoder().encode(payload)
        let sealed = try CryptoService.seal(plaintext, using: key, context: Self.context)
        try sealed.write(to: fileURL, options: [.atomic, .completeFileProtection])
        try excludeFromBackup(directory)
        try excludeFromBackup(fileURL)
    }

    func delete() {
        try? FileManager.default.removeItem(at: fileURL)
    }

    private func excludeFromBackup(_ url: URL) throws {
        var url = url
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try url.setResourceValues(values)
    }
}
