// DownloadManagerKit/Sources/DownloadManagerKit/Domain/Models/DownloadItem.swift

import Foundation

/// Public, immutable snapshot of a download's current state.
/// Published by the manager whenever any property changes.
public struct DownloadItem: Identifiable, Sendable, Equatable {
    public let id: UUID
    public let url: URL
    public var fileName: String
    public var state: DownloadState
    public var progress: Double
    public var downloadedBytes: Int64
    public var totalBytes: Int64?
    public var downloadSpeed: Double
    public var estimatedTimeRemaining: TimeInterval?
    public var mimeType: String?
    public var filePath: URL?
    public var priority: DownloadPriority
    public let createdDate: Date
    public var completedDate: Date?
    public var error: DownloadError?
    public var retryCount: Int

    public init(
        id: UUID = UUID(),
        url: URL,
        fileName: String,
        state: DownloadState = .pending,
        progress: Double = 0,
        downloadedBytes: Int64 = 0,
        totalBytes: Int64? = nil,
        downloadSpeed: Double = 0,
        estimatedTimeRemaining: TimeInterval? = nil,
        mimeType: String? = nil,
        filePath: URL? = nil,
        priority: DownloadPriority = .normal,
        createdDate: Date = Date(),
        completedDate: Date? = nil,
        error: DownloadError? = nil,
        retryCount: Int = 0
    ) {
        self.id = id
        self.url = url
        self.fileName = fileName
        self.state = state
        self.progress = progress
        self.downloadedBytes = downloadedBytes
        self.totalBytes = totalBytes
        self.downloadSpeed = downloadSpeed
        self.estimatedTimeRemaining = estimatedTimeRemaining
        self.mimeType = mimeType
        self.filePath = filePath
        self.priority = priority
        self.createdDate = createdDate
        self.completedDate = completedDate
        self.error = error
        self.retryCount = retryCount
    }

    /// Formatted file size string (e.g., "12.4 MB").
    public var formattedTotalSize: String? {
        guard let totalBytes else { return nil }
        return ByteCountFormatter.string(fromByteCount: totalBytes, countStyle: .file)
    }

    /// Formatted downloaded size string.
    public var formattedDownloadedSize: String {
        ByteCountFormatter.string(fromByteCount: downloadedBytes, countStyle: .file)
    }

    /// Formatted download speed (e.g., "2.3 MB/s").
    public var formattedSpeed: String {
        ByteCountFormatter.string(fromByteCount: Int64(downloadSpeed), countStyle: .file) + "/s"
    }

    /// Formatted ETA (e.g., "3m 24s").
    public var formattedETA: String? {
        guard let eta = estimatedTimeRemaining, eta.isFinite, eta > 0 else { return nil }
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        formatter.maximumUnitCount = 2
        return formatter.string(from: eta)
    }

    /// Progress as an integer percentage (0–100).
    public var percentComplete: Int {
        Int((progress * 100).rounded())
    }
}

// MARK: - Internal Persistence Record

/// Codable representation for persisting downloads to disk.
public struct DownloadRecord: Codable, Sendable {
    public let id: UUID
    public let url: URL
    public var state: DownloadState
    public var progress: Double
    public var resumeData: Data?
    public var filePath: String?
    public var fileName: String
    public var mimeType: String?
    public var totalBytes: Int64?
    public var downloadedBytes: Int64
    public var priority: DownloadPriority
    public let createdDate: Date
    public var completedDate: Date?
    public var errorDescription: String?
    public var retryCount: Int
    public var headers: [String: String]?
    public var expectedChecksum: String?

    public init(
        id: UUID,
        url: URL,
        state: DownloadState,
        progress: Double,
        resumeData: Data? = nil,
        filePath: String? = nil,
        fileName: String,
        mimeType: String? = nil,
        totalBytes: Int64? = nil,
        downloadedBytes: Int64 = 0,
        priority: DownloadPriority = .normal,
        createdDate: Date = Date(),
        completedDate: Date? = nil,
        errorDescription: String? = nil,
        retryCount: Int = 0,
        headers: [String: String]? = nil,
        expectedChecksum: String? = nil
    ) {
        self.id = id
        self.url = url
        self.state = state
        self.progress = progress
        self.resumeData = resumeData
        self.filePath = filePath
        self.fileName = fileName
        self.mimeType = mimeType
        self.totalBytes = totalBytes
        self.downloadedBytes = downloadedBytes
        self.priority = priority
        self.createdDate = createdDate
        self.completedDate = completedDate
        self.errorDescription = errorDescription
        self.retryCount = retryCount
        self.headers = headers
        self.expectedChecksum = expectedChecksum
    }

    public func toDownloadItem() -> DownloadItem {
        var error: DownloadError?
        if let desc = errorDescription {
            error = .unknown(description: desc)
        }
        return DownloadItem(
            id: id,
            url: url,
            fileName: fileName,
            state: state,
            progress: progress,
            downloadedBytes: downloadedBytes,
            totalBytes: totalBytes,
            mimeType: mimeType,
            filePath: filePath.flatMap { URL(fileURLWithPath: $0) },
            priority: priority,
            createdDate: createdDate,
            completedDate: completedDate,
            error: error,
            retryCount: retryCount
        )
    }

    public static func from(item: DownloadItem, resumeData: Data? = nil, headers: [String: String]? = nil, expectedChecksum: String? = nil) -> DownloadRecord {
        DownloadRecord(
            id: item.id,
            url: item.url,
            state: item.state,
            progress: item.progress,
            resumeData: resumeData,
            filePath: item.filePath?.path,
            fileName: item.fileName,
            mimeType: item.mimeType,
            totalBytes: item.totalBytes,
            downloadedBytes: item.downloadedBytes,
            priority: item.priority,
            createdDate: item.createdDate,
            completedDate: item.completedDate,
            errorDescription: item.error?.localizedDescription,
            retryCount: item.retryCount,
            headers: headers,
            expectedChecksum: expectedChecksum
        )
    }
}

/// Top-level wrapper that includes a schema version for future migrations.
public struct PersistedDownloadStore: Codable, Sendable {
    public static let currentSchemaVersion = 1
    public let schemaVersion: Int
    public var records: [DownloadRecord]

    public init(records: [DownloadRecord]) {
        self.schemaVersion = Self.currentSchemaVersion
        self.records = records
    }
}
