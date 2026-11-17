import Foundation

struct LockoutState: Codable, Equatable, Sendable {
    var failedAttempts = 0
    var lastFailureAt: Date?
}

enum LockoutPolicy {
    static let freeAttempts = 5

    static func delay(forFailures count: Int) -> TimeInterval {
        switch count - freeAttempts {
        case ...0: 0
        case 1: 60
        case 2: 5 * 60
        case 3: 15 * 60
        default: 60 * 60
        }
    }

    static func registeringFailure(_ state: LockoutState, at date: Date) -> LockoutState {
        LockoutState(failedAttempts: state.failedAttempts + 1, lastFailureAt: date)
    }

    static func remainingLockout(for state: LockoutState, at date: Date) -> TimeInterval {
        guard let lastFailure = state.lastFailureAt else { return 0 }
        let wait = delay(forFailures: state.failedAttempts)
        guard wait > 0 else { return 0 }
        // A clock set backwards must not shorten the wait.
        guard date >= lastFailure else { return wait }
        return max(0, lastFailure.addingTimeInterval(wait).timeIntervalSince(date))
    }

    static func attemptsBeforeLockout(_ state: LockoutState) -> Int {
        max(0, freeAttempts - state.failedAttempts)
    }
}

struct LockoutStore: Sendable {
    private static let account = "lockout.state"
    let keychain: KeychainStore

    func load() -> LockoutState {
        guard let data = try? keychain.read(Self.account),
              let state = try? JSONDecoder().decode(LockoutState.self, from: data)
        else { return LockoutState() }
        return state
    }

    func save(_ state: LockoutState) {
        guard let data = try? JSONEncoder().encode(state) else { return }
        try? keychain.set(data, account: Self.account)
    }
}
