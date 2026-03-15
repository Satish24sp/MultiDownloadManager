// DownloadManagerKit/Sources/DownloadManagerKit/UI/UIKit/DownloadsTabBarController.swift

#if canImport(UIKit)
import UIKit
import Combine

/// UIKit tab bar controller mirroring the SwiftUI DownloadsTabView.
public final class DownloadsTabBarController: UITabBarController {

    private let container: DependencyContainer

    public init(container: DependencyContainer) {
        self.container = container
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("Use init(container:)") }

    public override func viewDidLoad() {
        super.viewDidLoad()

        let downloadsVC = UINavigationController(
            rootViewController: DownloadListViewController(
                manager: container.downloadManager,
                settings: container.settingsManager
            )
        )
        downloadsVC.tabBarItem = UITabBarItem(
            title: NSLocalizedString("Downloads", comment: "Tab title"),
            image: UIImage(systemName: "arrow.down.circle"),
            selectedImage: UIImage(systemName: "arrow.down.circle.fill")
        )

        let activeVC = UINavigationController(
            rootViewController: DownloadListViewController(
                manager: container.downloadManager,
                settings: container.settingsManager,
                filter: .active
            )
        )
        activeVC.tabBarItem = UITabBarItem(
            title: NSLocalizedString("Active", comment: "Tab title"),
            image: UIImage(systemName: "play.circle"),
            selectedImage: UIImage(systemName: "play.circle.fill")
        )

        let completedVC = UINavigationController(
            rootViewController: DownloadListViewController(
                manager: container.downloadManager,
                settings: container.settingsManager,
                filter: .completed
            )
        )
        completedVC.tabBarItem = UITabBarItem(
            title: NSLocalizedString("Completed", comment: "Tab title"),
            image: UIImage(systemName: "checkmark.circle"),
            selectedImage: UIImage(systemName: "checkmark.circle.fill")
        )

        let settingsVC = UINavigationController(
            rootViewController: SettingsViewController(settings: container.settingsManager)
        )
        settingsVC.tabBarItem = UITabBarItem(
            title: NSLocalizedString("Settings", comment: "Tab title"),
            image: UIImage(systemName: "gear"),
            selectedImage: UIImage(systemName: "gear")
        )

        viewControllers = [downloadsVC, activeVC, completedVC, settingsVC]
    }
}
#endif
