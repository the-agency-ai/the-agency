// What Problem: The engine needs a top-level container for the parsed document
// structure that holds the root node and the original source text. The original
// source is needed for faithful serialization of unmodified sections.
//
// How & Why: Simple struct wrapping the root SectionNode and originalSource.
// The root node is level 0 with an empty heading — content before the first
// heading becomes the root's body. The originalSource is retained so the
// serializer can slice unmodified sections directly from it, preserving
// exact formatting that swift-markdown's serializer would alter.
//
// Written: 2026-04-07 during mdpal-cli session (iteration 1.1 rebuild)

/// The parsed representation of a document's structure.
///
/// Contains the root node of the section tree and the original source text.
/// The original source is retained for byte-range slicing during serialization
/// to preserve exact formatting of unmodified sections.
public struct SectionTree: Equatable, Sendable {

    /// The root node of the section tree.
    /// Level 0, empty heading. Content before the first heading is the root's body.
    public let root: SectionNode

    /// The original source text. Retained for slicing during serialization
    /// of unmodified sections.
    public let originalSource: String

    public init(root: SectionNode, originalSource: String) {
        self.root = root
        self.originalSource = originalSource
    }
}
