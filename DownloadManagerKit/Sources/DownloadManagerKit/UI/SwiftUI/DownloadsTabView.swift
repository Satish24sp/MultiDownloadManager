// DownloadManagerKit/Sources/DownloadManagerKit/UI/SwiftUI/DownloadsTabView.swift

import SwiftUI

/// Root tab container for the download manager UI.
public struct DownloadsTabView: View {

    @ObservedObject var viewModel: DownloadViewModel

    public init(viewModel: DownloadViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        TabView {
            NavigationView {
                DownloadListView(viewModel: viewModel)
            }
            .navigationViewStyle(.stack)
            .tabItem {
                Label(
                    NSLocalizedString("Downloads", comment: "Tab title"),
                    systemImage: "arrow.down.circle"
                )
            }

            NavigationView {
                ActiveDownloadsView(viewModel: viewModel)
            }
            .navigationViewStyle(.stack)
            .tabItem {
                Label(
                    NSLocalizedString("Active", comment: "Tab title"),
                    systemImage: "play.circle"
                )
            }

            NavigationView {
                CompletedDownloadsView(viewModel: viewModel)
            }
            .navigationViewStyle(.stack)
            .tabItem {
                Label(
                    NSLocalizedString("Completed", comment: "Tab title"),
                    systemImage: "checkmark.circle"
                )
            }

            NavigationView {
                SettingsView(settings: viewModel.settings)
            }
            .navigationViewStyle(.stack)
            .tabItem {
                Label(
                    NSLocalizedString("Settings", comment: "Tab title"),
                    systemImage: "gear"
                )
            }
        }
    }
}
