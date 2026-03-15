// DownloadManagerKit/Sources/DownloadManagerKit/Domain/Protocols/SettingsManaging.swift

import Foundation

/// Manages user-configurable download preferences.
/// Implementations must persist values across app launches.
public protocol SettingsManaging: AnyObject, Sendable {

    /// Where download progress should be displayed.
    var progressDisplayOption: ProgressDisplayOption { get set }

    /// Maximum number of simultaneous active downloads.
    var maxConcurrentDownloads: Int { get set }

    /// Automatically resume paused downloads when network returns.
    var isAutoResumeEnabled: Bool { get set }

    /// Automatically retry failed downloads.
    var isAutoRetryEnabled: Bool { get set }

    /// Maximum number of retry attempts before marking a download as failed.
    var maxRetryCount: Int { get set }

    /// Allow downloads over cellular networks.
    var allowsCellularDownloads: Bool { get set }

    /// When true, downloads are paused on cellular and only proceed on WiFi.
    var wifiOnlyMode: Bool { get set }
}
