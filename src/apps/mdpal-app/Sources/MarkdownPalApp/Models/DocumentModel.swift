// What Problem: The app needs an in-memory model of the document that holds
// sections, comments, and flags together. This is the app's view of the
// document — not the engine's Document class. The app owns this model and
// updates it by calling CLI commands and parsing JSON responses.
//
// How & Why: Observable class for SwiftUI binding. Holds the section list
// (flattened from tree by service), comments, and flags. Methods correspond
// to CLI commands the app will invoke. Phase 1A alignment: sections are
// [SectionTreeNode] (flat, from service). BundlePath used for CLI calls.
// editSection calls readSection after edit (MAR finding: EditResult has no
// content). New methods: addComment, resolveComment, flagSection, clearFlag.
// Filter helpers use .slug (not .sectionSlug).
//
// Written: 2026-04-05 during mdpal-app Phase 1 scaffold
// Updated: 2026-04-06 Phase 1A model alignment (CLI JSON spec dispatch #23)
// Updated: 2026-04-17 Phase 1C.4 — persistence surface: latestRevision
//          state + createRevision()/loadHistory()/loadCurrentVersion()/
//          bumpVersion(). bundleConflict is re-thrown for the UI to
//          handle; other failures populate lastError like the rest of
//          the load/mutation methods.

import Foundation
import SwiftUI

/// The app's in-memory representation of a Markdown document.
/// Observable for SwiftUI data flow.
@Observable
public final class DocumentModel {
    /// All sections in the document (flat list from service, ordered by document position).
    public var sections: [SectionTreeNode] = []

    /// The currently selected section's full content.
    public var selectedSection: Section?

    /// All comments in the document.
    public var comments: [Comment] = []

    /// All flags in the document.
    public var flags: [Flag] = []

    /// The bundle path for CLI operations.
    public var bundlePath: BundlePath?

    /// The current version ID from the sections response.
    public var currentVersionId: String?

    /// The raw Markdown content (from FileWrapper).
    /// Used by MarkdownDocument for serialization. Phase 2 replaces with bundle path.
    public var rawContent: String = ""

    /// Whether the document has unsaved changes.
    public var isDirty: Bool = false

    /// Error state for display.
    ///
    /// Phase 2.2: retained for non-CLI errors and backward compatibility
    /// with existing call sites. For typed `CLIServiceError`, prefer
    /// `lastAlert` which carries the structured per-error UX mapping.
    public var lastError: String?

    /// Structured alert content for the most recent typed `CLIServiceError`
    /// (Phase 2.2). When set, the UI renders a per-error-kind alert
    /// (title + body + primary action) instead of the generic "Something
    /// went wrong". Populated by `recordError(_:)`; cleared on dismiss.
    /// Falls back to `lastError` for non-CLI errors.
    public var lastAlert: AlertContent?

    /// Latest revision created or observed for this bundle. Used as the
    /// optimistic-concurrency anchor when createRevision is called —
    /// changes landed by another client between our load and our save
    /// will surface as `.bundleConflict`.
    public var latestRevision: RevisionInfo?

    /// Revision history for this bundle. Populated by loadHistory();
    /// newest-first. Drives the history drawer (1C.5).
    public var history: [RevisionInfo] = []

    /// Current version info (bundle-level). Populated by loadCurrentVersion().
    public var currentVersion: VersionInfo?

    /// The CLI service used for operations.
    ///
    /// Phase 2.6: mutable so promotion (pancake → package) can swap from
    /// PancakeCLIService to RealCLIService in place. Treat as an
    /// implementation detail — external callers route mutations through
    /// the public API and never replace the service themselves.
    private(set) public var cliService: CLIServiceProtocol

    /// Phase 2.6: closure to re-run after a successful promote(toBundleURL:).
    /// Captured by mutation methods when they catch `.packageRequired`. Cleared
    /// after invocation so a successful run doesn't leave a re-trigger behind.
    public var pendingPackageOp: (() async -> Void)?

    public init(cliService: CLIServiceProtocol = MockCLIService()) {
        self.cliService = cliService
    }

    // MARK: - Effective Bundle Path

    /// The bundle path to use for CLI calls.
    /// Falls back to empty path for Phase 1 mock usage.
    private var effectiveBundle: BundlePath {
        bundlePath ?? BundlePath("")
    }

    // MARK: - Error recording (Phase 2.2)

