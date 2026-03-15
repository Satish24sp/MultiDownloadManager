// Tests/DownloadManagerKitTests/PersistenceTests.swift

import XCTest
@testable import DownloadManagerKit

final class PersistenceTests: XCTestCase {

    private var persistence: JSONDownloadPersistence!
    private var tempDirectory: URL!

    override func setUp() {
        super.setUp()
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try! FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        persistence = JSONDownloadPersistence(
            storageDirectory: tempDirectory,
            logger: MockLogger()
        )
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDirectory)
        super.tearDown()
    }

    // MARK: - Save & Load

    func testSaveAll_and_loadAll_roundTrips() throws {
        let records = [makeRecord(), makeRecord()]
        try persistence.saveAll(records)

        let loaded = try persistence.loadAll()
        XCTAssertEqual(loaded.count, 2)
        XCTAssertEqual(loaded[0].id, records[0].id)
        XCTAssertEqual(loaded[1].id, records[1].id)
    }

    func testLoadAll_emptyWhenNoFile() throws {
        let loaded = try persistence.loadAll()
        XCTAssertTrue(loaded.isEmpty)
    }

    // MARK: - Save Single

    func testSave_addsNewRecord() throws {
        let record = makeRecord()
        try persistence.save(record)

        let loaded = try persistence.loadAll()
        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded[0].id, record.id)
    }

    func testSave_updatesExistingRecord() throws {
        var record = makeRecord()
        try persistence.save(record)

        record.progress = 0.75
        record.state = .downloading
        try persistence.save(record)

        let loaded = try persistence.loadAll()
        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded[0].progress, 0.75)
        XCTAssertEqual(loaded[0].state, .downloading)
    }

    // MARK: - Delete

    func testDelete_removesById() throws {
        let r1 = makeRecord()
        let r2 = makeRecord()
        try persistence.saveAll([r1, r2])

        try persistence.delete(id: r1.id)

        let loaded = try persistence.loadAll()
        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded[0].id, r2.id)
    }

    func testDeleteAll_removesEverything() throws {
        try persistence.saveAll([makeRecord(), makeRecord(), makeRecord()])
        try persistence.deleteAll()

        let loaded = try persistence.loadAll()
        XCTAssertTrue(loaded.isEmpty)
    }

    // MARK: - Schema Version

    func testPersistedStore_includesSchemaVersion() throws {
        try persistence.saveAll([makeRecord()])

        let fileURL = tempDirectory.appendingPathComponent("downloads.json")
        let data = try Data(contentsOf: fileURL)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let store = try decoder.decode(PersistedDownloadStore.self, from: data)
        XCTAssertEqual(store.schemaVersion, PersistedDownloadStore.currentSchemaVersion)
    }

    // MARK: - Helpers

    private func makeRecord() -> DownloadRecord {
        DownloadRecord(
            id: UUID(),
            url: URL(string: "https://example.com/\(UUID().uuidString).zip")!,
            state: .pending,
            progress: 0,
            resumeData: nil,
            filePath: nil,
            fileName: "test.zip",
            mimeType: nil,
            totalBytes: nil,
            downloadedBytes: 0,
            priority: .normal,
            createdDate: Date(),
            completedDate: nil,
            errorDescription: nil,
            retryCount: 0,
            headers: nil,
            expectedChecksum: nil
        )
    }
}
