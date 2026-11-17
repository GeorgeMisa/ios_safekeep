import Foundation

struct AutoLockMonitor {
    private(set) var backgroundedAt: TimeInterval?

    // System uptime is used instead of wall-clock time so changing the clock can't skip the timeout.
    mutating func didEnterBackground(uptime: TimeInterval = ProcessInfo.processInfo.systemUptime) {
        backgroundedAt = uptime
    }

    mutating func shouldLockOnReturn(
        option: AutoLockOption,
        uptime: TimeInterval = ProcessInfo.processInfo.systemUptime
    ) -> Bool {
        defer { backgroundedAt = nil }
        guard let backgroundedAt else { return false }
        return uptime - backgroundedAt >= option.seconds
    }
}
