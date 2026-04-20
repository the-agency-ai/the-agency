// What Problem: The app needs typed representations of sections returned
// by the mdpal CLI. These are app-side types — not shared with the engine.
// The engine has its own internal types; we parse CLI JSON into these.
//
// How & Why: Simple Swift structs conforming to Identifiable, Codable,
// and Hashable for SwiftUI list rendering and JSON parsing. The slug is
// the stable identifier (computed by the engine from headings). Version
// hashes enable optimistic concurrency on edits.
//
// Phase 1A alignment: SectionInfo replaced by recursive SectionTreeNode
// to match CLI spec. SectionsResponse wraps the tree with metadata.
// Section (read response) drops children, adds versionId.
// All CodingKeys removed — CLI JSON is camelCase, matches Swift names.
//
// Written: 2026-04-05 during mdpal-app Phase 1 scaffold
// Updated: 2026-04-06 Phase 1A model alignment (CLI JSON spec dispatch #23)

import Foundation

/// Recursive tree node for `mdpal sections` response.
/// Drives the sidebar list view after flattening in the service layer.
public struct SectionTreeNode: Identifiable, Codable, Hashable {
    public let slug: String
    public let heading: String
    public let level: Int
    public let versionHash: String
    public let children: [SectionTreeNode]

    public var id: String { slug }

    public init(slug: String, heading: String, level: Int,
                versionHash: String, children: [SectionTreeNode] = []) {
        self.slug = slug
        self.heading = heading
        self.level = level
        self.versionHash = versionHash
        self.children = children
    }
}

/// Wrapper for `mdpal sections` response.
/// Contains the recursive tree, count, and versionId.
/// Flattening happens here (once, in service layer), not per-render in views.
public struct SectionsResponse: Codable {
    public let sections: [SectionTreeNode]
    public let count: Int
    public let versionId: String

    public init(sections: [SectionTreeNode], count: Int, versionId: String) {
        self.sections = sections
        self.count = count
        self.versionId = versionId
    }

    /// Depth-first flattening of the section tree.
    /// Called once in the service layer when unwrapping the response.
    public func flattened() -> [SectionTreeNode] {
        var result: [SectionTreeNode] = []
        func walk(_ nodes: [SectionTreeNode]) {
            for node in nodes {
                result.append(node)
                walk(node.children)
            }
        }
        walk(sections)
        return result
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
    public let versionId: String

    public var id: String { slug }

    public init(slug: String, heading: String, level: Int, content: String,
                versionHash: String, versionId: String) {
        self.slug = slug
        self.heading = heading
        self.level = level
        self.content = content
        self.versionHash = versionHash
        self.versionId = versionId
    }
}
