import Foundation
import Testing
@testable import SafeKeep

struct PasswordGeneratorTests {
    @Test(arguments: [12, 20, 64])
    func generatesRequestedLength(length: Int) {
        var options = PasswordGenerator.Options()
        options.length = length
        #expect(PasswordGenerator.generate(options).count == length)
    }

    @Test func clampsLengthToRange() {
        var options = PasswordGenerator.Options()
        options.length = 3
        #expect(PasswordGenerator.generate(options).count == PasswordGenerator.lengthRange.lowerBound)
    }

    @Test func includesEverySelectedCharacterSet() {
        for _ in 0..<50 {
            let password = PasswordGenerator.generate(.init())
            #expect(password.contains(where: PasswordGenerator.lowercase.contains))
            #expect(password.contains(where: PasswordGenerator.uppercase.contains))
            #expect(password.contains(where: PasswordGenerator.digits.contains))
            #expect(password.contains(where: PasswordGenerator.symbols.contains))
        }
    }

    @Test func respectsDisabledSets() {
        let options = PasswordGenerator.Options(length: 30, includeUppercase: false, includeDigits: false, includeSymbols: false)
        let password = PasswordGenerator.generate(options)
        #expect(password.allSatisfy(PasswordGenerator.lowercase.contains))
    }

    @Test func outputsAreUnique() {
        let passwords = Set((0..<200).map { _ in PasswordGenerator.generate(.init()) })
        #expect(passwords.count == 200)
    }

    @Test func generatedPasswordsRateStrong() {
        #expect(PasswordStrength.level(for: PasswordGenerator.generate(.init())) == .strong)
    }
}

struct PasswordStrengthTests {
    @Test(arguments: [
        ("", StrengthLevel.empty),
        ("password", .weak),
        ("aaaaaaaaaaaa", .weak),
        ("Summer2024", .fair),
        ("Sunflower2024", .good),
        ("Xq7!vR2#pL9$wM4@", .strong),
    ])
    func levels(password: String, expected: StrengthLevel) {
        #expect(PasswordStrength.level(for: password) == expected)
    }
}

struct PasscodeRulesTests {
    @Test(arguments: ["111111", "123456", "654321", "000000", "12345"])
    func rejectsSimpleCodes(code: String) {
        #expect(PasscodeRules.isTooSimple(code))
    }

    @Test(arguments: ["482913", "605172", "112358"])
    func acceptsReasonableCodes(code: String) {
        #expect(!PasscodeRules.isTooSimple(code))
    }
}

struct VaultAuditTests {
    @Test func flagsWeakAndReusedPasswords() {
        let accounts = [
            TestSupport.account("A", password: "password"),
            TestSupport.account("B", password: "Xq7!vR2#pL9$wM4@"),
            TestSupport.account("C", password: "Xq7!vR2#pL9$wM4@"),
            TestSupport.account("D", password: "n3w-Unique!Strong#pw"),
        ]
        let report = VaultAudit.report(for: accounts)
        #expect(report.total == 4)
        #expect(report.weak == 1)
        #expect(report.reused == 2)
        #expect(report.needsAttention == 3)
        #expect(!report.isHealthy)
    }

    @Test func websiteURLRejectsUnsafeSchemes() {
        var account = Account()
        account.website = "javascript:alert(1)"
        #expect(account.websiteURL == nil)
        account.website = "mail.google.com"
        #expect(account.websiteURL?.absoluteString == "https://mail.google.com")
    }
}
