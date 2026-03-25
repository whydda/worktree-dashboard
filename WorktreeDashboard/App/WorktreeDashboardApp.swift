import SwiftUI
import AppKit

@main
struct WorktreeDashboardApp: App {
    @StateObject private var monitor = WorktreeMonitor()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(monitor: monitor)
        } label: {
            if let icon = loadMenuBarIcon() {
                Image(nsImage: icon)
            } else {
                Label("Worktrees", systemImage: "arrow.triangle.branch")
            }
        }
        .menuBarExtraStyle(.window)
        .defaultSize(width: 360, height: 480)
    }

    private func loadMenuBarIcon() -> NSImage? {
        // Find the icon in the bundle or relative to the executable
        let candidates = [
            Bundle.main.path(forResource: "MenuBarIcon", ofType: "png"),
            Bundle.main.resourcePath.map { "\($0)/MenuBarIcon.png" },
            Bundle.main.executablePath.map { (($0 as NSString).deletingLastPathComponent as NSString).appendingPathComponent("../Resources/MenuBarIcon.png") },
        ]

        for candidate in candidates {
            guard let path = candidate, let image = NSImage(contentsOfFile: path) else { continue }
            image.isTemplate = true  // macOS가 자동으로 밝기 조절
            image.size = NSSize(width: 18, height: 18)
            return image
        }

        return nil
    }

    init() {
        DispatchQueue.main.async { [self] in
            monitor.startMonitoring()
        }
    }
}
