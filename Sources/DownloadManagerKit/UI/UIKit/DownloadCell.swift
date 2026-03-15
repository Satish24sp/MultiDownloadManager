// DownloadManagerKit/Sources/DownloadManagerKit/UI/UIKit/DownloadCell.swift

#if canImport(UIKit)
import UIKit

/// Custom table view cell displaying download progress, speed, and action buttons.
public final class DownloadCell: UITableViewCell {

    public static let reuseIdentifier = "DownloadCell"

    // MARK: - Callbacks

    public var onPause: (() -> Void)?
    public var onResume: (() -> Void)?
    public var onCancel: (() -> Void)?
    public var onRetry: (() -> Void)?

    // MARK: - UI Elements

    private let fileNameLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.adjustsFontForContentSizeCategory = true
        label.lineBreakMode = .byTruncatingMiddle
        return label
    }()

    private let stateLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption2)
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private let speedLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption2)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .secondaryLabel
        return label
    }()

    private let progressBar: UIProgressView = {
        let bar = UIProgressView(progressViewStyle: .default)
        return bar
    }()

    private let percentLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption2)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .secondaryLabel
        return label
    }()

    private let actionButton: UIButton = {
        let button = UIButton(type: .system)
        button.setPreferredSymbolConfiguration(.init(pointSize: 18), forImageIn: .normal)
        return button
    }()

    private let errorLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption1)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .systemRed
        label.numberOfLines = 2
        label.isHidden = true
        return label
    }()

    // MARK: - Layout

    private lazy var topStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [fileNameLabel, stateLabel, speedLabel])
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        fileNameLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        stateLabel.setContentHuggingPriority(.required, for: .horizontal)
        speedLabel.setContentHuggingPriority(.required, for: .horizontal)
        return stack
    }()

    private lazy var progressStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [progressBar, percentLabel])
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        percentLabel.setContentHuggingPriority(.required, for: .horizontal)
        return stack
    }()

    private lazy var mainStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [topStack, progressStack, errorLabel])
        stack.axis = .vertical
        stack.spacing = 6
        return stack
    }()

    // MARK: - Init

    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    private func setupLayout() {
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(mainStack)
        contentView.addSubview(actionButton)

        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            mainStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            mainStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
            mainStack.trailingAnchor.constraint(equalTo: actionButton.leadingAnchor, constant: -12),

            actionButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            actionButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            actionButton.widthAnchor.constraint(equalToConstant: 30)
        ])

        actionButton.addTarget(self, action: #selector(actionTapped), for: .touchUpInside)
    }

    // MARK: - Configure

    public func configure(with item: DownloadItem) {
        fileNameLabel.text = item.fileName
        stateLabel.text = item.state.displayName
        stateLabel.textColor = stateColor(for: item.state)

        let showProgress = item.state == .downloading || item.state == .paused
        progressStack.isHidden = !showProgress
        progressBar.progress = Float(item.progress)
        percentLabel.text = "\(item.percentComplete)%"

        if item.state == .downloading {
            speedLabel.text = "\(item.formattedSpeed)"
            if let eta = item.formattedETA { speedLabel.text! += " — \(eta)" }
            speedLabel.isHidden = false
        } else {
            speedLabel.isHidden = true
        }

        if let error = item.error {
            errorLabel.text = error.localizedDescription
            errorLabel.isHidden = false
        } else {
            errorLabel.isHidden = true
        }

        currentState = item.state
        configureActionButton(for: item.state)

        isAccessibilityElement = true
        accessibilityLabel = "\(item.fileName), \(item.state.displayName)"
        if showProgress {
            accessibilityValue = "\(item.percentComplete) percent"
        }
    }

    private func configureActionButton(for state: DownloadState) {
        switch state {
        case .downloading:
            actionButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
            actionButton.accessibilityLabel = NSLocalizedString("Pause", comment: "Action")
        case .paused:
            actionButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
            actionButton.accessibilityLabel = NSLocalizedString("Resume", comment: "Action")
        case .failed, .cancelled:
            actionButton.setImage(UIImage(systemName: "arrow.clockwise"), for: .normal)
            actionButton.accessibilityLabel = NSLocalizedString("Retry", comment: "Action")
        case .pending, .queued:
            actionButton.setImage(UIImage(systemName: "xmark.circle"), for: .normal)
            actionButton.accessibilityLabel = NSLocalizedString("Cancel", comment: "Action")
        case .completed:
            actionButton.setImage(UIImage(systemName: "checkmark.circle.fill"), for: .normal)
            actionButton.tintColor = .systemGreen
            actionButton.isUserInteractionEnabled = false
        }
    }

    private var currentState: DownloadState = .pending

    @objc private func actionTapped() {
        switch currentState {
        case .downloading: onPause?()
        case .paused:      onResume?()
        case .failed, .cancelled: onRetry?()
        case .pending, .queued:   onCancel?()
        case .completed: break
        }
    }

    public override func prepareForReuse() {
        super.prepareForReuse()
        onPause = nil
        onResume = nil
        onCancel = nil
        onRetry = nil
        actionButton.isUserInteractionEnabled = true
        actionButton.tintColor = nil
    }

    private func stateColor(for state: DownloadState) -> UIColor {
        switch state {
        case .downloading: return .systemBlue
        case .completed:   return .systemGreen
        case .paused:      return .systemOrange
        case .failed:      return .systemRed
        case .cancelled:   return .systemGray
        case .pending, .queued: return .secondaryLabel
        }
    }
}
#endif
