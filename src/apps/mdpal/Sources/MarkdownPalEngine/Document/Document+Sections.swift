// What Problem: Iteration 1.3 adds the section operations on Document —
// listing, reading, editing with optimistic concurrency, and refreshing
// stale comment hashes. These are the read/write surface that the CLI
// commands and the app will drive.
//
// How & Why: All section addressing is path-style: parent/child slugs joined
// by "/". The engine walks the SectionNode tree, computing path slugs and
// version hashes from current content (NOT from a stored field — the engine
// is the source of truth for hashes).
//
// SLUG DISAMBIGUATION: Two siblings with the same heading would otherwise
// produce identical slugs and the second would be unreachable. We follow
// GitHub's convention: the first occurrence keeps the bare slug, subsequent
// occurrences get `-1`, `-2` etc. Disambiguation is computed at the parent
// level by counting prior siblings whose base slug matches.
//
// SLUG INDEX: We compute a single tree → slug index at the start of each
// operation and reuse it for find/list/edit. This eliminates duplicated
// slug computation and guarantees that findNode, replaceContent, and
// listSections all see the SAME slug for the same node.
//
// EDIT WITH HEADINGS: editSection's V1 implementation REPLACES the body
// content as a flat string. If newContent contains headings, those headings
// would live inside the body string but not be visible to listSections —
// a real correctness hazard. We reject newContent that parses to a tree
// with non-empty children, throwing parseError with an actionable message.
// Re-parsing newContent for inline sub-sections lands in iteration 1.4
// when bundle revisions arrive.
//
// Optimistic concurrency: editSection requires the caller's `versionHash`
// to match the current hash; mismatch throws EngineError.versionConflict
// with the current content so the caller can re-read and retry.
//
// Written: 2026-04-07 during mdpal-cli session (iteration 1.3)
// Updated: 2026-04-07 — QG fixes: sibling slug disambiguation, DRY slug
//          computation via index, edit-with-headings rejection.

import Foundation

extension Document {

    // MARK: - List

    /// List every section in the document as a flat array of summaries.
    /// Path slugs encode hierarchy (e.g., `intro/oauth`).
    public func listSections() -> [SectionInfo] {
        let index = buildSlugIndex()
        return index.entries.map { entry in
            SectionInfo(
                slug: entry.path,
                heading: entry.node.heading,
                level: entry.node.level,
                versionHash: VersionHash.compute(entry.node.content),
                childCount: entry.node.children.count
            )
        }
    }

    // MARK: - Read

    /// Read a section by path-style slug.
    /// Throws `.sectionNotFound` if no section matches.
    public func readSection(_ slug: String) throws -> Section {
        let index = buildSlugIndex()
        guard let entry = index.entry(forPath: slug) else {
            throw EngineError.sectionNotFound(slug: slug, available: index.allPaths())
        }
        return makeSection(entry: entry, in: index)
    }

    // MARK: - Edit

