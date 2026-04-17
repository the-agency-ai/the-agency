// What Problem: Phase 1A shipped behind MockCLIService. Phase 1B wires the
// app to a real `mdpal` binary on disk. The protocol is the same; the seam
// is the runner. RealCLIService owns: (a) resolving the binary at init —
// fail-fast if absent, with a typed cliNotFound error the UI can surface;
// (b) holding the CLIProcess that dispatches every command. The nine
// protocol methods land in 1B.2–1B.4 against the dispatch #23 wire format
// (mdpal-cli #408 confirms #23 remains the target; CLI binary lands in
// mdpal-cli Phase 2).
//
// How & Why: One init does the binary resolution. Tests inject a fake
// FileManager + environment to drive resolver behavior, and a fake
// ProcessRunner to drive command behavior. Production calls the no-arg
// init which uses real env, real filesystem, real Process. Each CLI
// method follows the same pattern: assemble argv, run through CLIProcess,
// map non-zero exit → .executionFailed, decode JSON → typed response, map
// decode failure → .parseError. The `runCommand<T>` helper factors that
// shape so 1B.2–1B.4 methods stay short.
//
// Written: 2026-04-15 during Phase 1B.1 (real-CLI integration foundation)
// Updated: 2026-04-17 Phase 1B.2 — listSections implemented against
//          dispatch #23 wire format; runCommand<T> helper scoped to
//          non-typed-error read commands (1B.3+ adds typed-envelope
//          decoding for sectionNotFound/versionConflict/bundleConflict);
//          shared JSONDecoder with .iso8601 hoisted to forward-proof
//          Date decoding when Comment/Flag land in 1B.3
// Updated: 2026-04-17 Phase 1B.3 — readSection, listComments, listFlags
//          implemented. listComments/listFlags unwrap their list-response
//          types (CommentsResponse/FlagsResponse) before returning the
//          array. Comment/Flag timestamps exercise the shared iso8601
//          decoder end-to-end for the first time.
// Updated: 2026-04-17 Phase 1B.4 — editSection + typed-envelope mapping.
//          runCommandWithEnvelope<T> extends runCommand<T> with optional
//          stderr-envelope decoding: non-zero exit tries to decode
//          CLIErrorResponse from stderr and map recognized discriminators
//          to typed CLIServiceError cases (.versionConflict,
//          .sectionNotFound, .bundleConflict). Unrecognized / unparseable
//          stderr falls through to .executionFailed. Same hook supports
//          1B.5 mutation methods.
// Updated: 2026-04-17 Phase 1B.5 — remaining mutation methods:
//          addComment, resolveComment, flagSection, clearFlag. All nine
//          CLIServiceProtocol methods are now real. Slug-based mutations
//          (addComment, flagSection, clearFlag) map sectionNotFound
//          through the envelope; resolveComment keys off commentId and
//          just uses runCommand.
// Updated: 2026-04-17 Phase 1B.7 — addComment switched from
//          `--tags <csv>` to repeatable `--tag <value>` per mdpal-cli
//          Phase 2.3 resolution (dispatch #579). Sidesteps the comma-
//          encoding question.

import Foundation

/// Real CLI service backed by an on-disk `mdpal` binary. Resolves the
/// binary at construction time so the failure mode (cliNotFound) is
/// surfaced immediately, not on first command. 1B.2 implements
/// `listSections`; the remaining eight methods are stubbed pending their
/// own iterations.
public final class RealCLIService: CLIServiceProtocol, Sendable {
    /// The bound CLI process — executable path + runner. Immutable so the
    /// class is safely Sendable without the @unchecked escape hatch.
    private let cli: CLIProcess

    /// Shared JSON decoder. Uses `.iso8601` so Comment/Flag timestamps
    /// (Date-typed, per dispatch #23) decode correctly in 1B.3. Configured
    /// once here rather than per-call so every command goes through the
    /// same decode policy — a drift in one method can't silently mismatch
    /// another. JSONDecoder is Sendable with immutable configuration, so
    /// sharing across concurrent `decode` calls is safe.
    private static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    /// Production init: resolves binary from real environment + filesystem,
    /// uses real Foundation.Process. Throws `cliNotFound` if no `mdpal`
    /// binary is found anywhere on the resolution ladder.
    public convenience init() throws {
        try self.init(
            environment: ProcessInfo.processInfo.environment,
            fileManager: .default,
            runner: DefaultProcessRunner()
        )
    }

