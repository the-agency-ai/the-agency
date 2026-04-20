// What Problem: Iteration 1.3 adds the comment lifecycle on Document —
// add, list (filtered), resolve. Comments are anchored to a section by
// path-style slug. The engine assigns id, timestamp, and version_hash;
// callers provide intent (type, author, text, optional priority/tags).
//
// How & Why: ID assignment is a simple monotonic counter scoped to the
// document — `c001`, `c002`, etc. Stored at the bottom of the
// unresolved/resolved comment lists, never re-numbered. The next id is
// computed from the maximum existing numeric suffix across BOTH lists.
//
// Resolving a comment moves it from unresolvedComments to resolvedComments
// and attaches a Resolution. Resolving an already-resolved comment throws
// commentAlreadyResolved.
//
// Section validation: addComment and resolveComment both validate that
// the target section exists (for addComment) or that the comment exists
// (for resolveComment). The version_hash captured at addComment time is
// the section's CURRENT hash, which lets refreshSection later detect
// staleness when the section content changes.
//
// Written: 2026-04-07 during mdpal-cli session (iteration 1.3)

import Foundation

extension Document {

    // MARK: - Add

    /// Add a comment anchored to a section.
    ///
    /// - Throws: `.sectionNotFound` if the comment's `sectionSlug` does
    ///   not match an existing section.
    @discardableResult
    public func addComment(_ input: NewComment) throws -> Comment {
        guard let node = findNode(slug: input.sectionSlug) else {
            throw EngineError.sectionNotFound(
                slug: input.sectionSlug,
                available: allSlugs()
            )
        }
        let id = nextCommentId()
        let now = Date()
        let context = input.context ?? node.content
        let comment = Comment(
            id: id,
            type: input.type,
            author: input.author,
            sectionSlug: input.sectionSlug,
            versionHash: VersionHash.compute(node.content),
            timestamp: now,
            context: context,
            text: input.text,
            resolution: nil,
            priority: input.priority ?? .normal,
            tags: input.tags ?? []
        )
        metadata.unresolvedComments.append(comment)
        return comment
    }

    // MARK: - List

    /// List comments matching the given filter, or all comments if filter is nil.
    public func listComments(filter: CommentFilter? = nil) -> [Comment] {
        let all = metadata.allComments
        guard let filter = filter else { return all }
        return all.filter { filter.matches($0) }
    }

    // MARK: - Resolve

    /// Resolve an unresolved comment by id, attaching a response.
    ///
    /// - Throws: `.commentNotFound` if no comment matches.
    /// - Throws: `.commentAlreadyResolved` if the comment is already in the
    ///   resolved list.
    @discardableResult
    public func resolveComment(
        id: String,
        response: String,
        resolvedBy: String,
        resolvedDate: Date = Date()
    ) throws -> Comment {
        if metadata.resolvedComments.contains(where: { $0.id == id }) {
            throw EngineError.commentAlreadyResolved(id: id)
        }
        guard let index = metadata.unresolvedComments.firstIndex(where: { $0.id == id }) else {
            throw EngineError.commentNotFound(id: id)
        }
        let original = metadata.unresolvedComments.remove(at: index)
        let resolved = original.with(
            resolution: Resolution(
                response: response,
                resolvedDate: resolvedDate,
                resolvedBy: resolvedBy
            )
        )
        metadata.resolvedComments.append(resolved)
        return resolved
    }

    // MARK: - ID assignment

    /// Generate the next comment id (e.g., `c0001`, `c0002`).
    ///
    /// Numeric suffix = max existing id + 1, across BOTH lists.
    /// Width is 4 digits so lexicographic sort matches numeric sort up to
    /// 9999 comments per document. If a single document ever exceeds that
    /// (extremely unlikely for human-authored markdown), the lex sort
    /// degrades but uniqueness is still preserved.
    private func nextCommentId() -> String {
        let maxExisting = metadata.allComments
            .compactMap { commentNumericSuffix($0.id) }
            .max() ?? 0
        let next = maxExisting + 1
        return String(format: "c%04d", next)
    }

    /// Extract the numeric tail of a comment id like `c0042` → 42.
    /// Returns nil if the id doesn't match the pattern.
    private func commentNumericSuffix(_ id: String) -> Int? {
        guard id.hasPrefix("c") else { return nil }
        return Int(id.dropFirst())
    }
}
