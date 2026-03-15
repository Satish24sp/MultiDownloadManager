// DownloadManagerKit/Sources/DownloadManagerKit/Domain/Models/DownloadState.swift

import Foundation

/// Represents the lifecycle state of a download task.
public enum DownloadState: String, Codable, Sendable, CaseIterable {
    /// Created but not yet queued for download.
    case pending
    /// Waiting in the queue for an available download slot.
    case queued
    /// Actively transferring data.
    case downloading
    /// Temporarily paused by the user or system (e.g., network loss).
    case paused
    /// Successfully downloaded and saved to disk.
    case completed
    /// Failed after exhausting all retry attempts.
    case failed
    /// Explicitly cancelled by the user.
    case cancelled

    /// Whether this state represents a terminal condition (no further automatic transitions).
    public var isTerminal: Bool {
        switch self {
        case .completed, .failed, .cancelled:
            return true
        case .pending, .queued, .downloading, .paused:
            return false
        }
    }

    /// Human-readable display name.
    public var displayName: String {
        switch self {
        case .pending:     return NSLocalizedString("Pending", comment: "Download state")
        case .queued:      return NSLocalizedString("Queued", comment: "Download state")
        case .downloading: return NSLocalizedString("Downloading", comment: "Download state")
        case .paused:      return NSLocalizedString("Paused", comment: "Download state")
        case .completed:   return NSLocalizedString("Completed", comment: "Download state")
        case .failed:      return NSLocalizedString("Failed", comment: "Download state")
        case .cancelled:   return NSLocalizedString("Cancelled", comment: "Download state")
        }
    }
}
