import SwiftUI

struct AboutView: View {
    @Environment(VaultSession.self) private var session

    private var version: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info?["CFBundleVersion"] as? String ?? "1"
        return "\(short) (\(build))"
    }

    var body: some View {
        List {
            Section {
                VStack(spacing: Spacing.md) {
                    AppMark(size: 72, onDarkBackground: false)
                    Text("SafeKeep")
                        .font(.title2.bold())
                    Text("Version \(version)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.sm)
            }
            .listRowBackground(Color.clear)

            Section("How Your Data Is Protected") {
                fact("lock.doc.fill", "AES-256-GCM", "Every account, including names and usernames, is encrypted in one sealed vault file.")
                fact("key.fill", "PBKDF2-SHA256", iterationsText)
                fact("iphone", "This iPhone only", "Keys live in the device-bound Keychain and never sync or restore elsewhere.")
                fact("wifi.slash", "No network", "No accounts, servers, analytics or tracking.")
            }

            Section {
                Text("Service icons come from Simple Icons (CC0). Logos and brand names are trademarks of their respective owners and are shown only to help you recognize your accounts.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var iterationsText: String {
        guard let iterations = session.passcodeIterations else { return "Your passcode is stretched before it can unlock the vault." }
        return "Your passcode is stretched with \(iterations.formatted()) rounds, tuned to this iPhone, to slow down guessing."
    }

    private func fact(_ symbol: String, _ title: String, _ detail: String) -> some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            Image(systemName: symbol)
                .font(.body.weight(.semibold))
                .foregroundStyle(Palette.brand)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.body.weight(.medium))
                Text(detail).font(.subheadline).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
    }
}