    /// Record an error in a way the UI can present richly.
    /// - For typed `CLIServiceError`: populates both `lastAlert` (via the
    ///   pure mapping function — structured per-error UX) and `lastError`
    ///   (string fallback for any lingering view that hasn't migrated).
    /// - For non-CLI errors: populates `lastError` with a prefixed message
    ///   and `lastAlert` with a generic "something went wrong" fallback so
    ///   the view always has an alert to render.
    ///
    /// `prefix` is the operation-specific context ("Failed to load sections"
    /// etc.), concatenated into `lastError` for backward compat with Phase
    /// 1 view code.
    func recordError(_ error: Error, prefix: String,
                     retry: (() async -> Void)? = nil) {
        if let cliError = error as? CLIServiceError {
            lastAlert = cliError.alertContent
            lastError = "\(prefix): \(cliError.localizedDescription)"
            // Phase 2.6: `.packageRequired` is the one error whose alert
            // offers a remedy that changes the document's shape. Park the
            // caller's retry closure so promote(toBundleURL:) can re-run
            // what the user originally asked for. Only this case — parking
            // a retry for, say, fileNotFound would let a later unrelated
            // promotion replay a stale operation.
            if case .packageRequired = cliError {
                pendingPackageOp = retry
            }
        } else {
            let description = error.localizedDescription
            lastError = "\(prefix): \(description)"
            lastAlert = AlertContent(
                title: "Something went wrong",
                body: "\(prefix): \(description)",
                primaryAction: .dismiss)
        }
    }

    /// Clear both error surfaces. Called after a successful operation so
    /// stale alerts don't linger. Phase 2.2 unifies the two clears that
    /// Phase 1 kept separate.
    func clearError() {
        lastError = nil
        lastAlert = nil
    }

    // MARK: - Section Operations

    /// Load sections from the document content.
    /// Calls `mdpal sections` via the CLI service.
    public func loadSections() async {
        do {
            sections = try await cliService.listSections(bundle: effectiveBundle)
            clearError()
        } catch {
            recordError(error, prefix: "Failed to load sections")
        }
    }

    /// Select and load a section's full content.
    /// Calls `mdpal read <slug>` via the CLI service.
    public func selectSection(slug: String) async {
        do {
            selectedSection = try await cliService.readSection(slug: slug, bundle: effectiveBundle)
            clearError()
        } catch {
            recordError(error, prefix: "Failed to read section '\(slug)'")
        }
    }

    /// Edit a section's content with optimistic concurrency.
    /// Calls `mdpal edit`, then re-reads the section to refresh content
    /// (MAR finding: EditResult has no content field).
    public func editSection(slug: String, newContent: String, versionHash: String) async throws {
        _ = try await cliService.editSection(
            slug: slug, content: newContent,
            versionHash: versionHash, bundle: effectiveBundle
        )
        // Re-read to get updated content (EditResult has no content)
        selectedSection = try await cliService.readSection(slug: slug, bundle: effectiveBundle)
        isDirty = true
        await loadSections()
        // Clear any prior error now that the mutation succeeded — prevents a
        // stale alert from showing after the user retries successfully.
        clearError()
    }

    // MARK: - Comment Operations

    /// Load all comments.
    /// Calls `mdpal comments` via the CLI service.
    public func loadComments() async {
        do {
            comments = try await cliService.listComments(bundle: effectiveBundle)
            clearError()
        } catch {
            recordError(error, prefix: "Failed to load comments")
        }
    }

    /// Get comments for a specific section.
    public func comments(forSection slug: String) -> [Comment] {
        comments.filter { $0.slug == slug }
    }

    /// Get unresolved comments for a specific section.
    public func unresolvedComments(forSection slug: String) -> [Comment] {
        comments.filter { $0.slug == slug && !$0.isResolved }
    }

    /// Add a comment to a section.
    public func addComment(slug: String, type: CommentType, author: String,
                           text: String, context: String? = nil,
                           priority: Priority = .normal, tags: [String] = []) async throws {
        let comment = try await cliService.addComment(
            slug: slug, bundle: effectiveBundle, type: type,
            author: author, text: text, context: context,
            priority: priority, tags: tags
        )
        comments.append(comment)
        // Clear any prior error now that the mutation succeeded.
        clearError()
    }

    /// Resolve a comment.
    public func resolveComment(commentId: String, response: String, by: String) async throws {
        _ = try await cliService.resolveComment(
            commentId: commentId, bundle: effectiveBundle,
            response: response, by: by
        )
        await loadComments()
        // Clear any prior error now that the mutation succeeded.
        clearError()
    }

