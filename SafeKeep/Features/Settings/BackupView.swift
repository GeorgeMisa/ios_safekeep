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
        List {
            Section {
                MascotHeader(
                    pose: .box,
                    message: "I'll pack your vault into one encrypted file. Keep it somewhere safe, like Files or another device."
                )
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)

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

            if lastExport > 0 {
                Section {
                    LabeledContent("Last Export", value: Date(timeIntervalSince1970: lastExport).formatted(date: .abbreviated, time: .shortened))
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Backup & Restore")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $isVerifyingExport, onDismiss: {
            if exportVerified { isChoosingExportPassword = true }
        }) {
            PasscodeVerifyView(heading: "Enter your passcode to export", pose: .box) {
                exportVerified = true
            }
        }
        .sheet(isPresented: $isChoosingExportPassword, onDismiss: {
            if exportDocument != nil { isExporting = true }
        }) {
            BackupPasswordSheet(mode: .export) { password in
                exportDocument = BackupDocument(data: try await session.exportBackup(password: password))
            }
        }
        .fileExporter(
            isPresented: $isExporting,
            document: exportDocument,
            contentType: .safekeepBackup,
            defaultFilename: "SafeKeep Backup \(Date.now.formatted(.iso8601.year().month().day()))"
        ) { result in
            exportDocument = nil
            switch result {
            case .success:
                lastExport = Date.now.timeIntervalSince1970
                alert = AlertContent(title: "Backup Exported", message: "Keep your backup password somewhere safe. SafeKeep can't recover it.")
            case .failure(let error):
                alert = AlertContent(title: "Export Failed", message: error.localizedDescription)
            }
        }
        .fileImporter(isPresented: $isImporting, allowedContentTypes: [.safekeepBackup]) { result in
            handleImport(result)
        }
        .sheet(isPresented: $isEnteringImportPassword, onDismiss: { importData = nil }) {
            BackupPasswordSheet(mode: .import) { password in
                guard let importData else { return }
                let summary = try await session.importBackup(importData, password: password)
                alert = AlertContent(
                    title: "Backup Imported",
                    message: "Added \(summary.added) \(summary.added == 1 ? "account" : "accounts")"
                        + (summary.skipped > 0 ? ", skipped \(summary.skipped) already in your vault." : ".")
                )
            }
        }
        .alert(alert?.title ?? "", isPresented: .constant(alert != nil)) {
            Button("OK") { alert = nil }
        } message: {
            Text(alert?.message ?? "")
        }
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
