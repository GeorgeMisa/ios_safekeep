import SwiftUI

enum AccountsFilter: Hashable {
    case all
    case needsAttention
    case category(AccountCategory)
}

struct AccountsView: View {
    @Environment(VaultSession.self) private var session
    @State private var query = ""
    @State private var filter = AccountsFilter.all
    @State private var isAdding = false

    private var flaggedIDs: Set<Account.ID> { VaultAudit.needsAttention(session.accounts) }

    private var groups: [(category: AccountCategory, accounts: [Account])] {
        let flagged = flaggedIDs
        let matches = AccountSearch.filter(session.accounts, query: query).filter { account in
            switch filter {
            case .all: true
            case .needsAttention: flagged.contains(account.id)
            case .category(let category): account.category == category
            }
        }
        let grouped = Dictionary(grouping: matches, by: \.category)
        return AccountCategory.allCases.compactMap { key in
            grouped[key].map { (key, $0) }
        }
    }

    private var usedCategories: [AccountCategory] {
        let used = Set(session.accounts.map(\.category))
        return AccountCategory.allCases.filter(used.contains)
    }

    var body: some View {
        NavigationStack {
            List {
                if !session.accounts.isEmpty {
                    Section {
                        AccountsFilterBar(
                            selection: $filter,
                            categories: usedCategories,
                            attentionCount: flaggedIDs.count
                        )
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }

                ForEach(groups, id: \.category) { group in
                    Section {
                        ForEach(group.accounts) { account in
                            NavigationLink(value: account.id) {
                                AccountRow(account: account)
                            }
                        }
                    } header: {
                        Label(group.category.title, systemImage: group.category.symbol)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .listSectionSpacing(Spacing.lg)
            .contentMargins(.top, Spacing.sm, for: .scrollContent)
            .overlay {
                if session.accounts.isEmpty {
                    MascotEmptyState(
                        pose: .key,
                        title: "Nothing stashed yet",
                        message: "Accounts you save show up here, grouped by the icon you pick."
                    ) {
                        Button("Add Account") { isAdding = true }
                            .buttonStyle(.borderedProminent)
                    }
                } else if groups.isEmpty {
                    MascotEmptyState(
                        pose: filter == .needsAttention && query.isEmpty ? .proud : .searching,
                        title: filter == .needsAttention && query.isEmpty ? "Nothing to fix" : "No matches",
                        message: filter == .needsAttention && query.isEmpty
                            ? "Every password is strong and unique. Nice work!"
                            : "Try a different name, username or website, or pick another filter."
                    )
                }
            }
            .overlay(alignment: .bottomTrailing) {
                if !session.accounts.isEmpty {
                    AddAccountButton { isAdding = true }
                        .padding(.trailing, Spacing.lg)
                        .padding(.bottom, Spacing.lg)
                }
            }
            .navigationTitle("Accounts")
            .toolbarTitleDisplayMode(.inlineLarge)
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search accounts")
            .navigationDestination(for: Account.ID.self) { id in
                AccountDetailView(accountID: id)
            }
            .sheet(isPresented: $isAdding) {
                AccountEditorView()
            }
            .onChange(of: usedCategories) { _, used in
                if case .category(let category) = filter, !used.contains(category) { filter = .all }
            }
        }
    }
}

private struct AccountsFilterBar: View {
    @Binding var selection: AccountsFilter
    let categories: [AccountCategory]
    let attentionCount: Int

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                chip("All", symbol: nil, value: .all)
                if attentionCount > 0 || selection == .needsAttention {
                    chip("Needs Attention (\(attentionCount))", symbol: "exclamationmark.shield.fill", value: .needsAttention)
                }
                ForEach(categories) { category in
                    chip(category.title, symbol: category.symbol, value: .category(category))
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.xs)
        }
        .sensoryFeedback(.selection, trigger: selection)
    }

    private func chip(_ title: String, symbol: String?, value: AccountsFilter) -> some View {
        CategoryChip(title: title, symbol: symbol, isSelected: selection == value) {
            selection = selection == value && value != .all ? .all : value
        }
    }
}
