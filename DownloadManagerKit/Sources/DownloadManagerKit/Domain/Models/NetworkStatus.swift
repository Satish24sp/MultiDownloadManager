// DownloadManagerKit/Sources/DownloadManagerKit/Domain/Models/NetworkStatus.swift

import Foundation

/// The type of network interface currently active.
public enum ConnectionType: String, Codable, Sendable {
    case wifi
    case cellular
    case wiredEthernet
    case unknown
}

/// Snapshot of the current network reachability state.
public struct NetworkStatus: Sendable, Equatable {
    public let isConnected: Bool
    public let connectionType: ConnectionType

    public init(isConnected: Bool, connectionType: ConnectionType) {
        self.isConnected = isConnected
        self.connectionType = connectionType
    }

    /// Convenience for an unreachable state.
    public static let disconnected = NetworkStatus(isConnected: false, connectionType: .unknown)
}

/// Controls where download progress is displayed to the user.
public enum ProgressDisplayOption: String, Codable, Sendable, CaseIterable {
    /// Progress shown only inside the app UI.
    case inApp
    /// Progress shown as a system notification.
    case notification
    /// Progress shown in both the app UI and as a system notification.
    case both

    public var displayName: String {
        switch self {
        case .inApp:        return NSLocalizedString("In-App Only", comment: "Progress display option")
        case .notification: return NSLocalizedString("Notification Only", comment: "Progress display option")
        case .both:         return NSLocalizedString("Both", comment: "Progress display option")
        }
    }
}
