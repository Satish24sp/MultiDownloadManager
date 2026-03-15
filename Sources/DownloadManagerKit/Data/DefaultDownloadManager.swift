// DownloadManagerKit/Sources/DownloadManagerKit/Data/DefaultDownloadManager.swift

import Foundation
import Combine

/// Thread-safe download manager backed by a serial dispatch queue.
/// Manages the full lifecycle of file downloads including queuing, progress,
/// persistence, retry, background sessions, and reactive publishing.
public final class DefaultDownloadManager: DownloadManaging, @unchecked Sendable {

    // MARK: - Dependencies

    private let sessionClient: URLSessionDownloadClient
    private let persistence: any DownloadPersisting
    private let networkMonitor: any NetworkMonitoring
    private let settings: any SettingsManaging
    private let logger: any DownloadLogging
    private let notificationManager: any NotificationManaging
    private let diskSpaceManager: any DiskSpaceManaging
    private let checksumValidator: any ChecksumValidating
    private let backgroundSessionIdentifier: String

    // MARK: - Serialized State

    private let queue = DispatchQueue(label: "com.downloadmanagerkit.manager", qos: .userInitiated)
    private var items: [UUID: DownloadItem] = [:]
    private var taskIdToDownloadId: [Int: UUID] = [:]
    private var downloadIdToTask: [UUID: URLSessionDownloadTask] = [:]
    private var resumeDataMap: [UUID: Data] = [:]
    private var requestMetadata: [UUID: (headers: [String: String]?, checksum: String?)] = [:]
    private var speedTrackers: [UUID: SpeedTracker] = [:]
    private var activeCount: Int = 0
    private var networkCancellable: AnyCancellable?
    private var progressContinuations: [UUID: [AsyncStream<DownloadItem>.Continuation]] = [:]
    private var pausedBySystem: Set<UUID> = []

    // MARK: - Combine

    private let _downloadsSubject = CurrentValueSubject<[DownloadItem], Never>([])

    public var downloadsPublisher: AnyPublisher<[DownloadItem], Never> {
        _downloadsSubject.eraseToAnyPublisher()
    }

    // MARK: - Background Session Support

    /// Set this from your AppDelegate's `handleEventsForBackgroundURLSession` to enable
    /// background session completion.
    public var backgroundCompletionHandler: (() -> Void)?

    // MARK: - Init

    public init(
        persistence: any DownloadPersisting,
        networkMonitor: any NetworkMonitoring,
        settings: any SettingsManaging,
        logger: any DownloadLogging,
        notificationManager: any NotificationManaging,
        diskSpaceManager: any DiskSpaceManaging,
        checksumValidator: any ChecksumValidating,
        backgroundSessionIdentifier: String = "com.downloadmanagerkit.background"
    ) {
        self.persistence = persistence
        self.networkMonitor = networkMonitor
        self.settings = settings
        self.logger = logger
        self.notificationManager = notificationManager
        self.diskSpaceManager = diskSpaceManager
        self.checksumValidator = checksumValidator
        self.backgroundSessionIdentifier = backgroundSessionIdentifier
        self.sessionClient = URLSessionDownloadClient()
    }

    deinit {
        sessionClient.invalidateAndCancel()
        networkCancellable?.cancel()
    }

    // MARK: - Lifecycle

