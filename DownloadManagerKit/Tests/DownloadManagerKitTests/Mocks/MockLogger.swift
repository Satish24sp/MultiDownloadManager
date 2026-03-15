// Tests/DownloadManagerKitTests/Mocks/MockLogger.swift

import Foundation
@testable import DownloadManagerKit

final class MockLogger: DownloadLogging, @unchecked Sendable {

    struct LogEntry {
        let level: LogLevel
        let category: LogCategory
        let message: String
    }

    private let lock = NSLock()
    private var _entries: [LogEntry] = []

    var entries: [LogEntry] {
        lock.lock()
        defer { lock.unlock() }
        return _entries
    }

    func log(_ level: LogLevel, category: LogCategory, message: String, file: String, function: String, line: Int) {
        lock.lock()
        defer { lock.unlock() }
        _entries.append(LogEntry(level: level, category: category, message: message))
    }

    func reset() {
        lock.lock()
        defer { lock.unlock() }
        _entries.removeAll()
    }

    func hasEntry(level: LogLevel? = nil, category: LogCategory? = nil, containing substring: String? = nil) -> Bool {
        entries.contains { entry in
            if let level, entry.level != level { return false }
            if let category, entry.category != category { return false }
            if let substring, !entry.message.contains(substring) { return false }
            return true
        }
    }
}
