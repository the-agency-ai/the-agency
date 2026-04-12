// What Problem: Main window view for mdslidepal-mac. Shows a sidebar with
// slide thumbnails and a detail pane with the selected slide preview.
// Phase 1 loads from a hardcoded fixture path; Phase 2 adds file-open UI.
//
// How & Why: NavigationSplitView for native macOS split-view behavior.
// Sidebar shows slide titles/indices; detail shows the scaled SlideContentView.
// The DeckState is read from the environment (set by MdSlidepalApp).
//
// Written: 2026-04-12 during mdslidepal-mac Phase 1.5

import SwiftUI

/// The main deck window view with sidebar + slide preview.
public struct DeckWindowView: View {
    @Environment(DeckState.self) private var deckState

    public init() {}

    public var body: some View {
        @Bindable var state = deckState

        NavigationSplitView {
            SlideListSidebar()
        } detail: {
            SlidePreviewPane()
        }
        .environment(\.theme, deckState.theme)
        .navigationTitle(deckState.document.title)
        .task {
            loadSampleDeck()
        }
    }

    /// Phase 1: load a sample fixture for development.
    private func loadSampleDeck() {
        // Try to load fixture 02 (multi-slide) for development
        let samplePaths = [
            // Relative to the repo root (for development)
            "claude/workstreams/mdslidepal/fixtures/02-multi-slide.md",
            // Bundle resource (for distribution)
        ]

        for path in samplePaths {
            let url = URL(fileURLWithPath: path)
            if FileManager.default.fileExists(atPath: url.path) {
                do {
                    try deckState.load(from: url)
                    return
                } catch {
                    // Try next path
                }
            }
        }

        // Fallback: load a minimal sample (no leading whitespace — would render as code block)
        deckState.load(from: "# Welcome to mdslidepal\n\nOpen a `.md` file to get started.\n\n---\n\n# Slide 2\n\nUse File \u{2192} Open to load a markdown deck.")
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
            Text("Slide \(slide.id + 1)")
                .font(.caption)
                .foregroundColor(Color(hex: theme.colors.muted))
            Text(slide.title ?? "(untitled)")
                .font(.headline)
                .lineLimit(2)
            if slide.notes != nil {
                Image(systemName: "note.text")
                    .font(.caption2)
                    .foregroundColor(Color(hex: theme.colors.accent))
            }
        }
        .padding(.vertical, 4)
    }
}

/// The detail pane showing the selected slide scaled to fit.
struct SlidePreviewPane: View {
    @Environment(DeckState.self) private var deckState
    @Environment(\.theme) private var theme

    var body: some View {
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
