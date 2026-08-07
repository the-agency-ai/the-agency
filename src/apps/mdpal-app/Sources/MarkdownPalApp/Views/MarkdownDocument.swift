// What Problem: SwiftUI's DocumentGroup requires a ReferenceFileDocument
// to manage the document lifecycle (open, save, auto-save, undo). The app
// needs to bridge between FileWrapper (SwiftUI's file representation) and
// our DocumentModel (the app's in-memory representation).
//
// How & Why: ReferenceFileDocument (not FileDocument) because we need
// reference semantics — the document model is shared across views and
// mutated in place. The document reads .md files via FileWrapper, hands
// the raw string to DocumentModel for parsing via CLI, and writes back
// on save. Phase 1 works with plain .md files; bundles (.mdpal) come
// in Phase 2.
//
// Per A&D decision: explicit save (Cmd+S) creates a bundle revision via
// `mdpal revision create --stdin`. Auto-save is FileWrapper only — no
// revision, no CLI call. The distinction is handled here.
//
// Service selection (1B.6): MarkdownDocument uses CLIServiceFactory.make()
// to resolve Real vs Mock at init time. MDPAL_MOCK=1 forces Mock for
// previews/tests; cliNotFound falls back to Mock so the app is usable
// on machines without an mdpal binary installed.
//
// Written: 2026-04-05 during mdpal-app Phase 1 scaffold
// Updated: 2026-04-17 Phase 1B.6 — CLIServiceFactory-driven service selection

import SwiftUI
import UniformTypeIdentifiers

/// The UTType for plain Markdown files.
/// Phase 2 adds .mdpal bundle type.
extension UTType {
    static let markdownText = UTType(
        importedAs: "net.daringfireball.markdown",
        conformingTo: .plainText
    )
}

/// SwiftUI ReferenceFileDocument for Markdown files.
public final class MarkdownDocument: ReferenceFileDocument {

    /// The app's document model (observable, drives the UI).
    ///
    /// `DocumentModel` is `@Observable` (Swift Observation framework);
    /// `MarkdownDocument` is not `ObservableObject`, so `@Published` would
    /// be inert here. Plain stored property is sufficient — SwiftUI views
    /// that depend on model state observe through the `@Observable` model
    /// itself via `@Bindable`.
    public var model: DocumentModel

    /// Snapshot type for serialization.
    public typealias Snapshot = String

    /// Supported content types.
    public static var readableContentTypes: [UTType] {
        [.markdownText, .plainText]
    }

    public static var writableContentTypes: [UTType] {
        [.markdownText, .plainText]
    }

    // MARK: - Initialization

    /// Resolution of the current CLI service — surfaced so the UI can
    /// show a banner indicating mock vs real mode when it matters.
    public let cliResolution: CLIServiceFactory.Resolution

    /// Create a new empty document.
    public init() {
        let (service, resolution) = CLIServiceFactory.make()
        self.model = DocumentModel(cliService: service)
        self.cliResolution = resolution
    }

