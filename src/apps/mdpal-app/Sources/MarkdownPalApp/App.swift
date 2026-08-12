// What Problem: The app needs an entry point that sets up SwiftUI's
// DocumentGroup for opening and editing Markdown files.
//
// How & Why: @main App with DocumentGroup using MarkdownDocument
// (ReferenceFileDocument). DocumentGroup provides the standard macOS
// document lifecycle: open, save, recent documents, multiple windows.
// Each document window gets a ContentView with the document's model.
//
// Phase 2.4: `.commands` modifier adds a "Create Revision" File menu
// command (⌘⇧S) that calls `MarkdownDocument.saveAsRevision()` — this is
// the explicit-save path that goes through the CLI and creates a bundle
// revision. FileWrapper-based auto-save continues to fire independently
// through the SwiftUI lifecycle on ⌘S and does NOT create a revision.
//
// A&D §6.7 reference note: A&D specifies "explicit save (⌘S or File →
// Save) triggers DocumentModel.createRevision". Phase 2.4 uses ⌘⇧S to
// avoid colliding with DocumentGroup's reserved ⌘S (SwiftUI's auto-save
// gesture). Phase 3.1 browser-shell pivot drops DocumentGroup; at that
// point we can reclaim ⌘S and align with A&D. Tracked as a follow-up
// item for Phase 3.
//
// Written: 2026-04-05 during mdpal-app Phase 1 scaffold
// Updated: 2026-04-19 Phase 2.4 — Create Revision File menu command

import SwiftUI
import MarkdownPalAppLib

@main
struct MarkdownPalApp: App {
    @FocusedValue(\.currentMarkdownDocument) private var focusedDocument

    var body: some Scene {
        DocumentGroup(newDocument: { MarkdownDocument() }) { file in
            ContentView(
                document: file.document.model,
                cliResolution: file.document.cliResolution
            )
            .focusedSceneValue(\.currentMarkdownDocument, file.document)
        }
        .commands {
            // Phase 2.4: Add "Create Revision" command in the File menu.
            // ⌘S is already bound to Save (which goes through fileWrapper
            // snapshot → auto-save path; no CLI revision). ⌘⇧S creates
            // an explicit bundle revision via the CLI.
            CommandGroup(after: .saveItem) {
                Button("Create Revision") {
                    guard let doc = focusedDocument else { return }
                    // Task inherits main-actor context from the Button
                    // action; explicit @MainActor inside the closure would
                    // be redundant (saveAsRevision is already annotated).
                    Task { await doc.saveAsRevision() }
                }
                .keyboardShortcut("s", modifiers: [.command, .shift])
                .disabled(focusedDocument == nil)
            }
        }
    }
}

/// FocusedValue key that tracks the currently-focused MarkdownDocument
/// so the File menu command can reach into it.
///
/// Phase 3 pivot (per A&D §10.1.1) may replace this with a browser-shell
/// window state object. V1 uses FocusedValue to keep the DocumentGroup
/// model working.
private struct CurrentMarkdownDocumentKey: FocusedValueKey {
    typealias Value = MarkdownDocument
}

extension FocusedValues {
    fileprivate var currentMarkdownDocument: MarkdownDocument? {
        get { self[CurrentMarkdownDocumentKey.self] }
        set { self[CurrentMarkdownDocumentKey.self] = newValue }
    }
}
