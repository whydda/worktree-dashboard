import SwiftUI

struct WorktreeRowView: View {
    let item: WorktreeItem
    let onDelete: (WorktreeItem) -> Void

    var body: some View {
        HStack(spacing: 10) {
            // Status icon
            Image(systemName: item.status.icon)
                .foregroundColor(statusColor)
                .font(.system(size: 14))
                .frame(width: 20)

            // Content
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(item.displayName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.primary)

                    Spacer()

                    if let dateStr = item.lastCommitDateFormatted {
                        Text(dateStr)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }

                if let message = item.lastCommitMessage {
                    Text(message)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }

            // Status badge
            Text(item.status.label)
                .font(.system(size: 10, weight: .medium))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(statusColor.opacity(0.15))
                .foregroundColor(statusColor)
                .clipShape(Capsule())
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .contentShape(Rectangle())
        .contextMenu {
            Button(role: .destructive) {
                onDelete(item)
            } label: {
                Label("Delete Worktree...", systemImage: "trash")
            }
        }
    }

    private var statusColor: Color {
        switch item.status {
        case .pushed: return .green
        case .inProgress: return .blue
        case .stale: return .orange
        case .unknown: return .gray
        }
    }
}
