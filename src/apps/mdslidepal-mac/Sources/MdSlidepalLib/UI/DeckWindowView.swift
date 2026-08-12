// What Problem: Main window view for mdslidepal-mac. Shows a sidebar with
// slide thumbnails and a detail pane with the selected slide preview.
// Supports File → Open, drag-and-drop, live-reload on file change.
//
// How & Why: NavigationSplitView for native macOS split-view behavior.
// Sidebar shows slide titles/indices; detail shows the scaled SlideContentView.
// This view is presentation only: opening, reloading, watching and exporting all
// belong to DeckController, which the menu bar shares. The view supplies the two
// UI affordances that must live in the view layer — the toolbar's .fileImporter
// and .onDrop — and hands the resulting URL straight to the controller.
//
// Written: 2026-04-12 during mdslidepal-mac Phase 1.5
// Updated: 2026-04-12 Phase 2 — file-open, live-reload, drag-and-drop, menus
// Updated: 2026-08-08 — open/reload/export and the file watcher moved to
//   DeckController, which the menu bar also uses. This view had its own copies
//   that had diverged from the delegate's; now both call one implementation.
//   The six NotificationCenter observers registered here (and never removed)
//   moved with them — the controller subscribes once and cleans up.

import SwiftUI
import UniformTypeIdentifiers

/// The main deck window view with sidebar + slide preview.
public struct DeckWindowView: View {
    @Environment(DeckController.self) private var controller
    @Environment(DeckState.self) private var deckState
    @State private var isFileImporterPresented = false

    public init() {}

    public var body: some View {
        NavigationSplitView {
            SlideListSidebar()
        } detail: {
            SlidePreviewPane()
        }
        .environment(\.theme, deckState.theme)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button {
                    isFileImporterPresented = true
                } label: {
                    Label("Open", systemImage: "doc")
                }
            }
            ToolbarItem(placement: .automatic) {
                Text("\(deckState.selectedSlideIndex + 1) / \(deckState.document.slides.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .fileImporter(
            isPresented: $isFileImporterPresented,
            allowedContentTypes: [.plainText, UTType(filenameExtension: "md") ?? .plainText],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    controller.openFile(url: url)
                }
            case .failure(let error):
                controller.errorMessage = error.localizedDescription
            }
        }
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            handleDrop(providers: providers)
        }
        .alert("Error", isPresented: errorBinding) {
            Button("OK") { controller.errorMessage = nil }
        } message: {
            Text(controller.errorMessage ?? "Unknown error")
        }
        // Slide navigation is bound in the Presentation menu, which the responder
        // chain consults first. Binding it here too would shadow-or-not depending
        // on whether the menu item happened to be enabled.
    }

    /// Presents the controller's error state; dismissing clears it.
    private var errorBinding: Binding<Bool> {
        Binding(
            get: { controller.errorMessage != nil },
            set: { if !$0 { controller.errorMessage = nil } }
        )
    }

    // MARK: - Drag and drop

    /// Open the first dropped file. A window shows one deck, so dropping several
    /// files should not race several opens against each other — each would claim
    /// security-scoped access and rebind the watcher, and the winner would be
    /// whichever provider happened to finish last.
    ///
    /// Returns false when nothing dropped is a file URL, so the drop is reported
    /// as unhandled rather than silently swallowed.
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first(where: {
            $0.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier)
        }) else {
            return false
        }

        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier) { item, _ in
            guard let data = item as? Data,
                  let url = URL(dataRepresentation: data, relativeTo: nil)
            else { return }
            Task { @MainActor in
                controller.openFile(url: url)
            }
        }
        return true
    }
}

/// Sidebar showing slide thumbnails/titles.
struct SlideListSidebar: View {
    @Environment(DeckState.self) private var deckState

    var body: some View {
        @Bindable var state = deckState

        List(selection: $state.selectedSlideIndex) {
            ForEach(deckState.document.slides) { slide in
                SlideRowView(slide: slide)
                    .tag(slide.id)
            }
        }
        .listStyle(.sidebar)
        .navigationSplitViewColumnWidth(min: 200, ideal: 250, max: 350)
    }
}

/// A single row in the slide sidebar.
struct SlideRowView: View {
    let slide: Slide
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Slide \(slide.id + 1)")
                    .font(.caption)
                    .foregroundColor(Color(hex: theme.colors.muted))
                Spacer()
                if slide.metadata != nil {
                    Image(systemName: "gear")
                        .font(.caption2)
                        .foregroundColor(Color(hex: theme.colors.muted))
                }
                if slide.notes != nil {
                    Image(systemName: "note.text")
                        .font(.caption2)
                        .foregroundColor(Color(hex: theme.colors.accent))
                }
            }
            Text(slide.title ?? "(untitled)")
                .font(.headline)
                .lineLimit(2)
        }
        .padding(.vertical, 4)
    }
}

/// The detail pane showing the selected slide scaled to fit.
struct SlidePreviewPane: View {
    @Environment(DeckState.self) private var deckState
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: 0) {
            // Diagnostics banner (contract §11 — non-modal alerts)
            DiagnosticsBanner(diagnostics: deckState.document.diagnostics)

            slideContent
        }
    }

    @ViewBuilder
    private var slideContent: some View {
        GeometryReader { geometry in
            if let slide = deckState.currentSlide {
                let scale = calculateScale(
                    containerSize: geometry.size,
                    logicalSize: CGSize(
                        width: CGFloat(theme.logicalDimensions.width),
                        height: CGFloat(theme.logicalDimensions.height)
                    )
                )

                SlideContentView(slide: slide, sourceURL: deckState.document.sourceURL)
                    .scaleEffect(scale)
                    .frame(
                        width: geometry.size.width,
                        height: geometry.size.height
                    )
            } else {
                ContentUnavailableView(
                    "No slides",
                    systemImage: "rectangle.slash",
                    description: Text("Open a markdown file to view slides")
                )
            }
        }
    }

    private func calculateScale(containerSize: CGSize, logicalSize: CGSize) -> CGFloat {
        let scaleX = containerSize.width / logicalSize.width
        let scaleY = containerSize.height / logicalSize.height
        return min(scaleX, scaleY, 1.0)  // Never scale up past 1:1
    }
}
