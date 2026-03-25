import Foundation
import Combine

@MainActor
final class WorktreeMonitor: ObservableObject {
    @Published var worktrees: [WorktreeItem] = []
    @Published var isLoading = false
    @Published var lastRefreshed: Date?

    private var timer: Timer?
    private let refreshInterval: TimeInterval = 30

    var worktreePath: String {
        get { UserDefaults.standard.string(forKey: "worktreeRootPath") ?? "" }
        set {
            UserDefaults.standard.set(newValue, forKey: "worktreeRootPath")
            Task { await refresh() }
        }
    }

    var hasPath: Bool {
        !worktreePath.isEmpty
    }

    var activeCount: Int {
        worktrees.filter { $0.status == .inProgress }.count
    }

    var staleCount: Int {
        worktrees.filter { $0.status == .stale }.count
    }

    func startMonitoring() {
        Task { await refresh() }
        timer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.refresh()
            }
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    func refresh() async {
        guard hasPath else { return }
        isLoading = true
        let items = await GitService.shared.scanWorktrees(rootPath: worktreePath)
        worktrees = items.filter { !$0.isMainWorktree } // Hide main worktree
        lastRefreshed = Date()
        isLoading = false
    }
}
