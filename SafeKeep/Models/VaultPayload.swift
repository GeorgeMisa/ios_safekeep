import Foundation

struct VaultPayload: Codable, Equatable, Sendable {
    var schemaVersion = 1
    var displayName = ""
    var accounts: [Account] = []
}
