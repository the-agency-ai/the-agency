// What Problem: Orchestrate the full parsing pipeline: raw markdown source →
// front-matter extraction → swift-markdown AST parse → slide splitting →
// metadata extraction → notes extraction → DeckDocument.
//
// How & Why: Single entry point that chains FrontMatterExtractor →
// Markdown.Document.init → SlideSplitter → SlideMetadataExtractor →
// NotesExtractor. Collects diagnostics from each stage. This is the
// public API that DeckState.load() calls.
//
// Written: 2026-04-12 during mdslidepal-mac Phase 1.3

import Foundation
import Markdown

public struct DeckParser {

    public init() {}

    /// Parse a markdown source string into a DeckDocument.
    public func parse(source: String) -> DeckDocument {
        var diagnostics: [Diagnostic] = []

        // Step 1: Extract front-matter (if present)
        let extraction = FrontMatterExtractor.extract(from: source)
        diagnostics.append(contentsOf: extraction.diagnostics)

        // Step 2: Parse remaining markdown with swift-markdown
        let document = Document(parsing: extraction.remainingSource)

        // Step 3: Split into slides on top-level ThematicBreak nodes
        var slides = SlideSplitter.split(document: document)

        // Step 4: Extract per-slide metadata from <!-- slide: ... --> blocks
        let (metadataSlides, metaDiags) = SlideMetadataExtractor.extract(from: slides)
        slides = metadataSlides
        diagnostics.append(contentsOf: metaDiags)

        // Step 5: Extract speaker notes from Notes: markers
        slides = NotesExtractor.extract(from: slides)

        return DeckDocument(
            frontMatter: extraction.frontMatter,
            slides: slides,
            diagnostics: diagnostics
        )
    }
}
