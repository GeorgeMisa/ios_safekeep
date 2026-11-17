import Foundation
import UIKit
import Testing
@testable import SafeKeep

struct HomeMascotMoodTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    private func date(hour: Int) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 11, day: 17, hour: hour))!
    }

    private func report(total: Int, weak: Int = 0, reused: Int = 0) -> SecurityReport {
        SecurityReport(total: total, weak: weak, reused: reused, needsAttention: weak + reused)
    }

    private func mood(_ report: SecurityReport, lastExport: Date? = nil, firstSave: Bool = false, hour: Int = 9, name: String = "") -> HomeMascotMood {
        HomeMascotMood.resolve(
            report: report, displayName: name, lastExport: lastExport,
            justSavedFirstAccount: firstSave, now: date(hour: hour), calendar: calendar
        )
    }

    @Test func emptyVaultHoldsTheKey() {
        #expect(mood(report(total: 0)).pose == .key)
    }

    @Test func firstSaveCelebratesOverEverything() {
        #expect(mood(report(total: 1, weak: 1), firstSave: true).pose == .celebrating)
    }

    @Test func weakPasswordsMakeKipConcerned() {
        let result = mood(report(total: 4, weak: 1, reused: 2))
        #expect(result.pose == .concerned)
        #expect(result.message.hasPrefix("Heads up! 1 weak and 2 reused passwords among your 4 saved accounts."))
    }

    @Test func staleBackupAsksForExport() {
        let old = date(hour: 9).addingTimeInterval(-40 * 24 * 60 * 60)
        #expect(mood(report(total: 3), lastExport: old).pose == .box)
        #expect(mood(report(total: 3)).pose == .box)
    }

    @Test func smallVaultSkipsBackupNag() {
        #expect(mood(report(total: 2)).pose == .waving)
    }

    @Test func recentBackupGreetsByTimeAndName() {
        let recent = date(hour: 20).addingTimeInterval(-24 * 60 * 60)
        let result = mood(report(total: 6), lastExport: recent, hour: 20, name: "Alex")
        #expect(result.pose == .proud)
        #expect(result.message.hasPrefix("Good evening, Alex!"))
    }

    @Test func singleProblemsUseSingularWording() {
        #expect(HomeMascotMood.problemPhrase(weak: 1, reused: 0) == "1 weak password")
        #expect(HomeMascotMood.problemPhrase(weak: 0, reused: 2) == "2 reused passwords")
        #expect(mood(report(total: 2, weak: 1)).message.contains("Open it and tap Generate"))
    }

    @Test func healthyMessageCarriesTheStatus() {
        let recent = date(hour: 9).addingTimeInterval(-24 * 60 * 60)
        let message = mood(report(total: 1), lastExport: recent).message
        #expect(message.contains("Your vault is protected: 1 saved account"))
        #expect(message.contains("encrypted on this iPhone"))
    }

    @Test(arguments: [(6, "Good morning"), (13, "Good afternoon"), (2, "Good evening")])
    func greetings(hour: Int, expected: String) {
        #expect(HomeMascotMood.greeting(for: date(hour: hour), calendar: calendar) == expected)
    }

    @Test func everyPoseHasAnAsset() {
        let bundle = Bundle.main
        for pose in MascotPose.allCases {
            #expect(UIImage(named: pose.assetName, in: bundle, compatibleWith: nil) != nil, "\(pose)")
        }
    }
}

