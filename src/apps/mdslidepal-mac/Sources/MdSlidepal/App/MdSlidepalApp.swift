// What Problem: Entry point for mdslidepal-mac. SPM-built SwiftUI apps
// exit immediately without a proper NSApplication setup. This uses manual
// NSApplication with full menu bar, keyboard handling, and SwiftUI hosting.
//
// How & Why: Manual NSApplication.run() keeps the run loop alive. A proper
// main menu is built programmatically (File, Edit, View, Presentation, Window,
// Help) with Quit (⌘Q), Open (⌘O), arrow key navigation, etc. The SwiftUI
// DeckWindowView is hosted in an NSHostingView inside an NSWindow.
//
// Written: 2026-04-12 during mdslidepal-mac Phase 1.1
// Updated: 2026-04-14 — full menu bar, keyboard handling, quit support
// Updated: 2026-08-08 — reconnected the Phase 3 presentation subsystem this file
//   orphaned when it moved from a SwiftUI App/Scene to a manual NSApplication
//   delegate: Present (⌘P) now opens the presenter and audience windows via
//   PresentationWindowManager. Document actions post the AppCommands notification
//   vocabulary and are handled once by DeckController, replacing the duplicated
//   open/reload/export implementations that had diverged from DeckWindowView's.

import SwiftUI
import AppKit
import MdSlidepalLib

@main
struct MdSlidepalMain {
    static func main() {
        let app = NSApplication.shared
        app.setActivationPolicy(.regular)
        let delegate = MdSlidepalAppDelegate()
        app.delegate = delegate
        app.run()
    }
}

// AppKit delivers delegate callbacks on the main thread, so annotating the class
// lets it touch @MainActor state (DeckState, DeckController) without wrapping
// every action in a Task.
@MainActor
class MdSlidepalAppDelegate: NSObject, NSApplicationDelegate {
    private var controller: DeckController!
    private var presentationWindows: PresentationWindowManager!
    private var window: NSWindow!

    func applicationDidFinishLaunching(_ notification: Notification) {
        controller = DeckController()
        presentationWindows = PresentationWindowManager(controller: controller)
        controller.installCommandHandlers()

        // Build the menu bar
        buildMainMenu()

        // Create the main window with SwiftUI content
        let contentView = DeckWindowView()
            .environment(controller)
            .environment(controller.deckState)
            .environment(\.theme, controller.deckState.theme)
            .frame(minWidth: 800, minHeight: 500)

        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1200, height: 800),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "mdslidepal"
        window.contentView = NSHostingView(rootView: contentView)
        window.center()
        window.makeKeyAndOrderFront(nil)

