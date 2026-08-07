// What Problem: RealCLIService needs to invoke the mdpal binary, send it
// optional stdin, and read back stdout/stderr/exit-code. Doing this
// directly with Foundation.Process scattered across nine command methods
// would (a) make the service untestable without a real binary on disk,
// and (b) duplicate the same plumbing nine times.
//
// How & Why: One choke point. `ProcessRunner` is the substitutable seam:
// production wires `DefaultProcessRunner` (Foundation.Process); tests
// wire `FakeProcessRunner` (returns canned ProcessResult). `CLIProcess`
// composes a runner + binary path and exposes one `run(args:stdin:)`
// method. Everything that knows about file descriptors, pipes, and
// process spawning lives here — RealCLIService stays pure: argv
// assembly + JSON decode + error mapping.
//
// Phase 1B.1 scope: the runner abstraction + binary resolution. The
// command methods on RealCLIService land in 1B.2–1B.4 once mdpal-cli
// confirms wire format (#407).
//
// Written: 2026-04-15 during Phase 1B.1 (real-CLI integration foundation)

import Foundation

/// One CLI invocation's outcome.
public struct ProcessResult: Sendable, Equatable {
    public let exitCode: Int32
    public let stdout: Data
    public let stderr: Data

    public init(exitCode: Int32, stdout: Data, stderr: Data) {
        self.exitCode = exitCode
        self.stdout = stdout
        self.stderr = stderr
    }

    /// Convenience: stdout decoded as UTF-8 (lossy fallback to empty).
    public var stdoutString: String {
        String(data: stdout, encoding: .utf8) ?? ""
    }

    /// Convenience: stderr decoded as UTF-8 (lossy fallback to empty).
    public var stderrString: String {
        String(data: stderr, encoding: .utf8) ?? ""
    }

    /// stderr decoded and sanitized for UI display: strips ANSI CSI
    /// sequences and C0 control chars (except newline/tab/CR), and
    /// caps length at 4096 chars with an ellipsis. Use this for alert
    /// strings sourced from `.executionFailed(stderr:)` — a malicious or
    /// mistaken binary writing `\u{1B}[2J\u{1B}[H` (clear screen + home)
    /// or similar control sequences shouldn't hijack UI rendering.
    /// Internal envelope parsing keeps using the raw `stderr` bytes.
    public var stderrStringForUI: String {
        Self.sanitizeForUI(stderrString)
    }

    /// ANSI/control sanitization + length cap. Exposed as `internal` only
    /// for testability; not part of the public API surface.
    static func sanitizeForUI(_ s: String) -> String {
        // Strip ANSI CSI sequences: ESC `[` + 0..n params + intermediates + final byte.
        // Hand-roll the tiny state machine instead of a regex — NSRegularExpression's
        // Swift-literal escape rules bite repeatedly, and the CSI grammar is small.
        //
        // CSI = ESC `[` + (param-byte: 0x30-0x3F)* + (intermediate-byte: 0x20-0x2F)* + (final-byte: 0x40-0x7E)
        var output = String.UnicodeScalarView()
        output.reserveCapacity(s.unicodeScalars.count)
        var it = s.unicodeScalars.makeIterator()
        while let ch = it.next() {
            if ch.value == 0x1B { // ESC
                // Peek next. If it's `[` we have a CSI; otherwise emit literal ESC.
                if let next = it.next() {
                    if next.value == 0x5B { // `[`
                        // Consume param, intermediate, then final byte — or EOF.
                        var finished = false
                        while !finished, let inner = it.next() {
                            let v = inner.value
                            if (0x40...0x7E).contains(v) {
                                finished = true // final byte consumed; skip emitting
                            } else if (0x20...0x3F).contains(v) {
                                continue // param / intermediate — keep skipping
                            } else {
                                // Not a CSI body char — re-emit it and stop the CSI walk.
                                // (Shouldn't happen in well-formed streams but we don't
                                // want to silently drop non-CSI data.)
                                output.append(inner)
                                finished = true
                            }
                        }
                    } else {
                        // ESC followed by non-`[` — drop both (rare; other single-char
                        // escapes like SGR reset are uncommon in CLI output).
                        _ = next
                    }
                }
                continue
            }
            // Strip C0 control chars except \t (0x09), \n (0x0A), \r (0x0D).
            let v = ch.value
            if v >= 0x20 || v == 0x09 || v == 0x0A || v == 0x0D {
                output.append(ch)
            }
        }
        let cleaned = String(output)
        if cleaned.count > 4096 {
            return String(cleaned.prefix(4096)) + "… (truncated)"
        }
        return cleaned
    }
}

