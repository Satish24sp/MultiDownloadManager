// Tests/DownloadManagerKitTests/NetworkMonitorTests.swift

import XCTest
import Combine
@testable import DownloadManagerKit

final class NetworkMonitorTests: XCTestCase {

    private var mock: MockNetworkMonitor!
    private var cancellables: Set<AnyCancellable>!

    override func setUp() {
        mock = MockNetworkMonitor()
        cancellables = Set<AnyCancellable>()
    }

    override func tearDown() {
        cancellables = nil
        mock = nil
    }

    func testInitialState_isConnected() {
        XCTAssertTrue(mock.isConnected)
        XCTAssertEqual(mock.connectionType, .wifi)
    }

    func testSimulateDisconnect_publishesUpdate() {
        let expectation = XCTestExpectation(description: "Disconnect published")

        mock.networkStatusPublisher
            .dropFirst()
            .sink { status in
                XCTAssertFalse(status.isConnected)
                XCTAssertEqual(status.connectionType, .unknown)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        mock.simulateStatusChange(isConnected: false, type: .unknown)
        wait(for: [expectation], timeout: 2)
    }

    func testSimulateCellular_publishesCorrectType() {
        let expectation = XCTestExpectation(description: "Cellular published")

        mock.networkStatusPublisher
            .dropFirst()
            .sink { status in
                XCTAssertTrue(status.isConnected)
                XCTAssertEqual(status.connectionType, .cellular)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        mock.simulateStatusChange(isConnected: true, type: .cellular)
        wait(for: [expectation], timeout: 2)
    }

    func testStartAndStop_tracksCallState() {
        mock.start()
        XCTAssertTrue(mock.startCalled)

        mock.stop()
        XCTAssertTrue(mock.stopCalled)
    }
}
