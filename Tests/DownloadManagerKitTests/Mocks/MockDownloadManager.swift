// Tests/DownloadManagerKitTests/Mocks/MockDownloadManager.swift

import Foundation
import Combine
@testable import DownloadManagerKit

final class MockDownloadManager: DownloadManaging, @unchecked Sendable {

    // MARK: - Call Tracking

    var startDownloadCalled = false
    var pauseDownloadCalled = false
    var resumeDownloadCalled = false
    var cancelDownloadCalled = false
    var deleteDownloadCalled = false
    var retryDownloadCalled = false
    var pauseAllCalled = false
    var resumeAllCalled = false
    var startCalled = false

    var lastStartedRequest: DownloadRequest?
    var lastPausedId: UUID?
    var lastResumedId: UUID?
    var lastCancelledId: UUID?
    var lastDeletedId: UUID?
    var lastRetriedId: UUID?

    // MARK: - Stubbed Responses

    var stubbedStartResult: Result<UUID, Error> = .success(UUID())
    var stubbedDownloads: [DownloadItem] = []

    private let _subject = CurrentValueSubject<[DownloadItem], Never>([])

    var downloadsPublisher: AnyPublisher<[DownloadItem], Never> {
        _subject.eraseToAnyPublisher()
    }

    func publishDownloads(_ items: [DownloadItem]) {
        stubbedDownloads = items
        _subject.send(items)
    }

    // MARK: - Protocol Conformance

    @discardableResult
    func startDownload(_ request: DownloadRequest) async throws -> UUID {
        startDownloadCalled = true
        lastStartedRequest = request
        return try stubbedStartResult.get()
    }

    func pauseDownload(id: UUID) async throws {
        pauseDownloadCalled = true
        lastPausedId = id
    }

    func resumeDownload(id: UUID) async throws {
        resumeDownloadCalled = true
        lastResumedId = id
    }

    func cancelDownload(id: UUID) async throws {
        cancelDownloadCalled = true
        lastCancelledId = id
    }

    func deleteDownload(id: UUID) async throws {
        deleteDownloadCalled = true
        lastDeletedId = id
    }

    func retryDownload(id: UUID) async throws {
        retryDownloadCalled = true
        lastRetriedId = id
    }

    func pauseAll() async {
        pauseAllCalled = true
    }

    func resumeAll() async {
        resumeAllCalled = true
    }

    func getDownload(id: UUID) async -> DownloadItem? {
        stubbedDownloads.first { $0.id == id }
    }

    func getAllDownloads() async -> [DownloadItem] {
        stubbedDownloads
    }

    func progressStream(for id: UUID) async -> AsyncStream<DownloadItem> {
        AsyncStream { continuation in
            if let item = stubbedDownloads.first(where: { $0.id == id }) {
                continuation.yield(item)
            }
            continuation.finish()
        }
    }

    func start() async {
        startCalled = true
    }
}
