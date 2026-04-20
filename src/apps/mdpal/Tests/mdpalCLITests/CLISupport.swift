// What Problem: Every CLI test needs to: (a) locate the built mdpal
// binary, (b) invoke it with arguments, (c) capture stdout, stderr,
// and exit code without deadlocking on large output, (d) clean up
// fixtures safely without removing unintended directories.
//
// How & Why: CLISupport provides four helpers — runCLI() launches a
// subprocess and concurrently drains both pipes (preventing the
// classic "child blocks on full pipe buffer while parent waits"
// deadlock); makeFixture() creates a fresh DocumentBundle in an
// isolated temp directory and returns a Fixture struct that captures
// the temp dir for safe cleanup; cleanup() removes only the captured
// temp dir.
//
// Written: 2026-04-17 during mdpal-cli session (Phase 2 iteration 2.1)

import Foundation
@testable import MarkdownPalEngine

enum CLISupport {

    /// Captured output of a single CLI invocation.
    struct Output {
        let stdout: String
        let stderr: String
        let exitCode: Int32
    }

    /// Locate the mdpal binary built into the SwiftPM build directory.
    /// Tests run after `swift build`, so the binary exists at
    /// `.build/{config}/mdpal`. We probe both debug and release.
    ///
    /// `MDPAL_BIN_DIR` env var overrides the search; if set, the binary
    /// MUST exist at `<MDPAL_BIN_DIR>/mdpal` and be executable, otherwise
    /// we throw a clear error so test failures don't masquerade as
    /// binary-not-found.
    static func binaryURL() throws -> URL {
        let env = ProcessInfo.processInfo.environment
        if let dir = env["MDPAL_BIN_DIR"] {
            let candidate = URL(fileURLWithPath: dir).appendingPathComponent("mdpal")
            guard FileManager.default.isExecutableFile(atPath: candidate.path) else {
                throw CLITestError.binaryEnvOverrideInvalid(path: candidate.path)
            }
            return candidate
        }

        // Walk up from CWD to find a .build directory, then probe debug/release.
        let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        var current: URL? = cwd
        while let dir = current {
            let buildDir = dir.appendingPathComponent(".build")
            if FileManager.default.fileExists(atPath: buildDir.path) {
                for config in ["debug", "release"] {
                    let candidate = buildDir.appendingPathComponent(config).appendingPathComponent("mdpal")
                    if FileManager.default.isExecutableFile(atPath: candidate.path) {
                        return candidate
                    }
                }
            }
            let parent = dir.deletingLastPathComponent()
            if parent.path == dir.path { break }
            current = parent
        }
        throw CLITestError.binaryNotFound
    }

    /// Default timeout for any single CLI invocation. 60s is well above
    /// any real command's wall-clock cost (the slowest path — prune of a
    /// 100-revision bundle with merge-forward — runs sub-second). A test
    /// that hangs against an unresponsive subprocess is a debugging
    /// nightmare; better to fail loudly with `Output(timedOut: true)`.
    static let defaultTimeoutSeconds: TimeInterval = 60

