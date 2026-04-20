// What Problem: The engine must be format-agnostic — it operates on abstract
// section trees, not Markdown-specific types. A parser protocol bridges between
// file formats and the engine's structural model.
//
// How & Why: Protocol with five requirements: supported extensions (for format
// detection), parse (text → tree), serialize (tree → text), slug computation
// (format-specific heading normalization), and metadata block detection/writing.
// This allows future parsers (YAML, Swift source, etc.) to plug in without
// engine changes.
//
// Written: 2026-04-07 during mdpal-cli session (iteration 1.1 rebuild)

import Foundation

/// Range of a metadata block in the source text.
public struct MetadataRange: Equatable, Sendable {
    /// The range of the entire metadata block (including delimiters).
    public let outerRange: Range<String.Index>
    /// The range of the YAML content within the block (excluding delimiters).
    public let contentRange: Range<String.Index>

    public init(outerRange: Range<String.Index>, contentRange: Range<String.Index>) {
        self.outerRange = outerRange
        self.contentRange = contentRange
    }
}

/// A parser converts raw text content into a structural tree
/// that the engine can operate on.
public protocol DocumentParser {

    /// The file extensions this parser handles (e.g., [".md", ".markdown"]).
    static var supportedExtensions: [String] { get }

    /// Parse raw text content into a structural tree.
    /// Returns the section tree with root node.
    func parse(_ content: String) throws -> SectionTree

    /// Serialize a (possibly modified) section tree back to text.
    /// Must round-trip faithfully: parse(serialize(tree)) ≈ tree
    /// for content not modified by the engine.
    func serialize(_ tree: SectionTree) throws -> String

    /// Compute the slug for a section heading.
    /// Each format may have its own slug rules.
    func slug(for heading: String) -> String

    /// Detect metadata block boundaries in the raw text.
    /// Returns nil if no metadata block exists.
    func findMetadataBlock(in content: String) -> MetadataRange?

    /// Insert or replace a metadata block in the raw text.
    func writeMetadataBlock(_ yaml: String, into content: String) -> String
}
