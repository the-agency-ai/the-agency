// What Problem: Phase 1 showed a single generic alert ("Something went wrong:
// \(message)") for every CLIServiceError. That was fine when the typed error
// surface was shallow (4 cases). Phase 2.1 grew the surface to 13 CLI cases
// (18 envelope discriminators, 13 service-level CLIServiceError cases). Users
// deserve per-error UX: "Section was modified" for versionConflict suggests
// Reload; "mdpal CLI not found" for cliNotFound suggests Install; "Your input
// is too large" for payloadTooLarge suggests splitting. The 2.2 deliverable
// is a pure mapping function from CLIServiceError to a structured
// AlertContent + AlertAction so the UI can render right title, body, and
// primary-button text for every kind.
//
// How & Why:
// - AlertContent is a flat struct (title / body / primary action + optional
//   secondary action). No presentation concerns leak in — the View decides
//   sheet vs. alert vs. inline.
// - AlertAction is an enum the View maps to button labels + closures. Keeps
//   the mapping function pure (no closures captured).
// - `CLIServiceError.alertContent` is an exhaustive switch. Adding a new
//   CLIServiceError case fails the build until a matching AlertContent is
//   authored — forces alert-UX to stay in sync with the error surface.
// - Tests exhaust every case (one per CLIServiceError case) so drift is
//   caught immediately.
//
// Written: 2026-04-19 during mdpal-app Phase 2.2

import Foundation

/// Structured alert content derived from a `CLIServiceError` or other
/// failure. Flat by design — no SwiftUI types, no closures. The View
/// layer renders this into an alert/sheet/banner as appropriate.
public struct AlertContent: Equatable, Hashable, Sendable {
    /// Short title for the alert. Single line. Sentence case.
    public let title: String

    /// Body text for the alert. Explain what happened and what the user
    /// can do. Multiple sentences OK.
    public let body: String

    /// The action the primary button should trigger.
    public let primaryAction: AlertAction

    /// Optional secondary action (e.g., "Cancel" or "Details..."). Nil
    /// when a single Dismiss button suffices.
    public let secondaryAction: AlertAction?

    public init(
        title: String,
        body: String,
        primaryAction: AlertAction = .dismiss,
        secondaryAction: AlertAction? = nil
    ) {
        self.title = title
        self.body = body
        self.primaryAction = primaryAction
        self.secondaryAction = secondaryAction
    }
}

/// Actions an alert's button can trigger. The View maps each case to a
/// button label + handler. Adding a new case forces the View-side switch
/// to update.
public enum AlertAction: Equatable, Hashable, Sendable {
    /// Close the alert without further action. Default.
    case dismiss
    /// Suggests the user should reload the bundle from disk (usually
    /// after a version/bundle conflict).
    case reload
    /// Retry the same operation.
    case retry
    /// Overwrite past a conflict — force-push. Rare in V1; reserved for
    /// future bundle-conflict UX that offers it explicitly.
    case overwrite
    /// Refresh the current view's state (comment list, flag list, section
    /// list) after stale data was detected.
    case refresh
    /// Walk the user to installing or configuring the mdpal CLI.
    case installCLI
    /// Open a details view with the full error payload (for parse errors
    /// or executionFailed where stderr is useful).
    case showDetails
    /// Promote the current pancake (.md) document to a packaged (.mdpal)
    /// bundle. Triggered when the user attempts an operation that requires
    /// package-level metadata (comments, flags, revisions). Phase 2.6.
    case convertToPackage

    /// User-facing button label. View can override for non-English locales.
    public var label: String {
        switch self {
        case .dismiss:          return "Dismiss"
        case .reload:           return "Reload"
        case .retry:            return "Retry"
        case .overwrite:        return "Overwrite"
        case .refresh:          return "Refresh"
        case .installCLI:       return "Install CLI"
        case .showDetails:      return "Show Details"
        case .convertToPackage: return "Convert to Package…"
        }
    }
}

