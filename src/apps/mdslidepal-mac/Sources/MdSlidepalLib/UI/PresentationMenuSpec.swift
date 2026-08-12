// What Problem: The Presentation menu bound Next/Previous/First/Last Slide to
// bare Right/Left/Home/End with `keyEquivalentModifierMask = []`. Main-menu key
// equivalents are matched in NSApplication.sendEvent *before* the key window's
// responder chain sees the event, so an unmodified arrow key could never reach a
// focused control — the NavigationSplitView sidebar list, any scroll view, any
// future text field. Arrow-key sidebar navigation was dead app-wide.
//
// How & Why: Contract §10 scopes bare Arrow/Home/End navigation to *presentation*
// mode ("Keyboard navigation (present/serve mode)"), where PresentationCoordinator's
// local NSEvent monitor already handles them and is only installed while
// presenting. So the menu items — which are live at all times — carry ⌘ instead,
// and outside presentation mode the arrows belong to whatever control has focus.
// The specs live in the library rather than inline in the app delegate so the
// modifier requirement can be pinned by a test; the executable target is not
// importable from the test runner.
//
// Written: 2026-08-12 during mdslidepal-mac PR-prep QG wave 2.

import AppKit

/// Title plus key equivalent for one main-menu command.
public struct MenuCommandSpec: Equatable {
    public let title: String
    public let keyEquivalent: String
    public let modifiers: NSEvent.ModifierFlags

    public init(title: String, keyEquivalent: String, modifiers: NSEvent.ModifierFlags) {
        self.title = title
        self.keyEquivalent = keyEquivalent
        self.modifiers = modifiers
    }

    /// Build the menu item this spec describes.
    @MainActor
    public func makeItem(action: Selector?, target: AnyObject?) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: keyEquivalent)
        item.keyEquivalentModifierMask = modifiers
        item.target = target
        return item
    }
}

/// Key equivalents for the Presentation menu's slide-navigation commands.
public enum PresentationMenuSpec {

    /// Every navigation command is modified. A bare Arrow/Home/End key
    /// equivalent here would be swallowed by the main menu before the key
    /// window's responder chain ran; contract §10's bare keys apply to
    /// presentation mode only and are served by PresentationCoordinator's
    /// local event monitor, which exists only while presenting.
    public static let navigationModifiers: NSEvent.ModifierFlags = [.command]

    private static func functionKey(_ code: Int) -> String {
        String(Character(UnicodeScalar(code)!))
    }

    public static let nextSlide = MenuCommandSpec(
        title: "Next Slide",
        keyEquivalent: functionKey(NSRightArrowFunctionKey),
        modifiers: navigationModifiers
    )

    public static let previousSlide = MenuCommandSpec(
        title: "Previous Slide",
        keyEquivalent: functionKey(NSLeftArrowFunctionKey),
        modifiers: navigationModifiers
    )

    public static let firstSlide = MenuCommandSpec(
        title: "First Slide",
        keyEquivalent: functionKey(NSHomeFunctionKey),
        modifiers: navigationModifiers
    )

    public static let lastSlide = MenuCommandSpec(
        title: "Last Slide",
        keyEquivalent: functionKey(NSEndFunctionKey),
        modifiers: navigationModifiers
    )

    /// All four in menu order.
    public static let navigationCommands: [MenuCommandSpec] = [
        nextSlide, previousSlide, firstSlide, lastSlide
    ]
}
