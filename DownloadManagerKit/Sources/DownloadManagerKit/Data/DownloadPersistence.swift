// DownloadManagerKit/Sources/DownloadManagerKit/Data/DownloadPersistence.swift

import Foundation

/// JSON file-based persistence for download records.
/// Data is stored at `Documents/DownloadManagerKit/downloads.json`.
public final class JSONDownloadPersistence: DownloadPersisting, @unchecked Sendable {

    private let fileURL: URL
    private let queue = DispatchQueue(label: "com.downloadmanagerkit.persistence", qos: .utility)
    private let logger: any DownloadLogging
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(
        storageDirectory: URL? = nil,
        logger: any DownloadLogging
    ) {
        let directory = storageDirectory ?? URL.documentsDirectory.appendingPathComponent("DownloadManagerKit", isDirectory: true)
        self.fileURL = directory.appendingPathComponent("downloads.json")
        self.logger = logger

        let enc = JSONEncoder()
        enc.dateEncodingStrategy = .iso8601
        enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.encoder = enc

        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        self.decoder = dec

        try? FileManager.default.ensureDirectoryExists(at: directory)
    }

    public func saveAll(_ records: [DownloadRecord]) throws {
        try queue.sync {
            let store = PersistedDownloadStore(records: records)
            let data = try encoder.encode(store)
            try data.write(to: fileURL, options: .atomic)
            logger.debug("Persisted \(records.count) records", category: .persistence)
        }
    }

    public func loadAll() throws -> [DownloadRecord] {
        try queue.sync {
            guard FileManager.default.fileExists(atPath: fileURL.path) else {
                return []
            }
            let data = try Data(contentsOf: fileURL)
            let store = try decoder.decode(PersistedDownloadStore.self, from: data)
            logger.debug("Loaded \(store.records.count) records (schema v\(store.schemaVersion))", category: .persistence)
            return store.records
        }
    }

    public func save(_ record: DownloadRecord) throws {
        try queue.sync {
            var records = (try? loadAllUnsafe()) ?? []
            if let index = records.firstIndex(where: { $0.id == record.id }) {
                records[index] = record
            } else {
                records.append(record)
            }
            let store = PersistedDownloadStore(records: records)
            let data = try encoder.encode(store)
            try data.write(to: fileURL, options: .atomic)
        }
    }

    public func delete(id: UUID) throws {
        try queue.sync {
            var records = (try? loadAllUnsafe()) ?? []
            records.removeAll { $0.id == id }
            let store = PersistedDownloadStore(records: records)
            let data = try encoder.encode(store)
            try data.write(to: fileURL, options: .atomic)
        }
    }

    public func deleteAll() throws {
        try queue.sync {
            if FileManager.default.fileExists(atPath: fileURL.path) {
                try FileManager.default.removeItem(at: fileURL)
            }
        }
    }

    /// Non-synchronized load — only call from within `queue.sync`.
    private func loadAllUnsafe() throws -> [DownloadRecord] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return [] }
        let data = try Data(contentsOf: fileURL)
        let store = try decoder.decode(PersistedDownloadStore.self, from: data)
        return store.records
    }
}
