import SwiftUI

@main
struct WorktreeDashboardApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // 빈 Settings scene (메뉴바 앱이므로 메인 윈도우 불필요)
        Settings {
            EmptyView()
        }
    }
}
