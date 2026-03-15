// DownloadManagerKit/Sources/DownloadManagerKit/Infrastructure/NotificationManager.swift

import Foundation
import UserNotifications

/// UNUserNotificationCenter-backed notification manager.
/// Throttles progress updates to at most once per second per download.
public final class DefaultNotificationManager: NotificationManaging, @unchecked Sendable {

    private let center = UNUserNotificationCenter.current()
    private let logger: any DownloadLogging
    private let throttleInterval: TimeInterval = 1.0
    private var lastNotificationDates: [UUID: Date] = [:]
    private let lock = NSLock()

    /// Notification category identifier for downloads.
    public static let categoryIdentifier = "DOWNLOAD_PROGRESS"
    public static let cancelActionIdentifier = "CANCEL_DOWNLOAD"

    public init(logger: any DownloadLogging) {
        self.logger = logger
        registerCategories()
    }

    private func registerCategories() {
        let cancelAction = UNNotificationAction(
            identifier: Self.cancelActionIdentifier,
            title: NSLocalizedString("Cancel", comment: "Notification action"),
            options: .destructive
        )
        let category = UNNotificationCategory(
            identifier: Self.categoryIdentifier,
            actions: [cancelAction],
            intentIdentifiers: []
        )
        center.setNotificationCategories([category])
    }

    public func requestAuthorization() async throws -> Bool {
        try await center.requestAuthorization(options: [.alert, .sound, .badge])
    }

    public func postProgressNotification(for item: DownloadItem) async {
        guard shouldThrottle(for: item.id) else { return }

        let content = UNMutableNotificationContent()
        content.title = item.fileName
        content.body = String(
            format: NSLocalizedString("Downloading… %d%%", comment: "Notification progress"),
            item.percentComplete
        )
        content.categoryIdentifier = Self.categoryIdentifier
        content.userInfo = ["downloadId": item.id.uuidString]

        let request = UNNotificationRequest(
            identifier: item.id.uuidString,
            content: content,
            trigger: nil
        )

        do {
            try await center.add(request)
        } catch {
            logger.error("Failed to post progress notification: \(error.localizedDescription)", category: .notification)
        }
    }

    public func postCompletionNotification(for item: DownloadItem) async {
        let content = UNMutableNotificationContent()
        content.title = item.fileName
        content.body = NSLocalizedString("Download complete", comment: "Notification completion")
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: item.id.uuidString,
            content: content,
            trigger: nil
        )

        do {
            try await center.add(request)
            logger.debug("Posted completion notification for \(item.fileName)", category: .notification)
        } catch {
            logger.error("Failed to post completion notification: \(error.localizedDescription)", category: .notification)
        }
    }

    public func postFailureNotification(for item: DownloadItem) async {
        let content = UNMutableNotificationContent()
        content.title = item.fileName
        content.body = String(
            format: NSLocalizedString("Download failed: %@", comment: "Notification failure"),
            item.error?.localizedDescription ?? NSLocalizedString("Unknown error", comment: "")
        )
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: item.id.uuidString,
            content: content,
            trigger: nil
        )

        do {
            try await center.add(request)
        } catch {
            logger.error("Failed to post failure notification: \(error.localizedDescription)", category: .notification)
        }
    }

    public func removeNotification(for downloadId: UUID) async {
        center.removeDeliveredNotifications(withIdentifiers: [downloadId.uuidString])
        center.removePendingNotificationRequests(withIdentifiers: [downloadId.uuidString])
    }

    public func removeAllNotifications() async {
        center.removeAllDeliveredNotifications()
        center.removeAllPendingNotificationRequests()
    }

    /// Returns true if enough time has passed since the last notification for this download.
    private func shouldThrottle(for id: UUID) -> Bool {
        lock.lock()
        defer { lock.unlock() }

        let now = Date()
        if let last = lastNotificationDates[id], now.timeIntervalSince(last) < throttleInterval {
            return false
        }
        lastNotificationDates[id] = now
        return true
    }
}
