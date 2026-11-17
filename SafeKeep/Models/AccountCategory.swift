import Foundation

enum AccountCategory: String, Codable, CaseIterable, Identifiable, Sendable {
    case email, social, entertainment, finance, shopping, work, developer, gaming, other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .email: "Email"
        case .social: "Social"
        case .entertainment: "Entertainment"
        case .finance: "Finance"
        case .shopping: "Shopping"
        case .work: "Work"
        case .developer: "Developer"
        case .gaming: "Gaming"
        case .other: "Other"
        }
    }

    var symbol: String {
        switch self {
        case .email: "envelope.fill"
        case .social: "person.2.fill"
        case .entertainment: "play.tv.fill"
        case .finance: "creditcard.fill"
        case .shopping: "bag.fill"
        case .work: "briefcase.fill"
        case .developer: "chevron.left.forwardslash.chevron.right"
        case .gaming: "gamecontroller.fill"
        case .other: "square.grid.2x2.fill"
        }
    }
}
