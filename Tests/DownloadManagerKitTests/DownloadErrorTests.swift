// Tests/DownloadManagerKitTests/DownloadErrorTests.swift

import XCTest
@testable import DownloadManagerKit

final class DownloadErrorTests: XCTestCase {

    func testLocalizedDescription_invalidURL() {
        let error = DownloadError.invalidURL
        XCTAssertFalse(error.localizedDescription.isEmpty)
        XCTAssertTrue(error.localizedDescription.lowercased().contains("invalid"))
    }

    func testLocalizedDescription_duplicateDownload() {
        let url = URL(string: "https://example.com/file.zip")!
        let error = DownloadError.duplicateDownload(url: url)
        XCTAssertTrue(error.localizedDescription.contains("example.com"))
    }

    func testLocalizedDescription_networkUnavailable() {
        let error = DownloadError.networkUnavailable
        XCTAssertFalse(error.localizedDescription.isEmpty)
    }

    func testLocalizedDescription_httpError() {
        let url = URL(string: "https://example.com/file.zip")!
        let error = DownloadError.httpError(statusCode: 404, url: url)
        XCTAssertTrue(error.localizedDescription.contains("404"))
    }

    func testLocalizedDescription_diskFull() {
        let error = DownloadError.diskFull(requiredBytes: 1_000_000_000, availableBytes: 100_000_000)
        XCTAssertFalse(error.localizedDescription.isEmpty)
    }

    func testLocalizedDescription_checksumMismatch() {
        let error = DownloadError.checksumMismatch(expected: "abc123", actual: "def456")
        XCTAssertTrue(error.localizedDescription.contains("abc123"))
        XCTAssertTrue(error.localizedDescription.contains("def456"))
    }

    func testLocalizedDescription_maxRetriesExceeded() {
        let url = URL(string: "https://example.com/file.zip")!
        let error = DownloadError.maxRetriesExceeded(url: url, attempts: 3)
        XCTAssertTrue(error.localizedDescription.contains("3"))
    }

    func testLocalizedDescription_cancelled() {
        let error = DownloadError.cancelled
        XCTAssertFalse(error.localizedDescription.isEmpty)
    }

    // MARK: - Equatable

    func testEquatable_sameCase() {
        XCTAssertEqual(DownloadError.invalidURL, DownloadError.invalidURL)
        XCTAssertEqual(DownloadError.cancelled, DownloadError.cancelled)
        XCTAssertEqual(DownloadError.networkUnavailable, DownloadError.networkUnavailable)
    }

    func testEquatable_differentCases() {
        XCTAssertNotEqual(DownloadError.invalidURL, DownloadError.cancelled)
    }

    func testEquatable_associatedValues() {
        let url = URL(string: "https://example.com/file.zip")!
        XCTAssertEqual(
            DownloadError.httpError(statusCode: 404, url: url),
            DownloadError.httpError(statusCode: 404, url: url)
        )
        XCTAssertNotEqual(
            DownloadError.httpError(statusCode: 404, url: url),
            DownloadError.httpError(statusCode: 500, url: url)
        )
    }

    // MARK: - DownloadState

    func testDownloadState_isTerminal() {
        XCTAssertTrue(DownloadState.completed.isTerminal)
        XCTAssertTrue(DownloadState.failed.isTerminal)
        XCTAssertTrue(DownloadState.cancelled.isTerminal)
        XCTAssertFalse(DownloadState.downloading.isTerminal)
        XCTAssertFalse(DownloadState.pending.isTerminal)
        XCTAssertFalse(DownloadState.paused.isTerminal)
        XCTAssertFalse(DownloadState.queued.isTerminal)
    }

    func testDownloadState_displayName_notEmpty() {
        for state in DownloadState.allCases {
            XCTAssertFalse(state.displayName.isEmpty, "\(state) has empty display name")
        }
    }

    // MARK: - DownloadPriority

    func testDownloadPriority_ordering() {
        XCTAssertTrue(DownloadPriority.high < DownloadPriority.normal)
        XCTAssertTrue(DownloadPriority.normal < DownloadPriority.low)
        XCTAssertTrue(DownloadPriority.high < DownloadPriority.low)
    }
}
