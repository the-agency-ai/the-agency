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

    /// The command bus this controller subscribes to.
    ///
    /// Injectable, defaulting to `.default`. The process-global center is shared
    /// with every other observer in the process — including
    /// PresentationWindowManager's `.startPresentation` subscription and any
    /// other controller a test happens to have built — so tests that post
    /// commands hand in a fresh center and get an isolated bus.
    @ObservationIgnored
    private let notificationCenter: NotificationCenter

    /// Cleanup that must run when the controller is deallocated. `deinit` is
    /// nonisolated and so cannot touch @MainActor state, but both operations
    /// here are thread-safe, so they live on a plain class that does its own
    /// teardown.
    private let resources: ControllerResources

    public init(
        deckState: DeckState? = nil,
        notificationCenter: NotificationCenter = .default
    ) {
        let state = deckState ?? DeckState()
        self.deckState = state
        self.notificationCenter = notificationCenter
        self.resources = ControllerResources(notificationCenter: notificationCenter)
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
        // The hosting alert is bound to `errorMessage != nil`. Without this the
        // message from an earlier failure survives the recovery and the alert
        // never dismisses.
        errorMessage = nil
    }

    /// Reload the current document from disk, preserving the slide position.
    public func reload() {
        guard let url = deckState.document.sourceURL else { return }
        do {
            try reloadPreservingPosition(from: url)
            // Same rule as openFile: a success clears the stale alert.
            errorMessage = nil
        } catch {
            errorMessage = "Reload failed: \(error.localizedDescription)"
        }
    }

    /// Load the deck named on the command line, or the welcome deck when there is
    /// no argument. Single place that decides what a fresh launch shows.
    public func loadInitialDeck(arguments: [String] = ProcessInfo.processInfo.arguments) {
        // Flag-style arguments are not paths. macOS injects `-psn_0_…` on a
        // Finder launch and Xcode adds `-NSDocumentRevisionsDebugMode`; treating
        // them as filenames popped a "No such file" alert on an ordinary launch.
        if let path = arguments.dropFirst().first(where: { !$0.hasPrefix("-") }) {
            let url = URL(fileURLWithPath: path)
            if FileManager.default.fileExists(atPath: url.path) {
                openFile(url: url)
                if errorMessage == nil { return }
                // Open failed. Fall through: the alert needs a window behind it,
                // and an empty document is not one.
            } else {
                errorMessage = "No such file: \(path)"
            }
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

        // `load` resets the selection to 0, so the position has to be put back.
        // Clamp rather than give up: the old code restored the index only when it
        // still fit, so deleting slides above the caret sent the presenter home to
        // slide 1 instead of to the nearest surviving slide — the one thing a
        // function named "preserving position" must not do. The clamp also keeps
        // `selectedSlideIndex` in range, which `currentSlide` depends on.
        let lastIndex = deckState.document.slides.count - 1
        guard lastIndex >= 0 else { return }
        deckState.selectedSlideIndex = min(max(currentIndex, 0), lastIndex)
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

    /// How `presentExportPanel()` asks for a destination: called with the
    /// suggested filename, answering with the chosen URL or nil when the user
    /// cancels.
    ///
    /// A seam, not a configuration point. The default is the real NSSavePanel;
    /// tests substitute a temporary directory so the `.exportPDF` command path
    /// can be exercised end to end without putting a panel on screen — otherwise
    /// that command is only ever reachable by hand.
    public typealias ExportDestinationProvider =
        @MainActor (_ suggestedName: String, _ completion: @escaping @MainActor (URL?) -> Void) -> Void

    @ObservationIgnored
    public var exportDestinationProvider: ExportDestinationProvider = { suggestedName, completion in
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.pdf]
        panel.nameFieldStringValue = suggestedName
        panel.canCreateDirectories = true

        panel.begin { response in
            Task { @MainActor in
                completion(response == .OK ? panel.url : nil)
            }
        }
    }

    /// Prompt for a destination and export the deck as PDF.
    public func presentExportPanel() {
        exportDestinationProvider("\(deckState.document.title).pdf") { [weak self] url in
            guard let self, let url else { return }
            self.export(to: url)
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
        let observer = notificationCenter.addObserver(
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

    /// The center the observers were registered on — they must be removed from
    /// the same one, not from `.default`.
    private let notificationCenter: NotificationCenter

    init(notificationCenter: NotificationCenter) {
        self.notificationCenter = notificationCenter
    }

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
            notificationCenter.removeObserver(observer)
        }
        securityScopedURL?.stopAccessingSecurityScopedResource()
    }
}
