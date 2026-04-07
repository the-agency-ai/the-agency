// What Problem: Consumers of the engine need a public-facing section type that
// exposes slug, heading, level, content, version hash, and children — without
// exposing the internal SectionNode's source range or tree-walking complexity.
//
// How & Why: SectionInfo is the public API type. It includes the computed slug
// and version hash that SectionNode doesn't carry (those are computed by the
// engine from the parser's slug function and content hashing). This separation
// keeps the parser's structural model clean and the public API rich.
//
// Written: 2026-04-07 during mdpal-cli session (iteration 1.1 rebuild)

import Foundation

/// Public-facing section information returned by engine operations.
///
/// Contains the computed slug, heading, level, content, version hash,
/// and child sections. This is what consumers see — SectionNode is internal.
public struct SectionInfo: Equatable, Sendable, Codable {

    /// The section's slug (path-style, e.g., "authentication/oauth").
    public let slug: String

    /// The heading text.
    public let heading: String

    /// The heading level (1-6).
    public let level: Int

    /// The section's body content.
    public let content: String

    /// Deterministic hash of the section content for optimistic concurrency.
    /// SHA-256 truncated to 12 hex characters.
    public let versionHash: String

    /// Child section info (recursive).
    public let children: [SectionInfo]

    public init(
        slug: String,
        heading: String,
        level: Int,
        content: String,
        versionHash: String,
        children: [SectionInfo]
    ) {
        self.slug = slug
        self.heading = heading
        self.level = level
        self.content = content
        self.versionHash = versionHash
        self.children = children
    }
}

// MARK: - Conversion from SectionNode

extension SectionNode {

    /// Convert this node to a public SectionInfo, computing slug and version hash.
    ///
    /// - Parameter parser: The parser whose `slug(for:)` method computes slugs.
    /// - Returns: A SectionInfo with computed slug, version hash, and recursive children.
    public func toSectionInfo(parser: some DocumentParser) -> SectionInfo {
        SectionInfo(
            slug: heading.isEmpty ? "" : parser.slug(for: heading),
            heading: heading,
            level: level,
            content: content,
            versionHash: VersionHash.compute(content),
            children: children.map { $0.toSectionInfo(parser: parser) }
        )
    }
}
