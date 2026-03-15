// DownloadManagerKit/Sources/DownloadManagerKit/UI/SwiftUI/ActiveDownloadsView.swift

import SwiftUI

/// Filtered list showing only active downloads (downloading, queued, pending, paused).
public struct ActiveDownloadsView: View {

    @ObservedObject var viewModel: DownloadViewModel

    public init(viewModel: DownloadViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        Group {
            if viewModel.activeDownloads.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(viewModel.activeDownloads) { item in
                        DownloadRowView(
                            item: item,
                            onPause: { viewModel.pause(id: item.id) },
                            onResume: { viewModel.resume(id: item.id) },
                            onCancel: { viewModel.cancel(id: item.id) },
                            onRetry: { viewModel.retry(id: item.id) },
                            onDelete: { viewModel.delete(id: item.id) }
                        )
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle(NSLocalizedString("Active", comment: "Screen title"))
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button(NSLocalizedString("Pause All", comment: "Action")) { viewModel.pauseAll() }
                    .disabled(viewModel.activeDownloads.allSatisfy { $0.state != .downloading })
                Button(NSLocalizedString("Resume All", comment: "Action")) { viewModel.resumeAll() }
                    .disabled(viewModel.activeDownloads.allSatisfy { $0.state != .paused })
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "play.circle.dotted")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
            Text(NSLocalizedString("No Active Downloads", comment: "Empty state title"))
                .font(.title3.weight(.medium))
            Text(NSLocalizedString("Active and queued downloads will appear here", comment: "Empty state subtitle"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
