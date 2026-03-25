import Foundation

enum WorktreeRemoveError: Error, LocalizedError {
    case isMainWorktree
    case mainRepoNotFound

    var errorDescription: String? {
        switch self {
        case .isMainWorktree: return "Cannot remove the main worktree"
        case .mainRepoNotFound: return "Could not find the main repository"
        }
    }
}

actor GitService {
    static let shared = GitService()
    private let staleDaysThreshold = 7

    func scanWorktrees(rootPath: String) async -> [WorktreeItem] {
        // Find the main git repo by checking .git files in subdirectories
        let mainRepoPath = findMainRepo(in: rootPath)
        guard let repoPath = mainRepoPath else { return [] }

        let worktreeEntries = parseWorktreeList(repoPath: repoPath)
        var items: [WorktreeItem] = []

        for entry in worktreeEntries {
            let item = await buildWorktreeItem(entry: entry, repoPath: repoPath)
            items.append(item)
        }

        // Sort: in-progress first, then pushed, then stale
        return items.sorted { a, b in
            let order: [WorktreeStatus] = [.inProgress, .pushed, .stale, .unknown]
            let ai = order.firstIndex(of: a.status) ?? 3
            let bi = order.firstIndex(of: b.status) ?? 3
            if ai != bi { return ai < bi }
            return (a.lastCommitDate ?? .distantPast) > (b.lastCommitDate ?? .distantPast)
        }
    }

    // MARK: - Private

    private func findMainRepo(in rootPath: String) -> String? {
        let fm = FileManager.default
        let expandedPath = NSString(string: rootPath).expandingTildeInPath

        // Check if rootPath itself has worktrees
        let entries = (try? fm.contentsOfDirectory(atPath: expandedPath)) ?? []
        for entry in entries {
            let gitFile = (expandedPath as NSString).appendingPathComponent(entry + "/.git")
            if fm.fileExists(atPath: gitFile) {
                // Read .git file to find main repo
                if let content = try? String(contentsOfFile: gitFile, encoding: .utf8),
                   content.hasPrefix("gitdir:") {
                    let gitdir = content.trimmingCharacters(in: .whitespacesAndNewlines)
                        .replacingOccurrences(of: "gitdir: ", with: "")
                    // Navigate up from .git/worktrees/xxx to .git
                    let mainGitDir = (gitdir as NSString)
                        .deletingLastPathComponent
                        .replacingOccurrences(of: "/worktrees", with: "")
                    let mainRepo = (mainGitDir as NSString).deletingLastPathComponent
                    return mainRepo
                }
            }
        }

        // Fallback: check if rootPath is a git repo itself
        if fm.fileExists(atPath: (expandedPath as NSString).appendingPathComponent(".git")) {
            return expandedPath
        }

        return nil
    }

    private struct WorktreeEntry {
        let path: String
        let branch: String
        let isMain: Bool
    }

    private func parseWorktreeList(repoPath: String) -> [WorktreeEntry] {
        let output = runGit(["worktree", "list", "--porcelain"], at: repoPath)
        var entries: [WorktreeEntry] = []
        var currentPath: String?
        var currentBranch: String?
        var isFirst = true

        for line in output.components(separatedBy: "\n") {
            if line.hasPrefix("worktree ") {
                if let path = currentPath, let branch = currentBranch {
                    entries.append(WorktreeEntry(path: path, branch: branch, isMain: isFirst && entries.isEmpty))
                }
                currentPath = String(line.dropFirst("worktree ".count))
                currentBranch = nil
            } else if line.hasPrefix("branch refs/heads/") {
                currentBranch = String(line.dropFirst("branch refs/heads/".count))
            } else if line == "bare" || line == "detached" {
                currentBranch = currentBranch ?? "(detached)"
            }

            if line.isEmpty, let path = currentPath {
                let branch = currentBranch ?? "(unknown)"
                entries.append(WorktreeEntry(path: path, branch: branch, isMain: entries.isEmpty && isFirst))
                isFirst = false
                currentPath = nil
                currentBranch = nil
            }
        }

        // Handle last entry
        if let path = currentPath {
            let branch = currentBranch ?? "(unknown)"
            entries.append(WorktreeEntry(path: path, branch: branch, isMain: entries.isEmpty))
        }

        return entries
    }

    private func buildWorktreeItem(entry: WorktreeEntry, repoPath: String) async -> WorktreeItem {
        let lastCommit = getLastCommitMessage(at: entry.path)
        let lastCommitDate = getLastCommitDate(at: entry.path)
        let status = determineStatus(
            path: entry.path,
            branch: entry.branch,
            lastCommitDate: lastCommitDate,
            repoPath: repoPath
        )
        let ticketId = WorktreeItem.parseTicketId(from: entry.branch)

        return WorktreeItem(
            id: entry.path,
            path: entry.path,
            branch: entry.branch,
            ticketId: ticketId,
            lastCommitMessage: lastCommit,
            lastCommitDate: lastCommitDate,
            status: status,
            isMainWorktree: entry.isMain
        )
    }

    private func determineStatus(path: String, branch: String, lastCommitDate: Date?, repoPath: String) -> WorktreeStatus {
        // Check if pushed to remote
        let remoteCheck = runGit(["branch", "-r", "--list", "origin/\(branch)"], at: path)
        let isPushed = !remoteCheck.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        if isPushed {
            // Check if local is ahead of remote
            let ahead = runGit(["rev-list", "--count", "origin/\(branch)..HEAD"], at: path)
            let aheadCount = Int(ahead.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
            if aheadCount == 0 {
                return .pushed
            }
        }

        // Check staleness
        if let date = lastCommitDate {
            let days = Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0
            if days >= staleDaysThreshold {
                return .stale
            }
        }

        return .inProgress
    }

    private func getLastCommitMessage(at path: String) -> String? {
        let output = runGit(["log", "--oneline", "-1", "--format=%s"], at: path)
        let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private func getLastCommitDate(at path: String) -> Date? {
        let output = runGit(["log", "-1", "--format=%ci"], at: path)
        let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        return formatter.date(from: trimmed)
    }

    /// Worktree 삭제: git worktree remove + 로컬 브랜치 삭제 + 리모트 브랜치 삭제(옵션)
    func removeWorktree(item: WorktreeItem, deleteRemoteBranch: Bool) async -> Result<Void, WorktreeRemoveError> {
        guard !item.isMainWorktree else {
            return .failure(.isMainWorktree)
        }

        let repoPath = findMainRepoFromWorktree(worktreePath: item.path)
        guard let mainRepo = repoPath else {
            return .failure(.mainRepoNotFound)
        }

        // 1. git worktree remove --force <path>
        let _ = runGit(["worktree", "remove", "--force", item.path], at: mainRepo)
        let fm = FileManager.default
        if fm.fileExists(atPath: item.path) {
            // Fallback: 직접 디렉토리 삭제
            try? fm.removeItem(atPath: item.path)
        }

        // 2. 로컬 브랜치 삭제
        let _ = runGit(["branch", "-D", item.branch], at: mainRepo)

        // 3. 리모트 브랜치 삭제 (옵션)
        if deleteRemoteBranch {
            let _ = runGit(["push", "origin", "--delete", item.branch], at: mainRepo)
        }

        // 4. worktree prune (정리)
        let _ = runGit(["worktree", "prune"], at: mainRepo)

        return .success(())
    }

    private func findMainRepoFromWorktree(worktreePath: String) -> String? {
        let gitFile = (worktreePath as NSString).appendingPathComponent(".git")
        guard let content = try? String(contentsOfFile: gitFile, encoding: .utf8),
              content.hasPrefix("gitdir:") else {
            return nil
        }
        let gitdir = content.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "gitdir: ", with: "")
        let mainGitDir = (gitdir as NSString)
            .deletingLastPathComponent
            .replacingOccurrences(of: "/worktrees", with: "")
        return (mainGitDir as NSString).deletingLastPathComponent
    }

    private func runGit(_ args: [String], at path: String) -> String {
        let process = Process()
        let pipe = Pipe()

        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = ["-C", path] + args
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return ""
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8) ?? ""
    }
}
