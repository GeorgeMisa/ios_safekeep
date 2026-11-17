import SwiftUI

struct StrengthMeter: View {
    let password: String

    private var level: StrengthLevel { PasswordStrength.level(for: password) }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.xs) {
                ForEach(1...4, id: \.self) { segment in
                    Capsule()
                        .fill(segment <= level.rawValue ? level.color : Color(.systemFill))
                        .frame(height: 4)
                }
            }
            HStack {
                Text(level == .empty ? "Password strength" : level.title)
                    .foregroundStyle(level == .empty ? .secondary : level.color)
                    .fontWeight(.medium)
                Spacer()
                if !password.isEmpty {
                    Text("\(password.count) characters")
                        .foregroundStyle(.secondary)
                }
            }
            .font(.caption)
        }
        .animation(.snappy, value: level)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Password strength")
        .accessibilityValue(level == .empty ? "No password" : level.title)
    }
}
