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
    }

    /// Resolve a comment.
    public func resolveComment(commentId: String, response: String, by: String) async throws {
        _ = try await cliService.resolveComment(
            commentId: commentId, bundle: effectiveBundle,
            response: response, by: by
        )
        await loadComments()
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
    }

    /// Clear a flag from a section.
    public func clearFlag(slug: String) async throws {
        _ = try await cliService.clearFlag(slug: slug, bundle: effectiveBundle)
        await loadFlags()
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
