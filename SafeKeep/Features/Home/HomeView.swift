import SwiftUI

struct HomeView: View {
    @Environment(VaultSession.self) private var session
    @AppStorage(PreferenceKey.lastExport) private var lastExport: Double = 0
    @State private var isAdding = false
    @State private var celebratesFirstSave = false

    private var mood: HomeMascotMood {
        HomeMascotMood.resolve(
            report: session.securityReport,
            displayName: session.payload.displayName,
            lastExport: lastExport > 0 ? Date(timeIntervalSince1970: lastExport) : nil,
            justSavedFirstAccount: celebratesFirstSave,
            now: .now
        )
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    MascotHeader(pose: mood.pose, message: mood.message)
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)

                if session.accounts.isEmpty {
                    Section {
                        Button {
                            isAdding = true
                        } label: {
                            Label("Add Your First Account", systemImage: "plus.circle.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity, minHeight: 34)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                } else {
                    Section {
                        ForEach(session.accounts) { account in
                            NavigationLink(value: account.id) {
                                AccountRow(account: account)
                            }
                        }
                    } header: {
                        HStack {
                            Text("Your Accounts")
                            Spacer()
                            Text("\(session.accounts.count)")
                                .monospacedDigit()
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .listSectionSpacing(Spacing.lg)
            .contentMargins(.top, Spacing.sm, for: .scrollContent)
            .overlay(alignment: .bottomTrailing) {
                if !session.accounts.isEmpty {
                    AddAccountButton { isAdding = true }
                        .padding(.trailing, Spacing.lg)
                        .padding(.bottom, Spacing.lg)
                }
            }
            .navigationTitle("SafeKeep")
            .toolbarTitleDisplayMode(.inlineLarge)
            .navigationDestination(for: Account.ID.self) { id in
                AccountDetailView(accountID: id)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Lock SafeKeep", systemImage: "lock.fill") { session.lock(userInitiated: true) }
                }
            }
            .sheet(isPresented: $isAdding) {
                AccountEditorView()
            }
            .onChange(of: session.payload.accounts.count) { old, new in
                celebratesFirstSave = old == 0 && new == 1
            }
        }
    }
}
