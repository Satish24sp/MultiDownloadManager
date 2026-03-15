// DownloadManagerKit/Sources/DownloadManagerKit/UI/UIKit/DownloadListViewController.swift

#if canImport(UIKit)
import UIKit
import Combine

/// Filter mode for the download list.
public enum DownloadListFilter: Sendable {
    case all
    case active
    case completed
}

/// Table-view-based download list with Combine-driven updates.
public final class DownloadListViewController: UITableViewController {

    private let manager: any DownloadManaging
    private let settings: any SettingsManaging
    private let filter: DownloadListFilter
    private var downloads: [DownloadItem] = []
    private var cancellables = Set<AnyCancellable>()

    public init(
        manager: any DownloadManaging,
        settings: any SettingsManaging,
        filter: DownloadListFilter = .all
    ) {
        self.manager = manager
        self.settings = settings
        self.filter = filter
        super.init(style: .plain)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    public override func viewDidLoad() {
        super.viewDidLoad()

        switch filter {
        case .all:       title = NSLocalizedString("Downloads", comment: "Screen title")
        case .active:    title = NSLocalizedString("Active", comment: "Screen title")
        case .completed: title = NSLocalizedString("Completed", comment: "Screen title")
        }

        tableView.register(DownloadCell.self, forCellReuseIdentifier: DownloadCell.reuseIdentifier)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 80

        let refresh = UIRefreshControl()
        refresh.addTarget(self, action: #selector(didPullToRefresh), for: .valueChanged)
        refreshControl = refresh

        if filter == .all {
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                barButtonSystemItem: .add,
                target: self,
                action: #selector(addDownloadTapped)
            )
        }

        setupBindings()
    }

    // MARK: - Bindings

    private func setupBindings() {
        manager.downloadsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] items in
                guard let self else { return }
                self.downloads = self.applyFilter(items)
                self.tableView.reloadData()
            }
            .store(in: &cancellables)
    }

    private func applyFilter(_ items: [DownloadItem]) -> [DownloadItem] {
        switch filter {
        case .all:
            return items
        case .active:
            return items.filter { $0.state == .downloading || $0.state == .queued || $0.state == .pending || $0.state == .paused }
        case .completed:
            return items.filter { $0.state == .completed }
        }
    }

    // MARK: - Actions

    @objc private func didPullToRefresh() {
        Task {
            _ = await manager.getAllDownloads()
            await MainActor.run { refreshControl?.endRefreshing() }
        }
    }

    @objc private func addDownloadTapped() {
        let alert = UIAlertController(
            title: NSLocalizedString("New Download", comment: "Alert title"),
            message: NSLocalizedString("Enter the download URL", comment: "Alert message"),
            preferredStyle: .alert
        )
        alert.addTextField { tf in
            tf.placeholder = "https://example.com/file.zip"
            tf.keyboardType = .URL
            tf.autocapitalizationType = .none
            tf.autocorrectionType = .no
        }
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Action"), style: .cancel))
        alert.addAction(UIAlertAction(title: NSLocalizedString("Download", comment: "Action"), style: .default) { [weak self] _ in
            guard let text = alert.textFields?.first?.text,
                  let url = URL(string: text), url.scheme != nil else { return }
            Task {
                try? await self?.manager.startDownload(DownloadRequest(url: url))
            }
        })
        present(alert, animated: true)
    }

    // MARK: - TableView DataSource

    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if downloads.isEmpty {
            showEmptyState()
        } else {
            tableView.backgroundView = nil
        }
        return downloads.count
    }

    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: DownloadCell.reuseIdentifier, for: indexPath) as! DownloadCell
        let item = downloads[indexPath.row]
        cell.configure(with: item)
        cell.onPause  = { [weak self] in Task { try? await self?.manager.pauseDownload(id: item.id) } }
        cell.onResume = { [weak self] in Task { try? await self?.manager.resumeDownload(id: item.id) } }
        cell.onCancel = { [weak self] in Task { try? await self?.manager.cancelDownload(id: item.id) } }
        cell.onRetry  = { [weak self] in Task { try? await self?.manager.retryDownload(id: item.id) } }
        return cell
    }

    // MARK: - Swipe Actions

    public override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let item = downloads[indexPath.row]
        let delete = UIContextualAction(style: .destructive, title: NSLocalizedString("Delete", comment: "Swipe action")) { [weak self] _, _, completion in
            Task {
                try? await self?.manager.deleteDownload(id: item.id)
                completion(true)
            }
        }
        return UISwipeActionsConfiguration(actions: [delete])
    }

    public override func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let item = downloads[indexPath.row]
        var actions: [UIContextualAction] = []

        if item.state == .downloading {
            let pause = UIContextualAction(style: .normal, title: NSLocalizedString("Pause", comment: "Swipe")) { [weak self] _, _, completion in
                Task { try? await self?.manager.pauseDownload(id: item.id); completion(true) }
            }
            pause.backgroundColor = .systemOrange
            actions.append(pause)
        } else if item.state == .paused {
            let resume = UIContextualAction(style: .normal, title: NSLocalizedString("Resume", comment: "Swipe")) { [weak self] _, _, completion in
                Task { try? await self?.manager.resumeDownload(id: item.id); completion(true) }
            }
            resume.backgroundColor = .systemBlue
            actions.append(resume)
        }

        return UISwipeActionsConfiguration(actions: actions)
    }

    // MARK: - Empty State

    private func showEmptyState() {
        let label = UILabel()
        label.text = NSLocalizedString("No Downloads", comment: "Empty state")
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        label.font = .preferredFont(forTextStyle: .title3)
        tableView.backgroundView = label
    }
}
#endif
