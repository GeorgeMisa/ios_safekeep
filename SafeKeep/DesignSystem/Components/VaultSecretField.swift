import SwiftUI

extension View {
    // Opts the field out of system Password AutoFill so iOS never offers to copy
    // vault entries into iCloud Keychain, which would defeat on-device-only storage.
    func vaultSecretField() -> some View {
        textContentType(.oneTimeCode)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .privacySensitive()
    }
}
