// What Problem: The app needs an in-memory model of the document that holds
// sections, comments, and flags together. This is the app's view of the
// document — not the engine's Document class. The app owns this model and
// updates it by calling CLI commands and parsing JSON responses.
//
// How & Why: Observable class for SwiftUI binding. Holds the section list
// (flattened from tree by service), comments, and flags. Methods correspond
// to CLI commands the app will invoke. Phase 1A alignment: sections are
// [SectionTreeNode] (flat, from service). BundlePath used for CLI calls.
// editSection calls readSection after edit (MAR finding: EditResult has no
// content). New methods: addComment, resolveComment, flagSection, clearFlag.
// Filter helpers use .slug (not .sectionSlug).
//
// Written: 2026-04-05 during mdpal-app Phase 1 scaffold
// Updated: 2026-04-06 Phase 1A model alignment (CLI JSON spec dispatch #23)
// Updated: 2026-04-17 Phase 1C.4 — persistence surface: latestRevision
//          state + createRevision()/loadHistory()/loadCurrentVersion()/
//          bumpVersion(). bundleConflict is re-thrown for the UI to
//          handle; other failures populate lastError like the rest of
//          the load/mutation methods.

import Foundation
import SwiftUI

/// The app's in-memory representation of a Markdown document.
/// Observable for SwiftUI data flow.
@Observable
public final class DocumentModel {
    /// All sections in the document (flat list from service, ordered by document position).
    public var sections: [SectionTreeNode] = []

    /// The currently selected section's full content.
    public var selectedSection: Section?

    /// All comments in the document.
    public var comments: [Comment] = []

    /// All flags in the document.
    public var flags: [Flag] = []

    /// The bundle path for CLI operations.
    public var bundlePath: BundlePath?

    /// The current version ID from the sections response.
    public var currentVersionId: String?

    /// The raw Markdown content (from FileWrapper).
    /// Used by MarkdownDocument for serialization. Phase 2 replaces with bundle path.
    public var rawContent: String = ""

    /// Whether the document has unsaved changes.
    public var isDirty: Bool = false

    /// Error state for display.
    public var lastError: String?

    /// Latest revision created or observed for this bundle. Used as the
    /// optimistic-concurrency anchor when createRevision is called —
    /// changes landed by another client between our load and our save
    /// will surface as `.bundleConflict`.
    public var latestRevision: RevisionInfo?

    /// Revision history for this bundle. Populated by loadHistory();
    /// newest-first. Drives the history drawer (1C.5).
    public var history: [RevisionInfo] = []

    /// Current version info (bundle-level). Populated by loadCurrentVersion().
    public var currentVersion: VersionInfo?

    /// The CLI service used for operations.
    private let cliService: CLIServiceProtocol

    public init(cliService: CLIServiceProtocol = MockCLIService()) {
        self.cliService = cliService
    }

    // MARK: - Effective Bundle Path

    /// The bundle path to use for CLI calls.
    /// Falls back to empty path for Phase 1 mock usage.
    private var effectiveBundle: BundlePath {
        bundlePath ?? BundlePath("")
    }

    // MARK: - Section Operations

    /// Load sections from the document content.
    /// Calls `mdpal sections` via the CLI service.
    public func loadSections() async {
        do {
            sections = try await cliService.listSections(bundle: effectiveBundle)
            lastError = nil
        } catch {
            lastError = "Failed to load sections: \(error.localizedDescription)"
        }
    }

    /// Select and load a section's full content.
    /// Calls `mdpal read <slug>` via the CLI service.
    public func selectSection(slug: String) async {
        do {
            selectedSection = try await cliService.readSection(slug: slug, bundle: effectiveBundle)
            lastError = nil
        } catch {
            lastError = "Failed to read section '\(slug)': \(error.localizedDescription)"
        }
    }

    /// Edit a section's content with optimistic concurrency.
    /// Calls `mdpal edit`, then re-reads the section to refresh content
    /// (MAR finding: EditResult has no content field).
    public func editSection(slug: String, newContent: String, versionHash: String) async throws {
        _ = try await cliService.editSection(
            slug: slug, content: newContent,
            versionHash: versionHash, bundle: effectiveBundle
        )
        // Re-read to get updated content (EditResult has no content)
        selectedSection = try await cliService.readSection(slug: slug, bundle: effectiveBundle)
        isDirty = true
        await loadSections()
        // Clear any prior error now that the mutation succeeded — prevents a
        // stale alert from showing after the user retries successfully.
        lastError = nil
    }

    // MARK: - Comment Operations

    /// Load all comments.
    /// Calls `mdpal comments` via the CLI service.
    public func loadComments() async {
        do {
            comments = try await cliService.listComments(bundle: effectiveBundle)
            lastError = nil
        } catch {
            lastError = "Failed to load comments: \(error.localizedDescription)"
        }
    }

    /// Get comments for a specific section.
    public func comments(forSection slug: String) -> [Comment] {
        comments.filter { $0.slug == slug }
    }

    /// Get unresolved comments for a specific section.
    public func unresolvedComments(forSection slug: String) -> [Comment] {
        comments.filter { $0.slug == slug && !$0.isResolved }
    }

    /// Add a comment to a section.
    public func addComment(slug: String, type: CommentType, author: String,
                           text: String, context: String? = nil,
                           priority: Priority = .normal, tags: [String] = []) async throws {
        let comment = try await cliService.addComment(
            slug: slug, bundle: effectiveBundle, type: type,
            author: author, text: text, context: context,
            priority: priority, tags: tags
        )
        comments.append(comment)
        // Clear any prior error now that the mutation succeeded.
        lastError = nil
    }

