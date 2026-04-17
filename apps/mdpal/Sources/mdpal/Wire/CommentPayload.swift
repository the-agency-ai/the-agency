// What Problem: The Comment value type emitted by the engine has
// engine-internal field names (`id`, `sectionSlug`, `resolution: Resolution?`)
// that don't match the dispatched JSON spec to mdpal-app
// (`commentId`, `slug`, `resolved: Bool`, `resolution: {response, by, timestamp}`).
// The CLI needs a wire-format DTO that maps from the engine type.
//
// How & Why: CommentPayload mirrors the spec exactly. Construction from
// a `Comment` performs the field renaming + the boolean derivation
// (`resolved`) + the nested ResolutionPayload mapping. Used by
// CommentCommand, CommentsCommand, and ResolveCommand.
//
// Reference: usr/jordan/mdpal/dispatches/dispatch-cli-json-output-shapes-20260406.md
//
// Written: 2026-04-17 during mdpal-cli session (Phase 2 iteration 2.3)

import Foundation
import MarkdownPalEngine

/// Wire shape for a single comment, per spec.
///
/// Custom encode emits `resolution: null` explicitly when the comment
/// is unresolved (Swift's synthesized Encodable would omit the key,
/// breaking consumers that expect a stable shape).
struct CommentPayload: Encodable {
    let commentId: String
    let slug: String
    let type: String
    let author: String
    let text: String
    let context: String
    let priority: String
    let tags: [String]
    let timestamp: Date
    let resolved: Bool
    let resolution: ResolutionPayload?

    init(from comment: Comment) {
        self.commentId = comment.id
        self.slug = comment.sectionSlug
        self.type = comment.type.rawValue
        self.author = comment.author
        self.text = comment.text
        self.context = comment.context
        self.priority = comment.priority.rawValue
        self.tags = comment.tags
        self.timestamp = comment.timestamp
        self.resolved = comment.isResolved
        self.resolution = comment.resolution.map(ResolutionPayload.init(from:))
    }

    private enum CodingKeys: String, CodingKey {
        case commentId, slug, type, author, text, context, priority, tags, timestamp, resolved, resolution
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(commentId, forKey: .commentId)
        try c.encode(slug, forKey: .slug)
        try c.encode(type, forKey: .type)
        try c.encode(author, forKey: .author)
        try c.encode(text, forKey: .text)
        try c.encode(context, forKey: .context)
        try c.encode(priority, forKey: .priority)
        try c.encode(tags, forKey: .tags)
        try c.encode(timestamp, forKey: .timestamp)
        try c.encode(resolved, forKey: .resolved)
        if let resolution { try c.encode(resolution, forKey: .resolution) }
        else { try c.encodeNil(forKey: .resolution) }
    }
}

/// Wire shape for a comment resolution, per spec. Note field renaming:
/// engine's `resolvedBy` → `by`, `resolvedDate` → `timestamp`.
struct ResolutionPayload: Encodable {
    let response: String
    let by: String
    let timestamp: Date

    init(from resolution: Resolution) {
        self.response = resolution.response
        self.by = resolution.resolvedBy
        self.timestamp = resolution.resolvedDate
    }
}
