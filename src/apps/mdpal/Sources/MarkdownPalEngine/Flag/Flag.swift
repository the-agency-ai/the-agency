// What Problem: Flags mark sections for discussion without the structure of
// a comment. They are lightweight bookmarks that say "come back to this."
//
// How & Why: Plain value struct, Codable for YAML round-trip. No id —
// flags are uniquely identified by (sectionSlug, author, timestamp). The
// note is optional because some flags are wordless markers.
//
// Written: 2026-04-07 during mdpal-cli session (iteration 1.2)

import Foundation

/// A lightweight flag marking a section for discussion.
public struct Flag: Equatable, Sendable, Codable {

    /// The slug of the section this flag is anchored to.
    public let sectionSlug: String

    /// Optional note explaining why the section is flagged.
    public let note: String?

    /// Who flagged the section.
    public let author: String

    /// When the flag was set.
    public let timestamp: Date

    public init(
        sectionSlug: String,
        note: String? = nil,
        author: String,
        timestamp: Date
    ) {
        self.sectionSlug = sectionSlug
        self.note = note
        self.author = author
        self.timestamp = timestamp
    }
}
