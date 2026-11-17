import SwiftUI

struct AccountRow: View {
    let account: Account

    var body: some View {
        HStack(spacing: Spacing.md) {
            BrandIconView(brandID: account.brandID, name: account.serviceName, category: account.category, size: 38)
            VStack(alignment: .leading, spacing: 2) {
                Text(account.serviceName)
                    .font(.body.weight(.medium))
                    .lineLimit(1)
                if !account.username.isEmpty {
                    Text(account.username)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
    }
}
