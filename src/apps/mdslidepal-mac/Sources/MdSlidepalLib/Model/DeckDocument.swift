// What Problem: Observable state container for a parsed slide deck. Drives
// the SwiftUI view hierarchy — when the deck changes (file reload, theme
// switch), views update automatically.
//
// How & Why: @Observable class holding the parsed slides, front-matter,
// theme, and diagnostics. The parse pipeline runs through MarkdownParser →
// FrontMatterExtractor → SlideSplitter → SlideMetadataExtractor →
// NotesExtractor, producing the final [Slide] array. DeckState wraps this
// and adds UI state (selected slide, presentation mode).
//
// Written: 2026-04-12 during mdslidepal-mac Phase 1.1

import Foundation
import Observation

/// The parsed content of a markdown slide deck.
///
/// Note: Does NOT conform to Equatable because Slide contains [Markup]
/// (reference types from swift-markdown that don't conform to Equatable).
/// SwiftUI updates are driven by DeckState being @Observable, not by
/// Equatable comparisons.
public struct DeckDocument {
    public var frontMatter: FrontMatter?
    public var slides: [Slide]
    public var diagnostics: [Diagnostic]
    /// The source file URL (for live-reload and relative path resolution).
    public var sourceURL: URL?

    public init(
        frontMatter: FrontMatter? = nil,
        slides: [Slide] = [],
        diagnostics: [Diagnostic] = [],
        sourceURL: URL? = nil
    ) {
        self.frontMatter = frontMatter
        self.slides = slides
        self.diagnostics = diagnostics
        self.sourceURL = sourceURL
    }

    /// Deck title: from front-matter, or first slide's first heading, or "Untitled".
    public var title: String {
        if let fmTitle = frontMatter?.title, !fmTitle.isEmpty {
            return fmTitle
        }
        if let firstTitle = slides.first?.title {
            return firstTitle
        }
        return "Untitled"
    }
}

/// Observable UI state for a deck — wraps DeckDocument + UI concerns.
/// @MainActor ensures all UI state mutations happen on the main thread.
@MainActor
@Observable
public class DeckState {
    public var document: DeckDocument = DeckDocument()
    public var selectedSlideIndex: Int = 0
    public var isPresenting: Bool = false
    public var theme: Theme = Theme.agencyDefault

    public init() {}

    /// The currently selected slide, if any.
    public var currentSlide: Slide? {
        guard !document.slides.isEmpty,
              selectedSlideIndex >= 0,
              selectedSlideIndex < document.slides.count
        else { return nil }
        return document.slides[selectedSlideIndex]
    }

    /// Navigate to the next slide.
    public func nextSlide() {
        if selectedSlideIndex < document.slides.count - 1 {
            selectedSlideIndex += 1
        }
    }

    /// Navigate to the previous slide.
    public func previousSlide() {
        if selectedSlideIndex > 0 {
            selectedSlideIndex -= 1
        }
    }

    /// Navigate to the first slide.
    public func firstSlide() {
        selectedSlideIndex = 0
    }

    /// Navigate to the last slide.
    public func lastSlide() {
        if !document.slides.isEmpty {
            selectedSlideIndex = document.slides.count - 1
        }
    }

    /// Load a deck from a markdown string.
    public func load(from source: String, sourceURL: URL? = nil) {
        let parser = DeckParser()
        var doc = parser.parse(source: source)
        doc.sourceURL = sourceURL

        // Apply theme from front-matter if specified
        if let themeName = doc.frontMatter?.theme {
            if let loaded = ThemeLoader.shared.load(name: themeName) {
                theme = loaded
            } else {
                doc.diagnostics.append(
                    Diagnostic(
                        severity: .warning,
                        message: "Theme '\(themeName)' not found; using default"
                    )
                )
            }
        }

        document = doc
        selectedSlideIndex = 0
    }

    /// Load a deck from a file URL.
    public func load(from url: URL) throws {
        let source = try String(contentsOf: url, encoding: .utf8)
        load(from: source, sourceURL: url)
    }
}