    /// Test seam: inject environment, filesystem, runner, and optional
    /// fallback list so resolution and command dispatch are fully
    /// deterministic — notably, tests can pass `fallbacks: []` to prevent
    /// the resolver from reaching a real mdpal at `/usr/local/bin` or
    /// `/opt/homebrew/bin` if the host has one installed.
    public init(
        environment: [String: String],
        fileManager: FileManager,
        runner: ProcessRunner,
        fallbacks: [String] = CLIBinaryResolver.defaultFallbacks
    ) throws {
        let executable = try CLIBinaryResolver.resolve(
            environment: environment,
            fileManager: fileManager,
            fallbacks: fallbacks
        )
        self.cli = CLIProcess(executable: executable, runner: runner)
    }

    // MARK: - Command dispatch helpers

    /// Run a CLI command and decode its stdout into the requested response
    /// type. The shape for `list*` / `read*` read commands:
    ///
    ///   1. Invoke the binary with the given args (no stdin unless passed).
    ///   2. Non-zero exit → `.executionFailed(exitCode, stderr)`. Typed
    ///      error-envelope parsing (sectionNotFound, versionConflict,
    ///      bundleConflict) is NOT done here — 1B.3+ mutation methods that
    ///      care about those envelopes will either (a) extend this helper
    ///      to optionally parse `CLIErrorResponse` from stderr, or (b)
    ///      wrap the stderr bytes themselves into typed errors. Do not
    ///      bolt typed-envelope decoding on without an iteration that
    ///      exercises the red/green cycle for each envelope.
    ///   3. JSON decode failure → `.parseError`.
    ///
    /// TODO(1B.x coordination): if `bundle.path` could start with `-`,
    /// prepend `"--"` to argv to avoid flag-confusion. Blocked on the
    /// actual mdpal CLI flag-parser behavior (mdpal-cli #408 — CLI
    /// unbuilt as of Phase 2).
    private func runCommand<T: Decodable>(
        _ args: [String],
        stdin: Data? = nil,
        as type: T.Type = T.self
    ) async throws -> T {
        let result = try await cli.run(args: args, stdin: stdin)
        guard result.exitCode == 0 else {
            throw CLIServiceError.executionFailed(
                exitCode: Int(result.exitCode),
                stderr: result.stderrStringForUI
            )
        }
        return try Self.decodeStdoutOrThrowParseError(T.self, from: result.stdout)
    }

    /// Variant of `runCommand<T>` that attempts typed-error-envelope
    /// decoding on non-zero exit. Used by 1B.4+ methods where the CLI
    /// signals distinct failure modes (versionConflict, sectionNotFound,
    /// bundleConflict) via structured stderr per dispatch #23.
    ///
    /// Behaviour:
    ///   - exit == 0 → decode stdout into T (same as runCommand<T>).
    ///   - exit != 0 AND stderr parses as a CLIErrorResponse envelope
    ///     AND `envelopeMapper` returns a typed error for it → throw
    ///     that typed error.
    ///   - exit != 0 AND stderr isn't envelope-shaped, OR the mapper
    ///     returns nil → fall through to `.executionFailed(exitCode:,
    ///     stderr:)` with the raw bytes.
    ///
    /// `envelopeMapper` lets each caller decide which envelope kinds it
    /// cares about — editSection maps `versionConflict`, readSection
    /// maps `sectionNotFound`, revisioning methods would map
    /// `bundleConflict`. Unrecognized kinds deliberately fall through
    /// rather than getting forced into a typed case prematurely.
    private func runCommandWithEnvelope<T: Decodable>(
        _ args: [String],
        stdin: Data? = nil,
        as type: T.Type = T.self,
        envelopeMapper: (CLIErrorResponse) -> CLIServiceError?
    ) async throws -> T {
        let result = try await cli.run(args: args, stdin: stdin)
        if result.exitCode != 0 {
            if let envelope = try? Self.decoder.decode(CLIErrorResponse.self, from: result.stderr),
               let mapped = envelopeMapper(envelope) {
                throw mapped
            }
            throw CLIServiceError.executionFailed(
                exitCode: Int(result.exitCode),
                stderr: result.stderrStringForUI
            )
        }
        return try Self.decodeStdoutOrThrowParseError(T.self, from: result.stdout)
    }