extension CLIServiceError {
    /// Structured alert content for this error. Exhaustive — every
    /// `CLIServiceError` case yields a purpose-built alert. Pure; no
    /// side effects; no closures; tested one-case-per-test in
    /// ModelTests's Phase 2.2 section.
    public var alertContent: AlertContent {
        switch self {
        case .sectionNotFound(let slug, let available):
            let suggestions = available.isEmpty
                ? "No sections are available."
                : "Available: \(available.prefix(5).joined(separator: ", "))\(available.count > 5 ? "..." : "")."
            return AlertContent(
                title: "Section not found",
                body: "The section '\(slug)' doesn't exist. \(suggestions) Try refreshing the section list.",
                primaryAction: .refresh)

        case .commentNotFound(let commentId):
            return AlertContent(
                title: "Comment not found",
                body: "Comment '\(commentId)' doesn't exist — it may have been resolved or the bundle reloaded. Refresh to see current comments.",
                primaryAction: .refresh)

        case .versionConflict(let slug, _, let currentHash):
            return AlertContent(
                title: "Section was modified",
                body: "Section '\(slug)' was changed by another writer (current hash: \(currentHash)). Reload to see the latest content, then retry your edit.",
                primaryAction: .reload)

        case .bundleConflict(let base, let current):
            return AlertContent(
                title: "Bundle changed on disk",
                body: "Another writer advanced the bundle from revision \(base) to \(current). Reload to continue.",
                primaryAction: .reload)

        case .parseError(let description):
            return AlertContent(
                title: "Couldn't parse response",
                body: "The mdpal CLI returned output the app couldn't understand. Details: \(description)",
                primaryAction: .showDetails)

        case .cliNotFound:
            return AlertContent(
                title: "mdpal CLI not found",
                body: "The mdpal command-line tool isn't installed or isn't in your PATH. Install it, or configure a custom path in app settings.",
                primaryAction: .installCLI)

        case .fileNotFound(let path):
            return AlertContent(
                title: "File not found",
                body: "The file at '\(path)' doesn't exist or isn't readable. Check the path and try again.",
                primaryAction: .dismiss)

        case .invalidArgument(let description):
            return AlertContent(
                title: "Invalid argument",
                body: "The CLI rejected the request as malformed: \(description). This is likely an app bug — please report it.",
                primaryAction: .showDetails)

        case .executionFailed(let exitCode, let stderr):
            // Shown verbatim when no more specific typed error is available.
            // Exit-code + truncated stderr. Show-details for the full message.
            let preview = stderr.count > 200
                ? String(stderr.prefix(200)) + "..."
                : stderr
            return AlertContent(
                title: "Something went wrong",
                body: "The mdpal CLI exited with code \(exitCode). \(preview.isEmpty ? "" : "Output: \(preview)")",
                primaryAction: .showDetails)

        case .payloadTooLarge(let maxBytes):
            let limitText: String
            if let maxBytes {
                let mib = Double(maxBytes) / (1024.0 * 1024.0)
                limitText = String(format: "maximum is %.1f MiB", mib)
            } else {
                limitText = "the CLI reported a size limit"
            }
            return AlertContent(
                title: "Your change is too large",
                body: "The content you're trying to save exceeds what the CLI accepts in one operation (\(limitText)). Try splitting into smaller edits or comments.",
                primaryAction: .dismiss)

        case .fileTooLarge(let path, let sizeBytes, let limitBytes):
            let pathStr = path.map { "'\($0)'" } ?? "A file in the bundle"
            let sizeText: String
            if let s = sizeBytes, let l = limitBytes {
                let sMiB = Double(s) / (1024.0 * 1024.0)
                let lMiB = Double(l) / (1024.0 * 1024.0)
                sizeText = String(format: " (%.1f MiB; limit %.1f MiB)", sMiB, lMiB)
            } else {
                sizeText = ""
            }
            return AlertContent(
                title: "File is too large",
                body: "\(pathStr) is larger than the CLI can process\(sizeText). Consider pruning revisions or splitting the document.",
                primaryAction: .dismiss)

        case .cancelled:
            return AlertContent(
                title: "Operation cancelled",
                body: "The operation was cancelled before it completed. No changes were saved.",
                primaryAction: .dismiss)

        case .packageRequired(let operation):
            return AlertContent(
                title: "Convert to a .mdpal bundle?",
                body: "‘\(operation)’ stores data that a plain Markdown file can’t hold (comments, flags, revision history). Converting will create a sibling .mdpal bundle alongside this file. The original .md file stays in place as the latest revision inside the bundle.",
                primaryAction: .convertToPackage,
                secondaryAction: .dismiss)
        }
    }
}
