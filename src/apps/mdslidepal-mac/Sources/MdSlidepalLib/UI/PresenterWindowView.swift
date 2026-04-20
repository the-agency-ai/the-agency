// What Problem: The presenter view shows the speaker what the audience sees
// plus notes, next slide preview, and a timer. This is the "laptop screen"
// view during a multi-display presentation.
//
// How & Why: Four-quadrant layout: current slide (scaled), next slide preview,
// notes pane (rendered markdown), and timer. Notes use the same inline
// renderer as slides but at a smaller scale. The presenter window reads
// DeckState and PresentationCoordinator from the environment.
//
// Written: 2026-04-12 during mdslidepal-mac Phase 3

import SwiftUI

/// The presenter view — shown on the laptop screen during presentation.
public struct PresenterWindowView: View {
    @Environment(DeckState.self) private var deckState
    @Environment(\.theme) private var theme
    let coordinator: PresentationCoordinator

    public init(coordinator: PresentationCoordinator) {
        self.coordinator = coordinator
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Top bar: slide counter + timer
            HStack {
                Text("Slide \(deckState.selectedSlideIndex + 1) of \(deckState.document.slides.count)")
                    .font(.headline)
                Spacer()
                Text(coordinator.formattedElapsedTime)
                    .font(.system(.title2, design: .monospaced))
                    .foregroundColor(Color(hex: theme.colors.accent))
                Spacer()
                Button("End") {
                    coordinator.stopPresentation()
                }
                .keyboardShortcut(.escape, modifiers: [])
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(hex: theme.colors.subtle))

            // Main content: current + next slide, notes
            HSplitView {
                // Left: current slide + next slide stacked
                VStack(spacing: 8) {
                    // Current slide (large)
                    currentSlideView
                        .frame(maxHeight: .infinity)
                        .border(Color(hex: theme.colors.accent), width: 2)

                    // Next slide preview (smaller)
                    if let nextSlide = nextSlide {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("NEXT")
                                .font(.caption.bold())
                                .foregroundColor(Color(hex: theme.colors.muted))
                            nextSlideView(slide: nextSlide)
                                .frame(maxHeight: 200)
                                .border(Color(hex: theme.colors.border), width: 1)
                        }
                    }
                }
                .frame(minWidth: 400)
                .padding(8)

                // Right: speaker notes
                VStack(alignment: .leading, spacing: 8) {
                    Text("NOTES")
                        .font(.caption.bold())
                        .foregroundColor(Color(hex: theme.colors.muted))

                    ScrollView {
                        if let notes = deckState.currentSlide?.notes {
                            Text(notes)
                                .font(.system(size: 18))
                                .lineSpacing(6)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .textSelection(.enabled)
                        } else {
                            Text("No speaker notes for this slide.")
                                .font(.system(size: 16))
                                .foregroundColor(Color(hex: theme.colors.muted))
                                .italic()
                        }
                    }
                }
                .frame(minWidth: 300)
                .padding(8)
            }
        }
        .background(Color(hex: theme.colors.background))
    }

    // MARK: - Sub-views

    @ViewBuilder
    private var currentSlideView: some View {
        GeometryReader { geo in
            if let slide = deckState.currentSlide {
                let scale = min(
                    geo.size.width / CGFloat(theme.logicalDimensions.width),
                    geo.size.height / CGFloat(theme.logicalDimensions.height),
                    1.0
                )
                SlideContentView(slide: slide, sourceURL: deckState.document.sourceURL)
                    .scaleEffect(scale)
                    .frame(width: geo.size.width, height: geo.size.height)
            }
        }
    }

    private func nextSlideView(slide: Slide) -> some View {
        GeometryReader { geo in
            let scale = min(
                geo.size.width / CGFloat(theme.logicalDimensions.width),
                geo.size.height / CGFloat(theme.logicalDimensions.height),
                1.0
            )
            SlideContentView(slide: slide, sourceURL: deckState.document.sourceURL)
                .scaleEffect(scale)
                .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    private var nextSlide: Slide? {
        let nextIndex = deckState.selectedSlideIndex + 1
        guard nextIndex < deckState.document.slides.count else { return nil }
        return deckState.document.slides[nextIndex]
    }
}

/// Full-screen audience view for presentation mode.
public struct AudienceFullScreenView: View {
    @Environment(DeckState.self) private var deckState
    @Environment(\.theme) private var theme
    let coordinator: PresentationCoordinator

    public init(coordinator: PresentationCoordinator) {
        self.coordinator = coordinator
    }

    public var body: some View {
        ZStack {
            // Slide content
            if !coordinator.isBlackScreen {
                GeometryReader { geo in
                    if let slide = deckState.currentSlide {
                        let scale = min(
                            geo.size.width / CGFloat(theme.logicalDimensions.width),
                            geo.size.height / CGFloat(theme.logicalDimensions.height)
                        )
                        SlideContentView(slide: slide, sourceURL: deckState.document.sourceURL)
                            .scaleEffect(scale)
                            .frame(width: geo.size.width, height: geo.size.height)
                    }
                }
            }

            // Black screen overlay
            if coordinator.isBlackScreen {
                Color.black
                    .ignoresSafeArea()
            }

            // Help overlay
            if coordinator.showHelp {
                helpOverlay
            }
        }
        .background(Color(hex: theme.colors.background))
        .ignoresSafeArea()
    }

    private var helpOverlay: some View {
        VStack(spacing: 16) {
            Text("Keyboard Shortcuts")
                .font(.title2.bold())

            VStack(alignment: .leading, spacing: 8) {
                shortcutRow("→ / Space / n", "Next slide")
                shortcutRow("← / p", "Previous slide")
                shortcutRow("Home", "First slide")
                shortcutRow("End", "Last slide")
                shortcutRow("Esc", "Exit presentation")
                shortcutRow("f", "Toggle fullscreen")
                shortcutRow("s", "Toggle speaker notes")
                shortcutRow("b / .", "Black screen")
                shortcutRow("?", "This help")
            }
            .font(.system(size: 18))
        }
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }

    private func shortcutRow(_ key: String, _ description: String) -> some View {
        HStack(spacing: 16) {
            Text(key)
                .font(.system(size: 16, design: .monospaced))
                .frame(width: 160, alignment: .trailing)
                .foregroundColor(Color(hex: theme.colors.accent))
            Text(description)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