    /// Read a document from a FileWrapper.
    ///
    /// Phase 2.6 (architectural): the real `mdpal` CLI operates on
    /// `.mdpal` bundle directories — it cannot read plain `.md` files.
    /// DocumentGroup-opened files are always plain Markdown, so we route
    /// them to `PancakeCLIService` — a first-class read service that
    /// derives sections + bodies from the file's own headings. Mutation
    /// operations that require packaged metadata (Add Comment, Flag,
    /// Create Revision, etc.) throw `CLIServiceError.packageRequired`,
    /// which DocumentModel surfaces as a "Convert to .mdpal bundle?"
    /// alert. After conversion (Phase 2.6.2), the service swaps to Real
    /// and the originally-requested op runs against the bundle.
    ///
    /// Pre-2.6, this code asked the factory to pick Real-or-Mock based on
    /// CLI availability, which produced two failure modes:
    ///   1. CLI not installed → MockCLIService with canned Acme fixture
    ///      (looked like the wrong file was shown).
    ///   2. CLI installed → Real CLI invoked with empty bundle path → CLI
    ///      rejected with `invalidBundlePath`, surfacing as an error alert.
    /// Both broke "open a .md, see your sections" — the basic promise.
    public required init(configuration: ReadConfiguration) throws {
        // Plain .md → PancakeCLIService. Reads are real (parsed from your
        // file's headings); mutations that need package metadata throw
        // .packageRequired so the View can offer to convert.
        let pancakeService = PancakeCLIService()
        let model = DocumentModel(cliService: pancakeService)

        guard let data = configuration.file.regularFileContents,
              let content = String(data: data, encoding: .utf8) else {
            throw CocoaError(.fileReadCorruptFile)
        }

        model.rawContent = content
        self.model = model
        self.cliResolution = .pancake

        // Load sections/comments/flags asynchronously after init.
        // load(from:) pushes content into the pancake service so the user
        // sees their actual file's sections, not a canned fixture.
        Task { @MainActor in
            await model.load(from: content)
        }
    }

    // MARK: - Serialization

    /// Create a snapshot of the current document state.
    public func snapshot(contentType: UTType) throws -> String {
        model.rawContent
    }

    /// Write a snapshot to a FileWrapper.
    ///
    /// This handles **auto-save** — FileWrapper only, no CLI call, no
    /// revision. Per A&D §6.7, the bundle's append-only revision model is
    /// preserved by NOT invoking the CLI from auto-save paths.
    ///
    /// **Explicit save** (⌘S, File → Create Revision) goes through
    /// `saveAsRevision()` instead, which shells out to `mdpal revision
    /// create` via `DocumentModel.createRevision`.
    public func fileWrapper(snapshot: String, configuration: WriteConfiguration) throws -> FileWrapper {
        let data = snapshot.data(using: .utf8) ?? Data()
        return FileWrapper(regularFileWithContents: data)
    }

    // MARK: - Explicit save (Phase 2.4)

    /// Save the current document as a new bundle revision via the CLI.
    ///
    /// Phase 2.4 wiring: triggered by the "Create Revision" File menu
    /// command (⌘S). Calls `DocumentModel.createRevision` which shells
    /// out to `mdpal revision create <bundle> --stdin [--base-revision]`.
    ///
    /// On `.bundleConflict`: the error is populated via
    /// `DocumentModel.recordError` → surfaces as the Phase-2.2 per-error
    /// alert (title "Bundle changed on disk", primary action Reload).
    /// The Reload button wires to `loadHistory() + loadSections()` so
    /// the user sees fresh state before retrying.
    ///
    /// On other failures: same alert pipeline — `recordError` populates
    /// `lastAlert` via the exhaustive mapping.
    ///
    /// On success: `isDirty` cleared; `latestRevision` advanced; caller
    /// can reload the history drawer to see the new entry immediately.
    ///
    /// Async; Task-cancellation-safe (Phase 2.5 will wire SIGTERM
    /// propagation through DefaultProcessRunner).
    @MainActor
    public func saveAsRevision() async {
        do {
            try await model.createRevision(content: model.rawContent)
            // DocumentModel.createRevision already clears errors on success
            // and advances latestRevision. The history drawer, if open,
            // can be refreshed by the caller via loadHistory().
        } catch let cliError as CLIServiceError {
            // All CLIServiceError paths (bundleConflict, parseError,
            // executionFailed, cliNotFound, payloadTooLarge, fileTooLarge,
            // cancelled, etc.) route through recordError so the Phase-2.2
            // per-error alert presents the right UX (Reload for conflict,
            // Install CLI for cliNotFound, etc.).
            model.recordError(cliError, prefix: "Failed to save revision")
        } catch {
            // Non-CLI error (e.g., URL-resolve failure before CLI was even
            // invoked). recordError wraps as generic AlertContent.
            model.recordError(error, prefix: "Failed to save revision")
        }
    }
}
