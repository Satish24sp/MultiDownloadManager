// DownloadManagerKit/Sources/DownloadManagerKit/UI/UIKit/SettingsViewController.swift

#if canImport(UIKit)
import UIKit

/// UIKit settings screen backed by any SettingsManaging implementation.
public final class SettingsViewController: UITableViewController {

    private let settings: any SettingsManaging

    private enum Section: Int, CaseIterable {
        case notifications
        case performance
        case recovery
        case network
    }

    public init(settings: any SettingsManaging) {
        self.settings = settings
        super.init(style: .insetGrouped)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    public override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("Settings", comment: "Screen title")
    }

    // MARK: - DataSource

    public override func numberOfSections(in tableView: UITableView) -> Int {
        Section.allCases.count
    }

    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section)! {
        case .notifications: return 1
        case .performance:   return 1
        case .recovery:      return 3
        case .network:       return 2
        }
    }

    public override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch Section(rawValue: section)! {
        case .notifications: return NSLocalizedString("Notifications", comment: "Section")
        case .performance:   return NSLocalizedString("Performance", comment: "Section")
        case .recovery:      return NSLocalizedString("Recovery", comment: "Section")
        case .network:       return NSLocalizedString("Network", comment: "Section")
        }
    }

    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch Section(rawValue: indexPath.section)! {
        case .notifications:
            return makeDetailCell(
                title: NSLocalizedString("Progress Display", comment: "Settings"),
                detail: settings.progressDisplayOption.displayName,
                indexPath: indexPath
            )

        case .performance:
            return makeDetailCell(
                title: NSLocalizedString("Max Concurrent", comment: "Settings"),
                detail: "\(settings.maxConcurrentDownloads)",
                indexPath: indexPath
            )

        case .recovery:
            switch indexPath.row {
            case 0: return makeToggleCell(
                title: NSLocalizedString("Auto Resume", comment: "Settings"),
                isOn: settings.isAutoResumeEnabled,
                tag: 100
            )
            case 1: return makeToggleCell(
                title: NSLocalizedString("Auto Retry", comment: "Settings"),
                isOn: settings.isAutoRetryEnabled,
                tag: 101
            )
            default: return makeDetailCell(
                title: NSLocalizedString("Max Retries", comment: "Settings"),
                detail: "\(settings.maxRetryCount)",
                indexPath: indexPath
            )
            }

        case .network:
            switch indexPath.row {
            case 0: return makeToggleCell(
                title: NSLocalizedString("Allow Cellular", comment: "Settings"),
                isOn: settings.allowsCellularDownloads,
                tag: 200
            )
            default: return makeToggleCell(
                title: NSLocalizedString("WiFi Only", comment: "Settings"),
                isOn: settings.wifiOnlyMode,
                tag: 201
            )
            }
        }
    }

    // MARK: - Cell Factories

    private func makeDetailCell(title: String, detail: String, indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
        cell.textLabel?.text = title
        cell.detailTextLabel?.text = detail
        cell.accessoryType = .disclosureIndicator
        cell.textLabel?.font = .preferredFont(forTextStyle: .body)
        cell.textLabel?.adjustsFontForContentSizeCategory = true
        cell.detailTextLabel?.font = .preferredFont(forTextStyle: .body)
        cell.detailTextLabel?.adjustsFontForContentSizeCategory = true
        return cell
    }

    private func makeToggleCell(title: String, isOn: Bool, tag: Int) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.textLabel?.text = title
        cell.selectionStyle = .none
        cell.textLabel?.font = .preferredFont(forTextStyle: .body)
        cell.textLabel?.adjustsFontForContentSizeCategory = true

        let toggle = UISwitch()
        toggle.isOn = isOn
        toggle.tag = tag
        toggle.addTarget(self, action: #selector(toggleChanged(_:)), for: .valueChanged)
        cell.accessoryView = toggle
        return cell
    }

    @objc private func toggleChanged(_ sender: UISwitch) {
        switch sender.tag {
        case 100: settings.isAutoResumeEnabled = sender.isOn
        case 101: settings.isAutoRetryEnabled = sender.isOn
        case 200: settings.allowsCellularDownloads = sender.isOn
        case 201: settings.wifiOnlyMode = sender.isOn
        default: break
        }
    }

    // MARK: - Selection

    public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        switch Section(rawValue: indexPath.section)! {
        case .notifications where indexPath.row == 0:
            showProgressDisplayPicker()
        case .performance where indexPath.row == 0:
            showStepperAlert(
                title: NSLocalizedString("Max Concurrent Downloads", comment: ""),
                current: settings.maxConcurrentDownloads,
                range: 1...10
            ) { [weak self] value in
                self?.settings.maxConcurrentDownloads = value
                self?.tableView.reloadData()
            }
        case .recovery where indexPath.row == 2:
            showStepperAlert(
                title: NSLocalizedString("Max Retries", comment: ""),
                current: settings.maxRetryCount,
                range: 0...10
            ) { [weak self] value in
                self?.settings.maxRetryCount = value
                self?.tableView.reloadData()
            }
        default:
            break
        }
    }

    private func showProgressDisplayPicker() {
        let alert = UIAlertController(
            title: NSLocalizedString("Progress Display", comment: ""),
            message: nil,
            preferredStyle: .actionSheet
        )
        for option in ProgressDisplayOption.allCases {
            alert.addAction(UIAlertAction(title: option.displayName, style: .default) { [weak self] _ in
                self?.settings.progressDisplayOption = option
                self?.tableView.reloadData()
            })
        }
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel))
        present(alert, animated: true)
    }

    private func showStepperAlert(title: String, current: Int, range: ClosedRange<Int>, completion: @escaping (Int) -> Void) {
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        alert.addTextField { tf in
            tf.text = "\(current)"
            tf.keyboardType = .numberPad
        }
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel))
        alert.addAction(UIAlertAction(title: NSLocalizedString("Save", comment: ""), style: .default) { _ in
            if let text = alert.textFields?.first?.text, let val = Int(text), range.contains(val) {
                completion(val)
            }
        })
        present(alert, animated: true)
    }
}
#endif
