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
    @Published public var model: DocumentModel

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
    public required init(configuration: ReadConfiguration) throws {
        let (service, resolution) = CLIServiceFactory.make()
        let model = DocumentModel(cliService: service)

        guard let data = configuration.file.regularFileContents,
              let content = String(data: data, encoding: .utf8) else {
            throw CocoaError(.fileReadCorruptFile)
        }

        model.rawContent = content
        self.model = model
        self.cliResolution = resolution

        // Load sections/comments/flags asynchronously after init
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
    /// This handles auto-save (FileWrapper only, no revision).
    public func fileWrapper(snapshot: String, configuration: WriteConfiguration) throws -> FileWrapper {
        let data = snapshot.data(using: .utf8) ?? Data()
        return FileWrapper(regularFileWithContents: data)
    }
}
