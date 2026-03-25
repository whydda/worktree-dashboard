import SwiftUI

struct SettingsView: View {
    @ObservedObject var monitor: WorktreeMonitor
    @State private var pathInput: String = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Text("Settings")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                Text("Worktree Root Path")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                HStack {
                    TextField("~/workspace/project/worktrees", text: $pathInput)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 13, design: .monospaced))

                    Button("Browse") {
                        selectFolder()
                    }
                }

                Text("The directory containing your git worktrees")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Divider()

            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.escape)

                Spacer()

                Button("Save") {
                    monitor.worktreePath = pathInput
                    dismiss()
                }
                .keyboardShortcut(.return)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(20)
        .frame(width: 420)
        .onAppear {
            pathInput = monitor.worktreePath
        }
    }

    private func selectFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Select your worktree root directory"

        if panel.runModal() == .OK, let url = panel.url {
            pathInput = url.path
        }
    }
}
