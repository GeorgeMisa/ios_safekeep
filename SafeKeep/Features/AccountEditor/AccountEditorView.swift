import SwiftUI

struct AccountEditorView: View {
    private enum Field: Int, Hashable, CaseIterable {
        case service, username, password, website, notes

        var previous: Field? { Field(rawValue: rawValue - 1) }
        var next: Field? { Field(rawValue: rawValue + 1) }
    }

    @Environment(VaultSession.self) private var session
    @Environment(\.dismiss) private var dismiss
    @State private var draft: Account
    @State private var isPasswordVisible = false
    @State private var isPickingIcon = false
    @State private var isConfirmingDiscard = false
    @State private var generatorOptions = PasswordGenerator.Options()
    @State private var errorMessage: String?
    @FocusState private var focus: Field?

    private let original: Account
    private let isNew: Bool

    init(existing: Account? = nil) {
        let account = existing ?? Account()
        _draft = State(initialValue: account)
        original = account
        isNew = existing == nil
    }

    private var brand: BrandIcon? { BrandCatalog.shared.brand(id: draft.brandID) }
    private var hasChanges: Bool { draft != original }
    private var canSave: Bool { !draft.serviceName.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                Form {
                    iconSection
                    serviceSection
                    loginSection
                    generatorSection
                    Section("Website") {
                        TextField("example.com", text: $draft.website)
                            .keyboardType(.URL)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .focused($focus, equals: .website)
                            .submitLabel(.next)
                            .onSubmit { focus = .notes }
                            .id(Field.website)
                    }
                    Section("Notes") {
                        TextField("Add a note", text: $draft.notes, axis: .vertical)
                            .lineLimit(3...8)
                            .autocorrectionDisabled()
                            .privacySensitive()
                            .focused($focus, equals: .notes)
                            .id(Field.notes)
                    }
                }
                .contentMargins(.bottom, Spacing.xl, for: .scrollContent)
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: focus) { _, field in reveal(field, with: proxy) }
                .onChange(of: draft.notes) { if focus == .notes { reveal(.notes, with: proxy) } }
            }
            .navigationTitle(isNew ? "Add Account" : "Edit Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Button("Previous Field", systemImage: "chevron.up") { focus = focus?.previous }
                        .disabled(focus?.previous == nil)
                    Button("Next Field", systemImage: "chevron.down") { focus = focus?.next }
                        .disabled(focus?.next == nil)
                    Spacer()
                    Button("Done") { focus = nil }
                        .fontWeight(.semibold)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if hasChanges { isConfirmingDiscard = true } else { dismiss() }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .fontWeight(.semibold)
                        .disabled(!canSave)
                }
            }
            .sheet(isPresented: $isPickingIcon) {
                IconPickerView(selectedID: draft.brandID, onSelect: apply)
            }
            .confirmationDialog("Discard changes?", isPresented: $isConfirmingDiscard, titleVisibility: .visible) {
                Button("Discard Changes", role: .destructive) { dismiss() }
                Button("Keep Editing", role: .cancel) {}
            }
            .alert("Couldn't Save", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
            .task {
                guard isNew else { return }
                try? await Task.sleep(for: .milliseconds(450))
                focus = .service
            }
        }
        .interactiveDismissDisabled(hasChanges)
    }

    // MARK: - Sections

    private var iconSection: some View {
        Section {
            Button {
                isPickingIcon = true
            } label: {
                VStack(spacing: Spacing.sm) {
                    BrandIconView(
                        brandID: draft.brandID,
                        name: draft.serviceName.isEmpty ? "?" : draft.serviceName,
                        category: draft.category,
                        size: 72
                    )
                    Text(brand == nil ? "Choose Icon" : "Change Icon")
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(.tint)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(brand.map { "Icon: \($0.name). Change icon" } ?? "Choose icon")
        }
        .listRowBackground(Color.clear)
    }

    private var serviceSection: some View {
        Section("Service") {
            TextField("Service name", text: $draft.serviceName)
                .textInputAutocapitalization(.words)
                .focused($focus, equals: .service)
                .id(Field.service)
                .submitLabel(.next)
                .onSubmit { focus = .username }
            Picker("Category", selection: $draft.category) {
                ForEach(AccountCategory.allCases) { category in
                    Label(category.title, systemImage: category.symbol).tag(category)
                }
            }
        }
    }

    private var loginSection: some View {
        Section("Login") {
            TextField("Username or email", text: $draft.username)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .vaultSecretField()
                .focused($focus, equals: .username)
                .id(Field.username)
                .submitLabel(.next)
                .onSubmit { focus = .password }

            HStack {
                Group {
                    if isPasswordVisible {
                        TextField("Password", text: $draft.password)
                            .font(.body.monospaced())
                    } else {
                        SecureField("Password", text: $draft.password)
                    }
                }
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .vaultSecretField()
                .focused($focus, equals: .password)
                .submitLabel(.next)
                .onSubmit { focus = .website }

                Button {
                    isPasswordVisible.toggle()
                } label: {
                    Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.borderless)
                .accessibilityLabel(isPasswordVisible ? "Hide password" : "Show password")
            }

            StrengthMeter(password: draft.password)
                .padding(.vertical, Spacing.xs)
                .id(Field.password)
        }
    }

    private var generatorSection: some View {
        Section {
            Button {
                draft.password = PasswordGenerator.generate(generatorOptions)
                isPasswordVisible = true
            } label: {
                Label("Generate Strong Password", systemImage: "wand.and.stars")
            }
            .sensoryFeedback(.impact(weight: .light), trigger: draft.password)

            DisclosureGroup("Options") {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    LabeledContent("Length", value: "\(generatorOptions.length)")
                    Slider(
                        value: Binding(
                            get: { Double(generatorOptions.length) },
                            set: { generatorOptions.length = Int($0) }
                        ),
                        in: Double(PasswordGenerator.lengthRange.lowerBound)...Double(PasswordGenerator.lengthRange.upperBound),
                        step: 1
                    )
                    .accessibilityLabel("Password length")
                }
                Toggle("Uppercase Letters", isOn: $generatorOptions.includeUppercase)
                Toggle("Numbers", isOn: $generatorOptions.includeDigits)
                Toggle("Symbols", isOn: $generatorOptions.includeSymbols)
            }
        } header: {
            Text("Password Generator")
        }
    }

    // MARK: - Actions

    // Waits for the keyboard animation, then centers the field in the space left above the keyboard
    // and its floating toolbar, so a growing field never slides underneath.
    private func reveal(_ field: Field?, with proxy: ScrollViewProxy) {
        guard let field else { return }
        Task {
            try? await Task.sleep(for: .milliseconds(300))
            withAnimation(.snappy) { proxy.scrollTo(field, anchor: .center) }
        }
    }

    private func apply(_ brand: BrandIcon?) {
        draft.brandID = brand?.id
        guard let brand else { return }
        if draft.serviceName.trimmingCharacters(in: .whitespaces).isEmpty { draft.serviceName = brand.name }
        draft.category = brand.category
        if draft.website.isEmpty, let website = brand.website { draft.website = website }
    }

    private func save() {
        var account = draft
        account.serviceName = account.serviceName.trimmingCharacters(in: .whitespacesAndNewlines)
        account.username = account.username.trimmingCharacters(in: .whitespacesAndNewlines)
        account.website = account.website.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            try session.save(account)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
