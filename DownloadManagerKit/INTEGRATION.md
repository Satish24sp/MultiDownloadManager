# DownloadManagerKit — Integration Guide

Step-by-step guide for integrating DownloadManagerKit into your iOS app. A standalone demo app (separate from this repo) is available; see the main repository README.

---

## Step 1: Add the Package

### Via Xcode

1. Open your project in Xcode 15+
2. Go to **File → Add Package Dependencies**
3. Paste the repository URL: `https://github.com/Satish24sp/MultiDownloadManager.git`
4. Set **Dependency Rule** to **Up to Next Major Version** from `1.0.0`
5. Click **Add Package**
6. Select the `DownloadManagerKit` library for your app target

### Via Package.swift

```swift
// swift-tools-version: 5.9

let package = Package(
    name: "YourApp",
    platforms: [.iOS(.v15)],
    dependencies: [
        .package(url: "https://github.com/Satish24sp/MultiDownloadManager.git", from: "1.0.0")
    ],
    targets: [
        .executableTarget(
            name: "YourApp",
            dependencies: ["DownloadManagerKit"]
        )
    ]
)
```

### Minimum Deployment Target

Ensure your project's deployment target is set to **iOS 15.0** or later in your Xcode project settings.

---

## Step 2: App Setup

### SwiftUI App Lifecycle

```swift
import SwiftUI
import DownloadManagerKit

@main
struct MyDownloadApp: App {

    @State private var container: DependencyContainer?

    var body: some Scene {
        WindowGroup {
            Group {
                if let container {
                    SidebarNavigationView(
                        viewModel: DownloadViewModel(container: container)
                    )
                } else {
                    ProgressView("Setting up…")
                        .task {
                            container = await DependencyContainer.create()
                        }
                }
            }
        }
    }
}
```

### UIKit App Lifecycle

**AppDelegate.swift:**

```swift
import UIKit
import DownloadManagerKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var container: DependencyContainer?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        return true
    }

    // MARK: — Background Session

    func application(
        _ application: UIApplication,
        handleEventsForBackgroundURLSession identifier: String,
        completionHandler: @escaping () -> Void
    ) {
        guard let manager = container?.downloadManager as? DefaultDownloadManager else {
            completionHandler()
            return
        }
        BackgroundSessionHandler.shared.handleBackgroundSession(
            identifier: identifier,
            completionHandler: completionHandler,
            downloadManager: manager
        )
    }
}
```

**SceneDelegate.swift:**

```swift
import UIKit
import DownloadManagerKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: windowScene)
        self.window = window

        Task {
            let container = await DependencyContainer.create()

            // Store reference in AppDelegate for background session access
            (UIApplication.shared.delegate as? AppDelegate)?.container = container

            await MainActor.run {
                window.rootViewController = DownloadsTabBarController(container: container)
                window.makeKeyAndVisible()
            }
        }
    }
}
```

---

## Step 3: Background Download Setup

### 3a. Enable Background Modes

1. Select your app target in Xcode
2. Go to **Signing & Capabilities**
3. Click **+ Capability** → **Background Modes**
4. Check **Background fetch**
5. Check **Remote notifications** (if using push to wake for downloads)

### 3b. Background Session Identifier

The default identifier is `com.downloadmanagerkit.background`. If you customize it:

```swift
let container = await DependencyContainer.create(
    backgroundSessionIdentifier: "com.yourapp.downloads"
)
```

The identifier must remain **identical across app launches** — iOS uses it to reconnect background tasks to your app.

### 3c. AppDelegate Integration

The `handleEventsForBackgroundURLSession` method in your AppDelegate is **required** for background downloads to complete when the app is suspended. Without it, iOS cannot notify your app that a download finished.

The `BackgroundSessionHandler` stores the system-provided completion handler and calls it when all delegate events are processed.

---

## Step 4: Notification Setup

### Request Permission

```swift
let granted = try await container.notificationManager.requestAuthorization()
if granted {
    container.settingsManager.progressDisplayOption = .both
} else {
    container.settingsManager.progressDisplayOption = .inApp
}
```

### Handle Notification Actions

To handle the "Cancel" action button on download notifications:

```swift
class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {

    let manager: any DownloadManaging

    init(manager: any DownloadManaging) {
        self.manager = manager
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        if response.actionIdentifier == DefaultNotificationManager.cancelActionIdentifier,
           let idString = response.notification.request.content.userInfo["downloadId"] as? String,
           let id = UUID(uuidString: idString) {
            try? await manager.cancelDownload(id: id)
        }
    }
}
```

Register it at app launch:

```swift
let delegate = NotificationDelegate(manager: container.downloadManager)
UNUserNotificationCenter.current().delegate = delegate
```

---

## Step 5: Configure Settings

```swift
let settings = container.settingsManager

// Performance
settings.maxConcurrentDownloads = 3

// Recovery
settings.isAutoResumeEnabled = true
settings.isAutoRetryEnabled = true
settings.maxRetryCount = 3

// Network policy
settings.wifiOnlyMode = false
settings.allowsCellularDownloads = true

// Display
settings.progressDisplayOption = .inApp  // .inApp | .notification | .both
```

