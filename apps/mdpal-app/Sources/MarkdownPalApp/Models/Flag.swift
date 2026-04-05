// What Problem: The app needs a typed representation of flags — section-level
// markers for "this needs discussion." Flags are simpler than comments:
// one per section, no threading, no resolution workflow.
//
// How & Why: Direct mapping from A&D §5.6. One flag per section (re-flagging
// replaces the existing flag). The app shows flags as visual indicators on
// sections in the sidebar and as a banner in the reader pane.
//
// Written: 2026-04-05 during mdpal-app Phase 1 scaffold

import Foundation

/// A flag marking a section for discussion (from `mdpal flags` output).
public struct Flag: Identifiable, Codable, Hashable {
    public let sectionSlug: String
    public let note: String?
    public let author: String
    public let timestamp: Date

    public var id: String { sectionSlug }

    public init(sectionSlug: String, note: String?, author: String, timestamp: Date) {
        self.sectionSlug = sectionSlug
        self.note = note
        self.author = author
        self.timestamp = timestamp
    }

    enum CodingKeys: String, CodingKey {
        case sectionSlug = "section_slug"
        case note, author, timestamp
    }
}