    public func start() async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            queue.async { [self] in
                createSession()
                setupCallbacks()
                restoreDownloads()
                observeNetwork()
                continuation.resume()
            }
        }
    }

    // MARK: - Public API

    @discardableResult
    public func startDownload(_ request: DownloadRequest) async throws -> UUID {
        try await withCheckedThrowingContinuation { continuation in
            queue.async { [self] in
                do {
                    let id = try _startDownload(request)
                    continuation.resume(returning: id)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    public func pauseDownload(id: UUID) async throws {
        await withCheckedContinuation { continuation in
            queue.async { [self] in
                _pauseDownload(id: id)
                continuation.resume()
            }
        }
    }

    public func resumeDownload(id: UUID) async throws {
        await withCheckedContinuation { continuation in
            queue.async { [self] in
                _resumeDownload(id: id)
                continuation.resume()
            }
        }
    }

    public func cancelDownload(id: UUID) async throws {
        await withCheckedContinuation { continuation in
            queue.async { [self] in
                _cancelDownload(id: id)
                continuation.resume()
            }
        }
    }

    public func deleteDownload(id: UUID) async throws {
        await withCheckedContinuation { continuation in
            queue.async { [self] in
                _deleteDownload(id: id)
                continuation.resume()
            }
        }
    }

    public func retryDownload(id: UUID) async throws {
        await withCheckedContinuation { continuation in
            queue.async { [self] in
                _retryDownload(id: id)
                continuation.resume()
            }
        }
    }

    public func pauseAll() async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            queue.async { [self] in
                let activeIds = items.values.filter { $0.state == .downloading }.map(\.id)
                for id in activeIds {
                    _pauseDownload(id: id)
                }
                continuation.resume()
            }
        }
    }

    public func resumeAll() async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            queue.async { [self] in
                let pausedIds = items.values.filter { $0.state == .paused }.map(\.id)
                for id in pausedIds {
                    _resumeDownload(id: id)
                }
                continuation.resume()
            }
        }
    }

    public func getDownload(id: UUID) async -> DownloadItem? {
        await withCheckedContinuation { continuation in
            queue.async { [self] in
                continuation.resume(returning: items[id])
            }
        }
    }

    public func getAllDownloads() async -> [DownloadItem] {
        await withCheckedContinuation { continuation in
            queue.async { [self] in
                continuation.resume(returning: self.sortedItems())
            }
        }
    }

    public func progressStream(for id: UUID) async -> AsyncStream<DownloadItem> {
        AsyncStream { [weak self] continuation in
            guard let self else {
                continuation.finish()
                return
            }
            self.queue.async {
                if self.progressContinuations[id] == nil {
                    self.progressContinuations[id] = []
                }
                self.progressContinuations[id]?.append(continuation)

                if let item = self.items[id] {
                    continuation.yield(item)
                }

                continuation.onTermination = { [weak self] _ in
                    self?.queue.async {
                        self?.progressContinuations[id]?.removeAll { $0 == continuation }
                    }
                }
            }
        }
    }

    // MARK: - Private: Session Setup

    private func createSession() {
        sessionClient.createSession(identifier: backgroundSessionIdentifier)
    }

    private func setupCallbacks() {
        sessionClient.onProgress = { [weak self] taskId, bytesWritten, totalWritten, totalExpected in
            self?.queue.async {
                self?.handleProgress(taskId: taskId, bytesWritten: bytesWritten, totalWritten: totalWritten, totalExpected: totalExpected)
            }
        }

        sessionClient.onFinishedDownloading = { [weak self] taskId, location, response in
            self?.queue.async {
                self?.handleFinishedDownloading(taskId: taskId, location: location, response: response)
            }
        }

        sessionClient.onTaskComplete = { [weak self] taskId, error in
            self?.queue.async {
                self?.handleTaskComplete(taskId: taskId, error: error)
            }
        }

        sessionClient.onAllEventsFinished = { [weak self] in
            DispatchQueue.main.async {
                self?.backgroundCompletionHandler?()
                self?.backgroundCompletionHandler = nil
            }
        }
    }

    // MARK: - Private: Network Observation

    private func observeNetwork() {
        networkMonitor.start()
        networkCancellable = networkMonitor.networkStatusPublisher
            .sink { [weak self] status in
                self?.queue.async {
                    self?.handleNetworkChange(status)
                }
            }
    }

    private func handleNetworkChange(_ status: NetworkStatus) {
        if !status.isConnected {
            logger.info("Network lost — pausing active downloads", category: .network)
            let activeIds = items.values.filter { $0.state == .downloading }.map(\.id)
            for id in activeIds {
                pausedBySystem.insert(id)
                _pauseDownload(id: id)
            }
        } else {
            if settings.wifiOnlyMode && status.connectionType != .wifi {
                logger.info("Network returned on cellular — WiFi-only mode, staying paused", category: .network)
                return
            }
            guard settings.isAutoResumeEnabled else { return }
            logger.info("Network returned — resuming system-paused downloads", category: .network)
            let toResume = pausedBySystem
            pausedBySystem.removeAll()
            for id in toResume {
                _resumeDownload(id: id)
            }
        }
    }

    // MARK: - Private: Persistence

    private func restoreDownloads() {
        do {
            let records = try persistence.loadAll()
            for record in records {
                var item = record.toDownloadItem()
                if item.state == .downloading || item.state == .queued {
                    item.state = .paused
                }
                items[item.id] = item
                if let resumeData = record.resumeData {
                    resumeDataMap[item.id] = resumeData
                }
                if record.headers != nil || record.expectedChecksum != nil {
                    requestMetadata[item.id] = (record.headers, record.expectedChecksum)
                }
            }
            publishUpdates()
            logger.info("Restored \(records.count) downloads from persistence", category: .persistence)
        } catch {
            logger.error("Failed to restore downloads: \(error.localizedDescription)", category: .persistence)
        }
    }

    private func persistState() {
        let records: [DownloadRecord] = items.values.map { item in
            DownloadRecord.from(
                item: item,
                resumeData: resumeDataMap[item.id],
                headers: requestMetadata[item.id]?.headers,
                expectedChecksum: requestMetadata[item.id]?.checksum
            )
        }
        do {
            try persistence.saveAll(records)
        } catch {
            logger.error("Failed to persist state: \(error.localizedDescription)", category: .persistence)
        }
    }

    // MARK: - Private: Core Operations

    private func _startDownload(_ request: DownloadRequest) throws -> UUID {
        guard request.url.scheme?.lowercased() == "https" || request.url.scheme?.lowercased() == "http" else {
            throw DownloadError.invalidURL
        }

        let isDuplicate = items.values.contains { $0.url == request.url && !$0.state.isTerminal }
        if isDuplicate {
            throw DownloadError.duplicateDownload(url: request.url)
        }

        if let totalBytes = (try? diskSpaceManager.availableSpace()), totalBytes < 50_000_000 {
            logger.warning("Low disk space warning: \(ByteCountFormatter.string(fromByteCount: totalBytes, countStyle: .file)) remaining", category: .download)
        }

        let fileName = request.fileName ?? request.url.inferredFileName
        let id = UUID()

        let item = DownloadItem(
            id: id,
            url: request.url,
            fileName: fileName,
            state: .pending,
            priority: request.priority,
            createdDate: Date()
        )

        items[id] = item
        requestMetadata[id] = (request.headers, request.expectedChecksum)
        speedTrackers[id] = SpeedTracker()

        logger.info("Download created: \(fileName) [\(id)]", category: .download)

        scheduleNextDownloads()
        publishUpdates()
        persistState()

        return id
    }

    private func _pauseDownload(id: UUID) {
        guard var item = items[id], item.state == .downloading || item.state == .queued else { return }

        if let task = downloadIdToTask[id] {
            task.cancel(byProducingResumeData: { [weak self] data in
                self?.queue.async {
                    if let data {
                        self?.resumeDataMap[id] = data
                    }
                    self?.persistState()
                }
            })
            cleanupTask(id: id, taskId: task.taskIdentifier)
        }

        item.state = .paused
        item.downloadSpeed = 0
        item.estimatedTimeRemaining = nil
        items[id] = item
        activeCount = max(0, activeCount - 1)

        logger.info("Paused: \(item.fileName) [\(id)]", category: .download)
        publishUpdates()
        persistState()
        scheduleNextDownloads()
    }

    private func _resumeDownload(id: UUID) {
        guard var item = items[id], item.state == .paused || item.state == .pending || item.state == .failed else { return }

        if activeCount >= settings.maxConcurrentDownloads {
            item.state = .queued
            items[id] = item
            publishUpdates()
            return
        }

        item.state = .downloading
        items[id] = item
        speedTrackers[id] = SpeedTracker()

        let task: URLSessionDownloadTask
        if let resumeData = resumeDataMap[id] {
            task = sessionClient.resumeDownloadTask(with: resumeData)
            resumeDataMap[id] = nil
        } else {
            let headers = requestMetadata[id]?.headers
            task = sessionClient.startDownloadTask(with: item.url, headers: headers)
        }

        taskIdToDownloadId[task.taskIdentifier] = id
        downloadIdToTask[id] = task
        activeCount += 1

        logger.info("Resumed: \(item.fileName) [\(id)]", category: .download)
        publishUpdates()
        persistState()
    }

    private func _cancelDownload(id: UUID) {
        guard var item = items[id], !item.state.isTerminal else { return }

        if let task = downloadIdToTask[id] {
            task.cancel()
            cleanupTask(id: id, taskId: task.taskIdentifier)
            activeCount = max(0, activeCount - 1)
        }

        item.state = .cancelled
        item.error = .cancelled
        item.downloadSpeed = 0
        item.estimatedTimeRemaining = nil
        items[id] = item
        resumeDataMap[id] = nil
        pausedBySystem.remove(id)

        logger.info("Cancelled: \(item.fileName) [\(id)]", category: .download)
        publishUpdates()
        persistState()
        finishContinuations(for: id)
        scheduleNextDownloads()
    }

    private func _deleteDownload(id: UUID) {
        guard let item = items[id] else { return }

        if let task = downloadIdToTask[id] {
            task.cancel()
            cleanupTask(id: id, taskId: task.taskIdentifier)
            activeCount = max(0, activeCount - 1)
        }

        if let filePath = item.filePath {
            try? FileManager.default.removeItem(at: filePath)
        }

        items[id] = nil
        resumeDataMap[id] = nil
        requestMetadata[id] = nil
        speedTrackers[id] = nil
        pausedBySystem.remove(id)

        try? persistence.delete(id: id)

        logger.info("Deleted: \(item.fileName) [\(id)]", category: .download)
        publishUpdates()
        finishContinuations(for: id)
        scheduleNextDownloads()
    }

    private func _retryDownload(id: UUID) {
        guard var item = items[id], item.state == .failed || item.state == .cancelled else { return }

        item.state = .pending
        item.error = nil
        item.progress = 0
        item.downloadedBytes = 0
        item.downloadSpeed = 0
        item.estimatedTimeRemaining = nil
        item.retryCount += 1
        items[id] = item
        resumeDataMap[id] = nil

        logger.info("Retrying (\(item.retryCount)): \(item.fileName) [\(id)]", category: .download)
        scheduleNextDownloads()
        publishUpdates()
        persistState()
    }

    // MARK: - Private: Scheduling

    private func scheduleNextDownloads() {
        let maxConcurrent = settings.maxConcurrentDownloads

        while activeCount < maxConcurrent {
            guard let next = nextQueuedItem() else { break }
            _resumeDownload(id: next.id)
        }
    }

    private func nextQueuedItem() -> DownloadItem? {
        items.values
            .filter { $0.state == .pending || $0.state == .queued }
            .sorted { lhs, rhs in
                if lhs.priority != rhs.priority { return lhs.priority < rhs.priority }
                return lhs.createdDate < rhs.createdDate
            }
            .first
    }

    // MARK: - Private: Delegate Handlers

    private func handleProgress(taskId: Int, bytesWritten: Int64, totalWritten: Int64, totalExpected: Int64) {
        guard let downloadId = taskIdToDownloadId[taskId], var item = items[downloadId] else { return }

        let progress = totalExpected > 0 ? Double(totalWritten) / Double(totalExpected) : 0
        item.progress = progress
        item.downloadedBytes = totalWritten
        item.totalBytes = totalExpected > 0 ? totalExpected : nil

        if let tracker = speedTrackers[downloadId] {
            tracker.update(bytesWritten: bytesWritten)
            item.downloadSpeed = tracker.currentSpeed
            if item.downloadSpeed > 0, let total = item.totalBytes {
                let remaining = Double(total - totalWritten)
                item.estimatedTimeRemaining = remaining / item.downloadSpeed
            }
        }

        items[downloadId] = item
        publishUpdates()
        yieldToContinuations(item: item)

        let displayOption = settings.progressDisplayOption
        if displayOption == .notification || displayOption == .both {
            Task { await notificationManager.postProgressNotification(for: item) }
        }
    }

    private func handleFinishedDownloading(taskId: Int, location: URL, response: URLResponse?) {
        guard let downloadId = taskIdToDownloadId[taskId], var item = items[downloadId] else { return }

        if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
            item.state = .failed
            item.error = .httpError(statusCode: httpResponse.statusCode, url: item.url)
            items[downloadId] = item
            publishUpdates()
            persistState()
            return
        }

        item.mimeType = response?.mimeType

        do {
            try FileManager.default.ensureDirectoryExists(at: URL.downloadsDirectory)
            let destinationURL = FileManager.default.uniqueFileURL(
                directory: URL.downloadsDirectory,
                fileName: item.fileName
            )
            try FileManager.default.moveItem(at: location, to: destinationURL)
            item.filePath = destinationURL

            if let expectedChecksum = requestMetadata[downloadId]?.checksum {
                let isValid = try checksumValidator.validate(fileURL: destinationURL, expectedChecksum: expectedChecksum)
                if !isValid {
                    let actual = try checksumValidator.sha256(of: destinationURL)
                    try? FileManager.default.removeItem(at: destinationURL)
                    item.state = .failed
                    item.error = .checksumMismatch(expected: expectedChecksum, actual: actual)
                    items[downloadId] = item
                    publishUpdates()
                    persistState()
                    logger.error("Checksum mismatch for \(item.fileName)", category: .download)
                    return
                }
            }

            item.state = .completed
            item.progress = 1.0
            item.completedDate = Date()
            item.downloadSpeed = 0
            item.estimatedTimeRemaining = nil
            items[downloadId] = item

            logger.info("Completed: \(item.fileName) → \(destinationURL.path)", category: .download)

            let displayOption = settings.progressDisplayOption
            if displayOption == .notification || displayOption == .both {
                Task { await notificationManager.postCompletionNotification(for: item) }
            }

        } catch {
            item.state = .failed
            item.error = .fileSystemError(description: error.localizedDescription)
            items[downloadId] = item
            logger.error("File move failed for \(item.fileName): \(error.localizedDescription)", category: .download)
        }

        publishUpdates()
        persistState()
        yieldToContinuations(item: item)
        if item.state.isTerminal { finishContinuations(for: downloadId) }
    }

    private func handleTaskComplete(taskId: Int, error: Error?) {
        guard let downloadId = taskIdToDownloadId[taskId], var item = items[downloadId] else { return }

        cleanupTask(id: downloadId, taskId: taskId)
        activeCount = max(0, activeCount - 1)

        if item.state == .completed || item.state == .cancelled {
            scheduleNextDownloads()
            return
        }

        if let nsError = error as? NSError {
            if nsError.code == NSURLErrorCancelled {
                if let resumeData = nsError.userInfo[NSURLSessionDownloadTaskResumeData] as? Data {
                    resumeDataMap[downloadId] = resumeData
                }
                if item.state != .paused && item.state != .cancelled {
                    item.state = .paused
                    items[downloadId] = item
                    publishUpdates()
                    persistState()
                }
                scheduleNextDownloads()
                return
            }

            if settings.isAutoRetryEnabled && item.retryCount < settings.maxRetryCount {
                item.retryCount += 1
                item.state = .pending
                items[downloadId] = item
                logger.warning("Scheduling retry \(item.retryCount)/\(settings.maxRetryCount) for \(item.fileName)", category: .download)

                let delay = retryDelay(attempt: item.retryCount)
                DispatchQueue.global().asyncAfter(deadline: .now() + delay) { [weak self] in
                    self?.queue.async {
                        self?.scheduleNextDownloads()
                    }
                }
                publishUpdates()
                persistState()
                return
            }

            item.state = .failed
            item.error = .unknown(description: nsError.localizedDescription)
            item.downloadSpeed = 0
            item.estimatedTimeRemaining = nil
            items[downloadId] = item

            let displayOption = settings.progressDisplayOption
            if displayOption == .notification || displayOption == .both {
                Task { [item] in await notificationManager.postFailureNotification(for: item) }
            }

            logger.error("Failed: \(item.fileName) — \(nsError.localizedDescription)", category: .download)
        }

        publishUpdates()
        persistState()
        yieldToContinuations(item: item)
        if item.state.isTerminal { finishContinuations(for: downloadId) }
        scheduleNextDownloads()
    }

    // MARK: - Private: Helpers

    private func cleanupTask(id: UUID, taskId: Int) {
        taskIdToDownloadId[taskId] = nil
        downloadIdToTask[id] = nil
        speedTrackers[id] = nil
    }

    private func retryDelay(attempt: Int) -> TimeInterval {
        min(pow(2.0, Double(attempt - 1)), 60)
    }

    private func sortedItems() -> [DownloadItem] {
        Array(items.values).sorted { $0.createdDate > $1.createdDate }
    }

    private func publishUpdates() {
        let sorted = sortedItems()
        _downloadsSubject.send(sorted)
    }

    private func yieldToContinuations(item: DownloadItem) {
        guard let conts = progressContinuations[item.id] else { return }
        for cont in conts {
            cont.yield(item)
        }
    }

    private func finishContinuations(for id: UUID) {
        guard let conts = progressContinuations.removeValue(forKey: id) else { return }
        for cont in conts {
            cont.finish()
        }
    }
}

