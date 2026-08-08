// What Problem: Opening, reloading and exporting a deck was implemented twice —
// once in MdSlidepalAppDelegate for the menu bar, once in DeckWindowView for the
// toolbar and drag-and-drop — and the two had already diverged. The delegate's
// path called neither startAccessingSecurityScopedResource() nor FileWatcher, so
// a file opened with ⌘O never live-reloaded even though that is the feature
// DeckWindowView's own header advertises. Error reporting diverged too (NSAlert
// vs a SwiftUI alert), and the window-title format string was repeated in three
// places.
//
// How & Why: One owner for the document lifecycle. Every entry point — menu,
// toolbar, drag-and-drop, command-line argument — goes through this controller,
// so there is exactly one implementation of "open a file" and it always sets up
// security-scoped access and the file watcher. Menu commands arrive as the
// Notification vocabulary declared in AppCommands.swift, which the controller
// subscribes to once; the delegate posts, the controller handles. Errors surface
// through `errorMessage` so the hosting UI decides how to present them.
//
// Security-scoped access is held for as long as the document is open rather than
// released at the end of the load, because the file watcher needs to keep reading
// the file after the initial load returns.
//
// Written: 2026-08-08 — restores the wiring the Phase 5.1 app-entry rewrite
// dropped, and collapses the duplicated open/reload/export paths into one.

import AppKit
import Foundation
import Observation
import SwiftUI

/// Single owner of the deck document lifecycle: open, reload, watch, export.
@MainActor
@Observable
public final class DeckController {

    /// The deck being displayed.
    public let deckState: DeckState

    /// Presentation-mode state. Owned here so the menu, the presenter window and
    /// the audience window all observe the same instance.
    public let presentation: PresentationCoordinator

    /// Last error, for the hosting UI to surface. Cleared by the UI on dismiss.
    public var errorMessage: String?

    private let fileWatcher = FileWatcher()

    /// Cleanup that must run when the controller is deallocated. `deinit` is
    /// nonisolated and so cannot touch @MainActor state, but both operations
    /// here are thread-safe, so they live on a plain class that does its own
    /// teardown.
    private let resources = ControllerResources()

    public init(deckState: DeckState? = nil) {
        let state = deckState ?? DeckState()
        self.deckState = state
        self.presentation = PresentationCoordinator()
        self.presentation.deckState = state
        configureFileWatcher()
    }

    // MARK: - Document lifecycle

    /// Open a markdown file as the current deck. The one implementation — menu,
    /// toolbar, drag-and-drop and the command line all land here.
    public func openFile(url: URL) {
        // Claim access around the read, but do not disturb the currently open
        // document until the load succeeds. Releasing first would revoke access
        // to a document that stays loaded and watched if this open fails, which
        // silently kills live-reload for it.
        let started = url.startAccessingSecurityScopedResource()

        do {
            try deckState.load(from: url)
        } catch {
            if started { url.stopAccessingSecurityScopedResource() }
            errorMessage = "Failed to open \(url.lastPathComponent): \(error.localizedDescription)"
            return
        }

        // Load succeeded — this is now the open document. Hand the claim over so
        // it is held for the document's lifetime (the file watcher keeps reading
        // long after this call returns) and the previous claim is released.
        resources.transferSecurityScopedAccess(to: url, alreadyStarted: started)
        fileWatcher.watch(url: url)
    }

    /// Reload the current document from disk, preserving the slide position.
    public func reload() {
        guard let url = deckState.document.sourceURL else { return }
        do {
            try reloadPreservingPosition(from: url)
        } catch {
            errorMessage = "Reload failed: \(error.localizedDescription)"
        }
    }

    /// Load the deck named on the command line, or the welcome deck when there is
    /// no argument. Single place that decides what a fresh launch shows.
    public func loadInitialDeck() {
        let args = ProcessInfo.processInfo.arguments
        if args.count > 1 {
            let url = URL(fileURLWithPath: args[1])
            if FileManager.default.fileExists(atPath: url.path) {
                openFile(url: url)
                return
            }
            errorMessage = "No such file: \(args[1])"
        }

        deckState.load(from: Self.welcomeDeck)
    }

    /// Title for the hosting window — one format string, one place.
    public var windowTitle: String {
        "mdslidepal \u{2014} \(deckState.document.title)"
    }

    private func reloadPreservingPosition(from url: URL) throws {
        let currentIndex = deckState.selectedSlideIndex
        try deckState.load(from: url)
        if currentIndex < deckState.document.slides.count {
            deckState.selectedSlideIndex = currentIndex
        }
    }

