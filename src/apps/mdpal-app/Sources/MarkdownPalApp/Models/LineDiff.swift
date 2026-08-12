// What Problem: When the CLI reports a versionConflict or bundleConflict,
// Phase 2.2's alert tells the user something changed but not WHAT. Users
// staring at 'Section was modified' can't tell if their unsaved edit
// overlaps trivially with the remote change (retry) or is a substantive
// divergence (reload + remerge). The information the CLI already carries —
// `currentContent` on versionConflict envelopes, `currentRevision` on
// bundleConflicts — is enough to show a diff between what the user wrote
// and what's on disk now.
//
// How & Why:
// - Pure line-diff over [String]: no swift-markdown dependency, no external
//   diff library. `CollectionDifference<String>` from Swift stdlib is enough
//   for the V1 use case (small documents, 5-50 KB typical, sections smaller).
// - LCS-based diff is O(n*m) worst case but n,m are small lines-per-section.
//   If a degenerate case surfaces (huge sections) we can revisit; not worth
//   pre-optimizing.
// - Output type is a flat [DiffLine] with .added/.removed/.unchanged — the
//   View layer renders as a unified diff (`+ `/`- `/`  ` prefix) or
//   side-by-side (two columns, gaps where .added/.removed has no mate).
// - Pure function is tested directly; View test comes later with an
//   XCUITest harness (Phase 3.9).
//
// Written: 2026-04-19 during mdpal-app Phase 2.3

import Foundation

/// A single line in a computed diff. Order within the output array
/// preserves the document order of the "current" content — unchanged
/// lines appear in place, additions interleaved where they land,
/// removals interleaved where they were dropped from.
///
/// Equatable + Hashable so View layer can use in `ForEach(... id:)`.
public struct DiffLine: Equatable, Hashable, Sendable {
    public enum Kind: Sendable {
        /// Line is in both pending and current content (unchanged).
        case unchanged
        /// Line is in pending but not current (user wrote it; not on disk now).
        /// The user needs to decide: re-add, or accept current shape.
        case pendingOnly
        /// Line is in current but not pending (other writer added; user didn't).
        /// The user needs to decide: merge in, or override.
        case currentOnly
    }

    public let kind: Kind
    public let text: String
    /// 1-based line index in the pending content. Nil for .currentOnly lines
    /// that have no pending counterpart.
    public let pendingLineNumber: Int?
    /// 1-based line index in the current content. Nil for .pendingOnly lines
    /// that have no current counterpart.
    public let currentLineNumber: Int?

    public init(kind: Kind, text: String,
                pendingLineNumber: Int?, currentLineNumber: Int?) {
        self.kind = kind
        self.text = text
        self.pendingLineNumber = pendingLineNumber
        self.currentLineNumber = currentLineNumber
    }
}

