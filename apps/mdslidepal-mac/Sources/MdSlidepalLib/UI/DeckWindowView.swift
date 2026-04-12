// What Problem: Main window view for mdslidepal-mac. Shows a sidebar with
// slide thumbnails and a detail pane with the selected slide preview.
// Supports File → Open, drag-and-drop, live-reload on file change.
//
// How & Why: NavigationSplitView for native macOS split-view behavior.
// Sidebar shows slide titles/indices; detail shows the scaled SlideContentView.
// File open via .fileImporter. Live-reload via FileWatcher with debounce.
// Drag-and-drop via .onDrop. Menu commands via NotificationCenter.
//
// Written: 2026-04-12 during mdslidepal-mac Phase 1.5
// Updated: 2026-04-12 Phase 2 — file-open, live-reload, drag-and-drop, menus

import SwiftUI
import UniformTypeIdentifiers

/// The main deck window view with sidebar + slide preview.
public struct DeckWindowView: View {
    @Environment(DeckState.self) private var deckState
    @State private var isFileImporterPresented = false
    @State private var fileWatcher = FileWatcher()
    @State private var errorMessage: String?
    @State private var showError = false

    public init() {}

    public var body: some View {
        NavigationSplitView {
            SlideListSidebar()
        } detail: {
            SlidePreviewPane()
        }
        .environment(\.theme, deckState.theme)
        .navigationTitle(deckState.document.title)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button {
                    isFileImporterPresented = true
                } label: {
                    Label("Open", systemImage: "doc")
                }
                .keyboardShortcut("o", modifiers: .command)
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
                    openFile(url: url)
                }
            case .failure(let error):
                showError(error.localizedDescription)
            }
        }
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            handleDrop(providers: providers)
            return true
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage ?? "Unknown error")
        }
        .task {
            loadInitialDeck()
            setupFileWatcher()
            setupNotificationHandlers()
        }
        // Keyboard navigation for slides (when not in presentation mode)
        .onKeyPress(.rightArrow) { deckState.nextSlide(); return .handled }
        .onKeyPress(.leftArrow) { deckState.previousSlide(); return .handled }
        .onKeyPress(.home) { deckState.firstSlide(); return .handled }
        .onKeyPress(.end) { deckState.lastSlide(); return .handled }
    }

    // MARK: - File Loading

    private func openFile(url: URL) {
        // Start security-scoped access for sandboxed apps
        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing { url.stopAccessingSecurityScopedResource() }
        }

        do {
            try deckState.load(from: url)
            fileWatcher.watch(url: url)
        } catch {
            showError("Failed to open \(url.lastPathComponent): \(error.localizedDescription)")
        }
    }

    private func reloadCurrentFile() {
        guard let url = deckState.document.sourceURL else { return }
        do {
            let currentIndex = deckState.selectedSlideIndex
            try deckState.load(from: url)
            // Preserve slide position if possible
            if currentIndex < deckState.document.slides.count {
                deckState.selectedSlideIndex = currentIndex
            }
        } catch {
            showError("Reload failed: \(error.localizedDescription)")
        }
    }

    private func handleDrop(providers: [NSItemProvider]) {
        for provider in providers {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier) { item, _ in
                guard let data = item as? Data,
                      let url = URL(dataRepresentation: data, relativeTo: nil)
                else { return }
                DispatchQueue.main.async {
                    openFile(url: url)
                }
            }
        }
    }

    // MARK: - Setup

    private func loadInitialDeck() {
        // Check if launched with a file argument
        let args = ProcessInfo.processInfo.arguments
        if args.count > 1 {
            let path = args[1]
            let url = URL(fileURLWithPath: path)
            if FileManager.default.fileExists(atPath: url.path) {
                openFile(url: url)
                return
            }
        }

        // Fallback: show welcome content
        deckState.load(from: "# Welcome to mdslidepal\n\nOpen a `.md` file to get started.\n\nUse **File \u{2192} Open** or drag a markdown file onto this window.\n\n---\n\n# Getting Started\n\nmdslidepal renders markdown files as slide decks.\n\n- Slides are separated by `---`\n- Code blocks get syntax highlighting\n- Speaker notes use the `Notes:` marker\n- Themes are loaded from JSON files")
    }

    private func setupFileWatcher() {
        fileWatcher.onChange = { [weak deckState] in
            guard let deckState else { return }
            guard let url = deckState.document.sourceURL else { return }
            let currentIndex = deckState.selectedSlideIndex
            do {
                try deckState.load(from: url)
                if currentIndex < deckState.document.slides.count {
                    deckState.selectedSlideIndex = currentIndex
                }
            } catch {
                // Silently ignore reload errors (file may be mid-save)
            }
        }
    }

    private func setupNotificationHandlers() {
        NotificationCenter.default.addObserver(
            forName: .reloadDeck, object: nil, queue: .main
        ) { _ in reloadCurrentFile() }

        NotificationCenter.default.addObserver(
            forName: .nextSlide, object: nil, queue: .main
        ) { _ in deckState.nextSlide() }

        NotificationCenter.default.addObserver(
            forName: .previousSlide, object: nil, queue: .main
        ) { _ in deckState.previousSlide() }

        NotificationCenter.default.addObserver(
            forName: .firstSlide, object: nil, queue: .main
        ) { _ in deckState.firstSlide() }

        NotificationCenter.default.addObserver(
            forName: .lastSlide, object: nil, queue: .main
        ) { _ in deckState.lastSlide() }
    }

    private func showError(_ message: String) {
        errorMessage = message
        showError = true
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
