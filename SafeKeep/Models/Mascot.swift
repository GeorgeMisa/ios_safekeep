import Foundation

enum Mascot {
    static let name = "Kip"
}

enum MascotPose: String, CaseIterable, Sendable {
    case waving, standard, proud, concerned, curled, sleepy, celebrating, key, searching, box

    var assetName: String { "Mascot/\(rawValue)" }
}
