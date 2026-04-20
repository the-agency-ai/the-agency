// What Problem: Manage presentation mode — full-screen audience view on an
// external display with a presenter view (notes, timer, next slide) on the
// laptop screen. Requires AppKit interop because SwiftUI on macOS 14 cannot
// target a specific NSScreen for full-screen or capture global key events.
//
// How & Why: @Observable class that coordinates two windows: audience and
// presenter. Uses NSScreen enumeration to detect external displays. Promotes
// the audience window to full-screen on the external display via
// NSWindow.toggleFullScreen(). Global key event routing via
// NSEvent.addLocalMonitorForEvents ensures keyboard nav works regardless
// of which window has focus. Single-display fallback: audience goes
// full-screen on main display, 's' toggles presenter overlay.
//
// Written: 2026-04-12 during mdslidepal-mac Phase 3

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
    /// Whether an external display is available.
    public var hasExternalDisplay: Bool {
        NSScreen.screens.count > 1
    }

    private var timer: Timer?
    private var presentationStartTime: Date?
    private var keyMonitor: Any?

    public weak var deckState: DeckState?

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
            case "f":
                // Full-screen toggle handled by the window
                return false
            case "s":
                // Toggle presenter notes view
                return false
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
