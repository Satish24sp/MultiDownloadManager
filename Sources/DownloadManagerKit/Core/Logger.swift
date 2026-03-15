// DownloadManagerKit/Sources/DownloadManagerKit/Core/Logger.swift

import Foundation
import os.log

/// Production logger backed by Apple's unified logging system (os.Logger).
public final class DefaultLogger: DownloadLogging, @unchecked Sendable {

    private let subsystem: String
    private let loggers: [LogCategory: os.Logger]

    public init(subsystem: String = "com.app.downloadmanager") {
        self.subsystem = subsystem
        var map = [LogCategory: os.Logger]()
        for category in [LogCategory.download, .network, .persistence, .notification, .general] {
            map[category] = os.Logger(subsystem: subsystem, category: category.rawValue)
        }
        self.loggers = map
    }

    public func log(
        _ level: LogLevel,
        category: LogCategory,
        message: String,
        file: String,
        function: String,
        line: Int
    ) {
        let logger = loggers[category] ?? os.Logger(subsystem: subsystem, category: category.rawValue)
        let fileName = (file as NSString).lastPathComponent

        switch level {
        case .debug:
            logger.debug("[\(fileName):\(line)] \(function) — \(message)")
        case .info:
            logger.info("[\(fileName):\(line)] \(function) — \(message)")
        case .warning:
            logger.warning("[\(fileName):\(line)] \(function) — \(message)")
        case .error:
            logger.error("[\(fileName):\(line)] \(function) — \(message)")
        }
    }
}
