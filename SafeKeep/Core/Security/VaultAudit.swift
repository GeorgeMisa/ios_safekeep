import Foundation

struct SecurityReport: Equatable, Sendable {
    let total: Int
    let weak: Int
    let reused: Int
    let needsAttention: Int

    var isHealthy: Bool { needsAttention == 0 }
}

enum VaultAudit {
    static func report(for accounts: [Account]) -> SecurityReport {
        let (weakIDs, reusedIDs) = flagged(accounts)
        return SecurityReport(
            total: accounts.count,
            weak: weakIDs.count,
            reused: reusedIDs.count,
            needsAttention: weakIDs.union(reusedIDs).count
        )
    }

    static func needsAttention(_ accounts: [Account]) -> Set<Account.ID> {
        let (weakIDs, reusedIDs) = flagged(accounts)
        return weakIDs.union(reusedIDs)
    }

    private static func flagged(_ accounts: [Account]) -> (weak: Set<Account.ID>, reused: Set<Account.ID>) {
        let withPasswords = accounts.filter { !$0.password.isEmpty }
        let weak = Set(withPasswords.filter { PasswordStrength.level(for: $0.password) <= .fair }.map(\.id))
        let reused = Set(Dictionary(grouping: withPasswords, by: \.password).values.filter { $0.count > 1 }.flatMap { $0.map(\.id) })
        return (weak, reused)
    }
}
