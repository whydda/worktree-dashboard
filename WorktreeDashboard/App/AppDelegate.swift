import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var panel: FloatingPanel!
    private let monitor = WorktreeMonitor()

    nonisolated func applicationDidFinishLaunching(_ notification: Notification) {
        Task { @MainActor in
            setupStatusItem()
            setupPanel()
            monitor.startMonitoring()
        }
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem.button {
            if let icon = loadMenuBarIcon() {
                button.image = icon
            } else {
                button.image = NSImage(systemSymbolName: "arrow.triangle.branch", accessibilityDescription: "Worktrees")
            }
            button.action = #selector(togglePanel)
            button.target = self
        }
    }

    private func setupPanel() {
        let contentView = MenuBarView(monitor: monitor)
        let hostingView = NSHostingView(rootView: contentView)
        panel = FloatingPanel(contentView: hostingView)
    }

    @objc private func togglePanel() {
        panel.toggleVisibility(near: statusItem.button)
    }

    private func loadMenuBarIcon() -> NSImage? {
        let candidates = [
            Bundle.main.path(forResource: "MenuBarIcon", ofType: "png"),
            Bundle.main.resourcePath.map { "\($0)/MenuBarIcon.png" },
        ]

        for candidate in candidates {
            guard let path = candidate, let image = NSImage(contentsOfFile: path) else { continue }
            image.isTemplate = true
            image.size = NSSize(width: 18, height: 18)
            return image
        }
        return nil
    }
}
