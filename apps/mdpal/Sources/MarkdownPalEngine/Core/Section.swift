// What Problem: When a caller asks for a single section by slug, they need
// the full content, the version hash for optimistic concurrency, and a list
// of direct child summaries — without re-walking the tree for the children.
// SectionInfo is too thin (no content); SectionNode is internal (uses
// String.Index ranges). Section is the public full-content type.
//
// How & Why: Value type. Carries the slug (path-style), heading, level,
// content body, versionHash, direct children as [SectionInfo] summaries
// (NOT recursive Sections), and a line range for editor positioning.
//
// Written: 2026-04-07 during mdpal-cli session (iteration 1.3)

import Foundation

/// A full section with content, returned by `Document.readSection`.
public struct Section: Equatable, Sendable {

    /// The section's path-style slug (e.g., "authentication/oauth").
    public let slug: String

    /// The heading text (raw, before slug computation).
    public let heading: String

    /// The heading level (1-6 for Markdown).
    public let level: Int

    /// The section's body content (text between heading and next heading/child).
    public let content: String

    /// Deterministic hash of the section content for optimistic concurrency.
    public let versionHash: String

    /// Direct child sections (one level deep, as summaries).
    public let children: [SectionInfo]

    /// The 1-based line range of this section in the source document.
    /// Lower bound = heading line, upper bound = exclusive end-of-section.
    /// Optional because iteration 1.3 does not yet wire source-range
    /// slicing through SectionNode — line ranges land in iteration 1.4.
    public let lineRange: Range<Int>?

    public init(
        slug: String,
        heading: String,
        level: Int,
        content: String,
        versionHash: String,
        children: [SectionInfo],
        lineRange: Range<Int>? = nil
    ) {
        self.slug = slug
        self.heading = heading
        self.level = level
        self.content = content
        self.versionHash = versionHash
        self.children = children
        self.lineRange = lineRange
    }
}
