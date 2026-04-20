// What Problem: `mdpal diff <rev1> <rev2> <bundle>` and any future
// app-side diff view need to compare two Documents and report what
// changed at the section level — added, removed, modified, or unchanged.
// Without a typed result, every caller would re-implement the slug-walk
// and the human-readable summary.
//
// How & Why: SectionDiff is the value carrier — slug, change type, and
// a human-readable summary string. SectionDiffType is the small enum of
// possible outcomes. The change classification is symmetric: comparing
// A.diff(against: B) against B.diff(against: A) inverts added↔removed
// and preserves modified/unchanged. The summary is intentionally
// human-readable per the dispatched spec ("not for programmatic use") —
// programmatic consumers should switch on `type`, not parse `summary`.
//
// Reference: usr/jordan/mdpal/dispatches/dispatch-cli-json-output-shapes-20260406.md
//
// Written: 2026-04-17 during mdpal-cli session (Phase 2 iteration 2.4)

import Foundation

/// A single section-level change between two documents.
///
/// Returned in document order: sections present in `target` come first
/// (in their target order), then sections only in `base` (in their base
/// order) marked as `removed`.
public struct SectionDiff: Equatable, Sendable {

    /// Path-style slug of the affected section.
    public let slug: String

    /// What kind of change this slug represents.
    public let type: SectionDiffType

    /// Human-readable description of the change. Format examples:
    ///   - added:     "New section"
    ///   - removed:   "Section deleted"
    ///   - modified:  "Content changed (142 chars added, 30 chars removed)"
    ///   - unchanged: "" (empty)
    ///
    /// Per the dispatched spec to mdpal-app, this is for human display.
    /// Programmatic consumers should switch on `type`, NOT parse `summary`.
    public let summary: String

    public init(slug: String, type: SectionDiffType, summary: String) {
        self.slug = slug
        self.type = type
        self.summary = summary
    }
}

/// Classification for a single section in a diff between two documents.
///
/// Raw values are camelCase symbol strings so they round-trip directly
/// to the wire format without translation.
public enum SectionDiffType: String, Equatable, Sendable, Codable {
    /// Slug exists in target, not in base.
    case added
    /// Slug exists in base, not in target.
    case removed
    /// Slug exists in both, but content differs.
    case modified
    /// Slug exists in both with identical content.
    case unchanged
}
