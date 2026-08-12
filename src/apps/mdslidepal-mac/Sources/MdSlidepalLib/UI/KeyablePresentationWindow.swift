// What Problem: NSWindow's default `canBecomeKey` returns false for any window
// whose style mask lacks `.titled`. The audience window is `.borderless`, so
// `makeKeyAndOrderFront(nil)` ordered it front but left the previous window key —
// every keystroke kept going to the deck window behind it. Presentation-mode keys
// appeared to work only because PresentationCoordinator installs an application-
// wide local NSEvent monitor that sees events before they are dispatched to any
// window; remove or narrow that monitor and the audience window would be deaf.
//
// How & Why: The documented fix is a subclass overriding `canBecomeKey` and
// `canBecomeMain`. Both are needed: a window that is key but not main still loses
// main-window-scoped behaviour (menu item validation, `NSApp.mainWindow`).
//
// Written: 2026-08-12 during mdslidepal-mac PR-prep QG wave 2.

import AppKit

/// A borderless window that can still take keyboard focus.
public final class KeyablePresentationWindow: NSWindow {
    public override var canBecomeKey: Bool { true }
    public override var canBecomeMain: Bool { true }
}
