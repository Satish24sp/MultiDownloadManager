// Tests/DownloadManagerKitTests/SettingsManagerTests.swift

import XCTest
@testable import DownloadManagerKit

final class SettingsManagerTests: XCTestCase {

    private var settings: DefaultSettingsManager!
    private let suite = UserDefaults(suiteName: "com.downloadmanagerkit.tests")!

    override func setUp() {
        suite.removePersistentDomain(forName: "com.downloadmanagerkit.tests")
        settings = DefaultSettingsManager(defaults: suite, keyPrefix: "test.")
    }

    // MARK: - Defaults

    func testDefaults_progressDisplayOption() {
        XCTAssertEqual(settings.progressDisplayOption, .inApp)
    }

    func testDefaults_maxConcurrentDownloads() {
        XCTAssertEqual(settings.maxConcurrentDownloads, 3)
    }

    func testDefaults_autoResume() {
        XCTAssertTrue(settings.isAutoResumeEnabled)
    }

    func testDefaults_autoRetry() {
        XCTAssertTrue(settings.isAutoRetryEnabled)
    }

    func testDefaults_maxRetryCount() {
        XCTAssertEqual(settings.maxRetryCount, 3)
    }

    func testDefaults_allowsCellular() {
        XCTAssertTrue(settings.allowsCellularDownloads)
    }

    func testDefaults_wifiOnlyMode() {
        XCTAssertFalse(settings.wifiOnlyMode)
    }

    // MARK: - Write and Read

    func testProgressDisplayOption_persistence() {
        settings.progressDisplayOption = .both
        XCTAssertEqual(settings.progressDisplayOption, .both)

        settings.progressDisplayOption = .notification
        XCTAssertEqual(settings.progressDisplayOption, .notification)
    }

    func testMaxConcurrentDownloads_persistence() {
        settings.maxConcurrentDownloads = 5
        XCTAssertEqual(settings.maxConcurrentDownloads, 5)
    }

    func testMaxConcurrentDownloads_clampedToMin1() {
        settings.maxConcurrentDownloads = 0
        XCTAssertEqual(settings.maxConcurrentDownloads, 1)
    }

    func testAutoResume_persistence() {
        settings.isAutoResumeEnabled = false
        XCTAssertFalse(settings.isAutoResumeEnabled)
    }

    func testAutoRetry_persistence() {
        settings.isAutoRetryEnabled = false
        XCTAssertFalse(settings.isAutoRetryEnabled)
    }

    func testMaxRetryCount_persistence() {
        settings.maxRetryCount = 7
        XCTAssertEqual(settings.maxRetryCount, 7)
    }

    func testMaxRetryCount_clampedToMin0() {
        settings.maxRetryCount = -1
        XCTAssertEqual(settings.maxRetryCount, 0)
    }

    func testAllowsCellular_persistence() {
        settings.allowsCellularDownloads = false
        XCTAssertFalse(settings.allowsCellularDownloads)
    }

    func testWifiOnlyMode_persistence() {
        settings.wifiOnlyMode = true
        XCTAssertTrue(settings.wifiOnlyMode)
    }

    // MARK: - Cross-Instance Persistence

    func testValues_persistAcrossInstances() {
        settings.maxConcurrentDownloads = 8
        settings.wifiOnlyMode = true

        let newInstance = DefaultSettingsManager(defaults: suite, keyPrefix: "test.")
        XCTAssertEqual(newInstance.maxConcurrentDownloads, 8)
        XCTAssertTrue(newInstance.wifiOnlyMode)
    }
}
