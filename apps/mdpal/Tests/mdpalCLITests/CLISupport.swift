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
    /// Note: pipes are drained AFTER waitUntilExit (or after kill on
    /// timeout). The simple synchronous path is more reliable than
    /// DispatchGroup orchestration around Foundation's Pipe; the
    /// per-command output is well under 16KB so the kernel pipe buffer
    /// won't block the child.
    static func runCLI(
        _ args: [String],
        stdin: String? = nil,
        timeoutSeconds: TimeInterval = defaultTimeoutSeconds
    ) throws -> Output {
        let binary = try binaryURL()

        let process = Process()
        process.executableURL = binary
        process.arguments = args

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        if let stdin {
            let stdinPipe = Pipe()
            process.standardInput = stdinPipe
            try process.run()
            stdinPipe.fileHandleForWriting.write(Data(stdin.utf8))
            try? stdinPipe.fileHandleForWriting.close()
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

        didTimeOutLock.lock()
        let timedOut = didTimeOut
        didTimeOutLock.unlock()
        if timedOut {
            throw CLITestError.timedOut(seconds: timeoutSeconds, args: args)
        }

        let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
        let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()

        return Output(
            stdout: String(data: stdoutData, encoding: .utf8) ?? "",
            stderr: String(data: stderrData, encoding: .utf8) ?? "",
            exitCode: process.terminationStatus
        )
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
