// DownloadManagerKit/Sources/DownloadManagerKit/UI/SwiftUI/DownloadListView.swift

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Displays all downloads with swipe actions and pull-to-refresh.
public struct DownloadListView: View {

    @ObservedObject var viewModel: DownloadViewModel
    @State private var showAddSheet = false
    @State private var urlText = ""

    public init(viewModel: DownloadViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        Group {
            if viewModel.downloads.isEmpty {
                emptyState
            } else {
                downloadList
            }
        }
        .navigationTitle(NSLocalizedString("Downloads", comment: "Screen title"))
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button(action: { showAddSheet = true }) {
                    Image(systemName: "plus")
                }
                .accessibilityLabel(NSLocalizedString("Add Download", comment: "Action"))

                Menu {
                    Button(NSLocalizedString("Pause All", comment: "Action")) { viewModel.pauseAll() }
                    Button(NSLocalizedString("Resume All", comment: "Action")) { viewModel.resumeAll() }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            addDownloadSheet
        }
        .alert(
            NSLocalizedString("Error", comment: "Alert title"),
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )
        ) {
            Button(NSLocalizedString("OK", comment: "Alert action"), role: .cancel) {}
        } message: {
            if let msg = viewModel.errorMessage {
                Text(msg)
            }
        }
    }

    // MARK: - Subviews

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "arrow.down.circle.dotted")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
            Text(NSLocalizedString("No Downloads Yet", comment: "Empty state title"))
                .font(.title3.weight(.medium))
            Text(NSLocalizedString("Tap + to add a download URL", comment: "Empty state subtitle"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var downloadList: some View {
        List {
            ForEach(viewModel.downloads) { item in
                DownloadRowView(
                    item: item,
                    onPause: { viewModel.pause(id: item.id) },
                    onResume: { viewModel.resume(id: item.id) },
                    onCancel: { viewModel.cancel(id: item.id) },
                    onRetry: { viewModel.retry(id: item.id) },
                    onDelete: { viewModel.delete(id: item.id) }
                )
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) { viewModel.delete(id: item.id) } label: {
                        Label(NSLocalizedString("Delete", comment: "Swipe action"), systemImage: "trash")
                    }
                }
                .swipeActions(edge: .leading) {
                    if item.state == .downloading {
                        Button { viewModel.pause(id: item.id) } label: {
                            Label(NSLocalizedString("Pause", comment: "Swipe action"), systemImage: "pause.fill")
                        }
                        .tint(.orange)
                    } else if item.state == .paused {
                        Button { viewModel.resume(id: item.id) } label: {
                            Label(NSLocalizedString("Resume", comment: "Swipe action"), systemImage: "play.fill")
                        }
                        .tint(.blue)
                    }
                }
            }
        }
        .listStyle(.plain)
        .refreshable {
            _ = await viewModel.manager.getAllDownloads()
        }
    }

    private var addDownloadSheet: some View {
        NavigationView {
            Form {
                Section {
                    PasteFriendlyTextField(
                        placeholder: NSLocalizedString("Enter download URL", comment: "Text field placeholder"),
                        text: $urlText
                    )
                }
            }
            .navigationTitle(NSLocalizedString("New Download", comment: "Sheet title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("Cancel", comment: "Action")) {
                        showAddSheet = false
                        urlText = ""
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(NSLocalizedString("Download", comment: "Action")) {
                        if let url = URL(string: urlText), url.scheme != nil {
                            viewModel.startDownload(url: url)
                        }
                        showAddSheet = false
                        urlText = ""
                    }
                    .disabled(URL(string: urlText)?.scheme == nil)
                }
            }
        }
        .navigationViewStyle(.stack)
    }
}

// MARK: - Paste-Friendly URL TextField

#if canImport(UIKit)
struct PasteFriendlyTextField: UIViewRepresentable {
    let placeholder: String
    @Binding var text: String

    func makeUIView(context: Context) -> UITextField {
        let field = UITextField()
        field.placeholder = placeholder
        field.keyboardType = .URL
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.spellCheckingType = .no
        field.textContentType = .init(rawValue: "")
        field.delegate = context.coordinator
        field.clearButtonMode = .whileEditing
        field.font = .preferredFont(forTextStyle: .body)
        field.adjustsFontForContentSizeCategory = true
        field.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return field
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        @Binding var text: String

        init(text: Binding<String>) {
            _text = text
        }

        func textFieldDidChangeSelection(_ textField: UITextField) {
            text = textField.text ?? ""
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            textField.resignFirstResponder()
            return true
        }
    }
}
#endif
