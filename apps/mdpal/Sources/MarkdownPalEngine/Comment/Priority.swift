// What Problem: Comments need a priority signal so triage tools and agents
// can route urgent items differently from background notes.
//
// How & Why: Three-level enum (low/normal/high). String-backed for YAML.
// `normal` is the default when callers don't specify a priority.
//
// Written: 2026-04-07 during mdpal-cli session (iteration 1.2)

/// Priority level for a comment.
public enum Priority: String, Codable, Equatable, Sendable, CaseIterable {
    case low
    case normal
    case high
}
