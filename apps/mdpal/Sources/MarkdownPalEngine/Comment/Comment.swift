// What Problem: Comments are first-class artifacts on document sections —
// they capture questions, suggestions, decisions, and notes from collaborators.
// The engine needs a stable in-memory representation that can be serialized
// to YAML and rehydrated without losing fields.
//
// How & Why: Value type (struct) for immutability. Identifiable conformance
// uses the engine-assigned id. The `versionHash` field captures the section
// content hash AT THE TIME the comment was written — this is how the engine
// detects "stale" comments (the section has changed since the comment was
// anchored). The original `context` is preserved so a future reader can see
// what the comment was written against, even after the section has been
// edited many times.
//
// Written: 2026-04-07 during mdpal-cli session (iteration 1.2)

import Foundation

/// A stored comment anchored to a document section.
public struct Comment: Identifiable, Equatable, Sendable, Codable {

    /// Engine-assigned unique identifier (e.g., "c001").
    public let id: String

    /// The kind of comment.
    public let type: CommentType

    /// Who authored the comment.
    public let author: String

    /// The slug of the section this comment is anchored to.
    public let sectionSlug: String

    /// Section content hash at the time the comment was written.
    /// Used to detect staleness when the section has been edited since.
    public let versionHash: String

    /// When the comment was created.
    public let timestamp: Date

    /// The original section content captured when the comment was written.
    /// Preserved for historical context — never updated by refresh.
    public let context: String

    /// The comment body.
    public let text: String

    /// The resolution (nil if unresolved).
    public let resolution: Resolution?

    /// Priority. Defaults to .normal when not specified.
    public let priority: Priority

    /// Tags. Defaults to [] when not specified.
    public let tags: [String]

    public init(
        id: String,
        type: CommentType,
        author: String,
        sectionSlug: String,
        versionHash: String,
        timestamp: Date,
        context: String,
        text: String,
        resolution: Resolution? = nil,
        priority: Priority = .normal,
        tags: [String] = []
    ) {
        self.id = id
        self.type = type
        self.author = author
        self.sectionSlug = sectionSlug
        self.versionHash = versionHash
        self.timestamp = timestamp
        self.context = context
        self.text = text
        self.resolution = resolution
        self.priority = priority
        self.tags = tags
    }

    /// Whether the comment has been resolved.
    public var isResolved: Bool { resolution != nil }

    /// Return a copy with the given fields replaced. Used by the engine
    /// to update version hashes (refreshSection) and attach resolutions
    /// (resolveComment) without hand-copying every field — which is
    /// brittle when Comment gains new fields. Pass nil to leave a field
    /// unchanged (we never need to clear a resolution).
    public func with(
        versionHash: String? = nil,
        resolution: Resolution? = nil
    ) -> Comment {
        Comment(
            id: self.id,
            type: self.type,
            author: self.author,
            sectionSlug: self.sectionSlug,
            versionHash: versionHash ?? self.versionHash,
            timestamp: self.timestamp,
            context: self.context,
            text: self.text,
            resolution: resolution ?? self.resolution,
            priority: self.priority,
            tags: self.tags
        )
    }
}