// MARK: - SpeedTracker

/// Exponential moving average speed calculator.
private final class SpeedTracker {
    private var lastUpdate = Date()
    private var accumulatedBytes: Int64 = 0
    private(set) var currentSpeed: Double = 0
    private let smoothingFactor = 0.3
    private let minInterval: TimeInterval = 0.25

    func update(bytesWritten: Int64) {
        accumulatedBytes += bytesWritten
        let now = Date()
        let elapsed = now.timeIntervalSince(lastUpdate)
        guard elapsed >= minInterval else { return }

        let instantSpeed = Double(accumulatedBytes) / elapsed
        if currentSpeed == 0 {
            currentSpeed = instantSpeed
        } else {
            currentSpeed = currentSpeed * (1 - smoothingFactor) + instantSpeed * smoothingFactor
        }
        accumulatedBytes = 0
        lastUpdate = now
    }
}

// MARK: - AsyncStream.Continuation Equatable (by identity)

extension AsyncStream.Continuation: @retroactive Equatable {
    public static func == (lhs: AsyncStream.Continuation, rhs: AsyncStream.Continuation) -> Bool {
        withUnsafePointer(to: lhs) { lhsPtr in
            withUnsafePointer(to: rhs) { rhsPtr in
                lhsPtr == rhsPtr
            }
        }
    }
}
