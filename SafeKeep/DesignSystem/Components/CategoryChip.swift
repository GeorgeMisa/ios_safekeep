import SwiftUI

struct CategoryChip: View {
    let title: String
    var symbol: String?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.xs) {
                if let symbol {
                    Image(systemName: symbol).imageScale(.small)
                }
                Text(title)
            }
            .font(.subheadline.weight(.medium))
            .padding(.horizontal, Spacing.md)
            .frame(minHeight: 34)
            .foregroundStyle(isSelected ? Color.white : Color.primary)
            .background(Capsule().fill(isSelected ? AnyShapeStyle(Palette.brand) : AnyShapeStyle(Color(.secondarySystemFill))))
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

struct CategoryChipBar: View {
    @Binding var selection: AccountCategory?
    var categories: [AccountCategory] = AccountCategory.allCases

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                CategoryChip(title: "All", isSelected: selection == nil) { selection = nil }
                ForEach(categories) { category in
                    CategoryChip(title: category.title, symbol: category.symbol, isSelected: selection == category) {
                        selection = selection == category ? nil : category
                    }
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.xs)
        }
        .sensoryFeedback(.selection, trigger: selection)
    }
}
