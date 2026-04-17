// What Problem: Listing all comments on a busy document overwhelms callers.
// They need a filter spec to narrow by section, type, author, or resolution
// state.
//
// How & Why: Plain value struct with optional fields. Each non-nil field
// is an AND filter. unresolvedOnly and resolvedOnly are mutually exclusive
// in practice but the struct doesn't enforce this — the consumer logic does.
//
// Written: 2026-04-07 during mdpal-cli session (iteration 1.2)

/// Filter specification for Document.listComments.
public struct CommentFilter: Equatable, Sendable {

    /// Match comments anchored to this section slug.
    public var sectionSlug: String?

    /// Match comments of this type.
    public var type: CommentType?

    /// Match comments by this author.
    public var author: String?

    /// If true, only return unresolved comments.
    public var unresolvedOnly: Bool

    /// If true, only return resolved comments.
    public var resolvedOnly: Bool

    public init(
        sectionSlug: String? = nil,
        type: CommentType? = nil,
        author: String? = nil,
        unresolvedOnly: Bool = false,
        resolvedOnly: Bool = false
    ) {
        self.sectionSlug = sectionSlug
        self.type = type
        self.author = author
        self.unresolvedOnly = unresolvedOnly
        self.resolvedOnly = resolvedOnly
    }

    /// Check whether a comment matches this filter.
    public func matches(_ comment: Comment) -> Bool {
        if let slug = sectionSlug, comment.sectionSlug != slug { return false }
        if let type = type, comment.type != type { return false }
        if let author = author, comment.author != author { return false }
        if unresolvedOnly && comment.isResolved { return false }
        if resolvedOnly && !comment.isResolved { return false }
        return true
    }
}
