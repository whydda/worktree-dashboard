import SwiftUI

struct MenuBarView: View {
    @ObservedObject var monitor: WorktreeMonitor
    @State private var showSettings = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Worktrees")
                    .font(.system(size: 14, weight: .bold))

                Spacer()

                if monitor.isLoading {
                    ProgressView()
                        .scaleEffect(0.6)
                        .frame(width: 16, height: 16)
                }

                Button(action: { Task { await monitor.refresh() } }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12))
                }
                .buttonStyle(.borderless)
                .help("Refresh")

                Button(action: { showSettings = true }) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 12))
                }
                .buttonStyle(.borderless)
                .help("Settings")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)

            Divider()

            // Content
            if !monitor.hasPath {
                emptyStateView
            } else if monitor.worktrees.isEmpty && !monitor.isLoading {
                noWorktreesView
            } else {
                worktreeListView
            }

            Divider()

            // Footer
            footerView
        }
        .frame(width: 360)
        .sheet(isPresented: $showSettings) {
            SettingsView(monitor: monitor)
        }
    }

    // MARK: - Subviews

    private var worktreeListView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(monitor.worktrees) { item in
                    WorktreeRowView(item: item)

                    if item.id != monitor.worktrees.last?.id {
                        Divider()
                            .padding(.leading, 38)
                    }
                }
            }
        }
        .frame(maxHeight: 400)
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "folder.badge.gearshape")
                .font(.system(size: 32))
                .foregroundColor(.secondary)

            Text("No path configured")
                .font(.system(size: 13, weight: .medium))

            Text("Set your worktree root path in Settings")
                .font(.system(size: 12))
                .foregroundColor(.secondary)

            Button("Open Settings") {
                showSettings = true
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding(24)
    }

    private var noWorktreesView: some View {
        VStack(spacing: 8) {
            Image(systemName: "tray")
                .font(.system(size: 24))
                .foregroundColor(.secondary)

            Text("No worktrees found")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
        }
        .padding(24)
    }

    private var footerView: some View {
        HStack {
            if let date = monitor.lastRefreshed {
                Text("Updated \(date, style: .relative) ago")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }

            Spacer()

            if monitor.staleCount > 0 {
                Label("\(monitor.staleCount) stale", systemImage: "exclamationmark.triangle")
                    .font(.system(size: 10))
                    .foregroundColor(.orange)
            }

            Text("\(monitor.worktrees.count) worktrees")
                .font(.system(size: 10))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}
