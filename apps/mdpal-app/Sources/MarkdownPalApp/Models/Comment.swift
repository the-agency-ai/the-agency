// What Problem: The app needs typed representations of comments and their
// lifecycle states (unresolved, resolved). These drive the review UI —
// comment threads anchored to sections.
//
// How & Why: Match the CLI JSON spec (dispatch #23) for comment types and
// field names. CommentType uses issue/todo instead of directive/decision.
// Resolution fields match spec: response, by, timestamp.
// Comment uses commentId (CLI field) with computed id for Identifiable.
// slug replaces sectionSlug. context is optional (may be absent).
// isStale removed — staleness is Phase 2 via `refresh` command.
// All CodingKeys removed — CLI JSON is camelCase, matches Swift names.
//
// Written: 2026-04-05 during mdpal-app Phase 1 scaffold
// Updated: 2026-04-06 Phase 1A model alignment (CLI JSON spec dispatch #23)

import Foundation

/// Comment types from the CLI spec.
public enum CommentType: String, Codable, CaseIterable {
    case question
    case suggestion
    case note
    case issue
    case todo
}

/// Priority levels.
public enum Priority: String, Codable, CaseIterable {
    case low
    case normal
    case high
}

/// A stored comment (from `mdpal comments` output).
public struct Comment: Identifiable, Codable, Hashable {
    public let commentId: String
    public let type: CommentType
    public let author: String
    public let slug: String
    public let timestamp: Date
    public let context: String?
    public let text: String
    public let resolved: Bool
    public let resolution: Resolution?
    public let priority: Priority
    public let tags: [String]

    /// Identifiable conformance — uses commentId from CLI spec.
    public var id: String { commentId }

    /// Whether this comment has been resolved.
    public var isResolved: Bool { resolved }

    public init(commentId: String, type: CommentType, author: String,
                slug: String, timestamp: Date,
                context: String?, text: String, resolved: Bool,
                resolution: Resolution? = nil,
                priority: Priority = .normal, tags: [String] = []) {
        self.commentId = commentId
        self.type = type
        self.author = author
        self.slug = slug
        self.timestamp = timestamp
        self.context = context
        self.text = text
        self.resolved = resolved
        self.resolution = resolution
        self.priority = priority
        self.tags = tags
    }
}

/// Comment resolution.
public struct Resolution: Codable, Hashable {
    public let response: String
    public let by: String
    public let timestamp: Date

    public init(response: String, by: String, timestamp: Date) {
        self.response = response
        self.by = by
        self.timestamp = timestamp
    }
}
