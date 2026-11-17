import Foundation

enum PreferenceKey {
    static let appearance = "pref.appearance"
    static let autoLock = "pref.autoLock"
    static let lastExport = "pref.lastExport"
}

enum AppearanceOption: String, CaseIterable, Identifiable {
    case system, light, dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }
}

enum AutoLockOption: String, CaseIterable, Identifiable {
    case immediately, oneMinute, fiveMinutes

    var id: String { rawValue }

    var title: String {
        switch self {
        case .immediately: "Immediately"
        case .oneMinute: "After 1 Minute"
        case .fiveMinutes: "After 5 Minutes"
        }
    }

    var seconds: TimeInterval {
        switch self {
        case .immediately: 0
        case .oneMinute: 60
        case .fiveMinutes: 300
        }
    }
}
