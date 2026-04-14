// What Problem: Entry point for the mdslidepal-mac app. Opens markdown files
// as slide decks in a native macOS window. Supports presentation mode with
// audience + presenter windows.
//
// How & Why: SwiftUI @main App with two WindowGroups: the main deck viewer
// and the presenter window. PresentationCoordinator manages the lifecycle.
// AppMenuCommands adds the menu bar.
//
// Written: 2026-04-12 during mdslidepal-mac Phase 1.1 scaffold
// Updated: 2026-04-12 Phase 3 — presenter window group, presentation coordinator

import SwiftUI
import MdSlidepalLib

@main
struct MdSlidepalApp: App {
    @State private var deckState = DeckState()
    @State private var presentationCoordinator = PresentationCoordinator()

    var body: some Scene {
        // Main deck window
        WindowGroup("mdslidepal") {
            DeckWindowView()
                .environment(deckState)
                .frame(minWidth: 800, minHeight: 500)
                .onReceive(NotificationCenter.default.publisher(for: .startPresentation)) { _ in
                    presentationCoordinator.deckState = deckState
                    presentationCoordinator.startPresentation()
                }
        }
        .commands {
            AppMenuCommands()
        }

        // Presenter window (opened during presentation mode)
        Window("Presenter", id: "presenter") {
            if presentationCoordinator.isPresenting {
                PresenterWindowView(coordinator: presentationCoordinator)
                    .environment(deckState)
                    .environment(\.theme, deckState.theme)
            }
        }

        // Full-screen audience window (opened during presentation mode)
        Window("Presentation", id: "audience") {
            if presentationCoordinator.isPresenting {
                AudienceFullScreenView(coordinator: presentationCoordinator)
                    .environment(deckState)
                    .environment(\.theme, deckState.theme)
            }
        }
    }
}
