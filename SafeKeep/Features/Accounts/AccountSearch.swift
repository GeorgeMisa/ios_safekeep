import Foundation

enum AccountSearch {
    static func filter(_ accounts: [Account], query: String) -> [Account] {
        let needle = query.trimmingCharacters(in: .whitespaces)
        guard !needle.isEmpty else { return accounts }
        return accounts.filter {
            $0.serviceName.localizedCaseInsensitiveContains(needle)
                || $0.username.localizedCaseInsensitiveContains(needle)
                || $0.website.localizedCaseInsensitiveContains(needle)
        }
    }
}
