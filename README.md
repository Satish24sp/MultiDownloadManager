# MultiDownloadManager

Production-grade iOS download manager — **Swift Package** with Clean Architecture, protocol-oriented design, and full SwiftUI + UIKit support.

[![Swift 5.9+](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)
[![iOS 15.0+](https://img.shields.io/badge/iOS-15.0+-blue.svg)](https://developer.apple.com/ios/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

---

## What’s in this repo

This repository **is** the Swift package. `Package.swift` is at the root so SPM can resolve it from the repo URL. The library product name is **DownloadManagerKit**.

---

## Step-by-step integration

### Step 1 — Add the package

**In Xcode**

1. Open your project in Xcode 15+.
2. **File → Add Package Dependencies…**
3. Enter the URL:  
   `https://github.com/Satish24sp/MultiDownloadManager.git`
4. Set **Dependency Rule** to **Up to Next Major Version** with minimum `1.0.0`.
5. Click **Add Package**, then add the **DownloadManagerKit** library to your app target.

**In Package.swift**

```swift
dependencies: [
    .package(url: "https://github.com/Satish24sp/MultiDownloadManager.git", from: "1.0.0")
]
```

Add to your target: `dependencies: ["DownloadManagerKit"]`.

---

### Step 2 — App setup

**SwiftUI**

```swift
import SwiftUI
import DownloadManagerKit

@main
struct MyApp: App {
    @State private var container: DependencyContainer?

    var body: some Scene {
        WindowGroup {
            if let container {
                SidebarNavigationView(viewModel: DownloadViewModel(container: container))
            } else {
                ProgressView("Loading…")
                    .task { container = await DependencyContainer.create() }
            }
        }
    }
}
```

**UIKit**

Create the container in your `SceneDelegate` (or `AppDelegate`), then set the root view controller to `DownloadsTabBarController(container: container)`.

---

### Step 3 — Background downloads (optional)

1. In your app target: **Signing & Capabilities → + Capability → Background Modes** → enable **Background fetch**.
2. In **AppDelegate**, implement:

```swift
func application(
    _ application: UIApplication,
    handleEventsForBackgroundURLSession identifier: String,
    completionHandler: @escaping () -> Void
) {
    BackgroundSessionHandler.shared.handleBackgroundSession(
        identifier: identifier,
        completionHandler: completionHandler,
        downloadManager: container?.downloadManager as? DefaultDownloadManager
    )
}
```

---

### Step 4 — Start a download

```swift
let request = DownloadRequest(
    url: URL(string: "https://example.com/file.zip")!,
    fileName: "file.zip",
    priority: .high
)
let id = try await container.downloadManager.startDownload(request)
```

---

## Full integration guide

For detailed steps (notifications, settings, error handling, checksums, retries, and troubleshooting), see:

**[INTEGRATION.md](INTEGRATION.md)**

---

## Demo app (separate, not in repo)

A **standalone demo app** that uses this package via SPM lives in the `MultiDownloadManager-Demo` folder (same directory as this repo; the folder is not published to GitHub). To run it: open `MultiDownloadManager-Demo/DemoApp.xcodeproj`, resolve packages, then build and run. See `MultiDownloadManager-Demo/README.md` for details.

---

## Publishing this repo

To host the package on GitHub:

1. Create a new **public** or **private** repository named `MultiDownloadManager` (empty, no README).
2. Push and tag:

   ```bash
   git remote add origin https://github.com/Satish24sp/MultiDownloadManager.git
   git push -u origin main
   git tag 1.0.0
   git push origin 1.0.0
   ```

3. For a **private** repo, add your GitHub account (or PAT) in Xcode → Settings → Accounts so SPM can resolve the package.

---

## Author

**Satish** — Senior iOS Engineer · 7+ years · Swift, UIKit, SwiftUI, MVVM+C

- GitHub: [@Satish24sp](https://github.com/Satish24sp)
- Portfolio: [satish24sp.github.io](https://satish24sp.github.io)
- LinkedIn: [in/satish-iosdev](https://www.linkedin.com/in/satish-iosdev)

---

## License

MIT License — see [LICENSE](LICENSE).
