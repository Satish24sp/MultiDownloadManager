// DownloadManagerKit/Sources/DownloadManagerKit/Domain/Protocols/DownloadLogging.swift

import Foundation

/// Log level severity.
public enum LogLevel: Int, Comparable, Sendable {
    case debug = 0
    case info = 1
    case warning = 2
    case error = 3

    public static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

/// Log category for filtering and subsystem routing.
public enum LogCategory: String, Sendable {
    case download
    case network
    case persistence
    case notification
    case general
}

/// Abstraction over the logging subsystem. Inject a mock for silent test output.
public protocol DownloadLogging: Sendable {

    /// Emit a log message.
    func log(_ level: LogLevel, category: LogCategory, message: String, file: String, function: String, line: Int)
}

extension DownloadLogging {
    public func debug(_ message: String, category: LogCategory = .general, file: String = #file, function: String = #function, line: Int = #line) {
        log(.debug, category: category, message: message, file: file, function: function, line: line)
    }

    public func info(_ message: String, category: LogCategory = .general, file: String = #file, function: String = #function, line: Int = #line) {
        log(.info, category: category, message: message, file: file, function: function, line: line)
    }

    public func warning(_ message: String, category: LogCategory = .general, file: String = #file, function: String = #function, line: Int = #line) {
        log(.warning, category: category, message: message, file: file, function: function, line: line)
    }

    public func error(_ message: String, category: LogCategory = .general, file: String = #file, function: String = #function, line: Int = #line) {
        log(.error, category: category, message: message, file: file, function: function, line: line)
    }
}