/// Phase 2.5: thread-safe handle to a `Process` that a cancellation
/// closure can reach to send SIGTERM. Independent of `runBlocking`'s
/// drain-side `NSLock` — `onCancel` runs on arbitrary threads and must
/// not block on drain-side locks; a dedicated small lock avoids that
/// deadlock class.
///
/// Lifecycle:
///   1. `set(process)` before `process.run()` — cancellation that arrives
///      during spawn terminates as soon as the kernel hands us a pid.
///   2. `terminateIfRunning()` from `onCancel` — no-op if set() hasn't
///      fired yet (spawn failure, or cancel-before-spawn).
///   3. `clear()` in `defer` at end of `runBlocking` — prevents a post-exit
///      terminate() on a dead Process.
///
/// `@unchecked Sendable` is acceptable here: internal state is guarded by
/// `lock`, and we never publish the process outside these three entry
/// points.
final class ProcessHolder: @unchecked Sendable {
    private let lock = NSLock()
    private var process: Process?
    private var cancelled: Bool = false

    func set(_ process: Process) {
        lock.lock()
        self.process = process
        lock.unlock()
    }

    func clear() {
        lock.lock()
        self.process = nil
        lock.unlock()
    }

    /// Whether onCancel has fired. Cleared never — this is a one-way flag
    /// per ProcessHolder instance (one flag per CLI invocation).
    /// Runner's runBlocking checks this before spawning to short-circuit
    /// cancel-before-spawn races.
    var isCancelled: Bool {
        lock.lock()
        defer { lock.unlock() }
        return cancelled
    }

    /// Handle cancellation — sets the flag AND sends SIGTERM if a process
    /// is set. Both steps are needed:
    /// - The flag closes the cancel-before-spawn race (F-Cd-1): runBlocking
    ///   checks it and short-circuits without spawning.
    /// - terminate() handles the spawned-and-running case: SIGTERM interrupts
    ///   the child so waitUntilExit returns promptly.
    ///
    /// Phase 2.5 QG fix (F-Cd-2): no `isRunning` guard. `Process.terminate()`
    /// on Darwin safely handles not-yet-run and already-exited Processes
    /// (no throw, no crash; best-effort SIGTERM dispatch).
    func handleCancellation() {
        lock.lock()
        cancelled = true
        let p = self.process
        lock.unlock()
        // Call terminate() without holding the lock: Process.terminate()
        // can block briefly on kernel syscall, and holding the lock would
        // stall a concurrent `set`/`clear` from runBlocking's defer.
        p?.terminate()
    }
}

/// The substitutable seam. Production uses `DefaultProcessRunner`; tests
/// inject a fake to drive scripted outcomes.
public protocol ProcessRunner: Sendable {
    /// Launch `executable` with `args`, optionally feeding `stdin`, and
    /// return the captured outcome. Implementations MUST NOT throw on
    /// non-zero exit codes — that's the caller's policy decision.
    func run(executable: String, args: [String], stdin: Data?) async throws -> ProcessResult
}

/// Production runner backed by Foundation.Process. Spawns the binary,
/// pipes stdout/stderr, optionally writes stdin, waits to completion.
public struct DefaultProcessRunner: ProcessRunner {
    /// Max bytes to retain per stream (stdout and stderr each, separately).
    /// Default 32 MiB — mdpal responses are JSON at kilobyte scale, so a
    /// child producing more is either pathological or malicious. Past the
    /// cap, further bytes are drained-and-dropped (so the producer doesn't
    /// deadlock) and a truncation marker is appended to stderr.
    public let maxOutputBytes: Int

    public init(maxOutputBytes: Int = 32 * 1024 * 1024) {
        self.maxOutputBytes = maxOutputBytes
    }