    private func configureFileWatcher() {
        fileWatcher.onChange = { [weak self] in
            guard let self, let url = self.deckState.document.sourceURL else { return }
            // A save in progress can leave the file momentarily unreadable or
            // half-written; the next change event will pick it up.
            try? self.reloadPreservingPosition(from: url)
        }
    }

    // MARK: - Export

    /// Prompt for a destination and export the deck as PDF.
    public func presentExportPanel() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.pdf]
        panel.nameFieldStringValue = "\(deckState.document.title).pdf"
        panel.canCreateDirectories = true

        panel.begin { [weak self] response in
            guard response == .OK, let url = panel.url else { return }
            Task { @MainActor in
                self?.export(to: url)
            }
        }
    }

    /// Export the deck as a PDF at `url`.
    public func export(to url: URL) {
        do {
            try PDFExporter.export(
                document: deckState.document,
                theme: deckState.theme,
                to: url
            )
        } catch {
            errorMessage = "PDF export failed: \(error.localizedDescription)"
        }
    }

    // MARK: - Command bus

    /// Subscribe to the menu command vocabulary declared in AppCommands.swift.
    ///
    /// Called once by the app delegate. Menu items post; this is the only
    /// subscriber, so each command has exactly one implementation.
    public func installCommandHandlers() {
        guard !resources.hasObservers else { return }

        // `.startPresentation` is deliberately NOT handled here. Starting the
        // coordinator without opening windows leaves it presenting with nothing
        // on screen while its global key monitor swallows Escape and the arrow
        // keys. PresentationWindowManager owns that command — it is the only
        // thing that can honor it completely.
        observe(.reloadDeck) { $0.reload() }
        observe(.exportPDF) { $0.presentExportPanel() }
        observe(.nextSlide) { $0.deckState.nextSlide() }
        observe(.previousSlide) { $0.deckState.previousSlide() }
        observe(.firstSlide) { $0.deckState.firstSlide() }
        observe(.lastSlide) { $0.deckState.lastSlide() }
    }

    private func observe(
        _ name: Notification.Name,
        _ handler: @escaping @MainActor (DeckController) -> Void
    ) {
        let observer = NotificationCenter.default.addObserver(
            forName: name, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                handler(self)
            }
        }
        resources.addObserver(observer)
    }

    // MARK: - Welcome content

    private static let welcomeDeck = """
        # Welcome to mdslidepal

        Open a `.md` file to get started.

        Use **File \u{2192} Open** or drag a markdown file onto this window.

        ---

        # Getting Started

        mdslidepal renders markdown files as slide decks.

        - Slides are separated by `---`
        - Code blocks get syntax highlighting
        - Speaker notes use the `Notes:` marker
        - Themes are loaded from JSON files
        """
}

/// Holds the two resources that must be released when the controller dies:
/// NotificationCenter observers and security-scoped file access.
///
/// Kept off the main actor deliberately. `deinit` is nonisolated and cannot read
/// @MainActor state, and both `removeObserver` and
/// `stopAccessingSecurityScopedResource` are safe to call from any thread — so a
/// plain class that owns them can clean up in its own `deinit`. The alternative,
/// marking the controller's stored properties `nonisolated(unsafe)`, would only
/// silence the compiler.
private final class ControllerResources {
    private let lock = NSLock()
    private var observers: [NSObjectProtocol] = []
    private var securityScopedURL: URL?

    var hasObservers: Bool {
        lock.lock()
        defer { lock.unlock() }
        return !observers.isEmpty
    }

    func addObserver(_ observer: NSObjectProtocol) {
        lock.lock()
        defer { lock.unlock() }
        observers.append(observer)
    }

    /// Adopt an access claim the caller has already started, releasing whatever
    /// was held before. `alreadyStarted` is the result of the caller's
    /// `startAccessingSecurityScopedResource()`, so start and stop stay balanced
    /// even when the URL did not need (or could not get) scoped access.
    func transferSecurityScopedAccess(to url: URL, alreadyStarted: Bool) {
        lock.lock()
        defer { lock.unlock() }

        if let previous = securityScopedURL, previous != url {
            previous.stopAccessingSecurityScopedResource()
            securityScopedURL = nil
        }

        if securityScopedURL == url {
            // Re-opening the same file: we now hold two claims, so drop the new
            // one and keep the original.
            if alreadyStarted { url.stopAccessingSecurityScopedResource() }
            return
        }

        securityScopedURL = alreadyStarted ? url : nil
    }

    deinit {
        for observer in observers {
            NotificationCenter.default.removeObserver(observer)
        }
        securityScopedURL?.stopAccessingSecurityScopedResource()
    }
}
