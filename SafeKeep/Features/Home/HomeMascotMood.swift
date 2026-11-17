import Foundation

struct HomeMascotMood: Equatable {
    let pose: MascotPose
    let message: String

    static let backupReminderInterval: TimeInterval = 30 * 24 * 60 * 60
    static let backupReminderMinimumAccounts = 3

    // Most urgent first: a fresh save, an empty vault, weak passwords, a stale backup, then a greeting.
    static func resolve(
        report: SecurityReport,
        displayName: String,
        lastExport: Date?,
        justSavedFirstAccount: Bool,
        now: Date,
        calendar: Calendar = .current
    ) -> HomeMascotMood {
        if justSavedFirstAccount {
            return HomeMascotMood(
                pose: .celebrating,
                message: "Your first login is safely stashed! 1 account, encrypted and kept only on this iPhone."
            )
        }

        if report.total == 0 {
            return HomeMascotMood(
                pose: .key,
                message: "Hi, I'm \(Mascot.name)! Your vault is empty. Add your first login and I'll encrypt it right here on this iPhone."
            )
        }

        let saved = accountsPhrase(report.total)

        if report.needsAttention > 0 {
            let fix = report.needsAttention == 1
                ? "Open it and tap Generate to swap in a strong one."
                : "Open each one and tap Generate to swap in strong ones."
            return HomeMascotMood(
                pose: .concerned,
                message: "Heads up! \(problemPhrase(weak: report.weak, reused: report.reused)) among your \(saved). \(fix)"
            )
        }

        let backupIsStale = lastExport.map { now.timeIntervalSince($0) > backupReminderInterval } ?? true
        if backupIsStale, report.total >= backupReminderMinimumAccounts {
            return HomeMascotMood(
                pose: .box,
                message: "Your \(saved) are encrypted on this iPhone with strong passwords. "
                    + (lastExport == nil
                        ? "You haven't made a backup yet, so export one in Settings."
                        : "Your last backup is over a month old, so export a fresh one in Settings.")
            )
        }

        let name = displayName.trimmingCharacters(in: .whitespaces)
        let greeting = greeting(for: now, calendar: calendar) + (name.isEmpty ? "!" : ", \(name)!")
        return HomeMascotMood(
            pose: report.total >= 5 ? .proud : .waving,
            message: "\(greeting) Your vault is protected: \(saved), strong passwords, encrypted on this iPhone."
        )
    }

    static func accountsPhrase(_ count: Int) -> String {
        "\(count) saved \(count == 1 ? "account" : "accounts")"
    }

    static func problemPhrase(weak: Int, reused: Int) -> String {
        switch (weak, reused) {
        case (0, let reused): "\(reused) reused \(reused == 1 ? "password" : "passwords")"
        case (let weak, 0): "\(weak) weak \(weak == 1 ? "password" : "passwords")"
        default: "\(weak) weak and \(reused) reused passwords"
        }
    }

    static func greeting(for date: Date, calendar: Calendar) -> String {
        switch calendar.component(.hour, from: date) {
        case 5..<12: "Good morning"
        case 12..<18: "Good afternoon"
        default: "Good evening"
        }
    }
}