    // MARK: - Flag Operations

    /// Load all flags.
    /// Calls `mdpal flags` via the CLI service.
    public func loadFlags() async {
        do {
            flags = try await cliService.listFlags(bundle: effectiveBundle)
            clearError()
        } catch {
            recordError(error, prefix: "Failed to load flags")
        }
    }

    /// Check if a section is flagged.
    public func isFlagged(slug: String) -> Bool {
        flags.contains { $0.slug == slug }
    }

    /// Get the flag for a section, if any.
    public func flag(forSection slug: String) -> Flag? {
        flags.first { $0.slug == slug }
    }

    /// Flag a section for discussion.
    public func flagSection(slug: String, author: String, note: String? = nil) async throws {
        let result = try await cliService.flagSection(
            slug: slug, bundle: effectiveBundle,
            author: author, note: note
        )
        if result.flagged {
            await loadFlags()
        }
        // Clear any prior error now that the mutation succeeded — covers the
        // result.flagged == false branch where loadFlags isn't called.
        clearError()
    }

    /// Clear a flag from a section.
    public func clearFlag(slug: String) async throws {
        _ = try await cliService.clearFlag(slug: slug, bundle: effectiveBundle)
        await loadFlags()
        // Clear any prior error now that the mutation succeeded.
        clearError()
    }

    /// Toggle the flag on a section — clears it if flagged, sets it if not.
    /// The view surfaces a single toggle control backed by this method.
    public func toggleFlag(slug: String, author: String, note: String? = nil) async throws {
        if isFlagged(slug: slug) {
            try await clearFlag(slug: slug)
        } else {
            try await flagSection(slug: slug, author: author, note: note)
        }
    }

    // MARK: - Persistence (Phase 1C.4)

    /// Create a new revision of the bundle from the given content.
    /// Uses `latestRevision?.versionId` as the optimistic-concurrency
    /// anchor when present — the service throws `.bundleConflict` if the
    /// bundle drifted past that anchor.
    ///
    /// ## Phase 2.4 QG contract — PURE RETHROW, NO RECORDING
    ///
    /// **Callers MUST record errors themselves via `recordError(_:prefix:)`**.
    /// This method is a pure rethrow — it does NOT populate `lastError`
    /// or `lastAlert` on failure. The single recording-site pattern
    /// (view-layer handles UX) prevents double-record.
    ///
    /// Current call sites: `MarkdownDocument.saveAsRevision()` (uses a
    /// `catch let cliError as CLIServiceError { recordError(...) }` ladder).
    /// **Any new caller that invokes `createRevision` directly must also
    /// wrap it in a try/catch that calls `recordError` — otherwise errors
    /// are invisible to the user (neither lastError nor lastAlert updates).**
    ///
    /// On success: isDirty cleared, `latestRevision` updated, nothing else
    /// reloaded (the UI calls `loadHistory()` explicitly when it needs
    /// the refreshed list).
    public func createRevision(content: String) async throws {
        do {
            let rev = try await cliService.createRevision(
                bundle: effectiveBundle,
                content: content,
                baseRevision: latestRevision?.versionId
            )
            latestRevision = rev
            isDirty = false
            clearError()
        } catch {
            // Rethrow without recording. `saveAsRevision` (or any other
            // view-layer caller) is the single recording site — it calls
            // `recordError` against the typed CLIServiceError, which routes
            // through the Phase-2.2 AlertContent mapping for per-error UX
            // (bundleConflict → reload; cliNotFound → install; etc.).
            // Phase-2.2 design: ONE recording site prevents double-record
            // (model.recordError then view.recordError) and keeps the
            // catch ladder here declarative rather than paved.
            throw error
        }
    }

    /// Load the bundle's revision history (newest-first).
    public func loadHistory() async {
        do {
            history = try await cliService.listHistory(bundle: effectiveBundle)
            // Keep latestRevision in sync with what the history says is latest.
            // Fallback: first entry (history is newest-first).
            latestRevision = history.first { $0.latest == true } ?? history.first
            clearError()
        } catch {
            recordError(error, prefix: "Failed to load history")
        }
    }

    /// Load the current bundle-level version info.
    public func loadCurrentVersion() async {
        do {
            currentVersion = try await cliService.showVersion(bundle: effectiveBundle)
            clearError()
        } catch {
            recordError(error, prefix: "Failed to load version info")
        }
    }

