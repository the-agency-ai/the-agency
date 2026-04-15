// What Problem: Phase 1A shipped behind MockCLIService. Phase 1B wires the
// app to a real `mdpal` binary on disk. The protocol is the same; the seam
// is the runner. RealCLIService owns: (a) resolving the binary at init —
// fail-fast if absent, with a typed cliNotFound error the UI can surface;
// (b) holding the CLIProcess that dispatches every command. The nine
// protocol methods land in 1B.2–1B.4 once mdpal-cli confirms wire format
// (#407).
//
// How & Why: One init does the binary resolution. Tests inject a fake
// FileManager + environment to drive resolver behavior, and a fake
// ProcessRunner to drive command behavior. Production calls the no-arg
// init which uses real env, real filesystem, real Process. Method bodies
// are placeholder throws — the harness compiles and tests prove the init
// path; real wiring is the next iteration.
//
// Written: 2026-04-15 during Phase 1B.1 (real-CLI integration foundation)

import Foundation

/// Real CLI service backed by an on-disk `mdpal` binary. Resolves the
/// binary at construction time so the failure mode (cliNotFound) is
/// surfaced immediately, not on first command. Method bodies are stubs
/// pending wire-format confirmation in #407 (Phase 1B.2+).
public final class RealCLIService: CLIServiceProtocol, Sendable {
    /// The bound CLI process — executable path + runner. Immutable so the
    /// class is safely Sendable without the @unchecked escape hatch.
    private let cli: CLIProcess

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

    /// Test seam: inject environment, filesystem, and runner so resolution
    /// and command dispatch are fully deterministic.
    public init(
        environment: [String: String],
        fileManager: FileManager,
        runner: ProcessRunner
    ) throws {
        let executable = try CLIBinaryResolver.resolve(
            environment: environment,
            fileManager: fileManager
        )
        self.cli = CLIProcess(executable: executable, runner: runner)
    }

    // MARK: - Protocol stubs (Phase 1B.2+ — wire format pending #407)

    private func notYetImplemented(_ method: String) -> CLIServiceError {
        .executionFailed(
            exitCode: -1,
            stderr: "RealCLIService.\(method) is Phase 1B.2+ — awaiting #407 wire format"
        )
    }

    public func listSections(bundle: BundlePath) async throws -> [SectionTreeNode] {
        throw notYetImplemented("listSections")
    }

    public func readSection(slug: String, bundle: BundlePath) async throws -> Section {
        throw notYetImplemented("readSection")
    }

    public func editSection(slug: String, content: String,
                            versionHash: String, bundle: BundlePath) async throws -> EditResult {
        throw notYetImplemented("editSection")
    }

    public func listComments(bundle: BundlePath) async throws -> [Comment] {
        throw notYetImplemented("listComments")
    }

    public func listFlags(bundle: BundlePath) async throws -> [Flag] {
        throw notYetImplemented("listFlags")
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
