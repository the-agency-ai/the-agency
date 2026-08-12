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
// window is not shown, because a presenter window there would cover the slides.
// There is no notes toggle in that configuration — speaker notes are visible
// only when a second display makes room for the presenter window.
//
// Window teardown is driven from stopPresentation() rather than from a window
// delegate, so Escape, the End button and the menu all converge on one path.
//
// Written: 2026-08-08 — restores Phase 3 presentation mode after the app-entry
// rewrite orphaned it.
// Updated: 2026-08-12 PR-prep QG wave 2 — windowWillClose no longer re-enters the
//   close cycle of the window it was told about, and the audience window is a
//   KeyablePresentationWindow so a borderless window can actually take the
//   keyboard rather than depending on the coordinator's event monitor.

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

    /// The command bus this manager listens on. Injectable for the same reason
    /// DeckController's is: `.default` is process-global, so two managers (or a
    /// manager and a test) posting `.startPresentation` on it drive each other.
    private let notificationCenter: NotificationCenter

    public init(controller: DeckController, notificationCenter: NotificationCenter = .default) {
        self.controller = controller
        self.notificationCenter = notificationCenter
        super.init()
        // Escape and the presenter's End button call stopPresentation() directly,
        // so teardown hangs off the coordinator rather than off stop() — every
        // route out of presentation mode closes the windows.
        controller.presentation.onPresentationEnded = { [weak self] in
            self?.closeWindows()
        }
        // This manager owns .startPresentation: it is the only object that can
        // honor the command completely (coordinator state *and* windows).
        startObserver = notificationCenter.addObserver(
            forName: .startPresentation, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.start() }
        }
    }

    deinit {
        if let startObserver {
            notificationCenter.removeObserver(startObserver)
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
        // presenter window there would cover the slides, so there is none.
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

    /// Allocate the audience window.
    ///
    /// `KeyablePresentationWindow`, not `NSWindow`: the style mask has no
    /// `.titled`, and a plain NSWindow without it refuses to become key, so
    /// `makeKeyAndOrderFront` would order the window front and leave the deck
    /// window behind it holding the keyboard.
    public static func makeAudienceWindow(
        contentRect: NSRect, screen: NSScreen?
    ) -> NSWindow {
        KeyablePresentationWindow(
            contentRect: contentRect,
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false,
            screen: screen
        )
    }

    private func openAudienceWindow(on screen: NSScreen?) {
        let window = Self.makeAudienceWindow(
            contentRect: screen?.frame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080),
            screen: screen
        )
        window.title = "mdslidepal \u{2014} Audience"
        // Hoist what the view needs into locals. Referencing `self.coordinator`
        // inside the @ViewBuilder closure captures the manager, closing the loop
        // manager -> window -> NSHostingView -> closure -> manager, and nothing
        // is ever deallocated.
        let coordinator = self.coordinator
        let deckState = controller.deckState
        window.contentView = NSHostingView(
            rootView: ThemedPresentationRoot {
                AudienceFullScreenView(coordinator: coordinator)
            }
            .environment(deckState)
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
        // Locals, not `self.…` — see openAudienceWindow for why.
        let coordinator = self.coordinator
        let deckState = controller.deckState
        window.contentView = NSHostingView(
            rootView: ThemedPresentationRoot {
                PresenterWindowView(coordinator: coordinator)
            }
            .environment(deckState)
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

    /// Drop the manager's reference to the window that is already inside its own
    /// close cycle, leaving the others untouched.
    ///
    /// `windowWillClose` arrives *during* `-[NSWindow close]`. Calling
    /// `stopPresentation()` from there fires `onPresentationEnded` →
    /// `closeWindows()` → `presenterWindow?.close()` on that same window,
    /// re-entering a close cycle AppKit has not finished. Clearing the reference
    /// first is preferred over deferring the whole teardown with
    /// `Task { @MainActor in … }`: the deferred version still tears down
    /// correctly but leaves the audience window on screen for a runloop turn
    /// after the presenter has gone, and it makes the "every exit route
    /// converges on one teardown" invariant depend on scheduling. Nil-ing first
    /// keeps teardown synchronous and single-pass.
    public static func releasingClosingWindow(
        _ closing: NSWindow?, audience: NSWindow?, presenter: NSWindow?
    ) -> (audience: NSWindow?, presenter: NSWindow?) {
        guard let closing else { return (audience, presenter) }
        return (
            audience: closing === audience ? nil : audience,
            presenter: closing === presenter ? nil : presenter
        )
    }

    public func windowWillClose(_ notification: Notification) {
        // Only reached when the user closes the presenter directly; closeWindows()
        // clears delegates before closing, so teardown does not re-enter here.
        (audienceWindow, presenterWindow) = Self.releasingClosingWindow(
            notification.object as? NSWindow,
            audience: audienceWindow,
            presenter: presenterWindow
        )
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
