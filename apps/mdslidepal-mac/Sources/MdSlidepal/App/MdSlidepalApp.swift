// What Problem: Entry point for the mdslidepal-mac app. Opens markdown files
// as slide decks in a native macOS window.
//
// How & Why: SwiftUI @main App with WindowGroup for the deck viewer. Phase 1
// opens a hardcoded fixture path for development; Phase 2 adds file-open UI.
// Uses MdSlidepalLib for all parsing and rendering logic.
//
// Written: 2026-04-12 during mdslidepal-mac Phase 1.1 scaffold

import SwiftUI
import MdSlidepalLib

@main
struct MdSlidepalApp: App {
    @State private var deckState = DeckState()

    var body: some Scene {
        WindowGroup("mdslidepal") {
            DeckWindowView()
                .environment(deckState)
        }
    }
}
