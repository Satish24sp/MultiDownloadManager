// DownloadManagerKit/Sources/DownloadManagerKit/UI/SwiftUI/SidebarNavigationView.swift

#if canImport(UIKit)
import SwiftUI
import UIKit

/// Adaptive layout: sidebar on iPad, tab bar on iPhone.
/// Uses NavigationSplitView on iPad and falls back to DownloadsTabView on iPhone.
public struct SidebarNavigationView: View {

    @ObservedObject var viewModel: DownloadViewModel
    @State private var selectedItem: SidebarItem? = .downloads

    public init(viewModel: DownloadViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        if UIDevice.current.userInterfaceIdiom == .pad {
            NavigationView {
                List(SidebarItem.allCases, selection: $selectedItem) { item in
                    Label(item.title, systemImage: item.icon)
                        .tag(item)
                }
                .navigationTitle(NSLocalizedString("Download Manager", comment: "Sidebar title"))
                detailView
            }
            .navigationViewStyle(.columns)
        } else {
            DownloadsTabView(viewModel: viewModel)
        }
    }

    @ViewBuilder
    private var detailView: some View {
        switch selectedItem {
        case .downloads:
            NavigationView { DownloadListView(viewModel: viewModel) }.navigationViewStyle(.stack)
        case .active:
            NavigationView { ActiveDownloadsView(viewModel: viewModel) }.navigationViewStyle(.stack)
        case .completed:
            NavigationView { CompletedDownloadsView(viewModel: viewModel) }.navigationViewStyle(.stack)
        case .settings:
            NavigationView { SettingsView(settings: viewModel.settings) }.navigationViewStyle(.stack)
        case .storage:
            NavigationView { StorageInfoView(diskSpaceManager: viewModel.diskSpaceManager) }.navigationViewStyle(.stack)
        case .logs:
            NavigationView { LogsView() }.navigationViewStyle(.stack)
        case .about:
            NavigationView { AboutView() }.navigationViewStyle(.stack)
        case .none:
            Text(NSLocalizedString("Select an item from the sidebar", comment: "Placeholder"))
        }
    }
}

// MARK: - Sidebar Items

private enum SidebarItem: String, CaseIterable, Identifiable {
    case downloads, active, completed, settings, storage, logs, about

    var id: String { rawValue }

    var title: String {
        switch self {
        case .downloads: return NSLocalizedString("Downloads", comment: "Sidebar item")
        case .active:    return NSLocalizedString("Active", comment: "Sidebar item")
        case .completed: return NSLocalizedString("Completed", comment: "Sidebar item")
        case .settings:  return NSLocalizedString("Settings", comment: "Sidebar item")
        case .storage:   return NSLocalizedString("Storage Info", comment: "Sidebar item")
        case .logs:      return NSLocalizedString("Logs", comment: "Sidebar item")
        case .about:     return NSLocalizedString("About", comment: "Sidebar item")
        }
    }

    var icon: String {
        switch self {
        case .downloads: return "arrow.down.circle"
        case .active:    return "play.circle"
        case .completed: return "checkmark.circle"
        case .settings:  return "gear"
        case .storage:   return "internaldrive"
        case .logs:      return "text.alignleft"
        case .about:     return "info.circle"
        }
    }
}

// MARK: - About View

private struct AboutView: View {
    var body: some View {
        Form {
            Section {
                row(label: NSLocalizedString("Name", comment: "About"), value: "DownloadManagerKit")
                row(label: NSLocalizedString("Version", comment: "About"), value: "1.0.0")
                row(label: NSLocalizedString("Platform", comment: "About"), value: "iOS 15+")
                row(label: NSLocalizedString("License", comment: "About"), value: "MIT")
            }

            Section {
                Text(NSLocalizedString(
                    "A production-grade, reusable download manager module built with Clean Architecture, supporting background downloads, priority queuing, and reactive progress tracking.",
                    comment: "About description"
                ))
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(NSLocalizedString("About", comment: "Screen title"))
    }

    private func row(label: String, value: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
    }
}
#endif