    public func run(executable: String, args: [String], stdin: Data?) async throws -> ProcessResult {
        // Run the synchronous Process work off the cooperative pool. waitUntilExit
        // and the drain wait both block; doing them on a Swift concurrency thread
        // would starve the pool. DispatchQueue.global gives us a dedicated worker.
        //
        // Phase 2.5 — task cancellation → SIGTERM (A&D §10.6):
        // - withTaskCancellationHandler wraps the continuation.
        // - On cancel, `onCancel` closure calls process.terminate() on the
        //   shared ProcessHolder — sends SIGTERM. The child's natural exit
        //   flows through the drain + waitUntilExit path as usual.
        // - Observation budget: SIGTERM-to-exit expected within 500ms for
        //   well-behaved children (tested at the real-process level).
        // - **V1 policy (QG 2.5 F-Dt-1):** no 2s-backstop timer. If the child
        //   ignores SIGTERM indefinitely, waitUntilExit blocks the dispatch
        //   queue worker. A&D §10.6 names 2s as an informal upper bound; V1
        //   accepts that mdpal-cli is trusted and well-behaved (never
        //   ignores SIGTERM) — an adversarial child would require XPC
        //   sandboxing + OS-level enforcement (Phase 3 sandbox work). The
        //   decision is comment-only discipline: no code path exists that
        //   promotes SIGTERM → SIGKILL in V1.
        // - Lock discipline: ProcessHolder's lock is independent of the
        //   drain loop's NSLock (drainLock, named in QG 2.5 F-Dt-3).
        //   `onCancel` runs on an arbitrary thread and must not block
        //   waiting for drainLock — it just reads the Process handle and
        //   calls terminate().
        // - If the Task is cancelled, we throw CLIServiceError.cancelled
        //   AFTER the continuation resumes (so pipes drain + handles close),
        //   not mid-flight. The partial bytes are discarded per A&D §10.6.
        // - ProcessHolder is `@unchecked Sendable` class + NSLock rather
        //   than `actor` because `onCancel: () -> Void` is NOT async and
        //   cannot `await`. See ProcessHolder's class-header comment.
        let cap = maxOutputBytes
        let processHolder = ProcessHolder()

        let result = try await withTaskCancellationHandler(operation: {
            try await withCheckedThrowingContinuation { continuation in
                DispatchQueue.global(qos: .userInitiated).async {
                    Self.runBlocking(executable: executable, args: args,
                                     stdin: stdin, maxBytes: cap,
                                     holder: processHolder,
                                     continuation: continuation)
                }
            }
        }, onCancel: {
            // Arbitrary thread — must be brief + lock-disciplined.
            // Both sets the cancel flag (closes cancel-before-spawn race
            // via runBlocking's early check) AND sends SIGTERM to any
            // already-spawned child.
            processHolder.handleCancellation()
        })

        // Post-resume cancellation check. If Task was cancelled while the
        // child was running, the child received SIGTERM (via onCancel),
        // drains completed, result came through. Surface as .cancelled
        // rather than the raw exit code from the signal.
        if Task.isCancelled {
            throw CLIServiceError.cancelled
        }
        return result
    }