    /// Shared stdout-decode step. Both runCommand variants route success
    /// through here so a future change to the parseError wording or
    /// decoder config lands in one place.
    private static func decodeStdoutOrThrowParseError<T: Decodable>(
        _ type: T.Type,
        from stdout: Data
    ) throws -> T {
        do {
            return try decoder.decode(T.self, from: stdout)
        } catch {
            throw CLIServiceError.parseError(
                description: "decode \(T.self): \(error.localizedDescription)"
            )
        }
    }

    // MARK: - Read-side commands (Phase 1B.2)

    /// Maps to `mdpal sections <bundle>`. Wire format per dispatch #23:
    /// `{ "sections": [SectionTreeNode], "count": Int, "versionId": String }`
    /// where each node has `children: [SectionTreeNode]`. Service flattens
    /// the tree depth-first so views render a single list.
    ///
    /// `response.count` and `response.versionId` are discarded here because
    /// `CLIServiceProtocol.listSections` returns `[SectionTreeNode]`.
    /// When the `DocumentModel` wants the bundle version (e.g. to detect
    /// stale reads), it gets it from `readSection`'s versionId field or a
    /// future `bundleInfo` call — not from this seam.
    public func listSections(bundle: BundlePath) async throws -> [SectionTreeNode] {
        let response = try await runCommand(
            ["sections", bundle.path],
            as: SectionsResponse.self
        )
        return response.flattened()
    }

    /// Maps to `mdpal read <slug> <bundle>`. Wire format per dispatch #23:
    /// flat Section payload — `slug`, `heading`, `level`, `content`,
    /// `versionHash`, `versionId`. No wrapper to unwrap.
    ///
    /// Typed error: CLI signals section-not-found via exit 3 +
    /// `{"error":"sectionNotFound","details":{"slug":"...", "availableSlugs":[...]}}`.
    /// 1B.4 migrated this method to `runCommandWithEnvelope` so the typed
    /// `.sectionNotFound(slug:, availableSlugs:)` lands in the error surface
    /// instead of the generic `.executionFailed` path. Unrecognized
    /// stderr falls through to `.executionFailed` as before.
    public func readSection(slug: String, bundle: BundlePath) async throws -> Section {
        try await runCommandWithEnvelope(
            ["read", slug, bundle.path],
            as: Section.self,
            envelopeMapper: { envelope in
                switch (envelope.error, envelope.details) {
                case ("sectionNotFound", .some(.sectionNotFound(let s, let available))):
                    return .sectionNotFound(slug: s, availableSlugs: available)
                default:
                    // tag unrecognized, or tag recognized but details fell
                    // through to .generic (malformed envelope) — let the
                    // raw stderr surface via .executionFailed.
                    return nil
                }
            }
        )
    }

    /// Maps to `mdpal comments <bundle>`. Wire format per dispatch #23:
    /// `{ "comments": [Comment], "count": Int, "filters": CommentsFilters }`.
    /// Service unwraps the response to just the `comments` array; `count`
    /// and `filters` are discarded by the protocol contract. When server-
    /// side filtering is needed (1B.x), this method grows optional filter
    /// parameters that translate to argv (`--section`, `--type`,
    /// `--resolved`, `--unresolved`).
    ///
    /// Comment timestamps decode as Date via the shared iso8601 decoder;
    /// the decoder config was hoisted in 1B.2 specifically to handle this.
    public func listComments(bundle: BundlePath) async throws -> [Comment] {
        let response = try await runCommand(
            ["comments", bundle.path],
            as: CommentsResponse.self
        )
        return response.comments
    }

    /// Maps to `mdpal flags <bundle>`. Wire format per dispatch #23:
    /// `{ "flags": [Flag], "count": Int }`. Service unwraps to the array.
    /// Flag timestamps decode as Date via the shared iso8601 decoder.
    public func listFlags(bundle: BundlePath) async throws -> [Flag] {
        let response = try await runCommand(
            ["flags", bundle.path],
            as: FlagsResponse.self
        )
        return response.flags
    }

