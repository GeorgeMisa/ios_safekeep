import Foundation
import LocalAuthentication
import Security

enum KeychainError: Error, Equatable {
    case accessControlUnavailable
    case authenticationFailed
    case unhandled(OSStatus)
}

struct KeychainStore: Sendable {
    enum Protection: Sendable {
        case deviceOnly
        case biometryCurrentSet
    }

    let service: String

    // MARK: - Write

    // Every item is ThisDeviceOnly: never synced to iCloud Keychain and never restored onto another device.
    func set(_ data: Data, account: String, protection: Protection = .deviceOnly) throws {
        try delete(account)
        var query = baseQuery(account)
        query[kSecValueData as String] = data

        switch protection {
        case .deviceOnly:
            query[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        case .biometryCurrentSet:
            var error: Unmanaged<CFError>?
            guard let access = SecAccessControlCreateWithFlags(
                nil, kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly, .biometryCurrentSet, &error
            ) else { throw KeychainError.accessControlUnavailable }
            query[kSecAttrAccessControl as String] = access
        }

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else { throw KeychainError.unhandled(status) }
    }

    // MARK: - Read

    func read(_ account: String, context: LAContext? = nil) throws -> Data? {
        var query = baseQuery(account)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        if let context { query[kSecUseAuthenticationContext as String] = context }

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        switch status {
        case errSecSuccess: return result as? Data
        case errSecItemNotFound: return nil
        case errSecUserCanceled, errSecAuthFailed: throw KeychainError.authenticationFailed
        default: throw KeychainError.unhandled(status)
        }
    }

    // MARK: - Delete

    func delete(_ account: String) throws {
        let status = SecItemDelete(baseQuery(account) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else { throw KeychainError.unhandled(status) }
    }

    func deleteAll() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
        ]
        SecItemDelete(query as CFDictionary)
    }

    private func baseQuery(_ account: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecUseDataProtectionKeychain as String: true,
        ]
    }
}
