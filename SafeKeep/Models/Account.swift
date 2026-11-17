import Foundation

struct Account: Identifiable, Codable, Hashable, Sendable {
    var id = UUID()
    var serviceName = ""
    var username = ""
    var password = ""
    var website = ""
    var notes = ""
    var brandID: String?
    var category: AccountCategory = .other
    var createdAt = Date.now
    var updatedAt = Date.now

    var websiteURL: URL? {
        let trimmed = website.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let candidate = trimmed.contains("://") ? trimmed : "https://\(trimmed)"
        guard let url = URL(string: candidate), let scheme = url.scheme?.lowercased(),
              scheme == "https" || scheme == "http", url.host() != nil
        else { return nil }
        return url
    }
}