    /// Edit a section's body content with optimistic concurrency.
    ///
    /// - Parameters:
    ///   - slug: Path-style slug of the section.
    ///   - newContent: New body content. Replaces the existing body verbatim.
    ///                 Heading and children are preserved. Must NOT contain
    ///                 new headings (V1 limitation; iteration 1.4 will
    ///                 re-parse for inline sub-sections).
    ///   - versionHash: The hash the caller observed when reading the section.
    ///                  Must match the current hash, or `.versionConflict`
    ///                  is thrown.
    /// - Returns: The freshly written Section with updated hash.
    @discardableResult
    public func editSection(
        _ slug: String,
        newContent: String,
        versionHash: String
    ) throws -> Section {
        let index = buildSlugIndex()
        guard let entry = index.entry(forPath: slug) else {
            throw EngineError.sectionNotFound(slug: slug, available: index.allPaths())
        }

        let currentHash = VersionHash.compute(entry.node.content)
        if currentHash != versionHash {
            throw EngineError.versionConflict(
                slug: slug,
                expected: versionHash,
                actual: currentHash,
                currentContent: entry.node.content
            )
        }

        // V1: reject newContent that introduces sub-sections. Re-parsing
        // body content for inline sub-sections lands in iteration 1.4.
        let probe = try parser.parse(newContent)
        if !probe.root.children.isEmpty {
            throw EngineError.parseError(
                description: "editSection cannot accept newContent containing headings (iteration 1.3 limitation). Edit child sections individually.",
                line: nil,
                column: nil
            )
        }

        // Rewrap the tree by walking the index path to mutate the matching
        // node. SectionNode is a struct, so we mutate via in-place index
        // path navigation.
        var rootCopy = sections.root
        applyContentEdit(
            indexPath: entry.indexPath,
            in: &rootCopy,
            newContent: newContent
        )
        sections = SectionTree(root: rootCopy, originalSource: sections.originalSource)

        // Re-fetch via a fresh index so the returned Section reflects the
        // new state.
        let updatedIndex = buildSlugIndex()
        guard let updatedEntry = updatedIndex.entry(forPath: slug) else {
            // Should be impossible — slug computation depends on heading,
            // which we did not modify.
            throw EngineError.sectionNotFound(slug: slug, available: updatedIndex.allPaths())
        }
        return makeSection(entry: updatedEntry, in: updatedIndex)
    }

    // MARK: - Refresh

    /// Refresh stale comment version hashes on a section.
    ///
    /// Updates each comment's `versionHash` to the section's current hash
    /// so it is no longer flagged as stale. Does NOT update the comment's
    /// `context` — the original captured context is preserved as historical
    /// record. Only operates on `unresolvedComments`; resolved comments
    /// are frozen at resolution time.
    ///
    /// Returns the list of comments that were refreshed (only those whose
    /// hash differed from the current section hash).
    @discardableResult
    public func refreshSection(_ slug: String) throws -> [Comment] {
        let index = buildSlugIndex()
        guard let entry = index.entry(forPath: slug) else {
            throw EngineError.sectionNotFound(slug: slug, available: index.allPaths())
        }
        let currentHash = VersionHash.compute(entry.node.content)
        var refreshed: [Comment] = []
        metadata.unresolvedComments = metadata.unresolvedComments.map { comment in
            guard comment.sectionSlug == slug, comment.versionHash != currentHash else {
                return comment
            }
            let updated = comment.with(versionHash: currentHash)
            refreshed.append(updated)
            return updated
        }
        return refreshed
    }

    // MARK: - Slug index

    /// One entry in the slug index — a node, its full path slug, and the
    /// list of child indices to navigate from the root.
    struct SlugIndexEntry {
        let path: String
        let node: SectionNode
        let indexPath: [Int]
        let parentPath: String
    }

    /// A precomputed map of path slug → SectionNode entry. Built once per
    /// public operation so listSections / findNode / replaceContent all
    /// agree on the same slug computation. Sibling collisions are
    /// disambiguated GitHub-style: first occurrence is bare, subsequent
    /// are `-1`, `-2` etc.
    struct SlugIndex {
        let entries: [SlugIndexEntry]
        private let byPath: [String: Int]

        init(entries: [SlugIndexEntry]) {
            self.entries = entries
            var map: [String: Int] = [:]
            for (i, entry) in entries.enumerated() {
                map[entry.path] = i
            }
            self.byPath = map
        }

        func entry(forPath path: String) -> SlugIndexEntry? {
            guard let i = byPath[path] else { return nil }
            return entries[i]
        }

        func allPaths() -> [String] { entries.map { $0.path } }
    }

    /// Build the slug index from the current section tree.
    func buildSlugIndex() -> SlugIndex {
        var entries: [SlugIndexEntry] = []
        for (i, child) in sections.root.children.enumerated() {
            collectIndexEntries(
                node: child,
                indexPath: [i],
                parentPath: "",
                siblings: sections.root.children,
                siblingIndex: i,
                into: &entries
            )
        }
        return SlugIndex(entries: entries)
    }

