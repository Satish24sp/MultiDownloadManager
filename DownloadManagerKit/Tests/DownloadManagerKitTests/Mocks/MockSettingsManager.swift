// Tests/DownloadManagerKitTests/Mocks/MockSettingsManager.swift

import Foundation
@testable import DownloadManagerKit

final class MockSettingsManager: SettingsManaging, @unchecked Sendable {
    var progressDisplayOption: ProgressDisplayOption = .inApp
    var maxConcurrentDownloads: Int = 3
    var isAutoResumeEnabled: Bool = true
    var isAutoRetryEnabled: Bool = true
    var maxRetryCount: Int = 3
    var allowsCellularDownloads: Bool = true
    var wifiOnlyMode: Bool = false
}
