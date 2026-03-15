// DownloadManagerKit/Sources/DownloadManagerKit/Domain/Protocols/NetworkMonitoring.swift

import Foundation
import Combine

/// Observes network reachability and interface type.
public protocol NetworkMonitoring: AnyObject, Sendable {

    /// Current reachability snapshot.
    var isConnected: Bool { get }

    /// Current network interface type.
    var connectionType: ConnectionType { get }

    /// Publisher that emits whenever network status changes.
    var networkStatusPublisher: AnyPublisher<NetworkStatus, Never> { get }

    /// Begin monitoring. Safe to call multiple times.
    func start()

    /// Stop monitoring and release system resources.
    func stop()
}