    // MARK: - Mutation: editSection (Phase 1B.4)

    /// Maps to `mdpal edit <slug> --version <hash> <bundle> --stdin`,
    /// with the new content fed on stdin.
    ///
    /// Wire format per dispatch #23:
    /// - Success (exit 0): JSON EditResult with new `versionHash`,
    ///   `versionId`, and `bytesWritten`.
    /// - versionConflict (exit 2): stderr envelope
    ///   `{ "error":"versionConflict", "details":{ slug, expectedHash,
    ///   currentHash, currentContent, versionId } }` → maps to typed
    ///   `.versionConflict(slug:, expectedHash:, currentHash:)`.
    ///   (The protocol's case drops `currentContent` and `versionId`;
    ///   DocumentModel fetches the current content via readSection on
    ///   retry. The richer fields stay on `CLIErrorDetails` for later
    ///   use.)
    /// - Other non-zero → `.executionFailed` (bundleConflict +
    ///   sectionNotFound would be mapped here if they were expected
    ///   from `edit`; they aren't per the spec, so falling through is
    ///   correct).
    public func editSection(
        slug: String,
        content: String,
        versionHash: String,
        bundle: BundlePath
    ) async throws -> EditResult {
        try await runCommandWithEnvelope(
            ["edit", slug, "--version", versionHash, bundle.path, "--stdin"],
            stdin: Data(content.utf8),
            as: EditResult.self,
            envelopeMapper: { envelope in
                switch (envelope.error, envelope.details) {
                case ("versionConflict",
                      .some(.versionConflict(let s, let expected, let current, _, _))):
                    return .versionConflict(
                        slug: s,
                        expectedHash: expected,
                        currentHash: current
                    )
                default:
                    // Unrecognized tag, OR tag matches but details shape
                    // doesn't (malformed envelope fell through to .generic):
                    // let the raw stderr surface via .executionFailed so
                    // the UI still shows something diagnostic.
                    return nil
                }
            }
        )
    }

    // MARK: - Mutations (Phase 1B.5)

    /// Maps slug-based mutation envelopes to typed `.sectionNotFound`.
    /// Used by addComment, flagSection, clearFlag. Unrecognized or
    /// wrong-shape envelopes fall through to .executionFailed.
    private static let sectionNotFoundMapper: (CLIErrorResponse) -> CLIServiceError? = { envelope in
        switch (envelope.error, envelope.details) {
        case ("sectionNotFound", .some(.sectionNotFound(let slug, let available))):
            return .sectionNotFound(slug: slug, availableSlugs: available)
        default:
            return nil
        }
    }

    /// Maps to `mdpal comment <slug> <bundle> --type <type> --author <author> --text <text>
    /// [--context <text>] [--priority <low|normal|high>] [--tags <comma-separated>]`.
    ///
    /// Always emits `--priority`; emits `--context` only if non-nil;
    /// emits `--tags` only if non-empty (CLI treats absent tags as []).
    public func addComment(
        slug: String,
        bundle: BundlePath,
        type: CommentType,
        author: String,
        text: String,
        context: String?,
        priority: Priority,
        tags: [String]
    ) async throws -> Comment {
        var args: [String] = [
            "comment", slug, bundle.path,
            "--type", type.rawValue,
            "--author", author,
            "--text", text,
            "--priority", priority.rawValue,
        ]
        if let context {
            args.append(contentsOf: ["--context", context])
        }
        // Per mdpal-cli #579: CLI takes repeatable `--tag <value>` (one
        // flag per tag), not a comma-separated `--tags` list. This
        // sidesteps the comma-encoding question that dispatch #23 left
        // open. Empty strings are filtered so `tags = [""]` doesn't
        // render as `--tag ""`.
        for tag in tags where !tag.isEmpty {
            args.append(contentsOf: ["--tag", tag])
        }
        return try await runCommandWithEnvelope(
            args, as: Comment.self, envelopeMapper: Self.sectionNotFoundMapper
        )
    }

