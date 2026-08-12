// What Problem: The main app window needs a split-view layout with a section
// sidebar on the left and a content reader/editor on the right. This is the
// standard macOS document app pattern — NavigationSplitView with list + detail.
//
// How & Why: NavigationSplitView is the macOS-native split view. The sidebar
// shows sections (SectionListView), the detail shows the selected section's
// content (SectionReaderView). Selection state drives navigation. Comments
// and flags are displayed inline in the reader pane.
//
// Phase 1A alignment: comment.slug (was comment.sectionSlug).
//
// Written: 2026-04-05 during mdpal-app Phase 1 scaffold
// Updated: 2026-04-06 Phase 1A model alignment (CLI JSON spec dispatch #23)
// Updated: 2026-04-15 Phase 1A.3 — surface document.lastError via alert
// Updated: 2026-04-17 Phase 1C.1 — banner copy for non-real resolutions
// Updated: pr-prep QG — the standalone CLIServiceBanner view was superseded
//   by the compact toolbar modeIndicator and had been left unreferenced in
//   the tree. Deleted; the indicator's tooltips now read from
//   CLIServiceFactory.Resolution.bannerMessage so there is a single, tested
//   source for that copy instead of two that drift apart.
// Updated: 2026-05-09 Phase 2.6.2 — convertToPackage triggers NSSavePanel + promote

import SwiftUI
import AppKit

/// The main content view — split between section list and section reader,
/// with an optional top banner when running in Mock mode.
public struct ContentView: View {
    @Bindable var document: DocumentModel
    /// Which CLI service is in use. Drives the top banner so users know
    /// when they're NOT hitting a real bundle. Default is
    /// `.real(executablePath: "")` for previews; production passes the
    /// actual resolution from `MarkdownDocument.cliResolution`.
    let cliResolution: CLIServiceFactory.Resolution
    @State private var selectedSlug: String?
    @State private var showingHistory = false
    /// Phase 2.6.3: sibling .mdpal URL discovered next to the open .md,
    /// nil otherwise. Drives the "Open as Package?" offer banner.
    @State private var siblingBundleURL: URL?

    public init(
        document: DocumentModel,
        cliResolution: CLIServiceFactory.Resolution = .real(executablePath: "")
    ) {
        self.document = document
        self.cliResolution = cliResolution
    }

