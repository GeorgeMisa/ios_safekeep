import SwiftUI

struct IconPickerView: View {
    let selectedID: String?
    let onSelect: (BrandIcon?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var category: AccountCategory?

    private let columns = [GridItem(.adaptive(minimum: 76), spacing: Spacing.md)]

    private var results: [BrandIcon] {
        BrandCatalog.shared.search(query, category: category)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    CategoryChipBar(selection: $category)
                        .padding(.horizontal, -Spacing.lg)

                    if results.isEmpty {
                        MascotEmptyState(
                            pose: .searching,
                            title: "No matching icons",
                            message: "Pick “No Icon” and I'll make a colored letter tile instead."
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.top, Spacing.xl)
                    } else {
                        LazyVGrid(columns: columns, spacing: Spacing.lg) {
                            ForEach(results) { brand in
                                cell(for: brand)
                            }
                        }
                    }
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.xl)
            }
            .navigationTitle("Choose Icon")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search apps and services")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("No Icon") {
                        onSelect(nil)
                        dismiss()
                    }
                }
            }
        }
    }

    private func cell(for brand: BrandIcon) -> some View {
        let isSelected = brand.id == selectedID
        return Button {
            onSelect(brand)
            dismiss()
        } label: {
            VStack(spacing: Spacing.sm) {
                BrandIconView(brandID: brand.id, name: brand.name, category: brand.category, size: 56)
                    .overlay {
                        if isSelected {
                            RoundedRectangle(cornerRadius: 56 * 0.26 + 4, style: .continuous)
                                .strokeBorder(Palette.brand, lineWidth: 2.5)
                                .padding(-4)
                        }
                    }
                Text(brand.name)
                    .font(.caption)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(brand.name)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
