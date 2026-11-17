import Foundation

struct BrandIcon: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let name: String
    let hex: String
    let category: AccountCategory
    let keywords: [String]
    let website: String?
    let hasGlyph: Bool
    let fullColor: Bool

    var assetName: String { "BrandIcons/\(id)" }
}

struct BrandCatalog: Sendable {
    static let shared = BrandCatalog(bundle: .main)

    let brands: [BrandIcon]
    private let index: [String: BrandIcon]

    init(brands: [BrandIcon]) {
        self.brands = brands.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        self.index = Dictionary(brands.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
    }

    init(bundle: Bundle) {
        guard let url = bundle.url(forResource: "BrandCatalog", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let brands = try? JSONDecoder().decode([BrandIcon].self, from: data)
        else {
            self.init(brands: [])
            return
        }
        self.init(brands: brands)
    }

    func brand(id: String?) -> BrandIcon? {
        guard let id else { return nil }
        return index[id]
    }

    func search(_ query: String, category: AccountCategory?) -> [BrandIcon] {
        let needle = query.trimmingCharacters(in: .whitespaces).lowercased()
        return brands.filter { brand in
            (category == nil || brand.category == category)
                && (needle.isEmpty
                    || brand.name.lowercased().contains(needle)
                    || brand.keywords.contains { $0.lowercased().contains(needle) })
        }
    }
}
