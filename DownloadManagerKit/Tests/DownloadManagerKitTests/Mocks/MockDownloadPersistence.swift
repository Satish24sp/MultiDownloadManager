// Tests/DownloadManagerKitTests/Mocks/MockDownloadPersistence.swift

import Foundation
@testable import DownloadManagerKit

final class MockDownloadPersistence: DownloadPersisting, @unchecked Sendable {

    var records: [DownloadRecord] = []
    var saveAllCalled = false
    var loadAllCalled = false
    var saveCalled = false
    var deleteCalled = false
    var deleteAllCalled = false
    var shouldThrowOnSave = false
    var shouldThrowOnLoad = false

    func saveAll(_ records: [DownloadRecord]) throws {
        saveAllCalled = true
        if shouldThrowOnSave { throw TestError.mockError }
        self.records = records
    }

    func loadAll() throws -> [DownloadRecord] {
        loadAllCalled = true
        if shouldThrowOnLoad { throw TestError.mockError }
        return records
    }

    func save(_ record: DownloadRecord) throws {
        saveCalled = true
        if shouldThrowOnSave { throw TestError.mockError }
        if let index = records.firstIndex(where: { $0.id == record.id }) {
            records[index] = record
        } else {
            records.append(record)
        }
    }

    func delete(id: UUID) throws {
        deleteCalled = true
        records.removeAll { $0.id == id }
    }

    func deleteAll() throws {
        deleteAllCalled = true
        records.removeAll()
    }
}

enum TestError: Error {
    case mockError
}