    private static func runBlocking(
        executable: String,
        args: [String],
        stdin: Data?,
        maxBytes: Int,
        holder: ProcessHolder,
        continuation: CheckedContinuation<ProcessResult, Error>
    ) {
        // Phase 2.5 QG fix (F-Cd-1): check holder.isCancelled before spawn.
        // If onCancel has already fired (cancel-before-spawn race), skip
        // the fork+exec entirely — spawning a child we're about to SIGTERM
        // is wasted wall clock.
        //
        // Phase 2 phase-complete QG (F-2): throw CLIServiceError.cancelled
        // into the continuation rather than return an empty-success
        // ProcessResult. Cleaner lifecycle: "cancelled means cancelled",
        // not "exit 0 with empty output." Eliminates a fragile dependency
        // on run()'s post-resume Task.isCancelled still being true at
        // resume time.
        //
        // Why holder.isCancelled instead of Task.isCancelled: the
        // DispatchQueue worker is NOT an async context, so Task.isCancelled
        // would read from whatever detached task runs the worker (nil),
        // not the outer async Task. The holder flag is explicitly set by
        // onCancel from the Task's cancellation context and is visible
        // here via lock-guarded read.
        if holder.isCancelled {
            continuation.resume(throwing: CLIServiceError.cancelled)
            return
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = args
        // Phase 2.5: register with the holder BEFORE process.run() so a
        // cancellation that arrives during spawn can terminate as soon as
        // the kernel hands us a pid. Register-then-clear pattern ensures
        // the holder never points at a dead process after waitUntilExit.
        holder.set(process)
        defer { holder.clear() }

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        let stdinPipe: Pipe?
        if stdin != nil {
            stdinPipe = Pipe()
            process.standardInput = stdinPipe
        } else {
            stdinPipe = nil
        }

        // Read pipes off the spawn thread to avoid deadlock on large output.
        // Foundation's pipe buffers are bounded (~64KB); if the child writes
        // more than that before we drain, it blocks. Reading via DispatchQueue
        // keeps the producer flowing while the process runs.
        //
        // Synchronization: writes to stdoutData/stderrData happen on drain
        // threads; reads happen after drainGroup.wait() (which establishes
        // happens-before via the dispatch_group leave/wait barrier). The
        // explicit lock below is belt-and-suspenders against future refactors
        // that might read these vars before the wait completes.
        //
        // Phase 2.5 QG fix (F-Dt-3): named `drainLock` to distinguish from
        // ProcessHolder's independent cancellation lock.
        let drainLock = NSLock()
        var stdoutData = Data()
        var stderrData = Data()
        var stdoutTruncated = false
        var stderrTruncated = false
        let drainGroup = DispatchGroup()
        let drainQueue = DispatchQueue(label: "CLIProcess.drain", attributes: .concurrent)

        // Bounded-drain helper: reads from the pipe until EOF, keeping
        // only the first `maxBytes` into the target and discarding the
        // rest so the producer doesn't block on a full pipe buffer.
        // `availableData` returns whatever the kernel buffered, then
        // returns empty at EOF. Returns true via `truncated` if any
        // data was dropped.
        func drain(
            from handle: FileHandle,
            into target: inout Data,
            maxBytes: Int,
            truncated: inout Bool
        ) {
            while true {
                let chunk = handle.availableData
                if chunk.isEmpty { return } // EOF
                if target.count < maxBytes {
                    let room = maxBytes - target.count
                    if chunk.count <= room {
                        target.append(chunk)
                    } else {
                        target.append(chunk.prefix(room))
                        truncated = true
                    }
                } else {
                    // Over cap: drop the chunk but mark truncated so the
                    // caller knows output was clipped.
                    truncated = true
                }
            }
        }

        drainGroup.enter()
        drainQueue.async {
            var local = Data()
            var truncated = false
            drain(from: stdoutPipe.fileHandleForReading,
                  into: &local, maxBytes: maxBytes, truncated: &truncated)
            drainLock.lock()
            stdoutData = local
            stdoutTruncated = truncated
            drainLock.unlock()
            drainGroup.leave()
        }
        drainGroup.enter()
        drainQueue.async {
            var local = Data()
            var truncated = false
            drain(from: stderrPipe.fileHandleForReading,
                  into: &local, maxBytes: maxBytes, truncated: &truncated)
            drainLock.lock()
            stderrData = local
            stderrTruncated = truncated
            drainLock.unlock()
            drainGroup.leave()
        }

        do {
            try process.run()
        } catch {
            // The executable path can contain the account name; it reaches
            // an alert body, so give it the same sanitize+cap treatment
            // every other CLI-sourced string gets before display.
            continuation.resume(throwing: CLIServiceError.executionFailed(
                exitCode: -1,
                stderr: ProcessResult.sanitizeForUI(
                    "Failed to launch \(executable): \(error.localizedDescription)")
            ))
            return
        }

        // Write stdin (if any) and close so the child sees EOF. A failure here
        // is captured and surfaced via stderr — the child may already have
        // exited (e.g. arg-parse failure), which is a normal race, but a hard
        // pipe error should still be visible to the caller for diagnostics.
        var stdinError: String?
        if let stdin, let stdinPipe {
            do {
                try stdinPipe.fileHandleForWriting.write(contentsOf: stdin)
                try stdinPipe.fileHandleForWriting.close()
            } catch {
                stdinError = "stdin write failed: \(error.localizedDescription)"
            }
        }

        process.waitUntilExit()
        drainGroup.wait()

        drainLock.lock()
        let outData = stdoutData
        var errData = stderrData
        let outTrunc = stdoutTruncated
        let errTrunc = stderrTruncated
        drainLock.unlock()
        if let stdinError {
            errData.append(Data("\n[CLIProcess] \(stdinError)\n".utf8))
        }
        if outTrunc {
            errData.append(Data("\n[CLIProcess] stdout truncated at \(maxBytes) bytes\n".utf8))
        }
        if errTrunc {
            errData.append(Data("\n[CLIProcess] stderr truncated at \(maxBytes) bytes\n".utf8))
        }

        continuation.resume(returning: ProcessResult(
            exitCode: process.terminationStatus,
            stdout: outData,
            stderr: errData
        ))
    }
}

/// Composes a runner with a resolved binary path. RealCLIService holds
/// one of these and calls `run(args:stdin:)` for every CLI invocation.
public struct CLIProcess: Sendable {
    public let executable: String
    private let runner: ProcessRunner

