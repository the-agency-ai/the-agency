// What Problem: The app needs a typed representation of flags — section-level
// markers for "this needs discussion." Flags are simpler than comments:
// one per section, no threading, no resolution workflow.
//
// How & Why: Direct mapping from CLI JSON spec (dispatch #23). One flag per
// section (re-flagging replaces the existing flag). The app shows flags as
// visual indicators on sections in the sidebar and as a banner in the reader.
// slug replaces sectionSlug to match CLI field names.
// All CodingKeys removed — CLI JSON is camelCase, matches Swift names.
//
// Written: 2026-04-05 during mdpal-app Phase 1 scaffold
// Updated: 2026-04-06 Phase 1A model alignment (CLI JSON spec dispatch #23)

import Foundation

/// A flag marking a section for discussion (from `mdpal flags` output).
public struct Flag: Identifiable, Codable, Hashable {
    public let slug: String
    public let note: String?
    public let author: String
    public let timestamp: Date

    public var id: String { slug }

    public init(slug: String, note: String?, author: String, timestamp: Date) {
        self.slug = slug
        self.note = note
        self.author = author
        self.timestamp = timestamp
    }
}
