// What Problem: Phase 2 shipped real-CLI integration via RealCLIService
// against `.mdpal` bundles. But the app's DocumentGroup opens plain `.md`
// files, which the real CLI cannot read — it requires a bundle directory.
// Without a service that handles plain `.md`, the app silently fell back
// to MockCLIService and showed canned "Acme Project" fixture content
// regardless of which file the user opened. Reported by principal:
// "the document you display is a mock document, not the document I selected."
//
// How & Why: PancakeCLIService is a first-class CLIServiceProtocol
// implementation for the *pancake* state of a document — plain .md, no
// metadata, no revision history. It parses the document's own raw content
// to derive sections + bodies, so the user sees their actual file. Mutation
// operations that require packaged metadata (addComment, resolveComment,
// flagSection, clearFlag, createRevision, listHistory, showVersion,
// bumpVersion) throw `CLIServiceError.packageRequired(operation:)` —
// the View layer catches this and prompts the user to promote the file to
// a .mdpal bundle. After promotion, the app swaps in RealCLIService and
// re-runs the originally-requested mutation against the new bundle.
//
// Naming: this is NOT a "mock." MockCLIService still exists for tests +
// previews + the canned-Acme demo path (set MDPAL_MOCK=1 to force it).
// PancakeCLIService is the real production behavior for plain Markdown
// files until the user opts into packaging.
//
// Vocabulary: pancake = plain .md (flat, no metadata). package = .mdpal
// bundle (with revisions, comments, flags). Source: PVR Rev 2 §3 +
// A&D Rev 2 §12 "Packaged/Pancake Boundary."
//
// Written: 2026-05-09 during Phase 2.6 hotfix (post-phase-complete)

import Foundation

/// CLI service for *pancake* documents — plain Markdown files without
/// .mdpal bundle metadata. Read operations parse the raw content;
/// mutation operations that require packaged metadata throw
/// `.packageRequired` so the View can prompt the user to promote.
public final class PancakeCLIService: CLIServiceProtocol, @unchecked Sendable {

    private let parsedLock = NSLock()
    private var parsedSections: [SectionTreeNode] = []
    private var parsedContent: [String: Section] = [:]

    /// Most-recent raw content pushed in via setDocumentContent. Used
    /// internally by listSections/readSection. Pancake state has no
    /// persisted versionId; we synthesize one from the content hash.
    private var contentHash: String = ""

    public init() {}

    /// Push the document's raw markdown content. Called by DocumentModel
    /// when the FileWrapper-backed document loads or saves. Subsequent
    /// listSections / readSection calls reflect the new content.
    public func setDocumentContent(_ content: String) {
        let (sections, contents) = MockCLIService.parseMarkdown(content)
        let hash = String(format: "%08x", abs(content.hashValue))
        parsedLock.lock()
        defer { parsedLock.unlock() }
        parsedSections = sections
        parsedContent = contents
        contentHash = hash
    }

    // MARK: - Reads (work in pancake mode)

    public func listSections(bundle: BundlePath) async throws -> [SectionTreeNode] {
        parsedLock.lock()
        let sections = parsedSections
        parsedLock.unlock()
        return sections
    }

    public func readSection(slug: String, bundle: BundlePath) async throws -> Section {
        parsedLock.lock()
        let contents = parsedContent
        let available = parsedSections.map(\.slug)
        parsedLock.unlock()
        guard let section = contents[slug] else {
            throw CLIServiceError.sectionNotFound(slug: slug, availableSlugs: available)
        }
        return section
    }

    /// Edit a section in pancake mode. Pancake supports in-place editing —
    /// the FileWrapper is what persists; CLI metadata isn't involved. We
    /// rebuild the document content with the new section body and return
    /// a synthetic EditResult. The caller (DocumentModel.editSection) then
    /// re-pushes the rebuilt content via setDocumentContent.
    ///
    /// Phase 2.6.1 ships this stubbed (passthrough that updates parsed state);
    /// in-place .md editing is a Phase 3 polish item — for now, pancake is
    /// effectively read-only at the section level. Edits land via direct
    /// rawContent mutation if any. Marked .packageRequired for explicitness.
    public func editSection(slug: String, content: String, versionHash: String, bundle: BundlePath) async throws -> EditResult {
        // Phase 2.6.1: pancake editing not yet wired to FileWrapper write-back.
        // Treat as package-required until 2.6.2 lands the in-place edit path.
        throw CLIServiceError.packageRequired(operation: "Edit section")
    }

    // MARK: - Reads that pancake can't satisfy (no metadata exists)

    public func listComments(bundle: BundlePath) async throws -> [Comment] {
        // Pancake has no comments. Empty list, not an error — the comment
        // panel just shows "No comments — convert to package to add some."
        return []
    }

    public func listFlags(bundle: BundlePath) async throws -> [Flag] {
        // Pancake has no flags. Empty list — same UX as no comments.
        return []
    }

    public func listHistory(bundle: BundlePath) async throws -> [RevisionInfo] {
        // Pancake has no revision history. Empty list. Asking the History
        // drawer to open is fine; it just shows empty.
        return []
    }

    public func showVersion(bundle: BundlePath) async throws -> VersionInfo {
        // Pancake has no version metadata. Synthesize a v0 / r0 / now.
        return VersionInfo(
            version: 0,
            versionId: "pancake-\(contentHash)",
            revision: 0,
            timestamp: Date()
        )
    }

    // MARK: - Mutations that REQUIRE packaging

    public func addComment(slug: String, bundle: BundlePath, type: CommentType,
                           author: String, text: String, context: String?,
                           priority: Priority, tags: [String]) async throws -> Comment {
        throw CLIServiceError.packageRequired(operation: "Add comment")
    }

    public func resolveComment(commentId: String, bundle: BundlePath,
                               response: String, by: String) async throws -> ResolveResult {
        throw CLIServiceError.packageRequired(operation: "Resolve comment")
    }

    public func flagSection(slug: String, bundle: BundlePath,
                            author: String, note: String?) async throws -> FlagResult {
        throw CLIServiceError.packageRequired(operation: "Flag section")
    }

    public func clearFlag(slug: String, bundle: BundlePath) async throws -> ClearFlagResult {
        throw CLIServiceError.packageRequired(operation: "Clear flag")
    }

    public func createRevision(bundle: BundlePath, content: String,
                               baseRevision: String?) async throws -> RevisionInfo {
        throw CLIServiceError.packageRequired(operation: "Create revision")
    }

    public func bumpVersion(bundle: BundlePath) async throws -> VersionBumpResult {
        throw CLIServiceError.packageRequired(operation: "Bump version")
    }
}
