import CryptoKit
import Foundation
import Observation

enum UnlockOutcome: Equatable {
    case success
    case wrongPasscode(attemptsLeft: Int)
    case lockedOut
    case failed(String)
}

struct ImportSummary: Equatable {
    let added: Int
    let skipped: Int
}

enum SessionError: LocalizedError {
    case locked
    case biometricsUnavailable
    case biometricsInvalidated

    var errorDescription: String? {
        switch self {
        case .locked: "SafeKeep is locked. Unlock it and try again."
        case .biometricsUnavailable: "Set up Face ID in the Settings app first."
        case .biometricsInvalidated: "Your Face ID settings changed, so Face ID unlock was turned off. Use your passcode, then turn it on again in Settings."
        }
    }
}

@MainActor
@Observable
final class VaultSession {
    enum Phase: Equatable {
        case onboarding, locked, unlocked
    }

    private enum Keys {
        static let installMarker = "vault.installMarker"
        static let biometrics = "vault.biometricsEnabled"
    }

    private(set) var phase: Phase
    private(set) var payload = VaultPayload()
    private(set) var lockout: LockoutState
    private(set) var isBiometricsEnabled: Bool
    private(set) var biometricHardware: BiometricKind
    private(set) var isBiometricsAvailable: Bool
    private(set) var autoPromptsBiometrics = true

    @ObservationIgnored private var vaultKey: SymmetricKey?
    @ObservationIgnored private let keyManager: VaultKeyManager
    @ObservationIgnored private let repository: VaultRepository
    @ObservationIgnored private let lockoutStore: LockoutStore
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let now: @Sendable () -> Date

    init(
        keyManager: VaultKeyManager,
        repository: VaultRepository,
        lockoutStore: LockoutStore,
        defaults: UserDefaults,
        now: @escaping @Sendable () -> Date = { .now }
    ) {
        self.keyManager = keyManager
        self.repository = repository
        self.lockoutStore = lockoutStore
        self.defaults = defaults
        self.now = now

        // Keychain items survive app deletion; a reinstall starts from a clean slate.
        if !defaults.bool(forKey: Keys.installMarker) {
            keyManager.eraseAll()
            repository.delete()
            defaults.set(false, forKey: Keys.biometrics)
            defaults.set(true, forKey: Keys.installMarker)
        }

        phase = keyManager.hasVault ? .locked : .onboarding
        lockout = lockoutStore.load()
        isBiometricsEnabled = defaults.bool(forKey: Keys.biometrics)
        biometricHardware = BiometricAuthenticator.hardwareKind
        isBiometricsAvailable = BiometricAuthenticator.isAvailable
    }

    static func live() -> VaultSession {
        let keychain = KeychainStore(service: "com.safekeep.vault")
        return VaultSession(
            keyManager: VaultKeyManager(keychain: keychain),
            repository: .live,
            lockoutStore: LockoutStore(keychain: keychain),
            defaults: .standard
        )
    }

    // MARK: - Derived state

    var accounts: [Account] {
        payload.accounts.sorted { $0.serviceName.localizedCaseInsensitiveCompare($1.serviceName) == .orderedAscending }
    }

    var securityReport: SecurityReport { VaultAudit.report(for: payload.accounts) }

    var unlockBiometric: BiometricKind { isBiometricsEnabled && isBiometricsAvailable ? biometricHardware : .none }

    var passcodeIterations: Int? { keyManager.passcodeIterations }

    func account(id: Account.ID) -> Account? {
        payload.accounts.first { $0.id == id }
    }

    func lockoutRemaining(at date: Date) -> TimeInterval {
        LockoutPolicy.remainingLockout(for: lockout, at: date)
    }

    func allowBiometricAutoPrompt() {
        autoPromptsBiometrics = true
    }

    func refreshBiometricAvailability() {
        biometricHardware = BiometricAuthenticator.hardwareKind
        isBiometricsAvailable = BiometricAuthenticator.isAvailable
    }

    // MARK: - Onboarding

    func setUp(passcode: String) async throws {
        let manager = keyManager
        let key = try await Task.detached(priority: .userInitiated) {
            try manager.createVaultKey(passcode: passcode)
        }.value
        let empty = VaultPayload()
        try repository.save(empty, using: key)
        payload = empty
        vaultKey = key
        resetLockout()
    }

    func finishOnboarding() {
        guard vaultKey != nil else { return }
        phase = .unlocked
    }

    // MARK: - Unlock

    func unlock(passcode: String) async -> UnlockOutcome {
        let (key, outcome) = await attempt(passcode: passcode)
        guard let key else { return outcome }
        do {
            try open(with: key)
            return .success
        } catch {
            return .failed("Your vault couldn't be opened.")
        }
    }

    func verifyPasscode(_ passcode: String) async -> UnlockOutcome {
        await attempt(passcode: passcode).1
    }

