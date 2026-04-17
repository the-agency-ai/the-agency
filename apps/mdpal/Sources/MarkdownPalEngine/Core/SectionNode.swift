// What Problem: The engine needs a structural representation of document sections
// that captures heading, level, content, source range, and hierarchy. This is
// the fundamental building block of the section tree.
//
// How & Why: Value type (struct) for immutability of parsed data. Stores heading
// text, level (1-6), body content (excluding heading and children), source range
// for faithful serialization, and child nodes for tree structure. The sourceRange
// uses String.Index for zero-copy slicing of the original source during serialization
// of unmodified sections.
//
// Written: 2026-04-07 during mdpal-cli session (iteration 1.1 rebuild)

/// A node in the section tree representing a heading and its content.
///
/// Each node captures:
/// - The heading text (raw, before slug computation)
/// - The heading level (1-6 for Markdown; parser-defined for other formats)
/// - The body content (text between this heading and the next heading/child)
/// - The source range in the original document for faithful serialization
/// - Child sections (subsections under this heading)
public struct SectionNode: Equatable, Sendable {

    /// The heading text (raw, before slug computation).
    /// Empty string for the root node.
    public let heading: String

    /// The heading level (1-6 for Markdown; parser-defined for other formats).
    /// Level 0 for the root node.
    public let level: Int

    /// The raw content of this section: body text only, EXCLUDING
    /// the heading line and EXCLUDING child sections.
    public let content: String

    /// The full source range in the original document (start of heading through
    /// end of body, before any child sections). Used for faithful serialization
    /// via slicing of the original source.
    public let sourceRange: Range<String.Index>

    /// Child sections (subsections under this heading).
    public internal(set) var children: [SectionNode]

    public init(
        heading: String,
        level: Int,
        content: String,
        sourceRange: Range<String.Index>,
        children: [SectionNode] = []
    ) {
        self.heading = heading
        self.level = level
        self.content = content
        self.sourceRange = sourceRange
        self.children = children
    }
}