/// Compute a line-level diff between two content strings. Splits on `\n`
/// (preserving empty lines including trailing blank). Uses Swift stdlib
/// `CollectionDifference` + its applying logic to produce an in-order
/// list of `DiffLine`s.
///
/// Determinism: same inputs yield byte-identical output across runs and
/// platforms — stdlib `CollectionDifference` is deterministic on `Equatable`
/// `Collection` types. Important for Phase 3's flatten-determinism story
/// (diff output is a building block for per-revision diffs).
///
/// Complexity: O(n*m) worst case via stdlib's LCS-based backing; n,m are
/// line counts of the two inputs. Typical section ~100 lines → ~10k
/// operations — fast.
public func computeLineDiff(pending: String, current: String) -> [DiffLine] {
    // An empty string is ZERO lines, not one empty line.
    //
    // pr-prep QG (re-prep vs v46.30): `"".components(separatedBy: "\n")`
    // returns `[""]`, so an empty pending document used to diff as one
    // empty line that matched nothing on the current side. Diffing "" against
    // "a\nb\nc" produced a spurious `.pendingOnly` empty line alongside the
    // three real additions, and DiffStats then reported "4 lines changed —
    // 3 added, 1 removed" for what is purely an addition. DiffView renders
    // that phantom as a blank `-` row. Standard diff tools treat an empty
    // file as zero lines; match that.
    let pendingLines = pending.isEmpty ? [] : pending.components(separatedBy: "\n")
    let currentLines = current.isEmpty ? [] : current.components(separatedBy: "\n")

    // Short-circuit for identical content. Saves work AND guarantees
    // returning unchanged-only output (no spurious pendingOnly /
    // currentOnly lines when the inputs equal byte-for-byte).
    guard pendingLines != currentLines else {
        return pendingLines.enumerated().map { (idx, text) in
            DiffLine(kind: .unchanged, text: text,
                     pendingLineNumber: idx + 1,
                     currentLineNumber: idx + 1)
        }
    }

    // CollectionDifference<String> captures which lines were inserted
    // (to transform pending→current) and which were removed. We expand
    // that into a flat [DiffLine] walking both sequences in order.
    let diff = currentLines.difference(from: pendingLines)

    // Build lookups: which pending-indexes are removed, and where new
    // current-indexes get inserted. Both keyed by offset.
    var removedPendingIndices = Set<Int>()
    var insertedCurrentIndices: [Int: String] = [:]
    for change in diff {
        switch change {
        case .remove(let offset, _, _):
            removedPendingIndices.insert(offset)
        case .insert(let offset, let element, _):
            insertedCurrentIndices[offset] = element
        }
    }

    // Walk the current-lines array in order. At each position:
    // - If index matches an insertion: emit a .currentOnly
    //   (the inserted line didn't exist in pending).
    // - Else: there's a matching pending line (via CollectionDifference's
    //   invariant that non-removed pending lines survive to current in order).
    // Removed pending lines are emitted BEFORE the current position where
    // they fell out, so the diff shows user-written-then-dropped content
    // at the structural place it used to live.
    var result: [DiffLine] = []
    var pendingCursor = 0  // walks pendingLines in order
    var currentCursor = 0  // walks currentLines in order

    while currentCursor < currentLines.count || pendingCursor < pendingLines.count {
        // Emit removed-pending lines at the current pending cursor first —
        // they're the bits the user had that got dropped upstream.
        while pendingCursor < pendingLines.count,
              removedPendingIndices.contains(pendingCursor) {
            result.append(DiffLine(
                kind: .pendingOnly,
                text: pendingLines[pendingCursor],
                pendingLineNumber: pendingCursor + 1,
                currentLineNumber: nil))
            pendingCursor += 1
        }

        // Emit inserted-current line at the current cursor if present.
        if currentCursor < currentLines.count,
           let insertedText = insertedCurrentIndices[currentCursor] {
            result.append(DiffLine(
                kind: .currentOnly,
                text: insertedText,
                pendingLineNumber: nil,
                currentLineNumber: currentCursor + 1))
            currentCursor += 1
            continue
        }

        // Both cursors on an unchanged line: emit as unchanged and advance both.
        if currentCursor < currentLines.count,
           pendingCursor < pendingLines.count,
           currentLines[currentCursor] == pendingLines[pendingCursor] {
            result.append(DiffLine(
                kind: .unchanged,
                text: currentLines[currentCursor],
                pendingLineNumber: pendingCursor + 1,
                currentLineNumber: currentCursor + 1))
            pendingCursor += 1
            currentCursor += 1
            continue
        }

        // Safety: if we fall through neither emits (shouldn't happen with
        // a well-formed CollectionDifference), break to avoid infinite loop.
        // Not reachable in practice — enforced by test coverage.
        break
    }

    return result
}

/// Statistics for a computed diff. Used by the alert summary (e.g.,
/// "3 lines changed — 2 added, 1 removed").
public struct DiffStats: Equatable, Hashable, Sendable {
    public let unchanged: Int
    public let pendingOnly: Int   // user wrote; not on disk now
    public let currentOnly: Int   // upstream added; user didn't have

    public var totalChanged: Int { pendingOnly + currentOnly }
    public var isIdentical: Bool { pendingOnly == 0 && currentOnly == 0 }

    public init(_ lines: [DiffLine]) {
        var unchanged = 0, pendingOnly = 0, currentOnly = 0
        for line in lines {
            switch line.kind {
            case .unchanged: unchanged += 1
            case .pendingOnly: pendingOnly += 1
            case .currentOnly: currentOnly += 1
            }
        }
        self.unchanged = unchanged
        self.pendingOnly = pendingOnly
        self.currentOnly = currentOnly
    }
}
