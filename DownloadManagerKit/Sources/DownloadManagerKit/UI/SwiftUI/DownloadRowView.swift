// DownloadManagerKit/Sources/DownloadManagerKit/UI/SwiftUI/DownloadRowView.swift

import SwiftUI

/// A single download row displaying progress, speed, state, and action buttons.
public struct DownloadRowView: View {

    let item: DownloadItem
    let onPause: () -> Void
    let onResume: () -> Void
    let onCancel: () -> Void
    let onRetry: () -> Void
    let onDelete: () -> Void

    public init(
        item: DownloadItem,
        onPause: @escaping () -> Void,
        onResume: @escaping () -> Void,
        onCancel: @escaping () -> Void,
        onRetry: @escaping () -> Void,
        onDelete: @escaping () -> Void
    ) {
        self.item = item
        self.onPause = onPause
        self.onResume = onResume
        self.onCancel = onCancel
        self.onRetry = onRetry
        self.onDelete = onDelete
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                fileIcon
                    .font(.title2)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.fileName)
                        .font(.subheadline.weight(.medium))
                        .lineLimit(1)

                    HStack(spacing: 8) {
                        stateBadge
                        if item.state == .downloading {
                            Text(item.formattedSpeed)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            if let eta = item.formattedETA {
                                Text(eta)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                Spacer()

                actionButtons
            }

            if item.state == .downloading || item.state == .paused {
                VStack(alignment: .leading, spacing: 4) {
                    ProgressView(value: item.progress)
                        .accessibilityValue("\(item.percentComplete) percent")
                    HStack {
                        Text("\(item.percentComplete)%")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Spacer()
                        if let total = item.formattedTotalSize {
                            Text("\(item.formattedDownloadedSize) / \(total)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            if let error = item.error {
                Text(error.localizedDescription)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.fileName), \(item.state.displayName)")
        .accessibilityHint(accessibilityHintText)
    }

    // MARK: - Subviews

    private var fileIcon: some View {
        let name: String = {
            let ext = (item.fileName as NSString).pathExtension.lowercased()
            switch ext {
            case "pdf": return "doc.fill"
            case "jpg", "jpeg", "png", "gif", "webp", "heic": return "photo.fill"
            case "mp4", "mov", "avi", "mkv": return "film.fill"
            case "mp3", "aac", "wav", "m4a": return "music.note"
            case "zip", "rar", "7z", "tar", "gz": return "archivebox.fill"
            default: return "doc.fill"
            }
        }()
        return Image(systemName: name)
    }

    private var stateBadge: some View {
        Text(item.state.displayName)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(stateColor.opacity(0.15))
            .foregroundStyle(stateColor)
            .clipShape(Capsule())
    }

    private var stateColor: Color {
        switch item.state {
        case .downloading: return .blue
        case .completed:   return .green
        case .paused:      return .orange
        case .failed:      return .red
        case .cancelled:   return .gray
        case .pending, .queued: return .secondary
        }
    }

    @ViewBuilder
    private var actionButtons: some View {
        HStack(spacing: 12) {
            switch item.state {
            case .downloading:
                Button(action: onPause) {
                    Image(systemName: "pause.fill")
                }
                .accessibilityLabel(NSLocalizedString("Pause", comment: "Action"))
                Button(action: onCancel) {
                    Image(systemName: "xmark.circle.fill")
                }
                .accessibilityLabel(NSLocalizedString("Cancel", comment: "Action"))

            case .paused:
                Button(action: onResume) {
                    Image(systemName: "play.fill")
                }
                .accessibilityLabel(NSLocalizedString("Resume", comment: "Action"))
                Button(action: onCancel) {
                    Image(systemName: "xmark.circle.fill")
                }
                .accessibilityLabel(NSLocalizedString("Cancel", comment: "Action"))

            case .failed, .cancelled:
                Button(action: onRetry) {
                    Image(systemName: "arrow.clockwise")
                }
                .accessibilityLabel(NSLocalizedString("Retry", comment: "Action"))
                Button(action: onDelete) {
                    Image(systemName: "trash")
                }
                .accessibilityLabel(NSLocalizedString("Delete", comment: "Action"))

            case .completed:
                Button(action: onDelete) {
                    Image(systemName: "trash")
                }
                .accessibilityLabel(NSLocalizedString("Delete", comment: "Action"))

            case .pending, .queued:
                Button(action: onCancel) {
                    Image(systemName: "xmark.circle.fill")
                }
                .accessibilityLabel(NSLocalizedString("Cancel", comment: "Action"))
            }
        }
        .buttonStyle(.borderless)
        .font(.body)
    }

    private var accessibilityHintText: String {
        switch item.state {
        case .downloading: return NSLocalizedString("Double tap to pause", comment: "Accessibility")
        case .paused: return NSLocalizedString("Double tap to resume", comment: "Accessibility")
        case .failed: return NSLocalizedString("Double tap to retry", comment: "Accessibility")
        default: return ""
        }
    }
}
