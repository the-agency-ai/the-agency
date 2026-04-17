// What Problem: The engine needs structured error types that callers can
// pattern-match on to provide useful error messages and appropriate exit codes.
//
// How & Why: Swift enum with associated values for rich error context.
// Each case maps to a specific failure mode from the A&D §3.3: parse errors,
// metadata errors, section not found (with available slugs for suggestions),
// version conflicts (with current content for recovery), comment lifecycle
// errors, file I/O errors, and unsupported format errors.
//
// Written: 2026-04-07 during mdpal-cli session (iteration 1.1 rebuild)
// Updated: 2026-04-07 — iteration 1.2: added comment, file, and format cases

import Foundation

/// Errors produced by the Markdown Pal engine.
public enum EngineError: Error, Equatable, Sendable {

    /// Failed to parse the document content.
    /// Optional line/column for parser errors that have positional info.
    case parseError(description: String, line: Int? = nil, column: Int? = nil)

    /// Metadata block is malformed (YAML parse failure or schema mismatch).
    case metadataError(String)

    /// The requested section slug was not found.
    /// Includes available slugs for suggestion.
    case sectionNotFound(slug: String, available: [String])

    /// Optimistic concurrency conflict: the section was modified since
    /// the caller's version hash was obtained.
    /// Includes the current version hash and current content for recovery.
    case versionConflict(slug: String, expected: String, actual: String, currentContent: String)

    /// No parser is registered for the given file extension.
    case unsupportedFormat(fileExtension: String)

    /// The document has no associated file path (called save() in library mode).
    case noFilePath

    /// Comment with the given id was not found.
    case commentNotFound(id: String)

    /// Attempted to resolve a comment that is already resolved.
    case commentAlreadyResolved(id: String)

    /// Attempted to clear a flag on a section that is not flagged.
    case sectionNotFlagged(slug: String)

    /// File I/O error (CLI mode only). The underlying error is preserved
    /// as a String description because Error is not Equatable.
    case fileError(path: String, description: String)

    /// Bundle path failed structural validation (e.g., missing `.mdpal`
    /// suffix, missing config file, target path already exists when creating).
    /// Distinct from `bundleConflict`, which signals runtime conflicts
    /// (concurrent writers, revision collisions).
    case invalidBundlePath(path: String, reason: String)

    /// Bundle operation conflict — concurrent write detected, revision
    /// already exists, or other runtime contention. Distinct from
    /// `invalidBundlePath`, which signals static structural problems.
    case bundleConflict(String)

    /// Optimistic-concurrency rejection at the bundle level: a write was
    /// attempted with a `--base-revision` that no longer matches the
    /// bundle's current latest. Carries both ids so callers can re-fetch
    /// and merge. Distinct from the generic `bundleConflict(String)` so
    /// the wire envelope's `details` block carries structured fields.
    case bundleBaseConflict(expected: String, actual: String)
}
