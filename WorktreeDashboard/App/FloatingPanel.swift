import AppKit
import SwiftUI

/// 다른 창을 클릭해도 닫히지 않는 플로팅 패널
final class FloatingPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    init(contentView: NSView) {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 700),
            styleMask: [.titled, .closable, .resizable, .fullSizeContentView, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        self.contentView = contentView
        self.titlebarAppearsTransparent = true
        self.titleVisibility = .hidden
        self.isMovableByWindowBackground = true
        self.level = .floating
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.isReleasedWhenClosed = false
        self.hidesOnDeactivate = false
        self.backgroundColor = .windowBackgroundColor
        self.minSize = NSSize(width: 320, height: 400)
        self.maxSize = NSSize(width: 600, height: 1200)
    }

    func toggleVisibility(near statusItemButton: NSStatusBarButton?) {
        if isVisible {
            orderOut(nil)
        } else {
            positionNearStatusItem(statusItemButton)
            makeKeyAndOrderFront(nil)
        }
    }

    private func positionNearStatusItem(_ button: NSStatusBarButton?) {
        guard let button = button,
              let buttonWindow = button.window else {
            center()
            return
        }

        let buttonRect = button.convert(button.bounds, to: nil)
        let screenRect = buttonWindow.convertToScreen(buttonRect)

        let x = screenRect.midX - frame.width / 2
        let y = screenRect.minY - frame.height - 4

        setFrameOrigin(NSPoint(x: x, y: y))
    }
}