All settings persist across app launches via UserDefaults.

---

## Step 6: Start Downloading

End-to-end example from button tap to file on disk:

```swift
// In your ViewModel or ViewController
func downloadFile() {
    let request = DownloadRequest(
        url: URL(string: "https://releases.example.com/app-v2.0.ipa")!,
        fileName: "app-v2.0.ipa",
        headers: ["Authorization": "Bearer \(authToken)"],
        priority: .high
    )

    Task {
        do {
            let id = try await manager.startDownload(request)
            print("Download started with ID: \(id)")

            // Option A: Observe via Combine
            manager.downloadsPublisher
                .compactMap { $0.first(where: { $0.id == id }) }
                .filter { $0.state == .completed }
                .first()
                .sink { item in
                    print("File saved to: \(item.filePath!.path)")
                }
                .store(in: &cancellables)

            // Option B: Observe via AsyncStream
            let stream = await manager.progressStream(for: id)
            for await item in stream {
                if item.state == .completed {
                    print("File saved to: \(item.filePath!.path)")
                }
            }
        } catch {
            print("Download failed: \(error.localizedDescription)")
        }
    }
}
```

Downloaded files are saved to `Documents/Downloads/`.

---

## Step 7: Error Handling

```swift
do {
    try await manager.startDownload(request)
} catch let error as DownloadError {
    switch error {
    case .invalidURL:
        showAlert("The URL is not valid.")
    case .duplicateDownload:
        showAlert("This file is already being downloaded.")
    case .networkUnavailable:
        showAlert("No internet connection. Please try again later.")
    case .httpError(let code, _):
        showAlert("Server error (HTTP \(code)). Please try again.")
    case .diskFull(_, let available):
        let size = ByteCountFormatter.string(fromByteCount: available, countStyle: .file)
        showAlert("Not enough space. Only \(size) available.")
    case .checksumMismatch:
        showAlert("The downloaded file is corrupted. Please try again.")
    case .maxRetriesExceeded(_, let attempts):
        showAlert("Download failed after \(attempts) attempts.")
    case .cancelled:
        break // User initiated, no alert needed
    default:
        showAlert(error.localizedDescription)
    }
} catch {
    showAlert("Unexpected error: \(error.localizedDescription)")
}
```

---

## Step 8: Testing Your Integration

### Checklist

- [ ] Start a download and verify the file appears in `Documents/Downloads/`
- [ ] Pause and resume a download — verify resume data works (file continues, doesn't restart)
- [ ] Kill the app during a download — relaunch and verify the download is restored as paused
- [ ] Turn off WiFi — verify active downloads auto-pause
- [ ] Turn on WiFi — verify auto-resume (if enabled in settings)
- [ ] Set WiFi-only mode, switch to cellular — verify downloads pause
- [ ] Download with an Authorization header — verify HTTP 200 success
- [ ] Background download — minimize app, verify completion notification
- [ ] Set progress display to `.notification` — verify notification updates appear
- [ ] Run unit tests — verify all pass: `swift test`
- [ ] Test with VoiceOver enabled — verify all elements are labeled
- [ ] Test with Dynamic Type at maximum size — verify layout doesn't break

---

## Troubleshooting

### Downloads don't resume after app restart

- Verify the background session identifier is **exactly the same** string every time
- Verify `manager.start()` is called at app launch (this loads persisted state)
- Check that the `handleEventsForBackgroundURLSession` AppDelegate method is implemented

### Notifications not appearing

- Verify notification permission was granted: check `UNUserNotificationCenter` authorization status
- Verify `progressDisplayOption` is `.notification` or `.both`
- Verify you're not running in the iOS Simulator (notification behavior differs)

### Background downloads not completing

- Verify the **Background Modes** capability is enabled with **Background fetch** checked
- Verify `handleEventsForBackgroundURLSession` is implemented in `AppDelegate`
- Verify the `completionHandler` is called in `urlSessionDidFinishEvents`
- Note: Xcode debugging can interfere with background session behavior

### Compile errors after adding package

- Verify deployment target is **iOS 15.0+**
- Verify Swift language version is **5.9+** in Build Settings
- Try **Product → Clean Build Folder** (Cmd+Shift+K) then rebuild
- Ensure only one version of the package is resolved (check Package.resolved)

### Downloads stuck in "queued" state

- Check `maxConcurrentDownloads` — if set to 1 and a download is active, others queue
- Check network status — if network is offline, downloads won't start

### High memory usage during downloads

- The download manager streams files to disk via URLSession (not in-memory)
- If you're observing high memory, check that you're not retaining download items in arrays unnecessarily

---

## Migration Guide

### v1.x → Future Versions

The persistence layer includes a `schemaVersion` field in the JSON store. When the schema changes:

1. The new version reads the old JSON
2. Checks `schemaVersion`
3. Migrates records to the new format
4. Writes with the updated `schemaVersion`

If you implement a custom `DownloadPersisting` (e.g., CoreData), manage your own migration via Core Data lightweight migration or manual mapping.
