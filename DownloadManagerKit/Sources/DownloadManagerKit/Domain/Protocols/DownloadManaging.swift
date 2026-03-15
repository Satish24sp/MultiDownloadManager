// DownloadManagerKit/Sources/DownloadManagerKit/Domain/Protocols/DownloadManaging.swift

import Foundation
import Combine

/// Primary API surface for managing file downloads.
/// All implementations must be thread-safe.
public protocol DownloadManaging: AnyObject, Sendable {

    /// Enqueue a new download. Returns the unique identifier assigned to it.
    /// - Throws: `DownloadError.duplicateDownload` if the URL is already being downloaded.
    /// - Throws: `DownloadError.diskFull` if insufficient space is available.
    @discardableResult
    func startDownload(_ request: DownloadRequest) async throws -> UUID

    /// Pause an active download, preserving resume data when possible.
    func pauseDownload(id: UUID) async throws

    /// Resume a paused download using stored resume data.
    func resumeDownload(id: UUID) async throws

    /// Cancel a download and clean up any temporary files.
    func cancelDownload(id: UUID) async throws

    /// Remove a download record and its file from disk.
    func deleteDownload(id: UUID) async throws

    /// Retry a failed download (respects max retry count).
    func retryDownload(id: UUID) async throws

    /// Pause all active downloads.
    func pauseAll() async

    /// Resume all paused downloads.
    func resumeAll() async

    /// Retrieve a snapshot of a single download by its identifier.
    func getDownload(id: UUID) async -> DownloadItem?

    /// Retrieve snapshots of all tracked downloads.
    func getAllDownloads() async -> [DownloadItem]

    // MARK: - Reactive Streams

    /// Combine publisher that emits the full download list on every change.
    var downloadsPublisher: AnyPublisher<[DownloadItem], Never> { get }

    /// Async stream of updates for a specific download.
    func progressStream(for id: UUID) async -> AsyncStream<DownloadItem>

    // MARK: - Lifecycle

    /// Complete initial setup: load persisted state, observe network, wire delegate callbacks.
    /// Must be called once after initialization before using the manager.
    func start() async
}
