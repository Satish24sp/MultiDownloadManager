// DownloadManagerKit/Sources/DownloadManagerKit/Domain/Protocols/NotificationManaging.swift

import Foundation

/// Manages local notifications for download progress and completion.
public protocol NotificationManaging: AnyObject, Sendable {

    /// Request notification authorization from the user.
    func requestAuthorization() async throws -> Bool

    /// Post or update a progress notification for a download.
    /// Updates are throttled internally to at most once per second per download.
    func postProgressNotification(for item: DownloadItem) async

    /// Post a completion notification.
    func postCompletionNotification(for item: DownloadItem) async

    /// Post a failure notification.
    func postFailureNotification(for item: DownloadItem) async

    /// Remove any pending/delivered notifications for a download.
    func removeNotification(for downloadId: UUID) async

    /// Remove all download-related notifications.
    func removeAllNotifications() async
}

/// Protocol for checking and managing disk space.
public protocol DiskSpaceManaging: Sendable {

    /// Available free space on the device in bytes.
    func availableSpace() throws -> Int64

    /// Total disk capacity in bytes.
    func totalSpace() throws -> Int64

    /// Space used by this app's downloads directory in bytes.
    func usedByApp() throws -> Int64

    /// Returns true if at least `bytes` of free space is available.
    func hasEnoughSpace(for bytes: Int64) throws -> Bool
}

/// Protocol for verifying downloaded file integrity.
public protocol ChecksumValidating: Sendable {

    /// Compute the SHA-256 hash of a file.
    func sha256(of fileURL: URL) throws -> String

    /// Verify that a file matches the expected SHA-256 checksum.
    func validate(fileURL: URL, expectedChecksum: String) throws -> Bool
}
