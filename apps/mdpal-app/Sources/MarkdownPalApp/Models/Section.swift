// What Problem: The app needs typed representations of sections returned
// by the mdpal CLI. These are app-side types — not shared with the engine.
// The engine has its own internal types; we parse CLI JSON into these.
//
// How & Why: Simple Swift structs conforming to Identifiable, Codable,
// and Hashable for SwiftUI list rendering and JSON parsing. The slug is
// the stable identifier (computed by the engine from headings). Version
// hashes enable optimistic concurrency on edits.
//
// Written: 2026-04-05 during mdpal-app Phase 1 scaffold

import Foundation

/// Summary info for a section (from `mdpal sections` output).
/// Drives the sidebar list view.
public struct SectionInfo: Identifiable, Codable, Hashable {
    public let slug: String
    public let heading: String
    public let level: Int
    public let versionHash: String
    public let childCount: Int

    public var id: String { slug }

    public init(slug: String, heading: String, level: Int, versionHash: String, childCount: Int) {
        self.slug = slug
        self.heading = heading
        self.level = level
        self.versionHash = versionHash
        self.childCount = childCount
    }

    enum CodingKeys: String, CodingKey {
        case slug
        case heading
        case level
        case versionHash = "version_hash"
        case childCount = "child_count"
    }
}

/// A full section with content (from `mdpal read` output).
/// Drives the main reader/editor pane.
public struct Section: Identifiable, Codable, Hashable {
    public let slug: String
    public let heading: String
    public let level: Int
    public let content: String
    public let versionHash: String
    public let children: [SectionInfo]

    public var id: String { slug }

    public init(slug: String, heading: String, level: Int, content: String,
                versionHash: String, children: [SectionInfo]) {
        self.slug = slug
        self.heading = heading
        self.level = level
        self.content = content
        self.versionHash = versionHash
        self.children = children
    }

    enum CodingKeys: String, CodingKey {
        case slug
        case heading
        case level
        case content
        case versionHash = "version_hash"
        case children
    }
}
