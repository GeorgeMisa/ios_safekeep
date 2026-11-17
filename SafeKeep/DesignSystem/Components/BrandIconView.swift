import SwiftUI

struct BrandIconView: View {
    let brandID: String?
    let name: String
    let category: AccountCategory
    var size: CGFloat = 36

    private var brand: BrandIcon? { BrandCatalog.shared.brand(id: brandID) }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: size * 0.26, style: .continuous)
        ZStack {
            if let brand, brand.fullColor {
                shape.fill(.white)
                Image(brand.assetName)
                    .renderingMode(.original)
                    .resizable()
                    .scaledToFit()
                    .padding(size * 0.2)
            } else if let brand {
                shape.fill(brandColor(brand))
                if brand.hasGlyph {
                    Image(brand.assetName)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(glyphColor(brand))
                        .padding(size * 0.22)
                } else {
                    monogramText(for: brand.name, color: glyphColor(brand))
                }
            } else {
                shape.fill(category.tint.gradient)
                monogramText(for: name, color: .white)
            }
        }
        .frame(width: size, height: size)
        .overlay(shape.strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.5))
        .accessibilityHidden(true)
    }

    private func monogramText(for text: String, color: Color) -> some View {
        Text(text.trimmingCharacters(in: .whitespaces).first.map { String($0).uppercased() } ?? "?")
            .font(.system(size: size * 0.44, weight: .semibold, design: .rounded))
            .foregroundStyle(color)
    }

    private func brandColor(_ brand: BrandIcon) -> Color {
        Color(hexString: brand.hex) ?? category.tint
    }

    private func glyphColor(_ brand: BrandIcon) -> Color {
        guard let value = UInt32(brand.hex, radix: 16) else { return .white }
        let red = Double((value >> 16) & 0xFF) / 255
        let green = Double((value >> 8) & 0xFF) / 255
        let blue = Double(value & 0xFF) / 255
        let luminance = 0.2126 * red + 0.7152 * green + 0.0722 * blue
        return luminance > 0.62 ? .black.opacity(0.85) : .white
    }
}
