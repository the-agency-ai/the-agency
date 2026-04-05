// What Problem: The app needs an in-memory model of the document that holds
// sections, comments, and flags together. This is the app's view of the
// document — not the engine's Document class. The app owns this model and
// updates it by calling CLI commands and parsing JSON responses.
//
// How & Why: Observable class for SwiftUI binding. Holds the section tree,
// comments, and flags. Methods correspond to CLI commands the app will invoke.
// Phase 1 uses mock data; Phase 2 swaps in real CLI calls via CLIService.
//
// Written: 2026-04-05 during mdpal-app Phase 1 scaffold

import Foundation
import SwiftUI

/// The app's in-memory representation of a Markdown document.
/// Observable for SwiftUI data flow.
@Observable
public final class DocumentModel {
    /// All sections in the document (flat list, ordered by document position).
    public var sections: [SectionInfo] = []

    /// The currently selected section's full content.
    public var selectedSection: Section?

    /// All comments in the document.
    public var comments: [Comment] = []

    /// All flags in the document.
    public var flags: [Flag] = []

    /// The raw Markdown content (from FileWrapper).
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

    // MARK: - Section Operations

    /// Load sections from the document content.
    /// Calls `mdpal sections` via the CLI service.
    public func loadSections() async {
        do {
            sections = try await cliService.listSections(content: rawContent)
            lastError = nil
        } catch {
            lastError = "Failed to load sections: \(error.localizedDescription)"
        }
    }

    /// Select and load a section's full content.
    /// Calls `mdpal read <slug>` via the CLI service.
    public func selectSection(slug: String) async {
        do {
            selectedSection = try await cliService.readSection(slug: slug, content: rawContent)
            lastError = nil
        } catch {
            lastError = "Failed to read section '\(slug)': \(error.localizedDescription)"
        }
    }

    /// Edit a section's content with optimistic concurrency.
    /// Calls `mdpal edit <slug> --version <hash>` via the CLI service.
    public func editSection(slug: String, newContent: String, versionHash: String) async throws {
        let updated = try await cliService.editSection(
            slug: slug, newContent: newContent,
            versionHash: versionHash, documentContent: rawContent
        )
        selectedSection = updated
        isDirty = true
        // Reload sections to reflect changes
        await loadSections()
    }

    // MARK: - Comment Operations

    /// Load all comments.
    /// Calls `mdpal comments` via the CLI service.
    public func loadComments() async {
        do {
            comments = try await cliService.listComments(content: rawContent)
            lastError = nil
        } catch {
            lastError = "Failed to load comments: \(error.localizedDescription)"
        }
    }

    /// Get comments for a specific section.
    public func comments(forSection slug: String) -> [Comment] {
        comments.filter { $0.sectionSlug == slug }
    }

    /// Get unresolved comments for a specific section.
    public func unresolvedComments(forSection slug: String) -> [Comment] {
        comments.filter { $0.sectionSlug == slug && !$0.isResolved }
    }

    // MARK: - Flag Operations

    /// Load all flags.
    /// Calls `mdpal flags` via the CLI service.
    public func loadFlags() async {
        do {
            flags = try await cliService.listFlags(content: rawContent)
            lastError = nil
        } catch {
            lastError = "Failed to load flags: \(error.localizedDescription)"
        }
    }

    /// Check if a section is flagged.
    public func isFlagged(slug: String) -> Bool {
        flags.contains { $0.sectionSlug == slug }
    }

    /// Get the flag for a section, if any.
    public func flag(forSection slug: String) -> Flag? {
        flags.first { $0.sectionSlug == slug }
    }

    // MARK: - Document Lifecycle

    /// Load a document from raw content (called when FileWrapper provides data).
    public func load(from content: String) async {
        rawContent = content
        isDirty = false
        await loadSections()
        await loadComments()
        await loadFlags()
    }
}
