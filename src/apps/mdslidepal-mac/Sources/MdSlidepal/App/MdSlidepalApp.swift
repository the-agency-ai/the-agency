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

class MdSlidepalAppDelegate: NSObject, NSApplicationDelegate {
    var deckState: DeckState!
    var window: NSWindow!

    func applicationDidFinishLaunching(_ notification: Notification) {
        deckState = DeckState()

        // Build the menu bar
        buildMainMenu()

        // Create the main window with SwiftUI content
        let contentView = DeckWindowView()
            .environment(deckState)
            .environment(\.theme, deckState.theme)
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

        // Load file from command-line argument
        let args = ProcessInfo.processInfo.arguments
        if args.count > 1 {
            let path = args[1]
            let url = URL(fileURLWithPath: path)
            if FileManager.default.fileExists(atPath: url.path) {
                do {
                    try deckState.load(from: url)
                    window.title = "mdslidepal — \(deckState.document.title)"
                } catch {
                    NSLog("Failed to load \(path): \(error)")
                }
            }
        }

        NSApplication.shared.activate(ignoringOtherApps: true)
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

    @objc func openDocument(_ sender: Any?) {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.plainText]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.message = "Choose a Markdown file to open as a slide deck"

        panel.begin { [weak self] response in
            guard response == .OK, let url = panel.url, let self = self else { return }
            Task { @MainActor in
                do {
                    try self.deckState.load(from: url)
                    self.window.title = "mdslidepal — \(self.deckState.document.title)"
                } catch {
                    let alert = NSAlert()
                    alert.messageText = "Failed to open file"
                    alert.informativeText = error.localizedDescription
                    alert.runModal()
                }
            }
        }
    }

    @objc func reloadDocument(_ sender: Any?) {
        Task { @MainActor in
            guard let url = deckState.document.sourceURL else { return }
            let currentIndex = deckState.selectedSlideIndex
            do {
                try deckState.load(from: url)
                if currentIndex < deckState.document.slides.count {
                    deckState.selectedSlideIndex = currentIndex
                }
                window.title = "mdslidepal — \(deckState.document.title)"
            } catch {
                NSLog("Reload failed: \(error)")
            }
        }
    }

    @objc func exportPDF(_ sender: Any?) {
        Task { @MainActor in
            let panel = NSSavePanel()
            panel.allowedContentTypes = [.pdf]
            panel.nameFieldStringValue = "\(deckState.document.title).pdf"
            panel.canCreateDirectories = true

            panel.begin { [weak self] response in
                guard response == .OK, let url = panel.url, let self = self else { return }
                Task { @MainActor in
                    do {
                        try PDFExporter.export(
                            document: self.deckState.document,
                            theme: self.deckState.theme,
                            to: url
                        )
                    } catch {
                        let alert = NSAlert()
                        alert.messageText = "PDF export failed"
                        alert.informativeText = error.localizedDescription
                        alert.runModal()
                    }
                }
            }
        }
    }

    @objc func nextSlide(_ sender: Any?) {
        Task { @MainActor in deckState.nextSlide() }
    }

    @objc func previousSlide(_ sender: Any?) {
        Task { @MainActor in deckState.previousSlide() }
    }

    @objc func firstSlide(_ sender: Any?) {
        Task { @MainActor in deckState.firstSlide() }
    }

    @objc func lastSlide(_ sender: Any?) {
        Task { @MainActor in deckState.lastSlide() }
    }
}
