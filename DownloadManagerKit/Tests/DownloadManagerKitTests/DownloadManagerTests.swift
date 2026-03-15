// Tests/DownloadManagerKitTests/DownloadManagerTests.swift

import XCTest
import Combine
@testable import DownloadManagerKit

final class DownloadManagerTests: XCTestCase {

    private var manager: DefaultDownloadManager!
    private var persistence: MockDownloadPersistence!
    private var networkMonitor: MockNetworkMonitor!
    private var settings: MockSettingsManager!
    private var logger: MockLogger!
    private var cancellables: Set<AnyCancellable>!

    override func setUp() async throws {
        persistence = MockDownloadPersistence()
        networkMonitor = MockNetworkMonitor()
        settings = MockSettingsManager()
        logger = MockLogger()
        cancellables = Set<AnyCancellable>()

        manager = DefaultDownloadManager(
            persistence: persistence,
            networkMonitor: networkMonitor,
            settings: settings,
            logger: logger,
            notificationManager: MockNotificationManager(),
            diskSpaceManager: MockDiskSpaceManager(),
            checksumValidator: MockChecksumValidator(),
            backgroundSessionIdentifier: "com.tests.background.\(UUID().uuidString)"
        )
        await manager.start()
    }

    override func tearDown() {
        cancellables = nil
        manager = nil
    }

    // MARK: - Start Download

    func testStartDownload_createsItemAndReturnsId() async throws {
        let url = URL(string: "https://example.com/file.zip")!
        let request = DownloadRequest(url: url)

        let id = try await manager.startDownload(request)
        let item = await manager.getDownload(id: id)

        XCTAssertNotNil(item)
        XCTAssertEqual(item?.url, url)
        XCTAssertEqual(item?.fileName, "file.zip")
    }

    func testStartDownload_duplicateURL_throws() async throws {
        let url = URL(string: "https://example.com/file.zip")!
        _ = try await manager.startDownload(DownloadRequest(url: url))

        do {
            _ = try await manager.startDownload(DownloadRequest(url: url))
            XCTFail("Expected duplicate download error")
        } catch let error as DownloadError {
            if case .duplicateDownload(let errorURL) = error {
                XCTAssertEqual(errorURL, url)
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        }
    }

    func testStartDownload_invalidScheme_throws() async {
        let url = URL(string: "ftp://example.com/file.zip")!
        do {
            _ = try await manager.startDownload(DownloadRequest(url: url))
            XCTFail("Expected invalid URL error")
        } catch let error as DownloadError {
            XCTAssertEqual(error, .invalidURL)
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    // MARK: - Priority Ordering

    func testPriorityOrdering() async throws {
        settings.maxConcurrentDownloads = 1

        let low = try await manager.startDownload(
            DownloadRequest(url: URL(string: "https://example.com/low.zip")!, priority: .low)
        )
        let high = try await manager.startDownload(
            DownloadRequest(url: URL(string: "https://example.com/high.zip")!, priority: .high)
        )

        let all = await manager.getAllDownloads()
        let highItem = all.first { $0.id == high }
        let lowItem = all.first { $0.id == low }

        XCTAssertNotNil(highItem)
        XCTAssertNotNil(lowItem)
        XCTAssertTrue(highItem!.priority < lowItem!.priority)
    }

    // MARK: - Cancel

    func testCancelDownload_setsStateToCancelled() async throws {
        let url = URL(string: "https://example.com/file.zip")!
        let id = try await manager.startDownload(DownloadRequest(url: url))

        try await manager.cancelDownload(id: id)

        let item = await manager.getDownload(id: id)
        XCTAssertEqual(item?.state, .cancelled)
    }

    // MARK: - Delete

    func testDeleteDownload_removesItem() async throws {
        let url = URL(string: "https://example.com/file.zip")!
        let id = try await manager.startDownload(DownloadRequest(url: url))

        try await manager.deleteDownload(id: id)

        let item = await manager.getDownload(id: id)
        XCTAssertNil(item)
    }

    // MARK: - Combine Publisher

    func testDownloadsPublisher_emitsOnChange() async throws {
        let expectation = XCTestExpectation(description: "Publisher emits")
        var receivedItems: [DownloadItem] = []

        manager.downloadsPublisher
            .dropFirst()
            .first()
            .sink { items in
                receivedItems = items
                expectation.fulfill()
            }
            .store(in: &cancellables)

        let url = URL(string: "https://example.com/file.zip")!
        _ = try await manager.startDownload(DownloadRequest(url: url))

        await fulfillment(of: [expectation], timeout: 5)
        XCTAssertFalse(receivedItems.isEmpty)
    }

    // MARK: - Persistence Integration

    func testPersistence_calledOnStart() async throws {
        let url = URL(string: "https://example.com/file.zip")!
        _ = try await manager.startDownload(DownloadRequest(url: url))

        XCTAssertTrue(persistence.saveAllCalled)
    }

    // MARK: - Get All Downloads

    func testGetAllDownloads_returnsAllItems() async throws {
        _ = try await manager.startDownload(DownloadRequest(url: URL(string: "https://example.com/a.zip")!))
        _ = try await manager.startDownload(DownloadRequest(url: URL(string: "https://example.com/b.zip")!))

        let all = await manager.getAllDownloads()
        XCTAssertEqual(all.count, 2)
    }
}

// MARK: - Additional Mocks for Tests

private final class MockNotificationManager: NotificationManaging, @unchecked Sendable {
    func requestAuthorization() async throws -> Bool { true }
    func postProgressNotification(for item: DownloadItem) async {}
    func postCompletionNotification(for item: DownloadItem) async {}
    func postFailureNotification(for item: DownloadItem) async {}
    func removeNotification(for downloadId: UUID) async {}
    func removeAllNotifications() async {}
}

private final class MockDiskSpaceManager: DiskSpaceManaging, @unchecked Sendable {
    func availableSpace() throws -> Int64 { 10_000_000_000 }
    func totalSpace() throws -> Int64 { 64_000_000_000 }
    func usedByApp() throws -> Int64 { 500_000_000 }
    func hasEnoughSpace(for bytes: Int64) throws -> Bool { true }
}

private final class MockChecksumValidator: ChecksumValidating, @unchecked Sendable {
    func sha256(of fileURL: URL) throws -> String { "mockhash" }
    func validate(fileURL: URL, expectedChecksum: String) throws -> Bool { true }
}
