// What Problem: The macOS menu bar needs standard commands (File → Open,
// File → Reload, View → Toggle Sidebar, etc.) plus slide-specific commands
// (present, navigation). Contract §mac specifies native menu bar with
// keyboard shortcuts honoring Mac conventions.
//
// How & Why: SwiftUI Commands struct added to the App's scene. Uses
// standard macOS keyboard shortcuts (⌘O, ⌘R, ⌘P). The commands interact
// with DeckState via FocusedValue bindings — the active window's DeckState
// is exposed via @FocusedObject.
//
// Written: 2026-04-12 during mdslidepal-mac Phase 2.5
//
// Status note (2026-08-08): the `Notification.Name` vocabulary below is live —
// MdSlidepalApp's menu items post it and DeckController is the single
// subscriber. The `AppMenuCommands` struct itself is currently inert: `Commands`
// can only attach to a SwiftUI `Scene`, and the app entry point is a manual
// NSApplication (SPM executables have no Info.plist bundle, so a SwiftUI `App`
// exits immediately — see MdSlidepalApp.swift). The equivalent menu is built as
// an NSMenu there. Retained deliberately: it is the Scene-based definition of
// the same command set, and the two must stay in step if the entry point ever
// moves back to a SwiftUI `App`.

import SwiftUI

/// Menu bar commands for mdslidepal.
public struct AppMenuCommands: Commands {

    public init() {}

    public var body: some Commands {
        // Replace default New Document with Open
        CommandGroup(replacing: .newItem) {
            // File → Open handled by .fileImporter on the window
        }

        // Reload command
        CommandGroup(after: .newItem) {
            Button("Reload") {
                NotificationCenter.default.post(
                    name: .reloadDeck, object: nil
                )
            }
            .keyboardShortcut("r", modifiers: .command)

            Button("Export PDF\u{2026}") {
                NotificationCenter.default.post(
                    name: .exportPDF, object: nil
                )
            }
            .keyboardShortcut("e", modifiers: [.command, .shift])

            Divider()
        }

        // Presentation commands
        CommandMenu("Presentation") {
            Button("Present") {
                NotificationCenter.default.post(
                    name: .startPresentation, object: nil
                )
            }
            .keyboardShortcut("p", modifiers: .command)

            Button("Next Slide") {
                NotificationCenter.default.post(
                    name: .nextSlide, object: nil
                )
            }
            .keyboardShortcut(.rightArrow, modifiers: [])

            Button("Previous Slide") {
                NotificationCenter.default.post(
                    name: .previousSlide, object: nil
                )
            }
            .keyboardShortcut(.leftArrow, modifiers: [])

            Divider()

            Button("First Slide") {
                NotificationCenter.default.post(
                    name: .firstSlide, object: nil
                )
            }
            .keyboardShortcut(.home, modifiers: [])

            Button("Last Slide") {
                NotificationCenter.default.post(
                    name: .lastSlide, object: nil
                )
            }
            .keyboardShortcut(.end, modifiers: [])
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    public static let reloadDeck = Notification.Name("mdslidepal.reloadDeck")
    public static let exportPDF = Notification.Name("mdslidepal.exportPDF")
    public static let startPresentation = Notification.Name("mdslidepal.startPresentation")
    public static let nextSlide = Notification.Name("mdslidepal.nextSlide")
    public static let previousSlide = Notification.Name("mdslidepal.previousSlide")
    public static let firstSlide = Notification.Name("mdslidepal.firstSlide")
    public static let lastSlide = Notification.Name("mdslidepal.lastSlide")
}
