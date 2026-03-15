// DownloadManagerKit/Sources/DownloadManagerKit/UI/SwiftUI/StorageInfoView.swift

import SwiftUI

/// Displays device storage statistics relevant to downloads.
public struct StorageInfoView: View {

    private let diskSpaceManager: any DiskSpaceManaging

    @State private var totalSpace: Int64 = 0
    @State private var availableSpace: Int64 = 0
    @State private var usedByApp: Int64 = 0

    public init(diskSpaceManager: any DiskSpaceManaging) {
        self.diskSpaceManager = diskSpaceManager
    }

    public var body: some View {
        Form {
            Section {
                row(title: NSLocalizedString("Total Disk Space", comment: "Storage label"), bytes: totalSpace)
                row(title: NSLocalizedString("Available Space", comment: "Storage label"), bytes: availableSpace)
                row(title: NSLocalizedString("Used by Downloads", comment: "Storage label"), bytes: usedByApp)
            } header: {
                Text(NSLocalizedString("Storage", comment: "Section header"))
            }

            Section {
                storageBar
            }
        }
        .navigationTitle(NSLocalizedString("Storage Info", comment: "Screen title"))
        .task { loadStats() }
        .refreshable { loadStats() }
    }

    private func row(title: String, bytes: Int64) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file))
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }

    private var storageBar: some View {
        GeometryReader { proxy in
            let usedFraction = totalSpace > 0 ? CGFloat(totalSpace - availableSpace) / CGFloat(totalSpace) : 0
            let appFraction = totalSpace > 0 ? CGFloat(usedByApp) / CGFloat(totalSpace) : 0

            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(.systemGray5))

                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.blue.opacity(0.4))
                    .frame(width: proxy.size.width * usedFraction)

                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.blue)
                    .frame(width: proxy.size.width * appFraction)
            }
        }
        .frame(height: 24)
        .accessibilityLabel(
            String(
                format: NSLocalizedString(
                    "%@ used by downloads out of %@ total",
                    comment: "Storage accessibility"
                ),
                ByteCountFormatter.string(fromByteCount: usedByApp, countStyle: .file),
                ByteCountFormatter.string(fromByteCount: totalSpace, countStyle: .file)
            )
        )
    }

    private func loadStats() {
        totalSpace = (try? diskSpaceManager.totalSpace()) ?? 0
        availableSpace = (try? diskSpaceManager.availableSpace()) ?? 0
        usedByApp = (try? diskSpaceManager.usedByApp()) ?? 0
    }
}