    /// Bump the bundle's major version. On success updates
    /// `currentVersion` via the returned VersionBumpResult.
    public func bumpVersion() async throws -> VersionBumpResult {
        let result = try await cliService.bumpVersion(bundle: effectiveBundle)
        currentVersion = VersionInfo(
            version: result.version,
            versionId: result.versionId,
            revision: result.revision,
            timestamp: result.timestamp
        )
        clearError()
        return result
    }

    // MARK: - Pancake → Package Promotion (Phase 2.6.2)

    /// Promote a pancake (.md) document to a packaged (.mdpal) bundle.
    ///
    /// Runs `mdpal create <name> --dir <dir> --content <rawContent>` to
    /// produce a real bundle on disk with the current `rawContent` as its
    /// initial revision. On success, swaps `cliService` from
    /// PancakeCLIService to RealCLIService and sets `bundlePath` to the
    /// new bundle. The bundle is now usable for the full set of
    /// mutations: comments, flags, revisions, etc.
    ///
    /// After a successful promote, if a `pendingPackageOp` closure was
    /// captured (the user attempted addComment etc. that triggered the
    /// promotion), it is invoked and cleared. Failures during the
    /// originally-requested op surface through the normal recordError
    /// pipeline.
    ///
    /// On failure (mdpal create error, e.g., target path already exists):
    /// records the error via the typed CLIServiceError pipeline so the
    /// user sees a structured alert. cliService and bundlePath are left
    /// unchanged — caller can retry with a different URL.
    ///
    /// - Parameter bundleURL: The full target path including .mdpal suffix
    ///   (e.g., `~/Notes/foo.mdpal`). Caller is responsible for picking
    ///   a path the user agreed to (NSSavePanel in the View layer).
    @MainActor
    public func promote(toBundleURL bundleURL: URL) async {
        // Preconditions
        guard cliService is PancakeCLIService else {
            // Already packaged or running on something else — no-op.
            recordError(CLIServiceError.invalidArgument(description: "Document is not in pancake mode"),
                        prefix: "Convert to package")
            return
        }
        guard !rawContent.isEmpty else {
            recordError(CLIServiceError.invalidArgument(description: "Document is empty — nothing to package"),
                        prefix: "Convert to package")
            return
        }

        // Compute name + dir for `mdpal create <name> --dir <dir>`
        let path = bundleURL.path
        var bareName = bundleURL.lastPathComponent
        if bareName.hasSuffix(".mdpal") { bareName.removeLast(".mdpal".count) }
        guard !bareName.isEmpty else {
            recordError(CLIServiceError.invalidArgument(description: "Bundle name cannot be empty"),
                        prefix: "Convert to package")
            return
        }
        let dir = bundleURL.deletingLastPathComponent().path

        // Run mdpal create. Use the resolver so the same fallbacks the
        // RealCLIService uses (MDPAL_BIN → PATH → /usr/local/bin →
        // /opt/homebrew/bin) apply here too.
        let result = await Self.runMdpalCreate(name: bareName, dir: dir, content: rawContent)
        switch result {
        case .failure(let err):
            recordError(err, prefix: "Convert to package")
            return
        case .success:
            break
        }

        // Swap service: pancake → real. RealCLIService init can throw
        // (cliNotFound) but we just successfully ran mdpal create, so
        // the binary is definitely there. Still, surface init errors.
        do {
            let realService = try RealCLIService(
                environment: ProcessInfo.processInfo.environment,
                fileManager: .default,
                runner: DefaultProcessRunner()
            )
            self.cliService = realService
            self.bundlePath = BundlePath(path)
        } catch let err as CLIServiceError {
            recordError(err, prefix: "Convert to package — service swap")
            return
        } catch {
            recordError(error, prefix: "Convert to package — service swap")
            return
        }

        // Bundle is real; reload section list + comments + flags from the
        // bundle so the UI reflects the freshly-created revision.
        await loadSections()
        await loadComments()
        await loadFlags()
        await loadHistory()

        clearError()

        // Re-run the originally-requested op, if any. Capture and clear
        // the closure first so a re-throw in the op doesn't leave the
        // pending op hanging around.
        if let pending = pendingPackageOp {
            pendingPackageOp = nil
            await pending()
        }
    }

    /// Result of mdpal create: success or a typed CLIServiceError.
    /// Static so it can run before self.cliService is in a usable state.
    private enum CreateResult { case success; case failure(Error) }

