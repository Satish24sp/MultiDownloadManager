// DownloadManagerKit/Sources/DownloadManagerKit/Domain/Models/DownloadPriority.swift

import Foundation

/// Priority level for scheduling downloads in the queue.
/// Higher-priority downloads are started before lower-priority ones.
public enum DownloadPriority: Int, Codable, Sendable, CaseIterable, Comparable {
    case high = 0
    case normal = 1
    case low = 2

    public static func < (lhs: DownloadPriority, rhs: DownloadPriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    /// Human-readable display name.
    public var displayName: String {
        switch self {
        case .high:   return NSLocalizedString("High", comment: "Download priority")
        case .normal: return NSLocalizedString("Normal", comment: "Download priority")
        case .low:    return NSLocalizedString("Low", comment: "Download priority")
        }
    }
}
