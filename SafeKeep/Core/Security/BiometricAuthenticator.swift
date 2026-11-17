import LocalAuthentication

enum BiometricKind: Sendable {
    case none, faceID, touchID, opticID

    var title: String {
        switch self {
        case .none: "Biometrics"
        case .faceID: "Face ID"
        case .touchID: "Touch ID"
        case .opticID: "Optic ID"
        }
    }

    var symbol: String {
        switch self {
        case .none: "lock"
        case .faceID: "faceid"
        case .touchID: "touchid"
        case .opticID: "opticid"
        }
    }
}

enum BiometricAuthenticator {
    static var hardwareKind: BiometricKind {
        let context = LAContext()
        var error: NSError?
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        return kind(for: context.biometryType)
    }

    static var isAvailable: Bool {
        var error: NSError?
        return LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    private static func kind(for type: LABiometryType) -> BiometricKind {
        switch type {
        case .faceID: .faceID
        case .touchID: .touchID
        case .opticID: .opticID
        default: .none
        }
    }
}
