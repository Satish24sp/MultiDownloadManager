import SwiftUI
import DownloadManagerKit

@main
struct DemoApp: App {
    @State private var container: DependencyContainer?

    var body: some Scene {
        WindowGroup {
            Group {
                if let container = container {
                    DownloadsTabView(viewModel: DownloadViewModel(container: container))
                } else {
                    ProgressView("Starting Download Manager…")
                        .task {
                            container = await DependencyContainer.create()
                        }
                }
            }
        }
    }
}
