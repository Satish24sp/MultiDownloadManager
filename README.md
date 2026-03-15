# MultiDownloadManager

A production-grade iOS download manager — **Swift Package** with Clean Architecture, protocol-oriented design, and full SwiftUI + UIKit support. Built for reliability at scale.

[![Swift 5.9+](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)
[![iOS 15.0+](https://img.shields.io/badge/iOS-15.0+-blue.svg)](https://developer.apple.com/ios/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

---

## Repository structure

| Path | Description |
|------|-------------|
| **DownloadManagerKit/** | Swift Package — core library. Add via SPM to your app. |
| **DemoApp/** | Sample Xcode app (SwiftUI + UIKit) demonstrating integration. |

The main deliverable is **DownloadManagerKit**. See [DownloadManagerKit/README.md](DownloadManagerKit/README.md) for features, installation, and API usage.

---

## Quick start

### Add via Swift Package Manager

**Xcode:** File → Add Package Dependencies → paste:

```
https://github.com/Satish24sp/MultiDownloadManager.git
```

**Package.swift:**

```swift
dependencies: [
    .package(url: "https://github.com/Satish24sp/MultiDownloadManager.git", from: "1.0.0")
]
```

Then add the library to your target: `dependencies: ["DownloadManagerKit"]`.

### Run the demo

1. Open `DemoApp/DemoApp.xcodeproj` in Xcode.
2. The app uses **DownloadManagerKit** via SPM from this GitHub repo (see [Hosting on GitHub](#hosting-on-github) if you haven’t pushed yet).
3. Select a simulator or device (iOS 15+), then Build and run (⌘R).

---

## Hosting on GitHub

DemoApp is configured to depend on this repository via SPM. To publish and use it:

1. **Create the repo on GitHub**  
   Go to [github.com/new](https://github.com/new), name it `MultiDownloadManager`, leave it empty (no README/license), and copy the repo URL.

2. **Initialize and push from your machine:**

   ```bash
   cd /path/to/MultiDownloadManager
   git init
   git add .
   git commit -m "Initial commit: DownloadManagerKit + DemoApp"
   git branch -M main
   git remote add origin https://github.com/Satish24sp/MultiDownloadManager.git
   git push -u origin main
   ```

3. **Create a version tag** (required for SPM “from: 1.0.0”):

   ```bash
   git tag 1.0.0
   git push origin 1.0.0
   ```

4. **Open DemoApp in Xcode**  
   File → Packages → Reset Package Caches (if needed), then build. Xcode will resolve **DownloadManagerKit** from the GitHub repo.

---

## Author

**Satish** — Senior iOS Engineer · 7+ years · Swift, UIKit, SwiftUI, MVVM+C

- GitHub: [@Satish24sp](https://github.com/Satish24sp)
- Portfolio: [satish24sp.github.io](https://satish24sp.github.io)
- LinkedIn: [in/satish-iosdev](https://www.linkedin.com/in/satish-iosdev)

---

## License

This project is licensed under the MIT License — see [DownloadManagerKit/LICENSE](DownloadManagerKit/LICENSE) for details.
