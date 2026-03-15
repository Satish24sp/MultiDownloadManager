// DownloadManagerKit/Sources/DownloadManagerKit/Core/DependencyContainer.swift

import Foundation

/// Wires all default implementations together.
/// Create one instance at app launch and pass it (or its individual services) to your UI layer.
///
/// Usage:
/// ```swift
/// let container = await DependencyContainer.create()
/// let manager = container.downloadManager
/// ```
public final class DependencyContainer: @unchecked Sendable {

    public let downloadManager: any DownloadManaging
    public let settingsManager: any SettingsManaging
    public let networkMonitor: any NetworkMonitoring
    public let notificationManager: any NotificationManaging
    public let logger: any DownloadLogging
    public let persistence: any DownloadPersisting
    public let diskSpaceManager: any DiskSpaceManaging
    public let checksumValidator: any ChecksumValidating

    /// Async factory that creates all services, wires them, and starts the download manager.
    public static func create(
        backgroundSessionIdentifier: String = "com.downloadmanagerkit.background"
    ) async -> DependencyContainer {
        let logger = DefaultLogger()
        let settings = DefaultSettingsManager()
        let persistence = JSONDownloadPersistence(logger: logger)
        let networkMonitor = DefaultNetworkMonitor(logger: logger)
        let notificationManager = DefaultNotificationManager(logger: logger)
        let diskSpaceManager = DefaultDiskSpaceManager()
        let checksumValidator = DefaultChecksumValidator()

        let manager = DefaultDownloadManager(
            persistence: persistence,
            networkMonitor: networkMonitor,
            settings: settings,
            logger: logger,
            notificationManager: notificationManager,
            diskSpaceManager: diskSpaceManager,
            checksumValidator: checksumValidator,
            backgroundSessionIdentifier: backgroundSessionIdentifier
        )

        await manager.start()

        return DependencyContainer(
            downloadManager: manager,
            settingsManager: settings,
            networkMonitor: networkMonitor,
            notificationManager: notificationManager,
            logger: logger,
            persistence: persistence,
            diskSpaceManager: diskSpaceManager,
            checksumValidator: checksumValidator
        )
    }

    private init(
        downloadManager: any DownloadManaging,
        settingsManager: any SettingsManaging,
        networkMonitor: any NetworkMonitoring,
        notificationManager: any NotificationManaging,
        logger: any DownloadLogging,
        persistence: any DownloadPersisting,
        diskSpaceManager: any DiskSpaceManaging,
        checksumValidator: any ChecksumValidating
    ) {
        self.downloadManager = downloadManager
        self.settingsManager = settingsManager
        self.networkMonitor = networkMonitor
        self.notificationManager = notificationManager
        self.logger = logger
        self.persistence = persistence
        self.diskSpaceManager = diskSpaceManager
        self.checksumValidator = checksumValidator
    }
}