    private func collectIndexEntries(
        node: SectionNode,
        indexPath: [Int],
        parentPath: String,
        siblings: [SectionNode],
        siblingIndex: Int,
        into entries: inout [SlugIndexEntry]
    ) {
        let leaf = disambiguatedLeafSlug(
            for: node,
            siblings: siblings,
            siblingIndex: siblingIndex
        )
        let path = parentPath.isEmpty ? leaf : "\(parentPath)/\(leaf)"
        entries.append(SlugIndexEntry(
            path: path,
            node: node,
            indexPath: indexPath,
            parentPath: parentPath
        ))
        for (i, child) in node.children.enumerated() {
            collectIndexEntries(
                node: child,
                indexPath: indexPath + [i],
                parentPath: path,
                siblings: node.children,
                siblingIndex: i,
                into: &entries
            )
        }
    }

    /// Compute a sibling-disambiguated leaf slug.
    /// First occurrence: bare slug. Subsequent: `-1`, `-2`, ...
    private func disambiguatedLeafSlug(
        for node: SectionNode,
        siblings: [SectionNode],
        siblingIndex: Int
    ) -> String {
        let base = parser.slug(for: node.heading)
        var collisionCount = 0
        for i in 0..<siblingIndex {
            if parser.slug(for: siblings[i].heading) == base {
                collisionCount += 1
            }
        }
        return collisionCount == 0 ? base : "\(base)-\(collisionCount)"
    }

    // MARK: - Materialize a Section

    private func makeSection(
        entry: SlugIndexEntry,
        in index: SlugIndex
    ) -> Section {
        let childInfos = entry.node.children.enumerated().map { (i, child) -> SectionInfo in
            let childPath = entry.path + "/" + disambiguatedLeafSlug(
                for: child,
                siblings: entry.node.children,
                siblingIndex: i
            )
            return SectionInfo(
                slug: childPath,
                heading: child.heading,
                level: child.level,
                versionHash: VersionHash.compute(child.content),
                childCount: child.children.count
            )
        }
        return Section(
            slug: entry.path,
            heading: entry.node.heading,
            level: entry.node.level,
            content: entry.node.content,
            versionHash: VersionHash.compute(entry.node.content),
            children: childInfos,
            // Line range lands in iteration 1.4 when source-range slicing
            // wires through SectionNode. Until then, the field is nil.
            lineRange: nil
        )
    }

    // MARK: - Tree mutation

    /// Replace the content of the node at the given index path.
    /// The path is a list of child indices from the root: [] is the root,
    /// [0] is the first top-level child, [0,1] is the second child of the
    /// first top-level child, etc.
    private func applyContentEdit(
        indexPath: [Int],
        in node: inout SectionNode,
        newContent: String
    ) {
        guard let firstIndex = indexPath.first else {
            // Reached the target — replace content.
            node = SectionNode(
                heading: node.heading,
                level: node.level,
                content: newContent,
                sourceRange: node.sourceRange,
                children: node.children
            )
            return
        }
        var newChildren = node.children
        applyContentEdit(
            indexPath: Array(indexPath.dropFirst()),
            in: &newChildren[firstIndex],
            newContent: newContent
        )
        node = SectionNode(
            heading: node.heading,
            level: node.level,
            content: node.content,
            sourceRange: node.sourceRange,
            children: newChildren
        )
    }

    // MARK: - Helpers used by other extensions

    /// Find a node by path-style slug. Used by Document+Comments and
    /// Document+Flags. Returns the SectionNode at the matching path,
    /// or nil if not found.
    func findNode(slug: String) -> SectionNode? {
        buildSlugIndex().entry(forPath: slug)?.node
    }

    /// All path-style slugs in the document, in document order.
    /// Used in error messages.
    func allSlugs() -> [String] {
        buildSlugIndex().allPaths()
    }
}
