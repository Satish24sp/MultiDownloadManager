// DownloadManagerKit/Sources/DownloadManagerKit/Core/Extensions/URL+Extensions.swift

import Foundation

extension URL {

    /// Extracts a human-readable file name from the URL, falling back to a UUID-based name.
    var inferredFileName: String {
        let name = lastPathComponent
        if name.isEmpty || name == "/" {
            return UUID().uuidString
        }
        return name
    }

    /// The app's Documents directory.
    static var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    /// The default downloads subdirectory inside Documents.
    static var downloadsDirectory: URL {
        documentsDirectory.appendingPathComponent("Downloads", isDirectory: true)
    }
}
