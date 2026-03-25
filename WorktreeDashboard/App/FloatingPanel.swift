import AppKit
import SwiftUI

/// 다른 창을 클릭해도 닫히지 않는 플로팅 패널
final class FloatingPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    init(contentView: NSView) {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 500),
            styleMask: [.titled, .closable, .fullSizeContentView, .nonactivatingPanel],
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
        self.hidesOnDeactivate = false  // 핵심: 포커스 잃어도 안 숨김
        self.backgroundColor = .windowBackgroundColor
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
