// What Problem: The app needs to call mdpal CLI commands and parse their
// JSON output. But in Phase 1 the CLI doesn't exist yet — mdpal-cli is
// building it in parallel. We need a protocol so we can swap between
// mock data (Phase 1) and real CLI calls (Phase 2) without changing views.
//
// How & Why: Protocol-based abstraction over CLI invocation. Each method
// maps to one CLI command. BundlePath newtype prevents String misuse.
// Phase 1A alignment: methods use BundlePath, return spec-aligned types.
// Service layer unwraps response wrappers and flattens trees — views get
// simple arrays. New methods for addComment, resolveComment, flagSection,
// clearFlag match CLI spec commands.
//
// Written: 2026-04-05 during mdpal-app Phase 1 scaffold
// Updated: 2026-04-06 Phase 1A model alignment (CLI JSON spec dispatch #23)

import Foundation

/// Protocol for interacting with the mdpal CLI.
/// Each method corresponds to a CLI command.
/// Service implementations unwrap response wrappers — callers get simple types.
public protocol CLIServiceProtocol: Sendable {
    /// List all sections in the document (flattened from tree).
    /// Maps to: `mdpal sections <bundle>`
    /// Service unwraps SectionsResponse and flattens the tree.
    func listSections(bundle: BundlePath) async throws -> [SectionTreeNode]

    /// Read a section's full content by slug.
    /// Maps to: `mdpal read <slug> <bundle>`
    func readSection(slug: String, bundle: BundlePath) async throws -> Section

    /// Edit a section's content with optimistic concurrency.
    /// Maps to: `mdpal edit <slug> --version <hash> <bundle> --stdin`
    func editSection(slug: String, content: String,
                     versionHash: String, bundle: BundlePath) async throws -> EditResult

    /// List all comments.
    /// Maps to: `mdpal comments <bundle>`
    /// Service unwraps CommentsResponse.
    func listComments(bundle: BundlePath) async throws -> [Comment]

    /// List all flags.
    /// Maps to: `mdpal flags <bundle>`
    /// Service unwraps FlagsResponse.
    func listFlags(bundle: BundlePath) async throws -> [Flag]

    /// Add a comment to a section.
    /// Maps to: `mdpal comment <slug> <bundle> --type <type> --author <author>`
    func addComment(slug: String, bundle: BundlePath, type: CommentType,
                    author: String, text: String, context: String?,
                    priority: Priority, tags: [String]) async throws -> Comment

    /// Resolve a comment.
    /// Maps to: `mdpal resolve <commentId> <bundle> --response <text> --by <author>`
    func resolveComment(commentId: String, bundle: BundlePath,
                        response: String, by: String) async throws -> ResolveResult

    /// Flag a section for discussion.
    /// Maps to: `mdpal flag <slug> <bundle> --author <author>`
    func flagSection(slug: String, bundle: BundlePath,
                     author: String, note: String?) async throws -> FlagResult

    /// Clear a flag from a section.
    /// Maps to: `mdpal clear-flag <slug> <bundle>`
    func clearFlag(slug: String, bundle: BundlePath) async throws -> ClearFlagResult
}

/// Errors from CLI operations.
public enum CLIServiceError: Error, LocalizedError {
    case sectionNotFound(slug: String, availableSlugs: [String])
    case commentNotFound(commentId: String)
    case versionConflict(slug: String, expectedHash: String, currentHash: String)
    case bundleConflict(baseRevision: String, currentRevision: String)
    case parseError(description: String)
    case cliNotFound
    case fileNotFound(path: String)
    case invalidArgument(description: String)
    case executionFailed(exitCode: Int, stderr: String)

    public var errorDescription: String? {
        switch self {
        case .sectionNotFound(let slug, let available):
            return "Section '\(slug)' not found. Available: \(available.joined(separator: ", "))"
        case .commentNotFound(let commentId):
            return "Comment '\(commentId)' not found — it may have been resolved or the bundle reloaded."
        case .versionConflict(let slug, _, let currentHash):
            return "Section '\(slug)' was modified (current hash: \(currentHash)). Reload and retry."
        case .bundleConflict(let base, let current):
            return "Bundle conflict: base revision \(base), current \(current). Reload and retry."
        case .parseError(let description):
            return "Failed to parse CLI output: \(description)"
        case .cliNotFound:
            return "mdpal CLI not found. Ensure it is installed and in PATH."
        case .fileNotFound(let path):
            return "File not found: \(path)"
        case .invalidArgument(let description):
            return "Invalid argument: \(description)"
        case .executionFailed(let exitCode, let stderr):
            return "CLI exited with code \(exitCode): \(stderr)"
        }
    }
}
