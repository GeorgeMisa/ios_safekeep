import Foundation
import Testing
@testable import SafeKeep

struct LockoutPolicyTests {
    private let start = Date(timeIntervalSince1970: 1_800_000_000)

    private func state(failures: Int, at date: Date) -> LockoutState {
        LockoutState(failedAttempts: failures, lastFailureAt: date)
    }

    @Test func firstFiveFailuresHaveNoDelay() {
        for failures in 1...5 {
            #expect(LockoutPolicy.remainingLockout(for: state(failures: failures, at: start), at: start) == 0)
        }
    }

    @Test(arguments: [(6, 60.0), (7, 300.0), (8, 900.0), (9, 3600.0), (15, 3600.0)])
    func escalatingSchedule(failures: Int, expected: TimeInterval) {
        #expect(LockoutPolicy.delay(forFailures: failures) == expected)
        #expect(LockoutPolicy.remainingLockout(for: state(failures: failures, at: start), at: start) == expected)
    }

    @Test func remainingCountsDown() {
        let locked = state(failures: 6, at: start)
        #expect(LockoutPolicy.remainingLockout(for: locked, at: start.addingTimeInterval(45)) == 15)
        #expect(LockoutPolicy.remainingLockout(for: locked, at: start.addingTimeInterval(61)) == 0)
    }

    @Test func clockMovedBackwardsStaysLocked() {
        let locked = state(failures: 7, at: start)
        #expect(LockoutPolicy.remainingLockout(for: locked, at: start.addingTimeInterval(-86_400)) == 300)
    }

    @Test func registeringFailureIncrements() {
        let next = LockoutPolicy.registeringFailure(LockoutState(), at: start)
        #expect(next.failedAttempts == 1)
        #expect(next.lastFailureAt == start)
        #expect(LockoutPolicy.attemptsBeforeLockout(next) == 4)
    }

    @Test func persistsInKeychain() {
        let keychain = TestSupport.keychain()
        defer { keychain.deleteAll() }
        let store = LockoutStore(keychain: keychain)
        let saved = state(failures: 6, at: start)
        store.save(saved)
        #expect(store.load() == saved)
    }
}

struct AutoLockMonitorTests {
    @Test func locksAfterTimeout() {
        var monitor = AutoLockMonitor()
        monitor.didEnterBackground(uptime: 100)
        let shouldLock = monitor.shouldLockOnReturn(option: .oneMinute, uptime: 161)
        #expect(shouldLock)
    }

    @Test func staysUnlockedWithinTimeout() {
        var monitor = AutoLockMonitor()
        monitor.didEnterBackground(uptime: 100)
        let shouldLock = monitor.shouldLockOnReturn(option: .fiveMinutes, uptime: 200)
        #expect(!shouldLock)
    }

    @Test func immediateAlwaysLocks() {
        var monitor = AutoLockMonitor()
        monitor.didEnterBackground(uptime: 100)
        let shouldLock = monitor.shouldLockOnReturn(option: .immediately, uptime: 100)
        #expect(shouldLock)
    }
}