    public var body: some View {
        VStack(spacing: 0) {
            siblingBundleOfferBanner
            mainSplitView
        }
        // Phase 2.6.3: probe for a sibling .mdpal next to the open .md.
        // Done after onAppear because `representedURL` isn't reliable until
        // the window has been bound to its document.
        .task {
            // Small delay so AppKit has bound representedURL.
            try? await Task.sleep(for: .milliseconds(100))
            await refreshSiblingBundleProbe()
        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                modeIndicator
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    Task {
                        await document.loadHistory()
                        showingHistory = true
                    }
                } label: {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }
            }
        }
        .sheet(isPresented: $showingHistory) {
            HistoryView(
                revisions: document.history,
                onDismiss: { showingHistory = false }
            )
        }
    }

    private var mainSplitView: some View {
        NavigationSplitView {
            SectionListView(
                sections: document.sections,
                flags: document.flags,
                commentCounts: commentCountsBySection,
                selectedSlug: $selectedSlug
            )
            .navigationSplitViewColumnWidth(min: 200, ideal: 250, max: 350)
        } detail: {
            if let section = document.selectedSection {
                SectionReaderView(
                    section: section,
                    comments: document.comments(forSection: section.slug),
                    flag: document.flag(forSection: section.slug),
                    document: document,
                    currentAuthor: "jordan"
                )
            } else {
                ContentUnavailableView(
                    "No Section Selected",
                    systemImage: "doc.text",
                    description: Text("Select a section from the sidebar to view its content.")
                )
            }
        }
        .onChange(of: selectedSlug) { _, newSlug in
            if let slug = newSlug {
                Task {
                    await document.selectSection(slug: slug)
                }
            } else {
                document.selectedSection = nil
            }
        }
        .task {
            await document.loadSections()
            await document.loadComments()
            await document.loadFlags()
        }
        // Phase 2.2: per-error-kind alert using AlertContent (title, body,
        // primary action). Prefers `lastAlert` (structured) over `lastError`
        // (string) — recordError populates both. Legacy call sites that
        // only set lastError get a generic fallback alert.
        .alert(
            document.lastAlert?.title ?? "Something went wrong",
            isPresented: Binding(
                get: { document.lastAlert != nil || document.lastError != nil },
                set: { shown in if !shown { document.clearError() } }
            ),
            presenting: document.lastAlert
        ) { alert in
            primaryAlertButton(for: alert.primaryAction)
            if let secondary = alert.secondaryAction {
                primaryAlertButton(for: secondary)
            }
            // Skip the trailing Dismiss when a .dismiss action is already
            // rendered in either slot. See the rule (and the duplicate-button
            // bug it fixes) on AlertContent.needsTrailingDismissButton, which
            // is unit-tested.
            if alert.needsTrailingDismissButton {
                Button("Dismiss", role: .cancel) { document.clearError() }
            }
        } message: { alert in
            Text(alert.body)
        }
    }

    /// Phase 2.2: renders an AlertAction as a button. Action handlers
    /// are minimal in 2.2 — dismiss or basic reload. Richer wiring
    /// (retry capture, overwrite UX, CLI-install flow) lands in later
    /// phases where those workflows materialize.
    @ViewBuilder
    private func primaryAlertButton(for action: AlertAction) -> some View {
        switch action {
        case .dismiss:
            Button(action.label, role: .cancel) { document.clearError() }
        case .reload:
            Button(action.label) {
                document.clearError()
                Task {
                    await document.loadHistory()
                    await document.loadSections()
                }
            }
        case .retry:
            // 2.2 doesn't capture the failed op; dismiss so the user can
            // retry by repeating their action. 2.4 explicit-save + Phase 3
            // inbox wire richer retry semantics.
            Button(action.label) { document.clearError() }
        case .overwrite:
            // Overwrite wiring lands in 2.3 diff-in-conflict alert.
            Button(action.label) { document.clearError() }
        case .refresh:
            Button(action.label) {
                document.clearError()
                Task { await document.loadComments(); await document.loadFlags() }
            }
        case .installCLI:
            // V1: no App Store deep-link (mdpal is Developer-ID, not App
            // Store). A future release can bundle an installer walk-through.
            Button(action.label) { document.clearError() }
        case .showDetails:
            // 2.2 doesn't have a details sheet; Phase 2.3 adds diff-in-conflict
            // and a general details sheet can follow in Phase 3.
            Button(action.label) { document.clearError() }
        case .convertToPackage:
            // Phase 2.6.2: show NSSavePanel pre-populated with the sibling
            // path (per Q1 = "default A, with override"), then run
            // promote(toBundleURL:) which invokes mdpal create + swaps
            // PancakeCLIService for RealCLIService.
            Button(action.label) {
                document.clearError()
                Task { @MainActor in
                    if let chosenURL = Self.runPromoteSavePanel(suggestedDefault: Self.defaultPromoteURL()) {
                        await document.promote(toBundleURL: chosenURL)
                    }
                }
            }
        }
    }

    /// Phase 2.6 (revised): compact mode indicator in the toolbar — an
    /// SF Symbol with a hover tooltip. Replaces the giant top-of-window
    /// banner. Pancake mode is clickable: a click opens the same
    /// Convert-to-Package save dialog the alert button uses, so users can
    /// proactively promote without waiting to be blocked by an op. Real
    /// mode shows a quiet checkmark (you're on the production path);
    /// mock modes show their respective warning glyphs.
    @ViewBuilder
    private var modeIndicator: some View {
        switch cliResolution {
        case .real:
            Image(systemName: "shippingbox.fill")
                .foregroundStyle(.green)
                .help("Package mode — full .mdpal bundle. Comments, flags, and revisions are persisted.")
        case .pancake:
            Button {
                // Confirmation first — surface the same Convert-to-Package
                // alert the package-required-op flow uses. The user reads
                // what's about to happen, clicks Convert, then NSSavePanel
                // opens. A bare misclick on the toolbar icon doesn't drop
                // a save dialog on them out of nowhere.
                document.lastAlert = AlertContent(
                    title: "Convert to a .mdpal bundle?",
                    body: "Convert this plain Markdown file into a packaged .mdpal bundle. The .md file is preserved as the bundle’s initial revision; from there you can add comments, flag sections, and create new revisions. You’ll choose where to save the bundle.",
                    primaryAction: .convertToPackage,
                    secondaryAction: .dismiss)
            } label: {
                Image(systemName: "doc.text")
                    .foregroundStyle(.blue)
            }
            .buttonStyle(.borderless)
            .help("\(cliResolution.bannerMessage ?? "") Click to convert.")
        case .mockRequested:
            Image(systemName: "info.circle.fill")
                .foregroundStyle(.purple)
                .help(cliResolution.bannerMessage ?? "")
        case .mockFallback:
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
                .help(cliResolution.bannerMessage ?? "")
        }
    }

    /// Phase 2.6.3: green "Open as Package?" offer banner shown when a
    /// `.mdpal` directory exists alongside the currently-open .md. One
    /// click switches the service from PancakeCLIService to RealCLIService
    /// pointing at that bundle. The banner only appears in pancake mode
    /// (no point offering to switch when you're already on the real CLI).
    @ViewBuilder
    private var siblingBundleOfferBanner: some View {
        if case .pancake = cliResolution, let bundleURL = siblingBundleURL {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "shippingbox.and.arrow.backward")
                    .font(.title2)
                    .foregroundStyle(.green)
                VStack(alignment: .leading, spacing: 4) {
                    Text("A .mdpal bundle exists for this file")
                        .font(.headline)
                        .foregroundStyle(.green)
                    Text("‘\(bundleURL.lastPathComponent)’ is alongside this Markdown file. Open it as a package to access its revisions, comments, and flags.")
                        .font(.callout)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                Button("Open as Package") {
                    Task { @MainActor in
                        await document.openExistingBundle(at: bundleURL)
                        siblingBundleURL = nil
                    }
                }
                .keyboardShortcut(.defaultAction)
                Button("Dismiss") { siblingBundleURL = nil }
                    .keyboardShortcut(.cancelAction)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.green.opacity(0.18))
            .overlay(alignment: .top) {
                Rectangle().fill(Color.green).frame(height: 3)
            }
            .overlay(alignment: .bottom) {
                Rectangle().fill(Color.green).frame(height: 3)
            }
        } else {
            EmptyView()
        }
    }

    /// Probe for a `.mdpal` directory next to the open `.md`. Updates
    /// `siblingBundleURL` so the offer banner appears (or doesn't).
    @MainActor
    private func refreshSiblingBundleProbe() async {
        guard case .pancake = cliResolution else {
            siblingBundleURL = nil
            return
        }
        guard let sourceURL = NSApp.mainWindow?.representedURL ?? NSApp.keyWindow?.representedURL else {
            siblingBundleURL = nil
            return
        }
        let baseName = sourceURL.deletingPathExtension().lastPathComponent
        let candidate = sourceURL.deletingLastPathComponent()
            .appendingPathComponent("\(baseName).mdpal")
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: candidate.path, isDirectory: &isDir), isDir.boolValue {
            siblingBundleURL = candidate
        } else {
            siblingBundleURL = nil
        }
    }

    /// Best-effort default for the promotion target — sibling .mdpal next
    /// to the source .md. Reads `representedURL` from the active window
    /// (set by AppKit/NSDocument when DocumentGroup opens a file). Returns
    /// nil if no source URL is available, in which case NSSavePanel opens
    /// at its system default.
    @MainActor
    static func defaultPromoteURL() -> URL? {
        guard let sourceURL = NSApp.mainWindow?.representedURL ?? NSApp.keyWindow?.representedURL else {
            return nil
        }
        let baseName = sourceURL.deletingPathExtension().lastPathComponent
        let parent = sourceURL.deletingLastPathComponent()
        return parent.appendingPathComponent("\(baseName).mdpal")
    }

    /// Run NSSavePanel synchronously on the main thread and return the
    /// chosen URL (with .mdpal extension applied if missing). Returns nil
    /// if the user cancels.
    @MainActor
    static func runPromoteSavePanel(suggestedDefault: URL?) -> URL? {
        let panel = NSSavePanel()
        panel.title = "Convert to Markdown Pal Package"
        panel.message = "The .mdpal bundle will hold this file’s revisions, comments, and flags. The .md file is preserved as the bundle’s initial revision."
        panel.prompt = "Convert"
        panel.allowedContentTypes = [.directory] // .mdpal looks like a directory to NSSavePanel
        panel.canCreateDirectories = true
        panel.isExtensionHidden = false
        if let suggested = suggestedDefault {
            panel.directoryURL = suggested.deletingLastPathComponent()
            panel.nameFieldStringValue = suggested.lastPathComponent
        } else {
            panel.nameFieldStringValue = "Untitled.mdpal"
        }

        let response = panel.runModal()
        guard response == .OK, var url = panel.url else { return nil }
        if url.pathExtension != "mdpal" {
            url = url.deletingPathExtension().appendingPathExtension("mdpal")
        }
        return url
    }

    /// Compute unresolved comment counts per section for badge display.
    private var commentCountsBySection: [String: Int] {
        var counts: [String: Int] = [:]
        for comment in document.comments where !comment.isResolved {
            counts[comment.slug, default: 0] += 1
        }
        return counts
    }
}
