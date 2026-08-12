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
// Updated: 2026-04-17 Phase 1C.3 — persistence surface: createRevision,
//          listHistory, showVersion, bumpVersion. Adds typed
//          .bundleConflict mapping for stale --base-revision writes.
// Updated: 2026-04-19 Phase 2.1/2.5 — CLIServiceError gains
//          payloadTooLarge(maxBytes:), fileTooLarge(path:, sizeBytes:,
//          limitBytes:) per dispatches #616 + #635, and cancelled for
//          Phase 2.5 task-cancellation → SIGTERM wiring.

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

    // MARK: - Persistence (Phase 1C)

    /// Create a new revision of the bundle from the given content, with
    /// optional optimistic-concurrency anchor. Maps to:
    /// `mdpal revision create <bundle> --stdin [--base-revision <versionId>]`.
    /// If `baseRevision` is stale, throws `.bundleConflict(...)`.
    func createRevision(bundle: BundlePath, content: String,
                        baseRevision: String?) async throws -> RevisionInfo

    /// List all revisions in the bundle, newest-first.
    /// Maps to: `mdpal history <bundle>`. Service unwraps `HistoryResponse`.
    func listHistory(bundle: BundlePath) async throws -> [RevisionInfo]

    /// Return current version info. Maps to: `mdpal version show <bundle>`.
    func showVersion(bundle: BundlePath) async throws -> VersionInfo

    /// Bump the bundle's major version. Maps to: `mdpal version bump <bundle>`.
    /// Returns the new version info (previous version included so the UI
    /// can surface "vN → vN+1" feedback).
    func bumpVersion(bundle: BundlePath) async throws -> VersionBumpResult
}

/// Errors from CLI operations.
///
/// Phase 2.1 (dispatches #616 + #635) adds `.payloadTooLarge` and
/// `.fileTooLarge` as typed cases with user-actionable UX. Other new
/// wire-format discriminators (from the canonical 18-case list) continue
/// to surface via `.executionFailed` — only the ones with genuinely
/// actionable user messages (size caps) get their own typed case.
/// `.cancelled` is added in prep for Phase 2.5 task-cancellation wiring.
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
    /// Phase 2.1 (dispatch #616): stdin content exceeds the engine's 16 MiB
    /// cap on comment/resolve/edit/revision-create. `maxBytes` is the
    /// engine-reported limit (nil means the envelope didn't carry details).
    /// Routed via exit code 5 (`sizeLimitExceeded`).
    case payloadTooLarge(maxBytes: Int?)
    /// Phase 2.1 (dispatch #635): on-disk file exceeds the engine's file
    /// size cap. Same exit code 5 as `.payloadTooLarge`, distinguished by
    /// discriminator.
    case fileTooLarge(path: String?, sizeBytes: Int?, limitBytes: Int?)
    /// Phase 2.1 prep (Phase 2.5 will wire): task cancellation propagated
    /// to child-process SIGTERM. Introduced here so the error taxonomy is
    /// complete before the runner-level changes land.
    case cancelled
    /// Phase 2.6: the document is in pancake mode (plain .md) but the
    /// user attempted an operation that requires a packaged bundle —
    /// add comment, flag section, create revision, etc. The associated
    /// `operation` string identifies what was attempted, so the alert
    /// can name it ("Adding a comment requires packaging…"). Routed via
    /// PancakeCLIService — never thrown by RealCLIService.
    case packageRequired(operation: String)

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
        case .payloadTooLarge(let maxBytes):
            if let maxBytes {
                let mib = Double(maxBytes) / (1024.0 * 1024.0)
                return String(format: "Your input is too large (max %.1f MiB). Try shortening or splitting into smaller edits.", mib)
            }
            return "Your input is too large. Try shortening or splitting into smaller edits."
        case .fileTooLarge(let path, let sizeBytes, let limitBytes):
            let pathStr = path.map { "'\($0)'" } ?? "A file"
            if let size = sizeBytes, let limit = limitBytes {
                let sizeMiB = Double(size) / (1024.0 * 1024.0)
                let limitMiB = Double(limit) / (1024.0 * 1024.0)
                return String(format: "%@ is too large (%.1f MiB; limit %.1f MiB).", pathStr, sizeMiB, limitMiB)
            }
            return "\(pathStr) is too large for the CLI to process."
        case .cancelled:
            return "Operation cancelled."
        case .packageRequired(let operation):
            return "'\(operation)' requires this file to be a .mdpal bundle. Convert it to a package and retry."
        }
    }
}
