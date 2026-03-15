// DownloadManagerKit/Sources/DownloadManagerKit/Infrastructure/ChecksumValidator.swift

import Foundation
import CryptoKit

/// SHA-256 file integrity validator using Apple CryptoKit.
public final class DefaultChecksumValidator: ChecksumValidating, @unchecked Sendable {

    public init() {}

    public func sha256(of fileURL: URL) throws -> String {
        let handle = try FileHandle(forReadingFrom: fileURL)
        defer { handle.closeFile() }

        var hasher = SHA256()
        let bufferSize = 1_048_576 // 1 MB chunks

        while autoreleasepool(invoking: {
            let data = handle.readData(ofLength: bufferSize)
            guard !data.isEmpty else { return false }
            hasher.update(data: data)
            return true
        }) {}

        let digest = hasher.finalize()
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    public func validate(fileURL: URL, expectedChecksum: String) throws -> Bool {
        let actual = try sha256(of: fileURL)
        return actual.lowercased() == expectedChecksum.lowercased()
    }
}
