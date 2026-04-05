// What Problem: The app needs typed representations of comments and their
// lifecycle states (unresolved, resolved, stale). These drive the review
// UI — comment threads anchored to sections.
//
// How & Why: Match the A&D's comment data model (§5) but as app-side types
// parsed from CLI JSON. CommentType uses the five-type enum from the A&D.
// Resolution is optional — nil means unresolved. Staleness is computed by
// comparing the comment's versionHash against the section's current hash.
//
// Written: 2026-04-05 during mdpal-app Phase 1 scaffold

import Foundation

/// Comment types from the A&D (§3.2).
public enum CommentType: String, Codable, CaseIterable {
    case question
    case suggestion
    case note
    case directive
    case decision
}

/// Priority levels.
public enum Priority: String, Codable, CaseIterable {
    case low
    case normal
    case high
}

/// A stored comment (from `mdpal comments` output).
public struct Comment: Identifiable, Codable, Hashable {
    public let id: String
    public let type: CommentType
    public let author: String
    public let sectionSlug: String
    public let versionHash: String
    public let timestamp: Date
    public let context: String
    public let text: String
    public let resolution: Resolution?
    public let priority: Priority
    public let tags: [String]

    public init(id: String, type: CommentType, author: String,
                sectionSlug: String, versionHash: String, timestamp: Date,
                context: String, text: String, resolution: Resolution?,
                priority: Priority = .normal, tags: [String] = []) {
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

    enum CodingKeys: String, CodingKey {
        case id, type, author, timestamp, context, text, resolution, priority, tags
        case sectionSlug = "section_slug"
        case versionHash = "version_hash"
    }

    /// Whether this comment's section has changed since the comment was created.
    public func isStale(currentSectionHash: String) -> Bool {
        versionHash != currentSectionHash
    }

    /// Whether this comment has been resolved.
    public var isResolved: Bool {
        resolution != nil
    }
}

/// Comment resolution.
public struct Resolution: Codable, Hashable {
    public let response: String
    public let resolvedDate: Date
    public let resolvedBy: String

    public init(response: String, resolvedDate: Date, resolvedBy: String) {
        self.response = response
        self.resolvedDate = resolvedDate
        self.resolvedBy = resolvedBy
    }

    enum CodingKeys: String, CodingKey {
        case response
        case resolvedDate = "resolved_date"
        case resolvedBy = "resolved_by"
    }
}
