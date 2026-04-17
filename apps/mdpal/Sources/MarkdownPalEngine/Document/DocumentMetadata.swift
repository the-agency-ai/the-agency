// What Problem: A document's metadata block holds DocumentInfo plus three
// lists: unresolved comments, resolved comments, and flags. The engine
// needs an aggregate type that bundles these together for serialization.
//
// How & Why: Plain value struct holding the four metadata sub-objects.
// Comments are split into resolved/unresolved lists at the YAML level
// (per the metadata format spec) but a single Comment type represents both
// — the difference is the presence of a Resolution. The engine routes a
// comment to the correct list based on `comment.isResolved`.
//
// Written: 2026-04-07 during mdpal-cli session (iteration 1.2)

/// Document-level metadata: identifying info, comments, and flags.
public struct DocumentMetadata: Equatable, Sendable {

    /// Document identifying information.
    public var document: DocumentInfo

    /// Comments without a resolution.
    public var unresolvedComments: [Comment]

    /// Comments with a resolution.
    public var resolvedComments: [Comment]

    /// Section flags.
    public var flags: [Flag]

    public init(
        document: DocumentInfo,
        unresolvedComments: [Comment] = [],
        resolvedComments: [Comment] = [],
        flags: [Flag] = []
    ) {
        self.document = document
        self.unresolvedComments = unresolvedComments
        self.resolvedComments = resolvedComments
        self.flags = flags
    }

    /// A blank metadata block for new documents.
    public static func blank() -> DocumentMetadata {
        DocumentMetadata(document: .blank())
    }

    /// All comments (unresolved + resolved).
    public var allComments: [Comment] {
        unresolvedComments + resolvedComments
    }
}
