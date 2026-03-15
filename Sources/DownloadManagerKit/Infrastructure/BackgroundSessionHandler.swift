// DownloadManagerKit/Sources/DownloadManagerKit/Infrastructure/BackgroundSessionHandler.swift

import Foundation

/// Coordinates background URLSession lifecycle with the app delegate.
///
/// Usage in AppDelegate:
/// ```swift
/// func application(
///     _ application: UIApplication,
///     handleEventsForBackgroundURLSession identifier: String,
///     completionHandler: @escaping () -> Void
/// ) {
///     BackgroundSessionHandler.shared.handleBackgroundSession(
///         identifier: identifier,
///         completionHandler: completionHandler,
///         downloadManager: myDownloadManager
///     )
/// }
/// ```
public final class BackgroundSessionHandler: @unchecked Sendable {

    /// Singleton for AppDelegate integration (the only place a singleton is appropriate).
    public static let shared = BackgroundSessionHandler()

    private var completionHandlers: [String: () -> Void] = [:]
    private let lock = NSLock()

    private init() {}

    /// Store the system-provided completion handler for a background session.
    public func handleBackgroundSession(
        identifier: String,
        completionHandler: @escaping () -> Void,
        downloadManager: DefaultDownloadManager
    ) {
        lock.lock()
        completionHandlers[identifier] = completionHandler
        lock.unlock()

        downloadManager.backgroundCompletionHandler = { [weak self] in
            self?.invokeCompletionHandler(for: identifier)
        }
    }

    private func invokeCompletionHandler(for identifier: String) {
        lock.lock()
        let handler = completionHandlers.removeValue(forKey: identifier)
        lock.unlock()

        DispatchQueue.main.async {
            handler?()
        }
    }
}
