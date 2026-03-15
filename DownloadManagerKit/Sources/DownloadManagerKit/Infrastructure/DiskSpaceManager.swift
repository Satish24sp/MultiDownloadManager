// DownloadManagerKit/Sources/DownloadManagerKit/Infrastructure/DiskSpaceManager.swift

import Foundation

/// FileManager-backed disk space inspector.
public final class DefaultDiskSpaceManager: DiskSpaceManaging, @unchecked Sendable {

    public init() {}

    public func availableSpace() throws -> Int64 {
        let values = try URL.documentsDirectory.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
        return values.volumeAvailableCapacityForImportantUsage ?? 0
    }

    public func totalSpace() throws -> Int64 {
        let values = try URL.documentsDirectory.resourceValues(forKeys: [.volumeTotalCapacityKey])
        return Int64(values.volumeTotalCapacity ?? 0)
    }

    public func usedByApp() throws -> Int64 {
        try FileManager.default.directorySize(at: URL.downloadsDirectory)
    }

    public func hasEnoughSpace(for bytes: Int64) throws -> Bool {
        let available = try availableSpace()
        return available >= bytes
    }
}
