import SwiftUI

struct HelpView: View {
    private let topics: [(question: String, answer: String)] = [
        (
            "What if I forget my passcode?",
            "SafeKeep can't recover it. Nobody holds a copy of your key, which is what keeps your vault private. Erase the vault from Settings, set a new passcode, and import your latest encrypted backup."
        ),
        (
            "Is my data uploaded anywhere?",
            "No. SafeKeep has no account, no server and no network code. Your vault lives only on this iPhone and is left out of iCloud and computer backups."
        ),
        (
            "How do I back up my passwords?",
            "Go to Settings › Backup & Restore and export an encrypted .safekeep file. It's protected by a separate backup password that you choose."
        ),
        (
            "Why does the app go blank in the app switcher?",
            "SafeKeep hides its screen whenever it isn't in front, so your passwords never appear in the app switcher, screen recordings or screen mirroring."
        ),
        (
            "Why did the timer lock me out?",
            "After 5 wrong passcodes, SafeKeep makes you wait before trying again: 1 minute, then 5, then 15, then an hour. This stops anyone from guessing their way in."
        ),
        (
            "How long does a copied password stay on the clipboard?",
            "30 seconds. It's also kept off Universal Clipboard, so it never reaches your other devices."
        ),
    ]

    var body: some View {
        List {
            Section {
                MascotHeader(pose: .standard, message: "Got a question? Tap one below and I'll explain.")
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)

            ForEach(topics, id: \.question) { topic in
                DisclosureGroup {
                    Text(topic.answer)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, Spacing.xs)
                } label: {
                    Text(topic.question)
                        .font(.body.weight(.medium))
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Help & Support")
        .navigationBarTitleDisplayMode(.inline)
    }
}