    /// Resolve a comment.
    public func resolveComment(commentId: String, response: String, by: String) async throws {
        _ = try await cliService.resolveComment(
            commentId: commentId, bundle: effectiveBundle,
            response: response, by: by
        )
        await loadComments()
        // Clear any prior error now that the mutation succeeded.
        lastError = nil
    }

    // MARK: - Flag Operations

    /// Load all flags.
    /// Calls `mdpal flags` via the CLI service.
    public func loadFlags() async {
        do {
            flags = try await cliService.listFlags(bundle: effectiveBundle)
            lastError = nil
        } catch {
            lastError = "Failed to load flags: \(error.localizedDescription)"
        }
    }

    /// Check if a section is flagged.
    public func isFlagged(slug: String) -> Bool {
        flags.contains { $0.slug == slug }
    }

    /// Get the flag for a section, if any.
    public func flag(forSection slug: String) -> Flag? {
        flags.first { $0.slug == slug }
    }

    /// Flag a section for discussion.
    public func flagSection(slug: String, author: String, note: String? = nil) async throws {
        let result = try await cliService.flagSection(
            slug: slug, bundle: effectiveBundle,
            author: author, note: note
        )
        if result.flagged {
            await loadFlags()
        }
        // Clear any prior error now that the mutation succeeded — covers the
        // result.flagged == false branch where loadFlags isn't called.
        lastError = nil
    }

    /// Clear a flag from a section.
    public func clearFlag(slug: String) async throws {
        _ = try await cliService.clearFlag(slug: slug, bundle: effectiveBundle)
        await loadFlags()
        // Clear any prior error now that the mutation succeeded.
        lastError = nil
    }

    /// Toggle the flag on a section — clears it if flagged, sets it if not.
    /// The view surfaces a single toggle control backed by this method.
    public func toggleFlag(slug: String, author: String, note: String? = nil) async throws {
        if isFlagged(slug: slug) {
            try await clearFlag(slug: slug)
        } else {
            try await flagSection(slug: slug, author: author, note: note)
        }
    }

    // MARK: - Persistence (Phase 1C.4)

    /// Create a new revision of the bundle from the given content.
    /// Uses `latestRevision?.versionId` as the optimistic-concurrency
    /// anchor when present — the service throws `.bundleConflict` if the
    /// bundle drifted past that anchor. Callers catch bundleConflict
    /// distinctly (typically to show a reload-or-overwrite prompt); other
    /// failures populate `lastError`.
    ///
    /// On success: isDirty cleared, `latestRevision` updated, nothing else
    /// reloaded (the UI calls `loadHistory()` explicitly when it needs
    /// the refreshed list).
    public func createRevision(content: String) async throws {
        do {
            let rev = try await cliService.createRevision(
                bundle: effectiveBundle,
                content: content,
                baseRevision: latestRevision?.versionId
            )
            latestRevision = rev
            isDirty = false
            lastError = nil
        } catch let conflict as CLIServiceError where isBundleConflict(conflict) {
            // Rethrow so the view layer can present a reload/overwrite
            // dialog. Don't pave the error into lastError — this is a
            // distinct workflow, not an "unexpected failure" toast.
            throw conflict
        } catch {
            lastError = "Failed to save revision: \(error.localizedDescription)"
            throw error
        }
    }

    /// Load the bundle's revision history (newest-first).
    public func loadHistory() async {
        do {
            history = try await cliService.listHistory(bundle: effectiveBundle)
            // Keep latestRevision in sync with what the history says is latest.
            // Fallback: first entry (history is newest-first).
            latestRevision = history.first { $0.latest == true } ?? history.first
            lastError = nil
        } catch {
            lastError = "Failed to load history: \(error.localizedDescription)"
        }
    }

    /// Load the current bundle-level version info.
    public func loadCurrentVersion() async {
        do {
            currentVersion = try await cliService.showVersion(bundle: effectiveBundle)
            lastError = nil
        } catch {
            lastError = "Failed to load version info: \(error.localizedDescription)"
        }
    }

    /// Predicate for the conflict-rethrow catch arm above. Pulling it
    /// out keeps the `where` clause readable.
    private func isBundleConflict(_ error: CLIServiceError) -> Bool {
        if case .bundleConflict = error { return true }
        return false
    }

    /// Bump the bundle's major version. On success updates
    /// `currentVersion` via the returned VersionBumpResult.
    public func bumpVersion() async throws -> VersionBumpResult {
        let result = try await cliService.bumpVersion(bundle: effectiveBundle)
        currentVersion = VersionInfo(
            version: result.version,
            versionId: result.versionId,
            revision: result.revision,
            timestamp: result.timestamp
        )
        lastError = nil
        return result
    }

    // MARK: - Document Lifecycle

    /// Load a document from a bundle path.
    public func load(from bundle: BundlePath) async {
        bundlePath = bundle
        isDirty = false
        await loadSections()
        await loadComments()
        await loadFlags()
    }

    /// Load a document from raw content (Phase 1 — FileWrapper provides data).
    /// Phase 2 replaces this with bundle-based loading.
    public func load(from content: String) async {
        rawContent = content
        isDirty = false
        await loadSections()
        await loadComments()
        await loadFlags()
    }
}