    func unlockWithBiometrics() async throws {
        let manager = keyManager
        do {
            let key = try await Task.detached(priority: .userInitiated) {
                try await manager.unlockWithBiometrics(reason: "Unlock your SafeKeep vault")
            }.value
            try open(with: key)
            resetLockout()
        } catch VaultKeyError.biometricsInvalidated {
            disableBiometrics()
            throw SessionError.biometricsInvalidated
        }
    }

    // A manual lock shouldn't immediately re-prompt Face ID, which would unlock again on sight.
    func lock(userInitiated: Bool = false) {
        vaultKey = nil
        payload = VaultPayload()
        autoPromptsBiometrics = !userInitiated
        if keyManager.hasVault, phase != .locked {
            phase = .locked
        }
    }

    private func attempt(passcode: String) async -> (SymmetricKey?, UnlockOutcome) {
        guard lockoutRemaining(at: now()) == 0 else { return (nil, .lockedOut) }
        let manager = keyManager
        do {
            let key = try await Task.detached(priority: .userInitiated) {
                try manager.unlock(passcode: passcode)
            }.value
            resetLockout()
            return (key, .success)
        } catch VaultKeyError.wrongPasscode {
            lockout = LockoutPolicy.registeringFailure(lockout, at: now())
            lockoutStore.save(lockout)
            if lockoutRemaining(at: now()) > 0 { return (nil, .lockedOut) }
            return (nil, .wrongPasscode(attemptsLeft: LockoutPolicy.attemptsBeforeLockout(lockout)))
        } catch {
            return (nil, .failed("Something went wrong. Try again."))
        }
    }

    private func open(with key: SymmetricKey) throws {
        payload = try repository.load(using: key)
        vaultKey = key
        phase = .unlocked
    }

    private func resetLockout() {
        guard lockout != LockoutState() else { return }
        lockout = LockoutState()
        lockoutStore.save(lockout)
    }

    // MARK: - Accounts

    func save(_ account: Account) throws {
        var updated = payload
        var account = account
        account.updatedAt = now()
        if let index = updated.accounts.firstIndex(where: { $0.id == account.id }) {
            updated.accounts[index] = account
        } else {
            account.createdAt = account.updatedAt
            updated.accounts.append(account)
        }
        try persist(updated)
    }

    func deleteAccount(id: Account.ID) throws {
        var updated = payload
        updated.accounts.removeAll { $0.id == id }
        try persist(updated)
    }

    func updateDisplayName(_ name: String) throws {
        var updated = payload
        updated.displayName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        try persist(updated)
    }

    private func persist(_ updated: VaultPayload) throws {
        guard let key = vaultKey else { throw SessionError.locked }
        try repository.save(updated, using: key)
        payload = updated
    }

    // MARK: - Passcode & biometrics

    func changePasscode(to newPasscode: String) async throws {
        guard let key = vaultKey else { throw SessionError.locked }
        let manager = keyManager
        try await Task.detached(priority: .userInitiated) {
            try manager.storePasscodeWrap(for: key, passcode: newPasscode)
        }.value
    }

    func enableBiometrics() throws {
        guard let key = vaultKey else { throw SessionError.locked }
        refreshBiometricAvailability()
        guard isBiometricsAvailable else { throw SessionError.biometricsUnavailable }
        try keyManager.enableBiometrics(for: key)
        isBiometricsEnabled = true
        defaults.set(true, forKey: Keys.biometrics)
    }

    func disableBiometrics() {
        keyManager.disableBiometrics()
        isBiometricsEnabled = false
        defaults.set(false, forKey: Keys.biometrics)
    }

    // MARK: - Backup

    func exportBackup(password: String) async throws -> Data {
        guard vaultKey != nil else { throw SessionError.locked }
        let snapshot = payload
        return try await Task.detached(priority: .userInitiated) {
            try BackupService.export(
                snapshot, password: password,
                iterations: CryptoService.calibratedIterations(targetMilliseconds: 800)
            )
        }.value
    }

    func importBackup(_ data: Data, password: String) async throws -> ImportSummary {
        guard vaultKey != nil else { throw SessionError.locked }
        let incoming = try await Task.detached(priority: .userInitiated) {
            try BackupService.decrypt(data, password: password)
        }.value
        let result = BackupService.merge(incoming.accounts, into: payload.accounts)
        var updated = payload
        updated.accounts = result.accounts
        if updated.displayName.isEmpty { updated.displayName = incoming.displayName }
        try persist(updated)
        return ImportSummary(added: result.added, skipped: result.skipped)
    }

    // MARK: - Erase

    func eraseVault() {
        keyManager.eraseAll()
        repository.delete()
        vaultKey = nil
        payload = VaultPayload()
        lockout = LockoutState()
        isBiometricsEnabled = false
        defaults.set(false, forKey: Keys.biometrics)
        phase = .onboarding
    }
}
