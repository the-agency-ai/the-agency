// What Problem: PresentationCoordinator tracked presentation state and
// PresenterWindowView / AudienceFullScreenView knew how to draw it, but nothing
// ever created the windows. The old SwiftUI App scene supplied them via a
// WindowGroup; the Phase 5.1 rewrite to a manual NSApplication delegate dropped
// that, leaving the whole Phase 3 presentation subsystem unreachable — no Present
// command, no presenter window, three files referenced by nothing.
//
// How & Why: The missing AppKit half. Creates and tears down the two windows the
// coordinator's state implies: an audience window (full-screen, on the external
// display when there is one) and a presenter window with notes, next-slide
// preview and timer. Placement follows the contract's multi-display rule — with a
// second screen the audience goes there and the presenter stays on the built-in
// display; with one screen the audience takes it full-screen and the presenter
// window is not shown, matching the coordinator's single-display fallback.
//
// Window teardown is driven from stopPresentation() rather than from a window
// delegate, so Escape, the End button and the menu all converge on one path.
//
// Written: 2026-08-08 — restores Phase 3 presentation mode after the app-entry
// rewrite orphaned it.

import AppKit
import SwiftUI

/// Creates and tears down the audience and presenter windows for presentation mode.
@MainActor
public final class PresentationWindowManager: NSObject {

    private let controller: DeckController
    private var audienceWindow: NSWindow?
    private var presenterWindow: NSWindow?
    private var savedPresentationOptions: NSApplication.PresentationOptions?
    private var startObserver: NSObjectProtocol?

    public init(controller: DeckController) {
        self.controller = controller
        super.init()
        // Escape and the presenter's End button call stopPresentation() directly,
        // so teardown hangs off the coordinator rather than off stop() — every
        // route out of presentation mode closes the windows.
        controller.presentation.onPresentationEnded = { [weak self] in
            self?.closeWindows()
        }
        // This manager owns .startPresentation: it is the only object that can
        // honor the command completely (coordinator state *and* windows).
        startObserver = NotificationCenter.default.addObserver(
            forName: .startPresentation, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.start() }
        }
    }

    deinit {
        if let startObserver {
            NotificationCenter.default.removeObserver(startObserver)
        }
    }

    private var coordinator: PresentationCoordinator { controller.presentation }

    /// True when presentation windows are on screen.
    public var isShowingWindows: Bool { audienceWindow != nil }

    /// Enter presentation mode: start the coordinator and open the windows.
    public func start() {
        guard !isShowingWindows else { return }

        coordinator.startPresentation()

        let screens = NSScreen.screens
        let audienceScreen = screens.count > 1 ? screens[1] : screens.first
        openAudienceWindow(on: audienceScreen)

        // With a single display the audience view occupies it entirely; showing a
        // presenter window there would cover the slides. The coordinator's 's'
        // key toggles notes in that configuration instead.
        if screens.count > 1 {
            openPresenterWindow(on: screens[0])
        }
    }

    /// Leave presentation mode. Windows are closed by the coordinator's
    /// teardown callback, so this and Escape behave identically.
    public func stop() {
        coordinator.stopPresentation()
    }

    /// Tear down the presentation windows. Invoked via the coordinator so every
    /// exit route — Escape, End button, menu, presenter close box — lands here
    /// exactly once.
    private func closeWindows() {
        guard isShowingWindows else { return }

        // Clear delegates before closing so windowWillClose does not bounce back
        // into stopPresentation while we are already tearing down.
        audienceWindow?.delegate = nil
        presenterWindow?.delegate = nil

        audienceWindow?.close()
        audienceWindow = nil
        presenterWindow?.close()
        presenterWindow = nil

        if let saved = savedPresentationOptions {
            NSApplication.shared.presentationOptions = saved
            savedPresentationOptions = nil
        }

        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    /// Toggle presentation mode — what the Present menu item calls.
    public func toggle() {
        isShowingWindows ? stop() : start()
    }

    // MARK: - Window construction

    private func openAudienceWindow(on screen: NSScreen?) {
        let window = NSWindow(
            contentRect: screen?.frame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080),
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false,
            screen: screen
        )
        window.title = "mdslidepal \u{2014} Audience"
        window.contentView = NSHostingView(
            rootView: ThemedPresentationRoot {
                AudienceFullScreenView(coordinator: self.coordinator)
            }
            .environment(controller.deckState)
        )
        window.isReleasedWhenClosed = false
        window.backgroundColor = .black
        window.collectionBehavior = [.fullScreenPrimary, .canJoinAllSpaces]

        // A borderless window cannot enter a full-screen space — AppKit ignores
        // toggleFullScreen on a non-resizable, non-titled window — and a .normal
        // window does not cover the menu bar or Dock. Raising the level and
        // hiding both is what actually gives the audience an uninterrupted slide.
        window.level = .screenSaver
        savedPresentationOptions = NSApplication.shared.presentationOptions
        NSApplication.shared.presentationOptions = [.hideDock, .autoHideMenuBar]

        if let screen {
            window.setFrame(screen.frame, display: true)
        }
        window.makeKeyAndOrderFront(nil)

        audienceWindow = window
    }

    private func openPresenterWindow(on screen: NSScreen) {
        // Inset from the screen edges rather than filling it, so the speaker can
        // still reach the editor behind it.
        let frame = screen.visibleFrame.insetBy(dx: 40, dy: 40)
        let window = NSWindow(
            contentRect: frame,
            styleMask: [.titled, .closable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false,
            screen: screen
        )
        window.title = "mdslidepal \u{2014} Presenter"
        window.contentView = NSHostingView(
            rootView: ThemedPresentationRoot {
                PresenterWindowView(coordinator: self.coordinator)
            }
            .environment(controller.deckState)
        )
        window.isReleasedWhenClosed = false
        // Closing the presenter with its red button must end the presentation,
        // not strand the audience window with no way to stop it.
        window.delegate = self
        window.level = .screenSaver + 1
        window.setFrame(frame, display: true)
        window.makeKeyAndOrderFront(nil)

        presenterWindow = window
    }
}

// MARK: - Window delegate

extension PresentationWindowManager: NSWindowDelegate {
    public func windowWillClose(_ notification: Notification) {
        // Only reached when the user closes the presenter directly; closeWindows()
        // clears delegates before closing, so teardown does not re-enter here.
        coordinator.stopPresentation()
    }
}

// MARK: - Theme plumbing

/// Re-reads the deck's theme on every render.
///
/// `NSHostingView` builds its root view once, so passing `deckState.theme` in as
/// a value would freeze the palette at launch — a reload that changes the
/// front-matter `theme:` mid-presentation would not be picked up. Reading
/// DeckState from the environment here mirrors what DeckWindowView does in its
/// own body.
private struct ThemedPresentationRoot<Content: View>: View {
    @Environment(DeckState.self) private var deckState
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .environment(\.theme, deckState.theme)
    }
}
