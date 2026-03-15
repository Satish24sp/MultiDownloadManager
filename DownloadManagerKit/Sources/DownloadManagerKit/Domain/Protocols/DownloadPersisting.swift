// DownloadManagerKit/Sources/DownloadManagerKit/Domain/Protocols/DownloadPersisting.swift

import Foundation

/// Abstracts the storage back-end for download records.
/// Default implementation uses JSON file storage; swap in CoreData/SwiftData via DI.
public protocol DownloadPersisting: Sendable {

    /// Persist the entire list of download records (replaces previous data).
    func saveAll(_ records: [DownloadRecord]) throws

    /// Load all persisted download records.
    func loadAll() throws -> [DownloadRecord]

    /// Persist or update a single download record.
    func save(_ record: DownloadRecord) throws

    /// Remove a download record by identifier.
    func delete(id: UUID) throws

    /// Remove all persisted records.
    func deleteAll() throws
}