        // One owner decides what a fresh launch shows — command-line file or the
        // welcome deck — and it sets up the watcher and security-scoped access.
        controller.loadInitialDeck()
        startTrackingWindowTitle()

        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    /// Keep the window title in step with the document, whatever changed it.
    ///
    /// Setting the title at each call site missed drag-and-drop, the toolbar's
    /// file importer, and every file-watcher reload. Observation covers all of
    /// them, and re-arms itself because withObservationTracking fires once.
    private func startTrackingWindowTitle() {
        withObservationTracking {
            window.title = controller.windowTitle
        } onChange: { [weak self] in
            Task { @MainActor in
                self?.startTrackingWindowTitle()
            }
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    // MARK: - Menu Bar

    func buildMainMenu() {
        let mainMenu = NSMenu()

        // App menu (mdslidepal)
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "About mdslidepal", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Quit mdslidepal", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        let appMenuItem = NSMenuItem()
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)

        // File menu
        let fileMenu = NSMenu(title: "File")
        let openItem = NSMenuItem(title: "Open…", action: #selector(openDocument(_:)), keyEquivalent: "o")
        openItem.target = self
        fileMenu.addItem(openItem)
        fileMenu.addItem(.separator())
        let reloadItem = NSMenuItem(title: "Reload", action: #selector(reloadDocument(_:)), keyEquivalent: "r")
        reloadItem.target = self
        fileMenu.addItem(reloadItem)
        fileMenu.addItem(.separator())
        let exportItem = NSMenuItem(title: "Export PDF…", action: #selector(exportPDF(_:)), keyEquivalent: "e")
        exportItem.keyEquivalentModifierMask = [.command, .shift]
        exportItem.target = self
        fileMenu.addItem(exportItem)
        fileMenu.addItem(.separator())
        let closeItem = NSMenuItem(title: "Close Window", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        fileMenu.addItem(closeItem)
        let fileMenuItem = NSMenuItem()
        fileMenuItem.submenu = fileMenu
        mainMenu.addItem(fileMenuItem)

        // Edit menu (standard)
        let editMenu = NSMenu(title: "Edit")
        editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        let editMenuItem = NSMenuItem()
        editMenuItem.submenu = editMenu
        mainMenu.addItem(editMenuItem)

        // View menu
        let viewMenu = NSMenu(title: "View")
        let fullScreenItem = NSMenuItem(title: "Enter Full Screen", action: #selector(NSWindow.toggleFullScreen(_:)), keyEquivalent: "f")
        fullScreenItem.keyEquivalentModifierMask = [.command, .control]
        viewMenu.addItem(fullScreenItem)
        let viewMenuItem = NSMenuItem()
        viewMenuItem.submenu = viewMenu
        mainMenu.addItem(viewMenuItem)

        // Presentation menu
        let presMenu = NSMenu(title: "Presentation")
        let presentItem = NSMenuItem(title: "Present", action: #selector(togglePresentation(_:)), keyEquivalent: "p")
        presentItem.target = self
        presMenu.addItem(presentItem)
        presMenu.addItem(.separator())
        let nextItem = NSMenuItem(title: "Next Slide", action: #selector(nextSlide(_:)), keyEquivalent: String(Character(UnicodeScalar(NSRightArrowFunctionKey)!)))
        nextItem.keyEquivalentModifierMask = []
        nextItem.target = self
        presMenu.addItem(nextItem)
        let prevItem = NSMenuItem(title: "Previous Slide", action: #selector(previousSlide(_:)), keyEquivalent: String(Character(UnicodeScalar(NSLeftArrowFunctionKey)!)))
        prevItem.keyEquivalentModifierMask = []
        prevItem.target = self
        presMenu.addItem(prevItem)
        presMenu.addItem(.separator())
        let firstItem = NSMenuItem(title: "First Slide", action: #selector(firstSlide(_:)), keyEquivalent: String(Character(UnicodeScalar(NSHomeFunctionKey)!)))
        firstItem.keyEquivalentModifierMask = []
        firstItem.target = self
        presMenu.addItem(firstItem)
        let lastItem = NSMenuItem(title: "Last Slide", action: #selector(lastSlide(_:)), keyEquivalent: String(Character(UnicodeScalar(NSEndFunctionKey)!)))
        lastItem.keyEquivalentModifierMask = []
        lastItem.target = self
        presMenu.addItem(lastItem)
        let presMenuItem = NSMenuItem()
        presMenuItem.submenu = presMenu
        mainMenu.addItem(presMenuItem)

        // Window menu
        let windowMenu = NSMenu(title: "Window")
        windowMenu.addItem(withTitle: "Minimize", action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m")
        windowMenu.addItem(withTitle: "Zoom", action: #selector(NSWindow.performZoom(_:)), keyEquivalent: "")
        let windowMenuItem = NSMenuItem()
        windowMenuItem.submenu = windowMenu
        mainMenu.addItem(windowMenuItem)
        NSApplication.shared.windowsMenu = windowMenu

        // Help menu
        let helpMenu = NSMenu(title: "Help")
        helpMenu.addItem(withTitle: "mdslidepal Help", action: nil, keyEquivalent: "")
        let helpMenuItem = NSMenuItem()
        helpMenuItem.submenu = helpMenu
        mainMenu.addItem(helpMenuItem)
        NSApplication.shared.helpMenu = helpMenu

        NSApplication.shared.mainMenu = mainMenu
    }

    // MARK: - Actions
    //
    // Menu items post the command vocabulary declared in AppCommands.swift.
    // DeckController is the single subscriber, so each command has exactly one
    // implementation shared with the toolbar and drag-and-drop paths.

    /// File → Open. The panel lives here because it is menu-bar UI; the resulting
    /// URL goes straight to the controller, which owns security-scoped access and
    /// the file watcher.
    @objc func openDocument(_ sender: Any?) {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.plainText]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.message = "Choose a Markdown file to open as a slide deck"

        panel.begin { [weak self] response in
            guard response == .OK, let url = panel.url else { return }
            Task { @MainActor in
                self?.controller.openFile(url: url)
            }
        }
    }

    @objc func reloadDocument(_ sender: Any?) {
        NotificationCenter.default.post(name: .reloadDeck, object: nil)
    }

    @objc func exportPDF(_ sender: Any?) {
        NotificationCenter.default.post(name: .exportPDF, object: nil)
    }

    @objc func togglePresentation(_ sender: Any?) {
        presentationWindows.toggle()
    }

    @objc func nextSlide(_ sender: Any?) {
        NotificationCenter.default.post(name: .nextSlide, object: nil)
    }

    @objc func previousSlide(_ sender: Any?) {
        NotificationCenter.default.post(name: .previousSlide, object: nil)
    }

    @objc func firstSlide(_ sender: Any?) {
        NotificationCenter.default.post(name: .firstSlide, object: nil)
    }

    @objc func lastSlide(_ sender: Any?) {
        NotificationCenter.default.post(name: .lastSlide, object: nil)
    }
}
