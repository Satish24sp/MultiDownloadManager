// DownloadManagerKit/Sources/DownloadManagerKit/UI/SwiftUI/LogsView.swift

import SwiftUI
import OSLog

/// Displays recent system log entries from the DownloadManagerKit subsystem.
/// Uses OSLogStore (available on iOS 15+).
public struct LogsView: View {

    @State private var entries: [LogEntry] = []
    @State private var isLoading = false

    public init() {}

    public var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if entries.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "text.alignleft")
                        .font(.system(size: 56))
                        .foregroundStyle(.secondary)
                    Text(NSLocalizedString("No Logs Available", comment: "Empty state"))
                        .font(.title3.weight(.medium))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(entries) { entry in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(entry.level)
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(entry.levelColor)
                            Text(entry.category)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(entry.date, style: .time)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Text(entry.message)
                            .font(.caption)
                            .lineLimit(3)
                    }
                    .padding(.vertical, 2)
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle(NSLocalizedString("Logs", comment: "Screen title"))
        .task { await loadLogs() }
        .refreshable { await loadLogs() }
    }

    @MainActor
    private func loadLogs() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let store = try OSLogStore(scope: .currentProcessIdentifier)
            let position = store.position(date: Date().addingTimeInterval(-3600))
            let predicate = NSPredicate(format: "subsystem == %@", "com.app.downloadmanager")

            let logEntries = try store.getEntries(at: position, matching: predicate)
                .compactMap { $0 as? OSLogEntryLog }
                .suffix(200)
                .map { entry in
                    LogEntry(
                        date: entry.date,
                        level: mapLevel(entry.level),
                        category: entry.category,
                        message: entry.composedMessage
                    )
                }

            entries = Array(logEntries)
        } catch {
            entries = []
        }
    }

    private func mapLevel(_ level: OSLogEntryLog.Level) -> String {
        switch level {
        case .debug:   return "DEBUG"
        case .info:    return "INFO"
        case .notice:  return "NOTICE"
        case .error:   return "ERROR"
        case .fault:   return "FAULT"
        default:       return "LOG"
        }
    }
}

// MARK: - LogEntry Model

private struct LogEntry: Identifiable {
    let id = UUID()
    let date: Date
    let level: String
    let category: String
    let message: String

    var levelColor: Color {
        switch level {
        case "ERROR", "FAULT": return .red
        case "NOTICE":         return .orange
        case "INFO":           return .blue
        default:               return .secondary
        }
    }
}