    public init(executable: String, runner: ProcessRunner = DefaultProcessRunner()) {
        self.executable = executable
        self.runner = runner
    }

    /// Run the bound binary with the given args and optional stdin.
    public func run(args: [String], stdin: Data? = nil) async throws -> ProcessResult {
        try await runner.run(executable: executable, args: args, stdin: stdin)
    }
}

// MARK: - Binary resolution

/// Resolves the mdpal CLI binary location. Precedence:
///   1. Explicit `MDPAL_BIN` environment variable (must be an executable file)
///   2. `PATH` lookup for `mdpal`
///   3. Common install locations (/usr/local/bin, /opt/homebrew/bin)
///
/// Returns the absolute path on success. Throws `CLIServiceError.cliNotFound`
/// when nothing usable is found.
///
/// `environment` and `fileManager` are injectable so tests can drive the
/// resolution deterministically without touching the real environment or
/// filesystem.
public enum CLIBinaryResolver {
    /// Default fallback locations searched after MDPAL_BIN and PATH miss.
    public static let defaultFallbacks = ["/usr/local/bin/mdpal", "/opt/homebrew/bin/mdpal"]

    public static func resolve(
        environment: [String: String] = ProcessInfo.processInfo.environment,
        fileManager: FileManager = .default,
        fallbacks: [String] = defaultFallbacks
    ) throws -> String {
        // 1. Explicit override.
        if let override = environment["MDPAL_BIN"], !override.isEmpty {
            if isExecutable(override, fileManager: fileManager) {
                return override
            }
            // An explicit override that points to nothing is a config error,
            // not a "look elsewhere" signal — surface it.
            throw CLIServiceError.cliNotFound
        }

        // 2. PATH lookup.
        // Only absolute PATH entries are honored. A relative entry (or the
        // empty-string entry that a trailing/doubled ':' produces, which
        // POSIX reads as "."), resolves against whatever directory the app
        // happens to be running in — an attacker who can drop a file named
        // `mdpal` into the user's working directory would get it executed.
        let pathEntries = (environment["PATH"] ?? "").split(separator: ":").map(String.init)
        for entry in pathEntries where entry.hasPrefix("/") {
            let candidate = (entry as NSString).appendingPathComponent("mdpal")
            if isExecutable(candidate, fileManager: fileManager) {
                return candidate
            }
        }

        // 3. Caller-supplied fallbacks (defaults to common install locations).
        for candidate in fallbacks where isExecutable(candidate, fileManager: fileManager) {
            return candidate
        }

        throw CLIServiceError.cliNotFound
    }

    private static func isExecutable(_ path: String, fileManager: FileManager) -> Bool {
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: path, isDirectory: &isDirectory),
              !isDirectory.boolValue else {
            return false
        }
        return fileManager.isExecutableFile(atPath: path)
    }
}
