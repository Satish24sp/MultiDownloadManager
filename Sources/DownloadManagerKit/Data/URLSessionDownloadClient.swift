// DownloadManagerKit/Sources/DownloadManagerKit/Data/URLSessionDownloadClient.swift

import Foundation

/// Bridges URLSessionDownloadDelegate callbacks into Sendable closures
/// that the download manager actor can consume via Tasks.
final class URLSessionDownloadClient: NSObject, @unchecked Sendable {

    // MARK: - Callback Types

    typealias ProgressHandler = @Sendable (
        _ taskIdentifier: Int,
        _ bytesWritten: Int64,
        _ totalBytesWritten: Int64,
        _ totalBytesExpectedToWrite: Int64
    ) -> Void

    typealias FinishDownloadHandler = @Sendable (
        _ taskIdentifier: Int,
        _ location: URL,
        _ response: URLResponse?
    ) -> Void

    typealias CompletionHandler = @Sendable (
        _ taskIdentifier: Int,
        _ error: Error?
    ) -> Void

    typealias AllEventsFinishedHandler = @Sendable () -> Void

    // MARK: - Callbacks

    var onProgress: ProgressHandler?
    var onFinishedDownloading: FinishDownloadHandler?
    var onTaskComplete: CompletionHandler?
    var onAllEventsFinished: AllEventsFinishedHandler?

    // MARK: - Session

    private(set) var session: URLSession!

    /// Creates and configures the background URLSession.
    func createSession(identifier: String, configuration: URLSessionConfiguration? = nil) {
        let config = configuration ?? {
            let c = URLSessionConfiguration.background(withIdentifier: identifier)
            c.isDiscretionary = false
            c.sessionSendsLaunchEvents = true
            c.allowsCellularAccess = true
            return c
        }()
        session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }

    /// Start a download task with optional custom headers.
    func startDownloadTask(with url: URL, headers: [String: String]?) -> URLSessionDownloadTask {
        var request = URLRequest(url: url)
        headers?.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        let task = session.downloadTask(with: request)
        task.resume()
        return task
    }

    /// Resume a download task from previously stored resume data.
    func resumeDownloadTask(with resumeData: Data) -> URLSessionDownloadTask {
        let task = session.downloadTask(withResumeData: resumeData)
        task.resume()
        return task
    }

    /// Retrieve all outstanding tasks from the session (for restoration after relaunch).
    func getOutstandingTasks() async -> [URLSessionDownloadTask] {
        await withCheckedContinuation { continuation in
            session.getTasksWithCompletionHandler { _, _, downloadTasks in
                continuation.resume(returning: downloadTasks)
            }
        }
    }

    func invalidateAndCancel() {
        session?.invalidateAndCancel()
    }
}

// MARK: - URLSessionDownloadDelegate

extension URLSessionDownloadClient: URLSessionDownloadDelegate {

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        onProgress?(
            downloadTask.taskIdentifier,
            bytesWritten,
            totalBytesWritten,
            totalBytesExpectedToWrite
        )
    }

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        onFinishedDownloading?(
            downloadTask.taskIdentifier,
            location,
            downloadTask.response
        )
    }

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
        onTaskComplete?(task.taskIdentifier, error)
    }

    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        onAllEventsFinished?()
    }
}
