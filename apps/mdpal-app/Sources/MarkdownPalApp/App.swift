// What Problem: The app needs an entry point that sets up SwiftUI's
// DocumentGroup for opening and editing Markdown files.
//
// How & Why: @main App with DocumentGroup using MarkdownDocument
// (ReferenceFileDocument). DocumentGroup provides the standard macOS
// document lifecycle: open, save, recent documents, multiple windows.
// Each document window gets a ContentView with the document's model.
//
// Written: 2026-04-05 during mdpal-app Phase 1 scaffold

import SwiftUI
import MarkdownPalAppLib

@main
struct MarkdownPalApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: { MarkdownDocument() }) { file in
            ContentView(document: file.document.model)
        }
    }
}
