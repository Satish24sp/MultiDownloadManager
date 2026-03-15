# DownloadManagerKit

A production-grade, reusable iOS download manager module built with **Clean Architecture**, **protocol-oriented design**, and **dependency injection**. Supports background downloads, priority queuing, reactive progress tracking, and both SwiftUI and UIKit.

## Features

- Multiple simultaneous downloads with configurable concurrency limit
- Pause / Resume / Cancel individual or all downloads
- Resume using `URLSession` resume data
- Background downloads with `URLSessionConfiguration.background`
- Restore downloads after app restart or crash
- Real-time progress tracking with download speed and ETA
- Priority queue (high, normal, low)
- Automatic retry with exponential backoff
- Auto-pause on network loss, auto-resume on reconnect
- WiFi-only mode with cellular policy control
- Duplicate download detection
- SHA-256 file integrity verification
- Disk space checking before download
- Local notification progress updates
- JSON-based persistence (swappable via protocol)
- Full Combine and async/await support
- SwiftUI and UIKit demo UI with accessibility support
- Fully mockable — every service behind a protocol
- Zero third-party dependencies — Apple frameworks only

## Requirements

| Requirement | Minimum |
|---|---|
| iOS | 15.0+ |
| Swift | 5.9+ |
| Xcode | 15.0+ |

## Installation

### Swift Package Manager (Xcode)

1. Open your project in Xcode
2. Go to **File → Add Package Dependencies**
3. Paste the repository URL
4. Use repository URL: `https://github.com/Satish24sp/MultiDownloadManager.git`
5. Select version **1.0.0** or later

### Swift Package Manager (Package.swift)

```swift
dependencies: [
    .package(url: "https://github.com/Satish24sp/MultiDownloadManager.git", from: "1.0.0")
]
```

Then add to your target:

```swift
.target(
    name: "YourApp",
    dependencies: ["DownloadManagerKit"]
)
```

## Quick Start

```swift
import DownloadManagerKit

// 1. Create the dependency container (do this once at app launch)
let container = await DependencyContainer.create()

// 2. Start a download
let request = DownloadRequest(url: URL(string: "https://example.com/file.zip")!)
let downloadId = try await container.downloadManager.startDownload(request)

// 3. Observe progress
container.downloadManager.downloadsPublisher
    .sink { downloads in
        for item in downloads {
            print("\(item.fileName): \(item.percentComplete)%")
        }
    }
    .store(in: &cancellables)
```

## Architecture

DownloadManagerKit follows **Clean Architecture** with five layers:

```
┌─────────────────────────────────────┐
│                 UI                  │  SwiftUI Views, UIKit ViewControllers
├─────────────────────────────────────┤
│            Infrastructure           │  NetworkMonitor, Notifications, Disk
├─────────────────────────────────────┤
│               Data                  │  DefaultDownloadManager, Persistence
├─────────────────────────────────────┤
│              Domain                 │  Models, Protocols (pure Swift)
├─────────────────────────────────────┤
│               Core                  │  DI Container, Logger, Extensions
└─────────────────────────────────────┘
```

All dependencies flow inward. The Domain layer has zero imports. Every service is defined as a protocol and injected through initializers.

## Usage

### Starting a Download

```swift
let request = DownloadRequest(
    url: URL(string: "https://example.com/video.mp4")!,
    fileName: "my-video.mp4",         // optional override
    headers: ["Authorization": "Bearer token123"],  // optional
    priority: .high,                   // .high, .normal, .low
    expectedChecksum: "a1b2c3..."      // optional SHA-256
)

let id = try await manager.startDownload(request)
```

### Observing Progress (Combine)

```swift
manager.downloadsPublisher
    .receive(on: DispatchQueue.main)
    .sink { items in
        for item in items where item.state == .downloading {
            print("\(item.fileName): \(item.percentComplete)% at \(item.formattedSpeed)")
        }
    }
    .store(in: &cancellables)
```

### Observing Progress (AsyncStream)

```swift
let stream = await manager.progressStream(for: downloadId)
for await item in stream {
    print("\(item.percentComplete)% — ETA: \(item.formattedETA ?? "calculating")")
}
```

### Pause / Resume / Cancel

```swift
try await manager.pauseDownload(id: downloadId)
try await manager.resumeDownload(id: downloadId)
try await manager.cancelDownload(id: downloadId)

// Bulk operations
await manager.pauseAll()
await manager.resumeAll()
```

### Retry a Failed Download

```swift
try await manager.retryDownload(id: downloadId)
```

### Delete a Download

```swift
// Removes the file from disk AND the record from persistence
try await manager.deleteDownload(id: downloadId)
```

### Background Downloads

In your `AppDelegate`:

```swift
func application(
    _ application: UIApplication,
    handleEventsForBackgroundURLSession identifier: String,
    completionHandler: @escaping () -> Void
) {
    BackgroundSessionHandler.shared.handleBackgroundSession(
        identifier: identifier,
        completionHandler: completionHandler,
        downloadManager: myDownloadManager as! DefaultDownloadManager
    )
}
```

### Authenticated Downloads

