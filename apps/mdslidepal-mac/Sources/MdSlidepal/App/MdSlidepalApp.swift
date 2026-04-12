// What Problem: Entry point for the mdslidepal-mac app. Opens markdown files
// as slide decks in a native macOS window.
//
// How & Why: SwiftUI @main App with WindowGroup for the deck viewer. Uses
// MdSlidepalLib for all parsing and rendering logic. AppMenuCommands adds
// the menu bar. Phase 3 will add a second WindowGroup for presenter mode.
//
// Written: 2026-04-12 during mdslidepal-mac Phase 1.1 scaffold
// Updated: 2026-04-12 Phase 2 — added AppMenuCommands

import SwiftUI
import MdSlidepalLib

@main
struct MdSlidepalApp: App {
    @State private var deckState = DeckState()

    var body: some Scene {
        WindowGroup("mdslidepal") {
            DeckWindowView()
                .environment(deckState)
                .frame(minWidth: 800, minHeight: 500)
        }
        .commands {
            AppMenuCommands()
        }
    }
}
