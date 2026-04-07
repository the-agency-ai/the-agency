// What Problem: The engine needs structured error types that callers can
// pattern-match on to provide useful error messages and appropriate exit codes.
//
// How & Why: Swift enum with associated values for rich error context.
// Each case maps to a specific failure mode from the A&D: parse errors,
// metadata errors, section not found (with available slugs for suggestions),
// version conflicts (with current content for recovery), and bundle conflicts.
//
// Written: 2026-04-07 during mdpal-cli session (iteration 1.1 rebuild)

import Foundation

/// Errors produced by the Markdown Pal engine.
public enum EngineError: Error, Equatable, Sendable {

    /// Failed to parse the document content.
    case parseError(String)

    /// Failed to read or write metadata.
    case metadataError(String)

    /// The requested section slug was not found.
    /// Includes available slugs for suggestion.
    case sectionNotFound(slug: String, available: [String])

    /// Optimistic concurrency conflict: the section was modified since
    /// the caller's version hash was obtained.
    /// Includes the current version hash and current content for recovery.
    case versionConflict(slug: String, expected: String, actual: String, currentContent: String)

    /// Bundle operation conflict.
    case bundleConflict(String)
}
