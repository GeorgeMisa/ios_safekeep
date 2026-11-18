import SwiftUI
import UniformTypeIdentifiers

struct BackupView: View {
    @Environment(VaultSession.self) private var session
    @AppStorage(PreferenceKey.lastExport) private var lastExport: Double = 0

    @State private var isVerifyingExport = false
    @State private var exportVerified = false
    @State private var isChoosingExportPassword = false
    @State private var exportDocument: BackupDocument?
    @State private var isExporting = false

    @State private var isImporting = false
    @State private var importData: Data?
    @State private var isEnteringImportPassword = false

    @State private var alert: AlertContent?

    var body: some View {
        backupList
            .navigationTitle("Backup & Restore")
            .navigationBarTitleDisplayMode(.inline)
            .modifier(exportFlow)
            .modifier(importFlow)
            .alert(alert?.title ?? "", isPresented: .constant(alert != nil)) {
                Button("OK") { alert = nil }
            } message: {
                Text(alert?.message ?? "")
            }
    }

    // MARK: - Sections

    private var backupList: some View {
        List {
            Section {
                MascotHeader(
                    pose: .box,
                    message: "I'll pack your vault into one encrypted file. Keep it somewhere safe, like Files or another device."
                )
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)

            exportSection
            importSection
            if lastExport > 0 {
                Section {
                    LabeledContent("Last Export", value: lastExportText)
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private var exportSection: some View {
        Section {
            Button {
                exportVerified = false
                isVerifyingExport = true
            } label: {
                SettingsRowLabel(title: "Export Encrypted Backup", symbol: "square.and.arrow.up", color: .blue)
            }
            .tint(.primary)
            .disabled(session.payload.accounts.isEmpty)
        } footer: {
            Text("Creates a .safekeep file locked with a separate backup password. Save it to Files or another device you trust.")
        }
    }

    private var importSection: some View {
        Section {
            Button {
                isImporting = true
            } label: {
                SettingsRowLabel(title: "Import Backup", symbol: "square.and.arrow.down", color: .teal)
            }
            .tint(.primary)
        } footer: {
            Text("Accounts already in your vault are skipped, so importing twice is safe.")
        }
    }

    private var lastExportText: String {
        Date(timeIntervalSince1970: lastExport).formatted(date: .abbreviated, time: .shortened)
    }

    private var defaultFilename: String {
        "SafeKeep Backup \(Date.now.formatted(.iso8601.year().month().day()))"
    }

    // MARK: - Flows

    private var exportFlow: ExportFlow {
        ExportFlow(
            isVerifying: $isVerifyingExport,
            verified: $exportVerified,
            isChoosingPassword: $isChoosingExportPassword,
            document: $exportDocument,
            isExporting: $isExporting,
            filename: defaultFilename,
            makeBackup: { password in try await session.exportBackup(password: password) },
            onResult: handleExport
        )
    }

    private var importFlow: ImportFlow {
        ImportFlow(
            isImporting: $isImporting,
            isEnteringPassword: $isEnteringImportPassword,
            importData: $importData,
            onPicked: handleImport,
            onPassword: importBackup
        )
    }

    private func handleExport(_ result: Result<URL, any Error>) {
        exportDocument = nil
        switch result {
        case .success:
            lastExport = Date.now.timeIntervalSince1970
            alert = AlertContent(title: "Backup Exported", message: "Keep your backup password somewhere safe. SafeKeep can't recover it.")
        case .failure(let error):
            alert = AlertContent(title: "Export Failed", message: error.localizedDescription)
        }
    }

    private func importBackup(password: String) async throws {
        guard let importData else { return }
        let summary = try await session.importBackup(importData, password: password)
        let added = "Added \(summary.added) \(summary.added == 1 ? "account" : "accounts")"
        let skipped = summary.skipped > 0 ? ", skipped \(summary.skipped) already in your vault." : "."
        alert = AlertContent(title: "Backup Imported", message: added + skipped)
    }

    private func handleImport(_ result: Result<URL, any Error>) {
        do {
            let url = try result.get()
            let isScoped = url.startAccessingSecurityScopedResource()
            defer { if isScoped { url.stopAccessingSecurityScopedResource() } }
            let size = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
            guard size <= BackupService.maximumFileSize else { throw BackupError.invalidFile }
            importData = try Data(contentsOf: url)
            isEnteringImportPassword = true
        } catch {
            alert = AlertContent(title: "Import Failed", message: (error as? BackupError)?.errorDescription ?? "That file couldn't be read.")
        }
    }
}

private struct AlertContent {
    let title: String
    let message: String
}

// MARK: - Presentation flows

private struct ExportFlow: ViewModifier {
    @Binding var isVerifying: Bool
    @Binding var verified: Bool
    @Binding var isChoosingPassword: Bool
    @Binding var document: BackupDocument?
    @Binding var isExporting: Bool
    let filename: String
    let makeBackup: (String) async throws -> Data
    let onResult: (Result<URL, any Error>) -> Void

    func body(content: Content) -> some View {
        content
            .fullScreenCover(isPresented: $isVerifying, onDismiss: {
                if verified { isChoosingPassword = true }
            }) {
                PasscodeVerifyView(heading: "Enter your passcode to export", pose: .box) {
                    verified = true
                }
            }
            .sheet(isPresented: $isChoosingPassword, onDismiss: {
                if document != nil { isExporting = true }
            }) {
                BackupPasswordSheet(mode: .export) { password in
                    document = BackupDocument(data: try await makeBackup(password))
                }
            }
            .fileExporter(
                isPresented: $isExporting,
                document: document,
                contentType: .safekeepBackup,
                defaultFilename: filename,
                onCompletion: onResult
            )
    }
}

private struct ImportFlow: ViewModifier {
    @Binding var isImporting: Bool
    @Binding var isEnteringPassword: Bool
    @Binding var importData: Data?
    let onPicked: (Result<URL, any Error>) -> Void
    let onPassword: (String) async throws -> Void

    func body(content: Content) -> some View {
        content
            .fileImporter(isPresented: $isImporting, allowedContentTypes: [.safekeepBackup], onCompletion: onPicked)
            .sheet(isPresented: $isEnteringPassword, onDismiss: { importData = nil }) {
                BackupPasswordSheet(mode: .import, onSubmit: onPassword)
            }
    }
}
