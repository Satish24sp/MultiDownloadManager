// Tests/DownloadManagerKitTests/Mocks/MockNetworkMonitor.swift

import Foundation
import Combine
@testable import DownloadManagerKit

final class MockNetworkMonitor: NetworkMonitoring, @unchecked Sendable {

    var isConnected: Bool = true
    var connectionType: ConnectionType = .wifi
    var startCalled = false
    var stopCalled = false

    private let _subject = CurrentValueSubject<NetworkStatus, Never>(
        NetworkStatus(isConnected: true, connectionType: .wifi)
    )

    var networkStatusPublisher: AnyPublisher<NetworkStatus, Never> {
        _subject.eraseToAnyPublisher()
    }

    func start() {
        startCalled = true
    }

    func stop() {
        stopCalled = true
    }

    /// Simulate a network status change.
    func simulateStatusChange(isConnected: Bool, type: ConnectionType) {
        self.isConnected = isConnected
        self.connectionType = type
        _subject.send(NetworkStatus(isConnected: isConnected, connectionType: type))
    }
}
