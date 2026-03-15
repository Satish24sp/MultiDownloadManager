// DownloadManagerKit/Sources/DownloadManagerKit/Domain/Models/DownloadRequest.swift

import Foundation

/// Input model for initiating a new download.
public struct DownloadRequest: Sendable {
    /// Remote URL of the file to download.
    public let url: URL

    /// Optional override for the saved file name. When nil, the name is derived from the URL.
    public let fileName: String?

    /// Custom HTTP headers (e.g., Authorization bearer tokens).
    public let headers: [String: String]?

    /// Scheduling priority for the download queue.
    public let priority: DownloadPriority

    /// Optional SHA-256 checksum to verify after download completes.
    public let expectedChecksum: String?

    public init(
        url: URL,
        fileName: String? = nil,
        headers: [String: String]? = nil,
        priority: DownloadPriority = .normal,
        expectedChecksum: String? = nil
    ) {
        self.url = url
        self.fileName = fileName
        self.headers = headers
        self.priority = priority
        self.expectedChecksum = expectedChecksum
    }
}
