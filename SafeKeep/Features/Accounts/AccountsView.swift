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
            accountList
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

    // MARK: - Sections

    private var accountList: some View {
        List {
            if !session.accounts.isEmpty {
                filterSection
            }
            ForEach(groups, id: \.category) { group in
                categorySection(group.category, accounts: group.accounts)
            }
        }
        .listStyle(.insetGrouped)
        .listSectionSpacing(Spacing.lg)
        .contentMargins(.top, Spacing.sm, for: .scrollContent)
        .overlay { emptyState }
        .overlay(alignment: .bottomTrailing) { floatingAddButton }
    }

    private var filterSection: some View {
        Section {
            AccountsFilterBar(selection: $filter, categories: usedCategories, attentionCount: flaggedIDs.count)
        }
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.clear)
    }

    private func categorySection(_ category: AccountCategory, accounts: [Account]) -> some View {
        Section {
            ForEach(accounts) { account in
                NavigationLink(value: account.id) {
                    AccountRow(account: account)
                }
            }
        } header: {
            Label(category.title, systemImage: category.symbol)
        }
    }

    private var isAllFixed: Bool { filter == .needsAttention && query.isEmpty }

    @ViewBuilder
    private var emptyState: some View {
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
                pose: isAllFixed ? .proud : .searching,
                title: isAllFixed ? "Nothing to fix" : "No matches",
                message: isAllFixed
                    ? "Every password is strong and unique. Nice work!"
                    : "Try a different name, username or website, or pick another filter."
            )
        }
    }

    @ViewBuilder
    private var floatingAddButton: some View {
        if !session.accounts.isEmpty {
            AddAccountButton { isAdding = true }
                .padding(.trailing, Spacing.lg)
                .padding(.bottom, Spacing.lg)
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
