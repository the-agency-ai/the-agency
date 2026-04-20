// What Problem: Document.listSections needs to return a summary of every
// section without forcing callers to walk a tree or load every section's
// content. Iteration 1.1 conflated SectionInfo with Section (full content +
// children); per A&D §3.2 these are distinct types.
//
// How & Why: SectionInfo is the SUMMARY form — slug, heading, level,
// versionHash, childCount. No body content, no recursive children. It's
// what shows up in directory-style listings. The full Section type carries
// content and children: [SectionInfo].
//
// Written: 2026-04-07 during mdpal-cli session (iteration 1.1 rebuild)
// Updated: 2026-04-07 — iteration 1.3: split SectionInfo (summary) from
//          Section (full). SectionInfo no longer has content or recursive
//          children — use Section for those.

import Foundation

/// Summary information about a section, returned by `Document.listSections`.
///
/// SectionInfo intentionally does NOT carry section body content or
/// recursive children — it's a flat directory entry. Use `Document.readSection`
/// to obtain a full `Section` with content.
public struct SectionInfo: Equatable, Sendable, Codable {

    /// The section's path-style slug (e.g., "authentication/oauth").
    public let slug: String

    /// The heading text (raw, before slug computation).
    public let heading: String

    /// The heading level (1-6 for Markdown).
    public let level: Int

    /// Deterministic hash of the section content for optimistic concurrency.
    public let versionHash: String

    /// Number of direct child sections.
    public let childCount: Int

    public init(
        slug: String,
        heading: String,
        level: Int,
        versionHash: String,
        childCount: Int
    ) {
        self.slug = slug
        self.heading = heading
        self.level = level
        self.versionHash = versionHash
        self.childCount = childCount
    }
}
