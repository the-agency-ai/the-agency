// What Problem: The app delegate built the main window inline with
// `window.contentView = NSHostingView(rootView:)`. SwiftUI bridges a view's
// `.toolbar` content to the NSWindow toolbar only when the view is hosted by an
// NSHostingController installed as the window's `contentViewController` — an
// NSHostingView set as `contentView` has no window-level toolbar to bridge to.
// DeckWindowView's toolbar carries the Open button and the `N / M` slide
// counter, the app's only slide-position indicator, so both were invisible.
// The `.frame(minWidth:minHeight:)` on the SwiftUI view likewise constrains only
// the SwiftUI layout; nothing stopped the user dragging the window smaller.
//
// How & Why: Window construction moved out of the executable target and into the
// library so it can be asserted on by the test runner — the executable target is
// not importable from tests. The factory sets `contentViewController` and mirrors
// the SwiftUI minimum into `contentMinSize`, which is the AppKit-side constraint
// the resize handles actually honour.
//
// Written: 2026-08-12 during mdslidepal-mac PR-prep QG wave 2.

import AppKit
import SwiftUI

/// Builds the app's main deck window.
@MainActor
public enum DeckWindowFactory {

    /// Smallest usable deck window: sidebar plus a readable slide preview.
    /// Applied to both the SwiftUI frame and the window's `contentMinSize` so
    /// the two agree.
    public static let minContentSize = CGSize(width: 800, height: 500)

    /// Default window size on first launch.
    public static let defaultContentSize = CGSize(width: 1200, height: 800)

    /// The hosting controller for the deck window's SwiftUI content.
    ///
    /// Returned as `NSViewController` so callers cannot accidentally depend on
    /// the (unspellable) modified-view generic parameter.
    public static func makeContentViewController(
        controller: DeckController
    ) -> NSViewController {
        let contentView = DeckWindowView()
            .environment(controller)
            .environment(controller.deckState)
            .environment(\.theme, controller.deckState.theme)
            .frame(minWidth: minContentSize.width, minHeight: minContentSize.height)
        let hosting = NSHostingController(rootView: contentView)
        // NSHostingController defaults to `.preferredContentSize`, which
        // republishes the SwiftUI fitting size to the window on every content
        // change — loading the initial deck snapped the window back to the 800x500
        // minimum a moment after launch. The window's size is AppKit's business
        // here: `contentMinSize` below is the constraint, not SwiftUI's ideal.
        hosting.sizingOptions = []
        return hosting
    }

    /// The main deck window, fully configured and ready to be ordered front.
    public static func makeMainWindow(controller: DeckController) -> NSWindow {
        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: defaultContentSize),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "mdslidepal"
        // contentViewController, not contentView: this is what gives SwiftUI a
        // window toolbar to publish `.toolbar` items into.
        window.contentViewController = makeContentViewController(controller: controller)
        window.contentMinSize = minContentSize
        // Assigning contentViewController makes AppKit resize the window to the
        // controller's fitting size, discarding the contentRect above. Restate
        // the launch size afterwards or the app opens at its minimum.
        window.setContentSize(defaultContentSize)
        return window
    }
}
