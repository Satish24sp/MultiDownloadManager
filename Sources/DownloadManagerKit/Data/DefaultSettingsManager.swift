// DownloadManagerKit/Sources/DownloadManagerKit/Data/DefaultSettingsManager.swift

import Foundation

/// UserDefaults-backed settings manager. Thread-safe because UserDefaults is thread-safe.
public final class DefaultSettingsManager: SettingsManaging, @unchecked Sendable {

    private let defaults: UserDefaults
    private let prefix: String

    public init(defaults: UserDefaults = .standard, keyPrefix: String = "com.downloadmanagerkit.settings.") {
        self.defaults = defaults
        self.prefix = keyPrefix
    }

    // MARK: - Keys

    private enum Key: String {
        case progressDisplayOption
        case maxConcurrentDownloads
        case isAutoResumeEnabled
        case isAutoRetryEnabled
        case maxRetryCount
        case allowsCellularDownloads
        case wifiOnlyMode
    }

    private func key(_ k: Key) -> String { prefix + k.rawValue }

    // MARK: - Properties

    public var progressDisplayOption: ProgressDisplayOption {
        get {
            guard let raw = defaults.string(forKey: key(.progressDisplayOption)),
                  let option = ProgressDisplayOption(rawValue: raw) else {
                return .inApp
            }
            return option
        }
        set { defaults.set(newValue.rawValue, forKey: key(.progressDisplayOption)) }
    }

    public var maxConcurrentDownloads: Int {
        get {
            let value = defaults.integer(forKey: key(.maxConcurrentDownloads))
            return value > 0 ? value : 3
        }
        set { defaults.set(max(1, newValue), forKey: key(.maxConcurrentDownloads)) }
    }

    public var isAutoResumeEnabled: Bool {
        get { defaults.object(forKey: key(.isAutoResumeEnabled)) as? Bool ?? true }
        set { defaults.set(newValue, forKey: key(.isAutoResumeEnabled)) }
    }

    public var isAutoRetryEnabled: Bool {
        get { defaults.object(forKey: key(.isAutoRetryEnabled)) as? Bool ?? true }
        set { defaults.set(newValue, forKey: key(.isAutoRetryEnabled)) }
    }

    public var maxRetryCount: Int {
        get {
            if defaults.object(forKey: key(.maxRetryCount)) == nil {
                return 3
            }
            return max(0, defaults.integer(forKey: key(.maxRetryCount)))
        }
        set { defaults.set(max(0, newValue), forKey: key(.maxRetryCount)) }
    }

    public var allowsCellularDownloads: Bool {
        get { defaults.object(forKey: key(.allowsCellularDownloads)) as? Bool ?? true }
        set { defaults.set(newValue, forKey: key(.allowsCellularDownloads)) }
    }

    public var wifiOnlyMode: Bool {
        get { defaults.object(forKey: key(.wifiOnlyMode)) as? Bool ?? false }
        set { defaults.set(newValue, forKey: key(.wifiOnlyMode)) }
    }
}
