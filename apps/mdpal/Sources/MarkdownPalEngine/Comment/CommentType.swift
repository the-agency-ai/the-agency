// What Problem: Comments come in distinct kinds — questions, suggestions,
// notes, directives, decisions. The engine needs a typed enumeration so
// callers can filter and route comments by intent.
//
// How & Why: Plain string-backed enum, Codable for YAML round-trip via Yams.
// Five cases per A&D §3.2. `note` is the catch-all for freeform comments
// that don't fit the other types.
//
// Written: 2026-04-07 during mdpal-cli session (iteration 1.2)

/// The kind of a comment.
///
/// - question: Ask for information or clarification
/// - suggestion: Propose a change
/// - note: Informational annotation (also the catch-all)
/// - directive: Instruction to act
/// - decision: Record a resolved choice
public enum CommentType: String, Codable, Equatable, Sendable, CaseIterable {
    case question
    case suggestion
    case note
    case directive
    case decision
}
