// What Problem: Core data model for a single slide in a deck. Each slide
// holds its markup content (as AST nodes), optional metadata from
// <!-- slide: --> blocks, and optional speaker notes.
//
// How & Why: Struct-based model with Identifiable for SwiftUI list binding.
// Stores Markdown.Markup children (not raw text) so rendering works directly
// from the AST — no re-parsing. Notes are stored as raw markdown text since
// they're rendered separately in the presenter view.
//
// Written: 2026-04-12 during mdslidepal-mac Phase 1.1

import Foundation
import Markdown

/// A single slide in a deck.
public struct Slide: Identifiable {
    public let id: Int  // 0-based slide index
    /// The AST nodes that make up this slide's visible content.
    public let markupChildren: [Markup]
    /// Optional per-slide metadata from `<!-- slide: ... -->` blocks.
    public var metadata: SlideMetadata?
    /// Optional speaker notes (raw markdown text, rendered in presenter view only).
    public var notes: String?

    public init(
        id: Int,
        markupChildren: [Markup],
        metadata: SlideMetadata? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.markupChildren = markupChildren
        self.metadata = metadata
        self.notes = notes
    }

    /// Plain text content of this slide (for sidebar previews, search, etc.).
    public var plainText: String {
        markupChildren.map { $0.format() }.joined(separator: "\n")
    }

    /// The first heading text found in this slide (for sidebar labels).
    public var title: String? {
        for child in markupChildren {
            if let heading = child as? Heading {
                return heading.plainText
            }
        }
        return nil
    }
}
