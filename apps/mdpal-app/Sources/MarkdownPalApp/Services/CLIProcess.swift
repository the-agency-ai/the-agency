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
        let cap = maxOutputBytes
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                Self.runBlocking(executable: executable, args: args,
                                 stdin: stdin, maxBytes: cap,
                                 continuation: continuation)
            }
        }
        // NOTE: Task cancellation does not currently terminate the child
        // process. Adding that requires threading a Process handle into a
        // withTaskCancellationHandler onCancel closure; deferred to a later
        // 1B iteration when the first cancellable command surfaces.
    }

    private static func runBlocking(
        executable: String,
        args: [String],
        stdin: Data?,
        maxBytes: Int,
        continuation: CheckedContinuation<ProcessResult, Error>
    ) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = args

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
        let lock = NSLock()
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
            lock.lock()
            stdoutData = local
            stdoutTruncated = truncated
            lock.unlock()
            drainGroup.leave()
        }
        drainGroup.enter()
        drainQueue.async {
            var local = Data()
            var truncated = false
            drain(from: stderrPipe.fileHandleForReading,
                  into: &local, maxBytes: maxBytes, truncated: &truncated)
            lock.lock()
            stderrData = local
            stderrTruncated = truncated
            lock.unlock()
            drainGroup.leave()
        }

        do {
            try process.run()
        } catch {
            continuation.resume(throwing: CLIServiceError.executionFailed(
                exitCode: -1,
                stderr: "Failed to launch \(executable): \(error.localizedDescription)"
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

        lock.lock()
        let outData = stdoutData
        var errData = stderrData
        let outTrunc = stdoutTruncated
        let errTrunc = stderrTruncated
        lock.unlock()
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
        let pathEntries = (environment["PATH"] ?? "").split(separator: ":").map(String.init)
        for entry in pathEntries where !entry.isEmpty {
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
