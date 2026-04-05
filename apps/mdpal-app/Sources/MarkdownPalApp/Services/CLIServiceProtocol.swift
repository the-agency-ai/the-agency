// What Problem: The app needs to call mdpal CLI commands and parse their
// JSON output. But in Phase 1 the CLI doesn't exist yet — mdpal-cli is
// building it in parallel. We need a protocol so we can swap between
// mock data (Phase 1) and real CLI calls (Phase 2) without changing views.
//
// How & Why: Protocol-based abstraction over CLI invocation. Each method
// maps to one CLI command. The mock implementation returns canned data for
// development. The real implementation will shell out to `mdpal` via Process
// and parse JSON stdout. This is the app's side of the CLI + ISCP contract.
//
// Written: 2026-04-05 during mdpal-app Phase 1 scaffold

import Foundation

/// Protocol for interacting with the mdpal CLI.
/// Each method corresponds to a CLI command.
public protocol CLIServiceProtocol: Sendable {
    /// List all sections in the document.
    /// Maps to: `mdpal sections <bundle>`
    func listSections(content: String) async throws -> [SectionInfo]

    /// Read a section's full content by slug.
    /// Maps to: `mdpal read <slug> <bundle>`
    func readSection(slug: String, content: String) async throws -> Section

    /// Edit a section's content with optimistic concurrency.
    /// Maps to: `mdpal edit <slug> --version <hash> <bundle> --stdin`
    func editSection(slug: String, newContent: String,
                     versionHash: String, documentContent: String) async throws -> Section

    /// List all comments, optionally filtered.
    /// Maps to: `mdpal comments <bundle>`
    func listComments(content: String) async throws -> [Comment]

    /// List all flags.
    /// Maps to: `mdpal flags <bundle>`
    func listFlags(content: String) async throws -> [Flag]
}

/// Errors from CLI operations.
public enum CLIServiceError: Error, LocalizedError {
    case sectionNotFound(slug: String, availableSlugs: [String])
    case versionConflict(slug: String, expectedHash: String, currentHash: String)
    case parseError(description: String)
    case cliNotFound
    case executionFailed(exitCode: Int, stderr: String)

    public var errorDescription: String? {
        switch self {
        case .sectionNotFound(let slug, let available):
            return "Section '\(slug)' not found. Available: \(available.joined(separator: ", "))"
        case .versionConflict(let slug, _, let currentHash):
            return "Section '\(slug)' was modified (current hash: \(currentHash)). Reload and retry."
        case .parseError(let description):
            return "Failed to parse CLI output: \(description)"
        case .cliNotFound:
            return "mdpal CLI not found. Ensure it is installed and in PATH."
        case .executionFailed(let exitCode, let stderr):
            return "CLI exited with code \(exitCode): \(stderr)"
        }
    }
}
