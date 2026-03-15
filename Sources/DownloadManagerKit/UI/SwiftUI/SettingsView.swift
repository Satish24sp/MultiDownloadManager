// DownloadManagerKit/Sources/DownloadManagerKit/UI/SwiftUI/SettingsView.swift

import SwiftUI

/// Settings screen backed by any SettingsManaging implementation.
public struct SettingsView: View {

    @State private var progressOption: ProgressDisplayOption
    @State private var maxConcurrent: Int
    @State private var autoResume: Bool
    @State private var autoRetry: Bool
    @State private var maxRetries: Int
    @State private var allowCellular: Bool
    @State private var wifiOnly: Bool

    private let settings: any SettingsManaging

    public init(settings: any SettingsManaging) {
        self.settings = settings
        _progressOption = State(initialValue: settings.progressDisplayOption)
        _maxConcurrent = State(initialValue: settings.maxConcurrentDownloads)
        _autoResume = State(initialValue: settings.isAutoResumeEnabled)
        _autoRetry = State(initialValue: settings.isAutoRetryEnabled)
        _maxRetries = State(initialValue: settings.maxRetryCount)
        _allowCellular = State(initialValue: settings.allowsCellularDownloads)
        _wifiOnly = State(initialValue: settings.wifiOnlyMode)
    }

    public var body: some View {
        Form {
            Section {
                Picker(
                    NSLocalizedString("Progress Display", comment: "Settings label"),
                    selection: $progressOption
                ) {
                    ForEach(ProgressDisplayOption.allCases, id: \.self) { option in
                        Text(option.displayName).tag(option)
                    }
                }
                .onChange(of: progressOption) { newValue in
                    settings.progressDisplayOption = newValue
                }
            } header: {
                Text(NSLocalizedString("Notifications", comment: "Settings section"))
            }

            Section {
                Stepper(
                    value: $maxConcurrent, in: 1...10
                ) {
                    HStack {
                        Text(NSLocalizedString("Max Concurrent", comment: "Settings label"))
                        Spacer()
                        Text("\(maxConcurrent)")
                            .foregroundStyle(.secondary)
                    }
                }
                .onChange(of: maxConcurrent) { newValue in
                    settings.maxConcurrentDownloads = newValue
                }
            } header: {
                Text(NSLocalizedString("Performance", comment: "Settings section"))
            }

            Section {
                Toggle(
                    NSLocalizedString("Auto Resume on Network", comment: "Settings label"),
                    isOn: $autoResume
                )
                .onChange(of: autoResume) { newValue in
                    settings.isAutoResumeEnabled = newValue
                }

                Toggle(
                    NSLocalizedString("Auto Retry on Failure", comment: "Settings label"),
                    isOn: $autoRetry
                )
                .onChange(of: autoRetry) { newValue in
                    settings.isAutoRetryEnabled = newValue
                }

                if autoRetry {
                    Stepper(
                        value: $maxRetries, in: 1...10
                    ) {
                        HStack {
                            Text(NSLocalizedString("Max Retries", comment: "Settings label"))
                            Spacer()
                            Text("\(maxRetries)")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .onChange(of: maxRetries) { newValue in
                        settings.maxRetryCount = newValue
                    }
                }
            } header: {
                Text(NSLocalizedString("Recovery", comment: "Settings section"))
            }

            Section {
                Toggle(
                    NSLocalizedString("Allow Cellular Downloads", comment: "Settings label"),
                    isOn: $allowCellular
                )
                .onChange(of: allowCellular) { newValue in
                    settings.allowsCellularDownloads = newValue
                }

                Toggle(
                    NSLocalizedString("WiFi Only Mode", comment: "Settings label"),
                    isOn: $wifiOnly
                )
                .onChange(of: wifiOnly) { newValue in
                    settings.wifiOnlyMode = newValue
                }
            } header: {
                Text(NSLocalizedString("Network", comment: "Settings section"))
            }
        }
        .navigationTitle(NSLocalizedString("Settings", comment: "Screen title"))
    }
}