    /// Launch the mdpal binary with the given arguments. Captures stdout,
    /// stderr, and exit code. Synchronous — blocks until the process exits
    /// or the timeout elapses, whichever comes first.
    ///
    /// On timeout, the child is sent SIGTERM (then SIGKILL after a brief
    /// grace period) and the function throws `CLITestError.timedOut` so
    /// the test fails with an actionable signal instead of stalling for
    /// the full test-runner timeout. The default 60s ceiling is a soft
    /// safety net — most commands complete in <100ms.
    ///
    /// F4 (phase-complete, partial): pipes are drained via the Pipe's
    /// readabilityHandler callback, which fires as data arrives and on
    /// EOF. The prior implementation read both pipes synchronously AFTER
    /// waitUntilExit, which deadlocked when the child's stdout exceeded
    /// the Darwin pipe buffer (16-64 KiB). Wire-format goldens, `history`
    /// over a long bundle, and `diff` of large sections could hit that
    /// ceiling — the failure presented as a 60s watchdog kill rather
    /// than a meaningful test failure.
    ///
    /// We use readabilityHandler instead of a loop on readData(ofLength:)
    /// because the synchronous readData can stall in practice even with
    /// a closed write end (seen during phase-complete testing). The
    /// event-driven handler is the standard Foundation Pipe pattern and
    /// fires reliably on both data-available and EOF.
    ///
    /// The watchdog still kills the child on real timeout. On timeout
    /// we still return whatever bytes the readers buffered before the
    /// kill.
    static func runCLI(
        _ args: [String],
        stdin: String? = nil,
        timeoutSeconds: TimeInterval = defaultTimeoutSeconds,
        executableURL: URL? = nil,
        env: [String: String]? = nil
    ) throws -> Output {
        // T13 (phase-complete): the optional `executableURL` lets a test
        // exercise the real runCLI machinery (pipe drain + watchdog +
        // exit handling) against a guaranteed-hanging binary like
        // /bin/sleep, without forcing a hang scenario through the mdpal
        // binary itself. Production callers leave it nil; the resolver
        // falls back to the locally-built mdpal binary.
        //
        // Phase 3 iter 3.4: optional `env` lets a test override
        // environment variables (notably MDPAL_ROOT for sandbox tests)
        // without mutating the shared process environment. When nil,
        // child inherits parent's env; when set, child sees the
        // OVERLAY of parent env + these keys.
        let binary = try executableURL ?? binaryURL()

        let process = Process()
        process.executableURL = binary
        process.arguments = args
        if let env {
            var merged = ProcessInfo.processInfo.environment
            for (k, v) in env { merged[k] = v }
            process.environment = merged
        }

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        // F4: readabilityHandler-based pipe drain. The handler fires on
        // every write by the child, and once with empty data when the
        // child closes the pipe. Uses `availableData` which never blocks
        // on short reads — returns whatever bytes are currently in the
        // pipe buffer (or empty on EOF).
        let stdoutBuffer = DrainBuffer()
        let stderrBuffer = DrainBuffer()
        let stdoutDone = DispatchSemaphore(value: 0)
        let stderrDone = DispatchSemaphore(value: 0)

        stdoutPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            if data.isEmpty {
                // EOF. Clear the handler so it doesn't fire again
                // (Foundation sometimes double-fires) and signal done.
                handle.readabilityHandler = nil
                stdoutDone.signal()
            } else {
                stdoutBuffer.append(data)
            }
        }
        stderrPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            if data.isEmpty {
                handle.readabilityHandler = nil
                stderrDone.signal()
            } else {
                stderrBuffer.append(data)
            }
        }

        if let stdin {
            let stdinPipe = Pipe()
            process.standardInput = stdinPipe
            // Ignore SIGPIPE for this process. When the child reads its
            // stdin cap and exits, the pending parent write hits a
            // closed pipe; without SIG_IGN the parent gets SIGPIPE'd
            // which crashes the entire test runner. Foundation Process
            // doesn't manage this for us. Set once per launch — cheap
            // and idempotent across calls.
            signal(SIGPIPE, SIG_IGN)
            try process.run()
            // Write stdin on a background queue so the test waits on
            // the child's exit, not on the kernel pipe buffer draining.
            // Errors from write (EPIPE when child closes early) are
            // intentionally swallowed — the main assertion is that the
            // child surfaces payloadTooLarge, not that we delivered the
            // full payload.
            let payload = Data(stdin.utf8)
            let stdinHandle = stdinPipe.fileHandleForWriting
            DispatchQueue.global(qos: .utility).async {
                // Try to write; if the child closed early we get a
                // broken-pipe error which write() throws. Catch and
                // ignore — the test's assertion is about the child's
                // response, not our delivery success.
                try? stdinHandle.write(contentsOf: payload)
                try? stdinHandle.close()
            }
        } else {
            try process.run()
        }

        // Watchdog using DispatchWorkItem.cancel(): if the process exits
        // BEFORE the deadline, we cancel the watchdog and it never runs.
        // If the deadline fires first, the watchdog terminates the
        // process and sets `didTimeOut`. Simpler than the prior semaphore
        // dance and eliminates the spurious-timeout race window where
        // the watchdog could fire just as the process exited cleanly.
        let didTimeOutLock = NSLock()
        var didTimeOut = false
        let watchdog = DispatchWorkItem { [weak process] in
            guard let process else { return }
            guard process.isRunning else { return }
            process.terminate()
            // Grace period for SIGTERM to take effect, then escalate.
            DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) { [weak process] in
                guard let process, process.isRunning else { return }
                kill(process.processIdentifier, SIGKILL)
            }
            didTimeOutLock.lock()
            didTimeOut = true
            didTimeOutLock.unlock()
        }
        DispatchQueue.global(qos: .userInitiated)
            .asyncAfter(deadline: .now() + timeoutSeconds, execute: watchdog)

        process.waitUntilExit()
        // Cancel the watchdog AFTER waitUntilExit returns. If the work
        // item already started executing it's a no-op; if it hasn't,
        // .cancel() prevents it from running at all.
        watchdog.cancel()

        // Wait for both pipe-drain readers to finish. They signal when
        // the child closed its end (which happens at process exit), so
        // this wait is bounded by the child's lifetime. A 5-second
        // ceiling protects against pathological cases where the
        // readabilityHandler doesn't fire on EOF (rare Foundation
        // edge case); we accept whatever bytes were captured to that
        // point and return.
        let drainDeadline = DispatchTime.now() + 5.0
        _ = stdoutDone.wait(timeout: drainDeadline)
        _ = stderrDone.wait(timeout: drainDeadline)
        // Clear handlers regardless — defensive against any handler
        // still alive after the timeout.
        stdoutPipe.fileHandleForReading.readabilityHandler = nil
        stderrPipe.fileHandleForReading.readabilityHandler = nil

        didTimeOutLock.lock()
        let timedOut = didTimeOut
        didTimeOutLock.unlock()
        if timedOut {
            // T13 (phase-complete): the prior code returned bytes that
            // the post-exit reads hadn't drained — racing whatever
            // signals were in flight. With the concurrent drainer we
            // already have whatever the child wrote before being killed,
            // but we still surface the timeout (callers expect it).
            throw CLITestError.timedOut(seconds: timeoutSeconds, args: args)
        }

        return Output(
            stdout: String(data: stdoutBuffer.snapshot(), encoding: .utf8) ?? "",
            stderr: String(data: stderrBuffer.snapshot(), encoding: .utf8) ?? "",
            exitCode: process.terminationStatus
        )
    }

    /// Reference-typed accumulator for the concurrent pipe drain.
    /// Class storage so closures can append from background queues
    /// without tripping Swift 6 sendable-capture warnings on a `var`
    /// data buffer. Internal NSLock guards every read and write.
    private final class DrainBuffer: @unchecked Sendable {
        private var data = Data()
        private let lock = NSLock()
        func append(_ chunk: Data) {
            lock.lock(); defer { lock.unlock() }
            data.append(chunk)
        }
        func snapshot() -> Data {
            lock.lock(); defer { lock.unlock() }
            return data
        }
    }

    /// A bundle fixture with explicit ownership of its temp directory,
    /// so cleanup never removes anything outside what we created.
    struct Fixture {
        let bundlePath: String
        let tempDir: String
    }

    /// Create a fresh fixture bundle at a unique temp path. Returns a
    /// Fixture struct carrying both the bundle path and the temp dir
    /// that wraps it. Caller must call `cleanup(_:)` when done.
    static func makeFixture(name: String, content: String) throws -> Fixture {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("mdpal-cli-test-\(UUID().uuidString)")
        let bundlePath = tempDir.appendingPathComponent("\(name).mdpal").path
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        _ = try DocumentBundle.create(
            name: name,
            initialContent: content,
            at: bundlePath,
            timestamp: Date(timeIntervalSince1970: 1_775_000_000) // pinned at create time only
        )
        return Fixture(bundlePath: bundlePath, tempDir: tempDir.path)
    }

    /// Remove a fixture's temp directory (and the bundle within it).
    /// Removes only the explicitly-captured temp dir — never an arbitrary
    /// parent of an external path.
    static func cleanup(_ fixture: Fixture) {
        // Defense: only remove paths under the OS temp dir.
        let tempRoot = FileManager.default.temporaryDirectory.path
        guard fixture.tempDir.hasPrefix(tempRoot) else { return }
        try? FileManager.default.removeItem(atPath: fixture.tempDir)
    }
}

enum CLITestError: Error, CustomStringConvertible {
    case binaryNotFound
    case binaryEnvOverrideInvalid(path: String)
    case wrongJSONRootType(actual: String)
    case timedOut(seconds: TimeInterval, args: [String])

    var description: String {
        switch self {
        case .binaryNotFound:
            return "mdpal binary not found — run `swift build` first"
        case .binaryEnvOverrideInvalid(let path):
            return "MDPAL_BIN_DIR overrides binary location to '\(path)' but no executable found there"
        case .wrongJSONRootType(let actual):
            return "Expected JSON root type to be an object, got: \(actual)"
        case .timedOut(let seconds, let args):
            return "mdpal subprocess exceeded \(seconds)s timeout: \(args.joined(separator: " "))"
        }
    }
}

/// Minimal JSON-from-string helper for tests.
enum TestJSON {
    static func parse(_ s: String) throws -> [String: Any] {
        let data = Data(s.utf8)
        let any = try JSONSerialization.jsonObject(with: data, options: [])
        guard let dict = any as? [String: Any] else {
            throw CLITestError.wrongJSONRootType(actual: String(describing: type(of: any)))
        }
        return dict
    }
}
