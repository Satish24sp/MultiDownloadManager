// DownloadManagerKit/Sources/DownloadManagerKit/Core/Extensions/FileManager+Extensions.swift

import Foundation

extension FileManager {

    /// Ensures a directory exists at the given URL, creating it if necessary.
    func ensureDirectoryExists(at url: URL) throws {
        if !fileExists(atPath: url.path) {
            try createDirectory(at: url, withIntermediateDirectories: true)
        }
    }

    /// Total size of all files in a directory (non-recursive by default).
    func directorySize(at url: URL) throws -> Int64 {
        guard let enumerator = enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey], options: [.skipsHiddenFiles]) else {
            return 0
        }
        var total: Int64 = 0
        for case let fileURL as URL in enumerator {
            let resourceValues = try fileURL.resourceValues(forKeys: [.fileSizeKey])
            total += Int64(resourceValues.fileSize ?? 0)
        }
        return total
    }

    /// Generates a unique file path by appending a counter if a file already exists.
    func uniqueFileURL(directory: URL, fileName: String) -> URL {
        let baseURL = directory.appendingPathComponent(fileName)
        if !fileExists(atPath: baseURL.path) {
            return baseURL
        }

        let name = (fileName as NSString).deletingPathExtension
        let ext = (fileName as NSString).pathExtension
        var counter = 1

        while true {
            let candidateName = ext.isEmpty ? "\(name) (\(counter))" : "\(name) (\(counter)).\(ext)"
            let candidate = directory.appendingPathComponent(candidateName)
            if !fileExists(atPath: candidate.path) {
                return candidate
            }
            counter += 1
        }
    }
}
