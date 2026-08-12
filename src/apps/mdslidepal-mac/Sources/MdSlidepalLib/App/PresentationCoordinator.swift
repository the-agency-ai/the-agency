// What Problem: Presentation mode needs state that outlives any one window —
// whether we are presenting, whether the screen is blacked out, whether help is
// up, and how long the talk has run — plus keyboard navigation that works no
// matter which of the presentation windows has focus. SwiftUI alone cannot
// capture keys outside the focused view, so AppKit interop is required.
//
// How & Why: An @Observable store of presentation state with two behaviors
// attached to it: a one-second elapsed-time timer, and a local NSEvent key
// monitor installed for the duration of the presentation that routes navigation
// and overlay keys into DeckState. Windows are deliberately *not* this type's
// concern — PresentationWindowManager owns their creation, screen placement and
// teardown, and hooks `onPresentationEnded` so that every exit route (Escape,
// the presenter's End button, the menu) converges on a single teardown.
//
// Written: 2026-04-12 during mdslidepal-mac Phase 3
// Updated: 2026-08-12 PR-prep QG — header corrected; it still described the
//   two-window coordination, NSScreen enumeration and toggleFullScreen work that
//   moved to PresentationWindowManager, and advertised an 's' presenter-overlay
//   toggle that does not exist. Unused `hasExternalDisplay` removed with it.

import SwiftUI
import AppKit
import Observation

/// Coordinates presentation mode — audience view + presenter view.
@MainActor
@Observable
public class PresentationCoordinator {
    /// Whether we're currently in presentation mode.
    public var isPresenting = false
    /// Whether the black screen is active.
    public var isBlackScreen = false
    /// Whether the help overlay is visible.
    public var showHelp = false
    /// Elapsed time since presentation started.
    public var elapsedTime: TimeInterval = 0

    private var timer: Timer?
    private var presentationStartTime: Date?
    private var keyMonitor: Any?

    public weak var deckState: DeckState?

    /// Invoked after presentation mode ends, however it ended — Escape, the
    /// presenter's End button, or the menu. PresentationWindowManager uses this
    /// to tear down its windows, so there is one teardown path rather than one
    /// per trigger.
    @ObservationIgnored
    public var onPresentationEnded: (() -> Void)?

    public init() {}

    // MARK: - Presentation Lifecycle

    /// Enter presentation mode.
    public func startPresentation() {
        guard !isPresenting else { return }
        isPresenting = true
        isBlackScreen = false
        showHelp = false
        presentationStartTime = Date()
        elapsedTime = 0

        // Start timer
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self, let start = self.presentationStartTime else { return }
                self.elapsedTime = Date().timeIntervalSince(start)
            }
        }

        // Install global key handler
        installKeyMonitor()
    }

    /// Exit presentation mode.
    public func stopPresentation() {
        guard isPresenting else { return }
        isPresenting = false
        isBlackScreen = false
        showHelp = false
        timer?.invalidate()
        timer = nil
        presentationStartTime = nil
        removeKeyMonitor()
        // The `guard isPresenting` above makes this safe to call from the
        // teardown handler itself — the second entry returns early.
        onPresentationEnded?()
    }

    /// Toggle black screen (b/. keys).
    public func toggleBlackScreen() {
        isBlackScreen.toggle()
    }

    /// Toggle help overlay (? key).
    public func toggleHelp() {
        showHelp.toggle()
    }

    // MARK: - Key Handling

    private func installKeyMonitor() {
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self, self.isPresenting else { return event }
            return self.handleKeyEvent(event) ? nil : event
        }
    }

    private func removeKeyMonitor() {
        if let monitor = keyMonitor {
            NSEvent.removeMonitor(monitor)
            keyMonitor = nil
        }
    }

    /// Handle a key event during presentation. Returns true if consumed.
    private func handleKeyEvent(_ event: NSEvent) -> Bool {
        guard let deckState = deckState else { return false }

        // Check for character keys
        if let chars = event.charactersIgnoringModifiers {
            switch chars {
            case " ", "n":
                deckState.nextSlide()
                return true
            case "p":
                deckState.previousSlide()
                return true
            case "b", ".":
                toggleBlackScreen()
                return true
            case "?":
                toggleHelp()
                return true
            default:
                break
            }
        }

        // Check for special keys
        switch event.keyCode {
        case 124: // Right arrow
            deckState.nextSlide()
            return true
        case 123: // Left arrow
            deckState.previousSlide()
            return true
        case 115: // Home
            deckState.firstSlide()
            return true
        case 119: // End
            deckState.lastSlide()
            return true
        case 53: // Escape
            stopPresentation()
            return true
        default:
            return false
        }
    }

    // MARK: - Timer Formatting

    /// Formatted elapsed time string (MM:SS or H:MM:SS).
    public var formattedElapsedTime: String {
        let totalSeconds = Int(elapsedTime)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
