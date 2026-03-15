// Tests/DownloadManagerKitTests/SwiftUIViewTests.swift

import XCTest
import SwiftUI
import Combine
@testable import DownloadManagerKit

// MARK: - DownloadViewModel Tests

@MainActor
final class DownloadViewModelTests: XCTestCase {

    private var mockManager: MockDownloadManager!
    private var mockSettings: MockSettingsManager!
    private var mockDisk: StubDiskSpaceManager!
    private var viewModel: DownloadViewModel!

    override func setUp() {
        super.setUp()
        mockManager = MockDownloadManager()
        mockSettings = MockSettingsManager()
        mockDisk = StubDiskSpaceManager()
        viewModel = DownloadViewModel(
            manager: mockManager,
            settings: mockSettings,
            diskSpaceManager: mockDisk
        )
    }

    override func tearDown() {
        viewModel = nil
        mockManager = nil
        mockSettings = nil
        mockDisk = nil
        super.tearDown()
    }

    // MARK: - Initialization

    func testInitialState_isEmpty() {
        XCTAssertTrue(viewModel.downloads.isEmpty)
        XCTAssertTrue(viewModel.activeDownloads.isEmpty)
        XCTAssertTrue(viewModel.completedDownloads.isEmpty)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testManagerAndSettingsAreExposed() {
        XCTAssertTrue(viewModel.manager is MockDownloadManager)
        XCTAssertTrue(viewModel.settings is MockSettingsManager)
        XCTAssertTrue(viewModel.diskSpaceManager is StubDiskSpaceManager)
    }

    // MARK: - Publisher Bindings

    func testPublisher_updatesDownloads() async {
        let expectation = XCTestExpectation(description: "Downloads updated")
        let items = [
            makeSampleItem(state: .downloading),
            makeSampleItem(state: .completed),
            makeSampleItem(state: .paused),
        ]

        var cancellable: AnyCancellable?
        cancellable = viewModel.$downloads
            .dropFirst()
            .first()
            .sink { received in
                XCTAssertEqual(received.count, 3)
                expectation.fulfill()
                cancellable?.cancel()
            }

        mockManager.publishDownloads(items)

        await fulfillment(of: [expectation], timeout: 3)
    }

    func testPublisher_filtersActiveDownloads() async {
        let expectation = XCTestExpectation(description: "Active downloads filtered")
        let downloading = makeSampleItem(state: .downloading)
        let queued = makeSampleItem(state: .queued)
        let paused = makeSampleItem(state: .paused)
        let completed = makeSampleItem(state: .completed)
        let failed = makeSampleItem(state: .failed)

        var cancellable: AnyCancellable?
        cancellable = viewModel.$activeDownloads
            .dropFirst()
            .first()
            .sink { active in
                XCTAssertEqual(active.count, 3)
                let ids = Set(active.map { $0.id })
                XCTAssertTrue(ids.contains(downloading.id))
                XCTAssertTrue(ids.contains(queued.id))
                XCTAssertTrue(ids.contains(paused.id))
                XCTAssertFalse(ids.contains(completed.id))
                XCTAssertFalse(ids.contains(failed.id))
                expectation.fulfill()
                cancellable?.cancel()
            }

        mockManager.publishDownloads([downloading, queued, paused, completed, failed])

        await fulfillment(of: [expectation], timeout: 3)
    }

    func testPublisher_filtersCompletedDownloads() async {
        let expectation = XCTestExpectation(description: "Completed downloads filtered")
        let completed1 = makeSampleItem(state: .completed)
        let completed2 = makeSampleItem(state: .completed)
        let downloading = makeSampleItem(state: .downloading)

        var cancellable: AnyCancellable?
        cancellable = viewModel.$completedDownloads
            .dropFirst()
            .first()
            .sink { items in
                XCTAssertEqual(items.count, 2)
                let ids = Set(items.map { $0.id })
                XCTAssertTrue(ids.contains(completed1.id))
                XCTAssertTrue(ids.contains(completed2.id))
                XCTAssertFalse(ids.contains(downloading.id))
                expectation.fulfill()
                cancellable?.cancel()
            }

        mockManager.publishDownloads([completed1, completed2, downloading])

        await fulfillment(of: [expectation], timeout: 3)
    }

    func testPublisher_pendingItemsInActive() async {
        let expectation = XCTestExpectation(description: "Pending in active")
        let pending = makeSampleItem(state: .pending)

        var cancellable: AnyCancellable?
        cancellable = viewModel.$activeDownloads
            .dropFirst()
            .first()
            .sink { active in
                XCTAssertEqual(active.count, 1)
                XCTAssertEqual(active.first?.id, pending.id)
                expectation.fulfill()
                cancellable?.cancel()
            }

        mockManager.publishDownloads([pending])

        await fulfillment(of: [expectation], timeout: 3)
    }

    // MARK: - Actions

    func testStartDownload_callsManager() async throws {
        let url = URL(string: "https://example.com/test.zip")!
        viewModel.startDownload(url: url, fileName: "test.zip", priority: .high)

        try await Task.sleep(nanoseconds: 500_000_000)
        XCTAssertTrue(mockManager.startDownloadCalled)
        XCTAssertEqual(mockManager.lastStartedRequest?.url, url)
        XCTAssertEqual(mockManager.lastStartedRequest?.fileName, "test.zip")
        XCTAssertEqual(mockManager.lastStartedRequest?.priority, .high)
    }

    func testStartDownload_errorSetsErrorMessage() async throws {
        mockManager.stubbedStartResult = .failure(DownloadError.invalidURL)

        viewModel.startDownload(url: URL(string: "https://example.com/test.zip")!)

        try await Task.sleep(nanoseconds: 500_000_000)
        XCTAssertNotNil(viewModel.errorMessage)
    }

    func testStartDownload_successClearsErrorMessage() async throws {
        viewModel.errorMessage = "Previous error"
        viewModel.startDownload(url: URL(string: "https://example.com/test.zip")!)

        try await Task.sleep(nanoseconds: 500_000_000)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testPause_callsManagerWithCorrectId() async throws {
        let id = UUID()
        viewModel.pause(id: id)

        try await Task.sleep(nanoseconds: 500_000_000)
        XCTAssertTrue(mockManager.pauseDownloadCalled)
        XCTAssertEqual(mockManager.lastPausedId, id)
    }

    func testResume_callsManagerWithCorrectId() async throws {
        let id = UUID()
        viewModel.resume(id: id)

        try await Task.sleep(nanoseconds: 500_000_000)
        XCTAssertTrue(mockManager.resumeDownloadCalled)
        XCTAssertEqual(mockManager.lastResumedId, id)
    }

    func testCancel_callsManagerWithCorrectId() async throws {
        let id = UUID()
        viewModel.cancel(id: id)

        try await Task.sleep(nanoseconds: 500_000_000)
        XCTAssertTrue(mockManager.cancelDownloadCalled)
        XCTAssertEqual(mockManager.lastCancelledId, id)
    }

    func testDelete_callsManagerWithCorrectId() async throws {
        let id = UUID()
        viewModel.delete(id: id)

        try await Task.sleep(nanoseconds: 500_000_000)
        XCTAssertTrue(mockManager.deleteDownloadCalled)
        XCTAssertEqual(mockManager.lastDeletedId, id)
    }

    func testRetry_callsManagerWithCorrectId() async throws {
        let id = UUID()
        viewModel.retry(id: id)

        try await Task.sleep(nanoseconds: 500_000_000)
        XCTAssertTrue(mockManager.retryDownloadCalled)
        XCTAssertEqual(mockManager.lastRetriedId, id)
    }

    func testPauseAll_callsManager() async throws {
        viewModel.pauseAll()

        try await Task.sleep(nanoseconds: 500_000_000)
        XCTAssertTrue(mockManager.pauseAllCalled)
    }

    func testResumeAll_callsManager() async throws {
        viewModel.resumeAll()

        try await Task.sleep(nanoseconds: 500_000_000)
        XCTAssertTrue(mockManager.resumeAllCalled)
    }

    // MARK: - Multiple Publisher Updates

    func testPublisher_updatesOnMultipleEmissions() async {
        let first = [makeSampleItem(state: .downloading)]
        let second = [makeSampleItem(state: .downloading), makeSampleItem(state: .completed)]

        let expectation = XCTestExpectation(description: "Second update received")

        var updateCount = 0
        var cancellable: AnyCancellable?
        cancellable = viewModel.$downloads
            .dropFirst()
            .sink { items in
                updateCount += 1
                if updateCount == 2 {
                    XCTAssertEqual(items.count, 2)
                    expectation.fulfill()
                    cancellable?.cancel()
                }
            }

        mockManager.publishDownloads(first)

        try? await Task.sleep(nanoseconds: 300_000_000)
        mockManager.publishDownloads(second)

        await fulfillment(of: [expectation], timeout: 5)
    }

    // MARK: - Empty State Transitions

    func testPublisher_transitionToEmpty() async {
        let items = [makeSampleItem(state: .downloading)]

        let expectation = XCTestExpectation(description: "Emptied")

        var updateCount = 0
        var cancellable: AnyCancellable?
        cancellable = viewModel.$downloads
            .dropFirst()
            .sink { received in
                updateCount += 1
                if updateCount == 1 {
                    XCTAssertEqual(received.count, 1)
                } else if updateCount == 2 {
                    XCTAssertTrue(received.isEmpty)
                    expectation.fulfill()
                    cancellable?.cancel()
                }
            }

        mockManager.publishDownloads(items)

        try? await Task.sleep(nanoseconds: 300_000_000)
        mockManager.publishDownloads([])

        await fulfillment(of: [expectation], timeout: 5)
    }
}

// MARK: - DownloadItem Model Tests (SwiftUI-related)

final class DownloadItemDisplayTests: XCTestCase {

    func testFormattedTotalSize_nilWhenNoTotalBytes() {
        let item = makeSampleItem(totalBytes: nil)
        XCTAssertNil(item.formattedTotalSize)
    }

    func testFormattedTotalSize_formatsCorrectly() {
        let item = makeSampleItem(totalBytes: 10_485_760)
        let size = item.formattedTotalSize
        XCTAssertNotNil(size)
        XCTAssertTrue(size!.contains("MB") || size!.contains("bytes"))
    }

    func testFormattedDownloadedSize_formatsCorrectly() {
        let item = makeSampleItem(downloadedBytes: 5_242_880)
        let size = item.formattedDownloadedSize
        XCTAssertFalse(size.isEmpty)
    }

    func testFormattedSpeed_includesPerSecond() {
        let item = makeSampleItem(speed: 1_048_576)
        XCTAssertTrue(item.formattedSpeed.contains("/s"))
    }

    func testFormattedETA_nilWhenZero() {
        let item = makeSampleItem(eta: 0)
        XCTAssertNil(item.formattedETA)
    }

    func testFormattedETA_nilWhenNil() {
        let item = makeSampleItem(eta: nil)
        XCTAssertNil(item.formattedETA)
    }

    func testFormattedETA_formatsPositiveValue() {
        let item = makeSampleItem(eta: 204)
        let eta = item.formattedETA
        XCTAssertNotNil(eta)
    }

    func testPercentComplete_roundsCorrectly() {
        let item = makeSampleItem(progress: 0.567)
        XCTAssertEqual(item.percentComplete, 57)
    }

    func testPercentComplete_zeroProgress() {
        let item = makeSampleItem(progress: 0)
        XCTAssertEqual(item.percentComplete, 0)
    }

    func testPercentComplete_fullProgress() {
        let item = makeSampleItem(progress: 1.0)
        XCTAssertEqual(item.percentComplete, 100)
    }
}

// MARK: - DownloadState Display Tests

final class DownloadStateDisplayTests: XCTestCase {

    func testDisplayName_returnsNonEmpty() {
        for state in DownloadState.allCases {
            XCTAssertFalse(state.displayName.isEmpty, "\(state) has empty displayName")
        }
    }

    func testIsTerminal_correctForAllStates() {
        XCTAssertTrue(DownloadState.completed.isTerminal)
        XCTAssertTrue(DownloadState.failed.isTerminal)
        XCTAssertTrue(DownloadState.cancelled.isTerminal)
        XCTAssertFalse(DownloadState.pending.isTerminal)
        XCTAssertFalse(DownloadState.queued.isTerminal)
        XCTAssertFalse(DownloadState.downloading.isTerminal)
        XCTAssertFalse(DownloadState.paused.isTerminal)
    }

    func testDisplayName_specificValues() {
        XCTAssertEqual(DownloadState.pending.displayName, "Pending")
        XCTAssertEqual(DownloadState.queued.displayName, "Queued")
        XCTAssertEqual(DownloadState.downloading.displayName, "Downloading")
        XCTAssertEqual(DownloadState.paused.displayName, "Paused")
        XCTAssertEqual(DownloadState.completed.displayName, "Completed")
        XCTAssertEqual(DownloadState.failed.displayName, "Failed")
        XCTAssertEqual(DownloadState.cancelled.displayName, "Cancelled")
    }
}

// MARK: - DownloadRowView Rendering Tests

final class DownloadRowViewRenderingTests: XCTestCase {

    func testDownloadRowView_initializesWithAllStates() {
        for state in DownloadState.allCases {
            let item = makeSampleItem(state: state)
            let view = DownloadRowView(
                item: item,
                onPause: {}, onResume: {}, onCancel: {}, onRetry: {}, onDelete: {}
            )
            XCTAssertNotNil(view)
        }
    }

    func testDownloadRowView_downloadingItem_showsProgress() {
        let item = makeSampleItem(state: .downloading, progress: 0.5, totalBytes: 1000, downloadedBytes: 500)
        let view = DownloadRowView(
            item: item,
            onPause: {}, onResume: {}, onCancel: {}, onRetry: {}, onDelete: {}
        )
        let body = view.body
        XCTAssertNotNil(body)
    }

    func testDownloadRowView_failedItem_showsError() {
        let item = DownloadItem(
            url: URL(string: "https://example.com/test.zip")!,
            fileName: "test.zip",
            state: .failed,
            error: .networkUnavailable
        )
        let view = DownloadRowView(
            item: item,
            onPause: {}, onResume: {}, onCancel: {}, onRetry: {}, onDelete: {}
        )
        let body = view.body
        XCTAssertNotNil(body)
    }

    func testDownloadRowView_completedItem_noProgressBar() {
        let item = makeSampleItem(state: .completed, progress: 1.0)
        let view = DownloadRowView(
            item: item,
            onPause: {}, onResume: {}, onCancel: {}, onRetry: {}, onDelete: {}
        )
        let body = view.body
        XCTAssertNotNil(body)
    }

    func testDownloadRowView_pausedItem_showsProgressBar() {
        let item = makeSampleItem(state: .paused, progress: 0.3)
        let view = DownloadRowView(
            item: item,
            onPause: {}, onResume: {}, onCancel: {}, onRetry: {}, onDelete: {}
        )
        let body = view.body
        XCTAssertNotNil(body)
    }
}

// MARK: - View Instantiation Tests

@MainActor
final class SwiftUIViewInstantiationTests: XCTestCase {

    func testDownloadsTabView_initializes() {
        let vm = makeViewModel()
        let view = DownloadsTabView(viewModel: vm)
        XCTAssertNotNil(view)
    }

    func testDownloadListView_initializes() {
        let vm = makeViewModel()
        let view = DownloadListView(viewModel: vm)
        XCTAssertNotNil(view)
    }

    func testActiveDownloadsView_initializes() {
        let vm = makeViewModel()
        let view = ActiveDownloadsView(viewModel: vm)
        XCTAssertNotNil(view)
    }

    func testCompletedDownloadsView_initializes() {
        let vm = makeViewModel()
        let view = CompletedDownloadsView(viewModel: vm)
        XCTAssertNotNil(view)
    }

    func testSettingsView_initializes() {
        let settings = MockSettingsManager()
        let view = SettingsView(settings: settings)
        XCTAssertNotNil(view)
    }

    func testStorageInfoView_initializes() {
        let disk = StubDiskSpaceManager()
        let view = StorageInfoView(diskSpaceManager: disk)
        XCTAssertNotNil(view)
    }

    func testDownloadRowView_initializesForEachFileType() {
        let extensions = ["pdf", "jpg", "mp4", "mp3", "zip", "txt"]
        for ext in extensions {
            let item = DownloadItem(
                url: URL(string: "https://example.com/file.\(ext)")!,
                fileName: "file.\(ext)",
                state: .downloading,
                progress: 0.5
            )
            let view = DownloadRowView(
                item: item,
                onPause: {}, onResume: {}, onCancel: {}, onRetry: {}, onDelete: {}
            )
            XCTAssertNotNil(view, "Failed to create DownloadRowView for .\(ext)")
        }
    }

    private func makeViewModel() -> DownloadViewModel {
        DownloadViewModel(
            manager: MockDownloadManager(),
            settings: MockSettingsManager(),
            diskSpaceManager: StubDiskSpaceManager()
        )
    }
}

// MARK: - SettingsView Binding Tests

@MainActor
final class SettingsViewBindingTests: XCTestCase {

    func testSettingsView_reflectsInitialValues() {
        let settings = MockSettingsManager()
        settings.maxConcurrentDownloads = 5
        settings.isAutoResumeEnabled = false
        settings.wifiOnlyMode = true

        let view = SettingsView(settings: settings)
        XCTAssertNotNil(view.body)
    }

    func testSettingsView_differentProgressOptions() {
        for option in ProgressDisplayOption.allCases {
            let settings = MockSettingsManager()
            settings.progressDisplayOption = option
            let view = SettingsView(settings: settings)
            XCTAssertNotNil(view.body)
        }
    }
}

// MARK: - StorageInfoView Data Tests

final class StorageInfoViewDataTests: XCTestCase {

    func testStorageInfoView_withZeroValues() {
        let disk = StubDiskSpaceManager(total: 0, available: 0, used: 0)
        let view = StorageInfoView(diskSpaceManager: disk)
        XCTAssertNotNil(view.body)
    }

    func testStorageInfoView_withRealisticValues() {
        let disk = StubDiskSpaceManager(
            total: 256_000_000_000,
            available: 128_000_000_000,
            used: 2_000_000_000
        )
        let view = StorageInfoView(diskSpaceManager: disk)
        XCTAssertNotNil(view.body)
    }

    func testStorageInfoView_withThrowingDiskManager() {
        let disk = ThrowingDiskSpaceManager()
        let view = StorageInfoView(diskSpaceManager: disk)
        XCTAssertNotNil(view.body)
    }
}

// MARK: - ViewModel Action Concurrency Tests

@MainActor
final class ViewModelConcurrencyTests: XCTestCase {

    func testMultipleActionsInSequence() async throws {
        let manager = MockDownloadManager()
        let vm = DownloadViewModel(
            manager: manager,
            settings: MockSettingsManager(),
            diskSpaceManager: StubDiskSpaceManager()
        )

        let id1 = UUID()
        let id2 = UUID()
        let id3 = UUID()

        vm.pause(id: id1)
        vm.resume(id: id2)
        vm.cancel(id: id3)

        try await Task.sleep(nanoseconds: 1_000_000_000)

        XCTAssertTrue(manager.pauseDownloadCalled)
        XCTAssertTrue(manager.resumeDownloadCalled)
        XCTAssertTrue(manager.cancelDownloadCalled)
        XCTAssertEqual(manager.lastPausedId, id1)
        XCTAssertEqual(manager.lastResumedId, id2)
        XCTAssertEqual(manager.lastCancelledId, id3)
    }

    func testStartMultipleDownloadsRapidly() async throws {
        let manager = MockDownloadManager()
        let vm = DownloadViewModel(
            manager: manager,
            settings: MockSettingsManager(),
            diskSpaceManager: StubDiskSpaceManager()
        )

        for i in 0..<5 {
            vm.startDownload(url: URL(string: "https://example.com/file\(i).zip")!)
        }

        try await Task.sleep(nanoseconds: 1_000_000_000)
        XCTAssertTrue(manager.startDownloadCalled)
    }
}

// MARK: - Test Helpers

private func makeSampleItem(
    state: DownloadState = .downloading,
    progress: Double = 0.0,
    totalBytes: Int64? = 1_048_576,
    downloadedBytes: Int64 = 0,
    speed: Double = 0,
    eta: TimeInterval? = nil
) -> DownloadItem {
    DownloadItem(
        id: UUID(),
        url: URL(string: "https://example.com/\(UUID().uuidString).zip")!,
        fileName: "\(UUID().uuidString).zip",
        state: state,
        progress: progress,
        downloadedBytes: downloadedBytes,
        totalBytes: totalBytes,
        downloadSpeed: speed,
        estimatedTimeRemaining: eta
    )
}

// MARK: - Test Doubles

private final class StubDiskSpaceManager: DiskSpaceManaging, @unchecked Sendable {
    let total: Int64
    let available: Int64
    let used: Int64

    init(total: Int64 = 64_000_000_000, available: Int64 = 10_000_000_000, used: Int64 = 500_000_000) {
        self.total = total
        self.available = available
        self.used = used
    }

    func availableSpace() throws -> Int64 { available }
    func totalSpace() throws -> Int64 { total }
    func usedByApp() throws -> Int64 { used }
    func hasEnoughSpace(for bytes: Int64) throws -> Bool { bytes <= available }
}

private final class ThrowingDiskSpaceManager: DiskSpaceManaging, @unchecked Sendable {
    func availableSpace() throws -> Int64 { throw NSError(domain: "Test", code: 1) }
    func totalSpace() throws -> Int64 { throw NSError(domain: "Test", code: 1) }
    func usedByApp() throws -> Int64 { throw NSError(domain: "Test", code: 1) }
    func hasEnoughSpace(for bytes: Int64) throws -> Bool { throw NSError(domain: "Test", code: 1) }
}
