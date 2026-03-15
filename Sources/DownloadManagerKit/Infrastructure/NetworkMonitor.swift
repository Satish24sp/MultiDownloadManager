// DownloadManagerKit/Sources/DownloadManagerKit/Infrastructure/NetworkMonitor.swift

import Foundation
import Network
import Combine

/// NWPathMonitor-backed network observer.
public final class DefaultNetworkMonitor: NetworkMonitoring, @unchecked Sendable {

    private let monitor: NWPathMonitor
    private let monitorQueue = DispatchQueue(label: "com.downloadmanagerkit.networkmonitor", qos: .utility)
    private let logger: any DownloadLogging
    private let _statusSubject = CurrentValueSubject<NetworkStatus, Never>(.disconnected)

    private var _isConnected = false
    private var _connectionType: ConnectionType = .unknown

    public var isConnected: Bool { _isConnected }
    public var connectionType: ConnectionType { _connectionType }

    public var networkStatusPublisher: AnyPublisher<NetworkStatus, Never> {
        _statusSubject
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    public init(logger: any DownloadLogging) {
        self.monitor = NWPathMonitor()
        self.logger = logger
    }

    public func start() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            let connected = path.status == .satisfied
            let type = self.resolveConnectionType(path)

            self._isConnected = connected
            self._connectionType = type

            let status = NetworkStatus(isConnected: connected, connectionType: type)
            self._statusSubject.send(status)
            self.logger.info("Network status: \(connected ? "connected" : "disconnected") via \(type.rawValue)", category: .network)
        }
        monitor.start(queue: monitorQueue)
    }

    public func stop() {
        monitor.cancel()
    }

    private func resolveConnectionType(_ path: NWPath) -> ConnectionType {
        if path.usesInterfaceType(.wifi) { return .wifi }
        if path.usesInterfaceType(.cellular) { return .cellular }
        if path.usesInterfaceType(.wiredEthernet) { return .wiredEthernet }
        return .unknown
    }
}
