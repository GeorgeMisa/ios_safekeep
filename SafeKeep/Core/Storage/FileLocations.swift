import Foundation

enum FileLocations {
    static var vaultFile: URL {
        URL.applicationSupportDirectory.appending(path: "Vault/vault.sealed")
    }
}
