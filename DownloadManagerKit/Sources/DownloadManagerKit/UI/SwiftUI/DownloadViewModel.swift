// DownloadManagerKit/Sources/DownloadManagerKit/UI/SwiftUI/DownloadViewModel.swift

import Foundation
import Combine
import SwiftUI

/// Observable view model that bridges the download manager into SwiftUI.
@MainActor
public final class DownloadViewModel: ObservableObject {

    @Published public var downloads: [DownloadItem] = []
    @Published public var activeDownloads: [DownloadItem] = []
    @Published public var completedDownloads: [DownloadItem] = []
    @Published public var errorMessage: String?

    public let manager: any DownloadManaging
    public let settings: any SettingsManaging
    public let diskSpaceManager: any DiskSpaceManaging

    private var cancellables = Set<AnyCancellable>()

    public init(
        manager: any DownloadManaging,
        settings: any SettingsManaging,
        diskSpaceManager: any DiskSpaceManaging
    ) {
        self.manager = manager
        self.settings = settings
        self.diskSpaceManager = diskSpaceManager
        setupBindings()
    }

    /// Convenience initializer from a DependencyContainer.
    public convenience init(container: DependencyContainer) {
        self.init(
            manager: container.downloadManager,
            settings: container.settingsManager,
            diskSpaceManager: container.diskSpaceManager
        )
    }

    private func setupBindings() {
        manager.downloadsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] items in
                self?.downloads = items
                self?.activeDownloads = items.filter {
                    $0.state == .downloading || $0.state == .queued || $0.state == .pending || $0.state == .paused
                }
                self?.completedDownloads = items.filter { $0.state == .completed }
            }
            .store(in: &cancellables)
    }

    // MARK: - Actions

    public func startDownload(url: URL, fileName: String? = nil, priority: DownloadPriority = .normal) {
        let request = DownloadRequest(url: url, fileName: fileName, priority: priority)
        Task {
            do {
                try await manager.startDownload(request)
                errorMessage = nil
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    public func pause(id: UUID) {
        Task { try? await manager.pauseDownload(id: id) }
    }

    public func resume(id: UUID) {
        Task { try? await manager.resumeDownload(id: id) }
    }

    public func cancel(id: UUID) {
        Task { try? await manager.cancelDownload(id: id) }
    }

    public func delete(id: UUID) {
        Task { try? await manager.deleteDownload(id: id) }
    }

    public func retry(id: UUID) {
        Task { try? await manager.retryDownload(id: id) }
    }

    public func pauseAll() {
        Task { await manager.pauseAll() }
    }

    public func resumeAll() {
        Task { await manager.resumeAll() }
    }
}
