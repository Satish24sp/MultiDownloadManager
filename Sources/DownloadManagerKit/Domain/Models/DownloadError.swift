// DownloadManagerKit/Sources/DownloadManagerKit/Domain/Models/DownloadError.swift

import Foundation

/// Typed error cases for all download-related failures.
public enum DownloadError: Error, Sendable, Equatable, LocalizedError {
    case invalidURL
    case duplicateDownload(url: URL)
    case networkUnavailable
    case httpError(statusCode: Int, url: URL)
    case timeout(url: URL)
    case fileSystemError(description: String)
    case diskFull(requiredBytes: Int64, availableBytes: Int64)
    case invalidResumeData
    case checksumMismatch(expected: String, actual: String)
    case backgroundSessionExpired
    case maxRetriesExceeded(url: URL, attempts: Int)
    case cancelled
    case unknown(description: String)

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return NSLocalizedString("The download URL is invalid.", comment: "Download error")
        case .duplicateDownload(let url):
            return String(
                format: NSLocalizedString("A download for %@ is already in progress.", comment: "Download error"),
                url.absoluteString
            )
        case .networkUnavailable:
            return NSLocalizedString("No network connection available.", comment: "Download error")
        case .httpError(let statusCode, let url):
            return String(
                format: NSLocalizedString("Server returned HTTP %d for %@.", comment: "Download error"),
                statusCode, url.absoluteString
            )
        case .timeout(let url):
            return String(
                format: NSLocalizedString("The request timed out for %@.", comment: "Download error"),
                url.absoluteString
            )
        case .fileSystemError(let description):
            return String(
                format: NSLocalizedString("File system error: %@", comment: "Download error"),
                description
            )
        case .diskFull(let required, let available):
            return String(
                format: NSLocalizedString(
                    "Not enough disk space. Required: %@ — Available: %@",
                    comment: "Download error"
                ),
                ByteCountFormatter.string(fromByteCount: required, countStyle: .file),
                ByteCountFormatter.string(fromByteCount: available, countStyle: .file)
            )
        case .invalidResumeData:
            return NSLocalizedString("Resume data is invalid or corrupted. The download will restart.", comment: "Download error")
        case .checksumMismatch(let expected, let actual):
            return String(
                format: NSLocalizedString("File integrity check failed. Expected: %@ — Got: %@", comment: "Download error"),
                expected, actual
            )
        case .backgroundSessionExpired:
            return NSLocalizedString("The background download session expired.", comment: "Download error")
        case .maxRetriesExceeded(let url, let attempts):
            return String(
                format: NSLocalizedString("Download failed after %d attempts for %@.", comment: "Download error"),
                attempts, url.absoluteString
            )
        case .cancelled:
            return NSLocalizedString("The download was cancelled.", comment: "Download error")
        case .unknown(let description):
            return String(
                format: NSLocalizedString("An unexpected error occurred: %@", comment: "Download error"),
                description
            )
        }
    }
}
