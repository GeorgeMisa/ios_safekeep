import SwiftUI

struct SettingsIcon: View {
    let symbol: String
    let color: Color

    var body: some View {
        RoundedRectangle(cornerRadius: 7, style: .continuous)
            .fill(color.gradient)
            .frame(width: 29, height: 29)
            .overlay {
                Image(systemName: symbol)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .accessibilityHidden(true)
    }
}

struct SettingsRowLabel: View {
    let title: String
    let symbol: String
    let color: Color
    var value: String?
    var showsChevron = false

    var body: some View {
        HStack(spacing: Spacing.md) {
            SettingsIcon(symbol: symbol, color: color)
            Text(title)
                .foregroundStyle(.primary)
            Spacer()
            if let value {
                Text(value).foregroundStyle(.secondary)
            }
            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
        }
        .contentShape(Rectangle())
    }
}
