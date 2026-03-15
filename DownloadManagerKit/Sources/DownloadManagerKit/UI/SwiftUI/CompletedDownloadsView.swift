// DownloadManagerKit/Sources/DownloadManagerKit/UI/SwiftUI/CompletedDownloadsView.swift

import SwiftUI

/// Filtered list showing only completed downloads.
public struct CompletedDownloadsView: View {

    @ObservedObject var viewModel: DownloadViewModel

    public init(viewModel: DownloadViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        Group {
            if viewModel.completedDownloads.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(viewModel.completedDownloads) { item in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.fileName)
                                    .font(.subheadline.weight(.medium))
                                    .lineLimit(1)
                                HStack(spacing: 8) {
                                    if let size = item.formattedTotalSize {
                                        Text(size)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    if let date = item.completedDate {
                                        Text(date, style: .relative)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                viewModel.delete(id: item.id)
                            } label: {
                                Label(NSLocalizedString("Delete", comment: "Swipe action"), systemImage: "trash")
                            }
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(item.fileName), completed")
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle(NSLocalizedString("Completed", comment: "Screen title"))
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.dotted")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
            Text(NSLocalizedString("No Completed Downloads", comment: "Empty state title"))
                .font(.title3.weight(.medium))
            Text(NSLocalizedString("Finished downloads will appear here", comment: "Empty state subtitle"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