    /// Maps to `mdpal resolve <commentId> <bundle> --response <text> --by <author>`.
    /// Keyed off commentId, not slug. Per mdpal-cli #579, the CLI emits
    /// `{ "error":"commentNotFound", "details":{ "commentId": ... } }`
    /// at exit 3 when the commentId doesn't exist — this method maps
    /// that envelope to typed `.commentNotFound(commentId:)` so the UI
    /// can render a useful message. Unrecognized / wrong-shape envelopes
    /// fall through to `.executionFailed`.
    public func resolveComment(
        commentId: String,
        bundle: BundlePath,
        response: String,
        by: String
    ) async throws -> ResolveResult {
        try await runCommandWithEnvelope(
            ["resolve", commentId, bundle.path, "--response", response, "--by", by],
            as: ResolveResult.self,
            envelopeMapper: { envelope in
                switch (envelope.error, envelope.details) {
                case ("commentNotFound", .some(.commentNotFound(let id))):
                    return .commentNotFound(commentId: id)
                default:
                    return nil
                }
            }
        )
    }

    /// Maps to `mdpal flag <slug> <bundle> --author <author> [--note <text>]`.
    /// Emits `--note` only if non-nil (omitting the flag is the spec's
    /// "no note" signal).
    public func flagSection(
        slug: String,
        bundle: BundlePath,
        author: String,
        note: String?
    ) async throws -> FlagResult {
        var args = ["flag", slug, bundle.path, "--author", author]
        if let note {
            args.append(contentsOf: ["--note", note])
        }
        return try await runCommandWithEnvelope(
            args, as: FlagResult.self, envelopeMapper: Self.sectionNotFoundMapper
        )
    }

    /// Maps to `mdpal clear-flag <slug> <bundle>`.
    public func clearFlag(slug: String, bundle: BundlePath) async throws -> ClearFlagResult {
        try await runCommandWithEnvelope(
            ["clear-flag", slug, bundle.path],
            as: ClearFlagResult.self,
            envelopeMapper: Self.sectionNotFoundMapper
        )
    }

    // MARK: - Persistence (Phase 1C.3)

    /// Maps `bundleConflict` envelopes to typed `.bundleConflict`. Shared
    /// by revision-creation (the only 1C command that emits it in dispatch
    /// #23's spec; extend when more consumers land).
    private static let bundleConflictMapper: (CLIErrorResponse) -> CLIServiceError? = { envelope in
        switch (envelope.error, envelope.details) {
        case ("bundleConflict", .some(.bundleConflict(let base, let current))):
            return .bundleConflict(baseRevision: base, currentRevision: current)
        default:
            return nil
        }
    }

    /// Maps to `mdpal revision create <bundle> --stdin [--base-revision <versionId>]`.
    /// `--base-revision` enables optimistic concurrency: if the current
    /// latest has drifted past the caller's anchor, the CLI emits exit 4
    /// with a bundleConflict envelope.
    public func createRevision(
        bundle: BundlePath,
        content: String,
        baseRevision: String?
    ) async throws -> RevisionInfo {
        var args = ["revision", "create", bundle.path, "--stdin"]
        if let baseRevision {
            args.append(contentsOf: ["--base-revision", baseRevision])
        }
        return try await runCommandWithEnvelope(
            args,
            stdin: Data(content.utf8),
            as: RevisionInfo.self,
            envelopeMapper: Self.bundleConflictMapper
        )
    }

    /// Maps to `mdpal history <bundle>`. Service unwraps HistoryResponse
    /// to just the revision array; `count` and `currentVersion` are
    /// derivable from the array but mdpal-cli computes them once, so if
    /// the UI needs them later we can expose via a sibling method.
    public func listHistory(bundle: BundlePath) async throws -> [RevisionInfo] {
        let response = try await runCommand(
            ["history", bundle.path],
            as: HistoryResponse.self
        )
        return response.revisions
    }

    /// Maps to `mdpal version show <bundle>`.
    public func showVersion(bundle: BundlePath) async throws -> VersionInfo {
        try await runCommand(
            ["version", "show", bundle.path],
            as: VersionInfo.self
        )
    }

    /// Maps to `mdpal version bump <bundle>`. Returns both the new
    /// version and the previous one for UX feedback.
    public func bumpVersion(bundle: BundlePath) async throws -> VersionBumpResult {
        try await runCommand(
            ["version", "bump", bundle.path],
            as: VersionBumpResult.self
        )
    }

    /// The resolved binary path, exposed for diagnostics/tests.
    public var executablePath: String { cli.executable }
}
