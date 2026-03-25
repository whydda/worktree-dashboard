import SwiftUI

@main
struct WorktreeDashboardApp: App {
    @StateObject private var monitor = WorktreeMonitor()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(monitor: monitor)
        } label: {
            Label("Worktrees", systemImage: menuBarIcon)
        }
        .menuBarExtraStyle(.window)
        .defaultSize(width: 360, height: 480)
    }

    private var menuBarIcon: String {
        if monitor.staleCount > 0 {
            return "exclamationmark.triangle"
        }
        return "arrow.triangle.branch"
    }

    init() {
        // Monitor starts when app launches
        DispatchQueue.main.async { [self] in
            monitor.startMonitoring()
        }
    }
}