    private static func runMdpalCreate(name: String, dir: String, content: String,
                                       runner: ProcessRunner = DefaultProcessRunner()) async -> CreateResult {
        // Resolve the binary the same way RealCLIService does — falls back
        // through MDPAL_BIN → PATH → /usr/local/bin/mdpal → /opt/homebrew/bin/mdpal.
        let executablePath: String
        do {
            executablePath = try CLIBinaryResolver.resolve()
        } catch {
            return .failure(CLIServiceError.cliNotFound)
        }

        // Go through ProcessRunner rather than hand-rolling Process here.
        // The previous inline implementation called readDataToEndOfFile()
        // from inside terminationHandler — that reads *after* the child has
        // exited and drains one pipe fully before the other, so a bundle
        // whose create output exceeds the pipe buffer (~64 KiB) deadlocks,
        // and nothing capped the read. DefaultProcessRunner drains both
        // pipes concurrently under a 32 MiB cap.
        //
        // `--` terminates option parsing so a bundle name that begins with
        // a dash is treated as the positional argument, not a flag.
        let result: ProcessResult
        do {
            result = try await runner.run(
                executable: executablePath,
                args: ["create", "--dir", dir, "--content", content, "--format", "json", "--", name],
                stdin: nil
            )
        } catch let err as CLIServiceError {
            return .failure(err)
        } catch {
            return .failure(CLIServiceError.executionFailed(
                exitCode: -1,
                stderr: "Failed to launch mdpal: \(error.localizedDescription)"))
        }

        guard result.exitCode != 0 else { return .success }

        let stdout = String(data: result.stdout, encoding: .utf8) ?? ""
        // Sanitize before the text can reach an alert — same treatment the
        // rest of the app gives CLI stderr.
        let stderr = result.stderrStringForUI

        // Try to parse the JSON envelope error; map invalidBundlePath
        // specifically, otherwise fall through to generic executionFailed.
        if let data = stdout.data(using: .utf8),
           let env = try? JSONDecoder().decode(CLIErrorResponse.self, from: data),
           env.error == "invalidBundlePath" {
            return .failure(CLIServiceError.invalidArgument(description: env.message))
        }
        return .failure(CLIServiceError.executionFailed(
            exitCode: Int(result.exitCode),
            stderr: stderr.isEmpty ? stdout : stderr))
    }

    /// Phase 2.6.3: switch to an existing .mdpal bundle without creating
    /// one. Used when sibling-bundle detection finds a `.mdpal` next to
    /// the .md the user opened, and the user clicks "Open as Package."
    /// Skips `mdpal create`; just swaps to RealCLIService and points at
    /// the bundle URL. The service swap and reload mirror promote().
    @MainActor
    public func openExistingBundle(at bundleURL: URL) async {
        guard cliService is PancakeCLIService else {
            recordError(CLIServiceError.invalidArgument(description: "Document is not in pancake mode"),
                        prefix: "Open as package")
            return
        }
        let path = bundleURL.path
        guard FileManager.default.fileExists(atPath: path) else {
            recordError(CLIServiceError.fileNotFound(path: path), prefix: "Open as package")
            return
        }

        do {
            let realService = try RealCLIService(
                environment: ProcessInfo.processInfo.environment,
                fileManager: .default,
                runner: DefaultProcessRunner()
            )
            self.cliService = realService
            self.bundlePath = BundlePath(path)
        } catch let err as CLIServiceError {
            recordError(err, prefix: "Open as package")
            return
        } catch {
            recordError(error, prefix: "Open as package")
            return
        }

        await loadSections()
        await loadComments()
        await loadFlags()
        await loadHistory()
        clearError()
    }

    // MARK: - Document Lifecycle

    /// Load a document from a bundle path.
    public func load(from bundle: BundlePath) async {
        bundlePath = bundle
        isDirty = false
        await loadSections()
        await loadComments()
        await loadFlags()
    }

    /// Load a document from raw content (Phase 1 — FileWrapper provides data).
    /// Phase 2 replaces this with bundle-based loading.
    ///
    /// Phase 2.6: push content into PancakeCLIService (or MockCLIService
    /// when explicitly mock-requested) so the read paths reflect the user's
    /// actual file. RealCLIService ignores this — it goes directly to the
    /// on-disk bundle.
    public func load(from content: String) async {
        rawContent = content
        isDirty = false
        if let pancake = cliService as? PancakeCLIService {
            pancake.setDocumentContent(content)
        } else if let mock = cliService as? MockCLIService {
            mock.setDocumentContent(content)
        }
        await loadSections()
        await loadComments()
        await loadFlags()
    }
}
