import Foundation
import SwiftUI
import UniformTypeIdentifiers

enum BackupError: LocalizedError, Equatable {
    case invalidFile
    case unsupportedVersion
    case wrongPassword
    case passwordTooShort

    var errorDescription: String? {
        switch self {
        case .invalidFile: "This file isn't a SafeKeep backup."
        case .unsupportedVersion: "This backup was made by a newer version of SafeKeep."
        case .wrongPassword: "That backup password is incorrect."
        case .passwordTooShort: "Use at least \(BackupService.minimumPasswordLength) characters."
        }
    }
}

struct BackupEnvelope: Codable, Sendable {
    var format: String
    var version: Int
    var kdf: String
    var iterations: Int
    var salt: Data
    var sealed: Data
    var createdAt: Date
}

enum BackupService {
    static let minimumPasswordLength = 12
    static let maximumFileSize = 20 * 1024 * 1024

    private static let format = "safekeep-backup"
    private static let version = 1
    private static let kdf = "pbkdf2-sha256"
    private static let context = "safekeep.backup.v1"
    private static let acceptedIterations = 1_000...20_000_000

    // MARK: - Export

    static func export(_ payload: VaultPayload, password: String, iterations: Int, now: Date = .now) throws -> Data {
        guard password.count >= minimumPasswordLength else { throw BackupError.passwordTooShort }
        let salt = try CryptoService.randomBytes(count: 16)
        let key = try CryptoService.deriveKey(from: password, salt: salt, iterations: iterations)
        let sealed = try CryptoService.seal(JSONEncoder().encode(payload), using: key, context: context)
        let envelope = BackupEnvelope(
            format: format, version: version, kdf: kdf,
            iterations: iterations, salt: salt, sealed: sealed, createdAt: now
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(envelope)
    }

    // MARK: - Import

    static func decrypt(_ data: Data, password: String) throws -> VaultPayload {
        guard data.count <= maximumFileSize else { throw BackupError.invalidFile }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let envelope = try? decoder.decode(BackupEnvelope.self, from: data),
              envelope.format == format, envelope.kdf == kdf,
              acceptedIterations.contains(envelope.iterations)
        else { throw BackupError.invalidFile }
        guard envelope.version <= version else { throw BackupError.unsupportedVersion }

        let key = try CryptoService.deriveKey(from: password, salt: envelope.salt, iterations: envelope.iterations)
        let plaintext: Data
        do {
            plaintext = try CryptoService.open(envelope.sealed, using: key, context: context)
        } catch {
            throw BackupError.wrongPassword
        }
        guard let payload = try? JSONDecoder().decode(VaultPayload.self, from: plaintext) else {
            throw BackupError.invalidFile
        }
        return payload
    }

    static func merge(_ incoming: [Account], into existing: [Account]) -> (accounts: [Account], added: Int, skipped: Int) {
        var merged = existing
        var ids = Set(existing.map(\.id))
        var fingerprints = Set(existing.map(fingerprint))
        var added = 0
        for account in incoming {
            let print = fingerprint(account)
            guard !ids.contains(account.id), !fingerprints.contains(print) else { continue }
            merged.append(account)
            ids.insert(account.id)
            fingerprints.insert(print)
            added += 1
        }
        return (merged, added, incoming.count - added)
    }

    private static func fingerprint(_ account: Account) -> String {
        [account.serviceName.lowercased(), account.username.lowercased(), account.password].joined(separator: "\u{1F}")
    }
}

// MARK: - File document

extension UTType {
    static let safekeepBackup = UTType(exportedAs: "com.safekeep.backup")
}

struct BackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.safekeepBackup] }

    var data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else { throw BackupError.invalidFile }
        self.data = data
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
