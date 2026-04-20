// What Problem: Callers creating a comment shouldn't have to supply the
// engine-assigned fields (id, timestamp, version_hash, context). They
// only know the intent — type, author, section, text, and optional
// metadata. The engine fills in the rest.
//
// How & Why: A separate input struct distinguishes "what callers provide"
// from "what the engine produces." The engine takes a NewComment and emits
// a fully populated Comment with id, timestamp, hash, and current section
// context filled in.
//
// Written: 2026-04-07 during mdpal-cli session (iteration 1.2)

/// Input for creating a new comment via Document.addComment.
///
/// The engine assigns id, timestamp, versionHash, and context (if nil)
/// when this is added to a Document.
public struct NewComment: Equatable, Sendable {

    /// The kind of comment.
    public let type: CommentType

    /// Who is authoring the comment.
    public let author: String

    /// The slug of the section to anchor the comment to.
    public let sectionSlug: String

    /// The comment body.
    public let text: String

    /// Optional override of the captured section context.
    /// If nil, the engine captures the current section content.
    public let context: String?

    /// Optional priority. Defaults to .normal if nil.
    public let priority: Priority?

    /// Optional tags. Defaults to [] if nil.
    public let tags: [String]?

    public init(
        type: CommentType,
        author: String,
        sectionSlug: String,
        text: String,
        context: String? = nil,
        priority: Priority? = nil,
        tags: [String]? = nil
    ) {
        self.type = type
        self.author = author
        self.sectionSlug = sectionSlug
        self.text = text
        self.context = context
        self.priority = priority
        self.tags = tags
    }
}