```swift
let request = DownloadRequest(
    url: URL(string: "https://api.example.com/files/secret.pdf")!,
    headers: [
        "Authorization": "Bearer eyJhbGciOiJIUzI1NiIs...",
        "X-API-Key": "your-api-key"
    ]
)
try await manager.startDownload(request)
```

### Checksum Verification

```swift
let request = DownloadRequest(
    url: URL(string: "https://example.com/firmware.bin")!,
    expectedChecksum: "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
)
// If checksum doesn't match after download, state is set to .failed
// with error .checksumMismatch(expected:actual:)
```

### Notification Progress

```swift
// 1. Request permission
let granted = try await container.notificationManager.requestAuthorization()

// 2. Set display option
container.settingsManager.progressDisplayOption = .both  // .inApp, .notification, or .both
```

### Settings Configuration

```swift
let settings = container.settingsManager
settings.maxConcurrentDownloads = 5
settings.isAutoResumeEnabled = true
settings.isAutoRetryEnabled = true
settings.maxRetryCount = 3
settings.wifiOnlyMode = false
settings.allowsCellularDownloads = true
settings.progressDisplayOption = .inApp
```

### SwiftUI Integration

```swift
import SwiftUI
import DownloadManagerKit

@main
struct MyApp: App {
    @State private var container: DependencyContainer?

    var body: some Scene {
        WindowGroup {
            if let container {
                SidebarNavigationView(
                    viewModel: DownloadViewModel(container: container)
                )
            } else {
                ProgressView("Loading…")
                    .task {
                        container = await DependencyContainer.create()
                    }
            }
        }
    }
}
```

### UIKit Integration

```swift
import UIKit
import DownloadManagerKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    var container: DependencyContainer?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        window = UIWindow(windowScene: windowScene)

        Task {
            let container = await DependencyContainer.create()
            self.container = container

            await MainActor.run {
                window?.rootViewController = DownloadsTabBarController(container: container)
                window?.makeKeyAndVisible()
            }
        }
    }
}
```

## Customization

All services are protocol-based. Replace any default implementation:

```swift
// Custom persistence (e.g., CoreData)
class CoreDataPersistence: DownloadPersisting { ... }

// Custom logger
class RemoteLogger: DownloadLogging { ... }

// Inject into the download manager
let manager = DefaultDownloadManager(
    persistence: CoreDataPersistence(),
    networkMonitor: DefaultNetworkMonitor(logger: myLogger),
    settings: DefaultSettingsManager(),
    logger: RemoteLogger(),
    notificationManager: DefaultNotificationManager(logger: myLogger),
    diskSpaceManager: DefaultDiskSpaceManager(),
    checksumValidator: DefaultChecksumValidator()
)
await manager.start()
```

## Testing

All protocols have mock implementations in the test target:

```swift
import XCTest
@testable import DownloadManagerKit

final class MyFeatureTests: XCTestCase {
    func testDownloadTriggered() async throws {
        let mock = MockDownloadManager()

        // Your code that uses DownloadManaging
        let viewModel = MyViewModel(manager: mock)
        viewModel.downloadFile(url: someURL)

        XCTAssertTrue(mock.startDownloadCalled)
        XCTAssertEqual(mock.lastStartedRequest?.url, someURL)
    }
}
```

Run all tests:

```bash
cd DownloadManagerKit
swift test
```

## API Reference

| Protocol | Purpose |
|---|---|
| `DownloadManaging` | Start, pause, resume, cancel, delete, retry downloads; Combine + AsyncStream |
| `NetworkMonitoring` | Observe network reachability and connection type |
| `SettingsManaging` | Read/write user preferences (concurrent limit, auto-retry, WiFi-only, etc.) |
| `DownloadPersisting` | Save/load/delete download records |
| `DownloadLogging` | Structured logging with levels and categories |
| `NotificationManaging` | Post and manage local notifications for download progress |
| `DiskSpaceManaging` | Check available, total, and app-used disk space |
| `ChecksumValidating` | SHA-256 file integrity verification |

## Thread Safety

`DefaultDownloadManager` uses a private serial `DispatchQueue` for all state mutations. All public methods are `async` and bridge to the queue via `CheckedContinuation`. The Combine `downloadsPublisher` is backed by a `CurrentValueSubject` (thread-safe for sends). All protocol implementations are marked `Sendable` or `@unchecked Sendable` with documented synchronization.

## Known Limitations

- **Notification progress** requires user permission via `UNUserNotificationCenter`
- **Background sessions** are subject to iOS-imposed limits on frequency and timing
- **Resume data** is not always available — the server must support HTTP `Range` requests
- **OSLogStore** (used in LogsView) may not capture all log entries on all devices
- **Background session identifier** must remain consistent across app launches

## Repository

This package is part of [MultiDownloadManager](https://github.com/Satish24sp/MultiDownloadManager). Add the **root repository URL** in Xcode or SPM; the library target is `DownloadManagerKit`.

## License

MIT License — see [LICENSE](LICENSE) for details.

## Author

**Satish** · [GitHub](https://github.com/Satish24sp) · [Portfolio](https://satish24sp.github.io)
