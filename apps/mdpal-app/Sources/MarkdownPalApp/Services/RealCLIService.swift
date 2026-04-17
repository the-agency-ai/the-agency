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
                stderr: result.stderrString
            )
        }
        do {
            return try Self.decoder.decode(T.self, from: result.stdout)
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
    /// The CLI signals section-not-found via exit 3 + structured stderr
    /// `{"error":"sectionNotFound","details":{"slug":"...", "availableSlugs":[...]}}`.
    /// For 1B.3 that surfaces as the generic `.executionFailed(3, stderr)`;
    /// typed `.sectionNotFound(slug:, availableSlugs:)` mapping lands in
    /// 1B.4 alongside editSection's versionConflict envelope — same
    /// stderr-envelope machinery covers both. 1B.3 ships
    /// `.executionFailed` so DocumentModel's error path is wired now;
    /// 1B.4 swaps the case without churning call sites.
    public func readSection(slug: String, bundle: BundlePath) async throws -> Section {
        try await runCommand(
            ["read", slug, bundle.path],
            as: Section.self
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

    // MARK: - Protocol stubs (land in 1B.4–1B.5)

    private func notYetImplemented(_ method: String) -> CLIServiceError {
        .executionFailed(
            exitCode: -1,
            stderr: "RealCLIService.\(method) is not yet implemented"
        )
    }

    public func editSection(slug: String, content: String,
                            versionHash: String, bundle: BundlePath) async throws -> EditResult {
        throw notYetImplemented("editSection")
    }

    public func addComment(slug: String, bundle: BundlePath, type: CommentType,
                           author: String, text: String, context: String?,
                           priority: Priority, tags: [String]) async throws -> Comment {
        throw notYetImplemented("addComment")
    }

    public func resolveComment(commentId: String, bundle: BundlePath,
                               response: String, by: String) async throws -> ResolveResult {
        throw notYetImplemented("resolveComment")
    }

    public func flagSection(slug: String, bundle: BundlePath,
                            author: String, note: String?) async throws -> FlagResult {
        throw notYetImplemented("flagSection")
    }

    public func clearFlag(slug: String, bundle: BundlePath) async throws -> ClearFlagResult {
        throw notYetImplemented("clearFlag")
    }

    /// The resolved binary path, exposed for diagnostics/tests.
    public var executablePath: String { cli.executable }
}
