import Foundation

struct WorktreeItem: Identifiable, Equatable {
    let id: String // path as unique id
    let path: String
    let branch: String
    let ticketId: String?
    let lastCommitMessage: String?
    let lastCommitDate: Date?
    let status: WorktreeStatus
    let isMainWorktree: Bool

    var displayName: String {
        ticketId ?? branch
    }

    var relativePath: String {
        (path as NSString).lastPathComponent
    }

    var daysSinceLastCommit: Int? {
        guard let date = lastCommitDate else { return nil }
        return Calendar.current.dateComponents([.day], from: date, to: Date()).day
    }

    var lastCommitDateFormatted: String? {
        guard let date = lastCommitDate else { return nil }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    static func parseTicketId(from branch: String) -> String? {
        // Match patterns like MB2-1234, PROJ-123, etc.
        let pattern = #"([A-Z][A-Z0-9]+-\d+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: branch, range: NSRange(branch.startIndex..., in: branch)),
              let range = Range(match.range(at: 1), in: branch) else {
            return nil
        }
        return String(branch[range])
    }
}
