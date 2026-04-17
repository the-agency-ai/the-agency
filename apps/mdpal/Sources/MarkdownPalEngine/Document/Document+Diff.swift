// What Problem: To support `mdpal diff <rev1> <rev2> <bundle>`, the
// engine needs an API that compares two parsed Documents at the section
// level. The `mdpal diff` CLI command is the proximate driver, but
// app-side diff views and merge-conflict pickers will reuse this.
//
// How & Why: `Document.diff(against:)` walks both documents' slug indexes
// and produces a `[SectionDiff]` ordered as: every slug present in
// `self` (target) in document order, then any slugs only in `other`
// (base), in their base order, marked as removed. Section identity is
// the path-style slug; section content is compared by `versionHash`
// (already derived from content via `VersionHash.compute`), so the
// comparison is content-equivalent without re-hashing each call.
//
// `DocumentBundle.diff(rev1:, rev2:)` is the convenience wrapper used
// by the CLI: looks up each revision by versionId, loads each as a
// Document, returns base.diff(against: target). Throws bundleConflict
// if either revision id is unknown.
//
// Summary text format: per the dispatched spec ("human-readable, not
// for programmatic use"), modified sections report a delta of character
// counts — `max(0, new.count - old.count)` chars added and
// `max(0, old.count - new.count)` chars removed. This is approximate
// (not a true LCS diff) but matches the spec's example shape and the
// spec's stability disclaimer. Programmatic consumers switch on
// `type`, not `summary`.
//
// Reference: usr/jordan/mdpal/dispatches/dispatch-cli-json-output-shapes-20260406.md
//
// Written: 2026-04-17 during mdpal-cli session (Phase 2 iteration 2.4)

import Foundation

extension Document {

    /// Compare this document (target) against another (base) and return a
    /// list of section-level changes.
    ///
    /// The result includes ALL slugs (added, removed, modified, AND
    /// unchanged). Callers who only want changes filter by `type`. CLI
    /// `mdpal diff` filters out `.unchanged` per the dispatched spec.
    ///
    /// - Parameter other: The base document to compare against.
    /// - Returns: Section diffs in this order:
    ///   1. Every slug in `self` (target), in document order — emitted as
    ///      `added` (slug only in target), `modified` (slug in both, hash
    ///      differs), or `unchanged` (slug in both, hashes equal).
    ///   2. Every slug only in `other` (base), in base document order —
    ///      emitted as `removed`.
    public func diff(against other: Document) throws -> [SectionDiff] {
        let targetSections = self.listSections()
        let baseSections = other.listSections()

        // Build a {slug: content} cache for both sides. We do the readSection
        // walk eagerly (vs lazily inside the modified branch) so readSection
        // failures surface as throws instead of being swallowed by `try?`. A
        // bug or I/O failure during the diff is far better as a loud error
        // than as a silently misleading "0 chars added, 0 chars removed".
        let targetContentBySlug = try Self.readAllSectionContents(self, sections: targetSections)
        let baseContentBySlug = try Self.readAllSectionContents(other, sections: baseSections)

        // Build base summary index for O(1) slug lookup.
        var baseBySlug: [String: SectionInfo] = [:]
        baseBySlug.reserveCapacity(baseSections.count)
        for section in baseSections {
            baseBySlug[section.slug] = section
        }
        var consumed: Set<String> = []
        consumed.reserveCapacity(targetSections.count)

        var result: [SectionDiff] = []
        result.reserveCapacity(targetSections.count + baseSections.count)

        // Pass 1: walk target sections in document order.
        for targetSection in targetSections {
            consumed.insert(targetSection.slug)
            if let baseSection = baseBySlug[targetSection.slug] {
                if baseSection.versionHash == targetSection.versionHash {
                    result.append(SectionDiff(
                        slug: targetSection.slug,
                        type: .unchanged,
                        summary: ""
                    ))
                } else {
                    let summary = Self.modifiedSummary(
                        baseContent: baseContentBySlug[targetSection.slug],
                        targetContent: targetContentBySlug[targetSection.slug]
                    )
                    result.append(SectionDiff(
                        slug: targetSection.slug,
                        type: .modified,
                        summary: summary
                    ))
                }
            } else {
                result.append(SectionDiff(
                    slug: targetSection.slug,
                    type: .added,
                    summary: "New section"
                ))
            }
        }

        // Pass 2: walk base sections in document order, emit removed for
        // slugs not seen in target.
        for baseSection in baseSections where !consumed.contains(baseSection.slug) {
            result.append(SectionDiff(
                slug: baseSection.slug,
                type: .removed,
                summary: "Section deleted"
            ))
        }

        return result
    }

    /// Eagerly read every section's content so the diff caller catches
    /// readSection failures as a thrown error rather than as silent
    /// data loss in the human-readable summary string.
    private static func readAllSectionContents(
        _ document: Document,
        sections: [SectionInfo]
    ) throws -> [String: String] {
        var contents: [String: String] = [:]
        contents.reserveCapacity(sections.count)
        for section in sections {
            contents[section.slug] = try document.readSection(section.slug).content
        }
        return contents
    }

    /// Build the human-readable `summary` field for a `.modified` change.
    ///
    /// The dispatched spec example is "Content changed (142 chars added,
    /// 30 chars removed)". We approximate by length delta: anything
    /// gained is "added", anything lost is "removed". A pure reorder
    /// (same length, different content) reports zero/zero, but the type
    /// remains `.modified` because hashes differ — the type is the
    /// reliable signal, the summary is documentation.
    private static func modifiedSummary(
        baseContent: String?,
        targetContent: String?
    ) -> String {
        // After F2 (eager content read) both arguments are populated for any
        // slug present in either document; the optional shape is preserved
        // only for resilience to future callers that pass nil deliberately.
        let oldLen = baseContent?.count ?? 0
        let newLen = targetContent?.count ?? 0
        let added = max(0, newLen - oldLen)
        let removed = max(0, oldLen - newLen)
        return "Content changed (\(added) chars added, \(removed) chars removed)"
    }
}

extension DocumentBundle {

    /// Compare two revisions of this bundle by versionId.
    ///
    /// Convenience wrapper that loads each revision as a Document and
    /// calls `target.diff(against: base)`.
    ///
    /// - Parameters:
    ///   - baseRevision: versionId of the older revision (the "from").
    ///   - targetRevision: versionId of the newer revision (the "to").
    /// - Returns: Section diffs ordered per `Document.diff(against:)`.
    /// - Throws: `EngineError.bundleConflict` if either revision id is
    ///   not present in the bundle.
    public func diff(
        baseRevision: String,
        targetRevision: String
    ) throws -> [SectionDiff] {
        let revisions = try listRevisions()
        guard let base = revisions.first(where: { $0.versionId == baseRevision }) else {
            throw EngineError.bundleConflict(
                "Revision not found in bundle: '\(baseRevision)'"
            )
        }
        guard let target = revisions.first(where: { $0.versionId == targetRevision }) else {
            throw EngineError.bundleConflict(
                "Revision not found in bundle: '\(targetRevision)'"
            )
        }
        let baseDoc = try Document(contentsOfFile: base.filePath)
        let targetDoc = try Document(contentsOfFile: target.filePath)
        return try targetDoc.diff(against: baseDoc)
    }
}
