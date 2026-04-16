// What Problem: The main app window needs a split-view layout with a section
// sidebar on the left and a content reader/editor on the right. This is the
// standard macOS document app pattern — NavigationSplitView with list + detail.
//
// How & Why: NavigationSplitView is the macOS-native split view. The sidebar
// shows sections (SectionListView), the detail shows the selected section's
// content (SectionReaderView). Selection state drives navigation. Comments
// and flags are displayed inline in the reader pane.
//
// Phase 1A alignment: comment.slug (was comment.sectionSlug).
//
// Written: 2026-04-05 during mdpal-app Phase 1 scaffold
// Updated: 2026-04-06 Phase 1A model alignment (CLI JSON spec dispatch #23)
// Updated: 2026-04-15 Phase 1A.3 — surface document.lastError via alert

import SwiftUI

/// The main content view — split between section list and section reader.
public struct ContentView: View {
    @Bindable var document: DocumentModel
    @State private var selectedSlug: String?

    public init(document: DocumentModel) {
        self.document = document
    }

    public var body: some View {
        NavigationSplitView {
            SectionListView(
                sections: document.sections,
                flags: document.flags,
                commentCounts: commentCountsBySection,
                selectedSlug: $selectedSlug
            )
            .navigationSplitViewColumnWidth(min: 200, ideal: 250, max: 350)
        } detail: {
            if let section = document.selectedSection {
                SectionReaderView(
                    section: section,
                    comments: document.comments(forSection: section.slug),
                    flag: document.flag(forSection: section.slug),
                    document: document,
                    currentAuthor: "jordan"
                )
            } else {
                ContentUnavailableView(
                    "No Section Selected",
                    systemImage: "doc.text",
                    description: Text("Select a section from the sidebar to view its content.")
                )
            }
        }
        .onChange(of: selectedSlug) { _, newSlug in
            if let slug = newSlug {
                Task {
                    await document.selectSection(slug: slug)
                }
            } else {
                document.selectedSection = nil
            }
        }
        .task {
            await document.loadSections()
            await document.loadComments()
            await document.loadFlags()
        }
        .alert(
            "Something went wrong",
            isPresented: Binding(
                get: { document.lastError != nil },
                set: { shown in if !shown { document.lastError = nil } }
            ),
            presenting: document.lastError
        ) { _ in
            Button("Dismiss", role: .cancel) { document.lastError = nil }
        } message: { message in
            Text(message)
        }
    }

    /// Compute unresolved comment counts per section for badge display.
    private var commentCountsBySection: [String: Int] {
        var counts: [String: Int] = [:]
        for comment in document.comments where !comment.isResolved {
            counts[comment.slug, default: 0] += 1
        }
        return counts
    }
}
