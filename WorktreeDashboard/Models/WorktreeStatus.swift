import Foundation

enum WorktreeStatus: String, CaseIterable {
    case pushed
    case inProgress
    case stale
    case unknown

    var icon: String {
        switch self {
        case .pushed: return "checkmark.circle.fill"
        case .inProgress: return "arrow.triangle.2.circlepath"
        case .stale: return "exclamationmark.triangle.fill"
        case .unknown: return "questionmark.circle"
        }
    }

    var label: String {
        switch self {
        case .pushed: return "Pushed"
        case .inProgress: return "In Progress"
        case .stale: return "Stale"
        case .unknown: return "Unknown"
        }
    }

    var colorName: String {
        switch self {
        case .pushed: return "green"
        case .inProgress: return "blue"
        case .stale: return "orange"
        case .unknown: return "gray"
        }
    }
}
