// What Problem: Iter 2.5 added engine-level hardening (file-size cap
// via SizedFileReader, link(2) atomic create, pointer validation,
// subprocess timeout in CLISupport). The engine throws the right
// EngineError variants and the engine tests verify that — but the
// CLI's job is to translate engine errors into the right wire envelope
// + exit code. A regression that swallowed the throw or stringified it
// as `fileError` would pass every engine test and silently break
// mdpal-app's downstream routing.
//
// How & Why: One test per hardening vector exercising the FULL CLI
// path (binary launch → engine call → envelope emission). T-1 asserts
// the fileTooLarge wire shape. T-4 asserts the subprocess-timeout
// machinery actually fires within the configured window.
//
// Reference: usr/jordan/mdpal/dispatches/dispatch-cli-json-output-shapes-20260406.md
//
// Written: 2026-04-17 during mdpal-cli session (Phase 2 iteration 2.5 QG fix T-1, T-4)

import Testing
import Foundation
@testable import MarkdownPalEngine

private let smallContent = """
# Intro

body.
"""

// T-1: fileTooLarge envelope at the CLI layer.
//
// Plant a 17 MiB "revision" file in a real bundle, then exercise a CLI
// command that reads revisions (mdpal sections / mdpal read). Engine
// throws EngineError.fileTooLarge → EngineErrorMapper → CLI exits 5
// with {error: "fileTooLarge", details: {path, sizeBytes, limitBytes}}.
@Test func cliEmitsFileTooLargeEnvelopeOnOversizedRevision() throws {
    let fixture = try CLISupport.makeFixture(name: "filetoolarge", content: smallContent)
    defer { CLISupport.cleanup(fixture) }

    // Plant an oversized revision file (17 MiB > 16 MiB cap). Use a
    // versionId AFTER the fixture's V0001.0001 so the engine selects it
    // as the latest. Pin a future timestamp.
    let oversizedContent = String(repeating: "A", count: 17 * 1024 * 1024)
    let oversizedPath = "\(fixture.bundlePath)/V0001.0002.20290101T0000Z.md"
    try oversizedContent.write(toFile: oversizedPath, atomically: true, encoding: .utf8)

    // `mdpal sections` reads the latest revision via currentDocument
    // → Document(contentsOfFile:) → SizedFileReader.readRevisionUTF8.
    let result = try CLISupport.runCLI(["sections", fixture.bundlePath])
    #expect(result.exitCode == 5, "expected exit 5 (sizeLimitExceeded); got \(result.exitCode); stderr: \(result.stderr.prefix(300))")
    let envelope = try TestJSON.parse(result.stderr)
    #expect(envelope["error"] as? String == "fileTooLarge")
    let details = try #require(envelope["details"] as? [String: Any])
    #expect(details["path"] is String)
    let sizeBytes = try #require(details["sizeBytes"] as? Int)
    let limitBytes = try #require(details["limitBytes"] as? Int)
    #expect(sizeBytes > limitBytes)
    #expect(limitBytes == 16 * 1024 * 1024, "expected revisionMaxBytes (16 MiB), got \(limitBytes)")
}

// T-4: subprocess timeout actually fires.
//
// Spawn `mdpal sections` against a fixture, but with a deliberately
// short timeout AND stdin held open without EOF (so any read of stdin
// would block indefinitely). The current CLI doesn't read stdin during
// `sections`, so we instead verify the timeout via a command path that
// CAN block: `mdpal edit ... --stdin` with stdin never closing.
//
// Implementation: launch via a shell wrapper that pipes from a
// never-closing source. Foundation Process can't easily NOT close a
// stdin pipe, so we use `mdpal edit --stdin` against a fixture and
// pass an unclosed stdin pipe. Since the test harness DOES close the
// stdin pipe in runCLI, we instead test the timeout machinery by
// invoking a known-hanging /bin/sleep through the binary path swap.
//
// Simplest reliable test: run `/bin/sleep 30` via a Process directly
// (bypassing runCLI's binary lookup) and verify the watchdog fires
// at 1 second.
@Test func subprocessTimeoutFiresOnHangingChild() throws {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/bin/sleep")
    process.arguments = ["30"]
    let stdoutPipe = Pipe()
    let stderrPipe = Pipe()
    process.standardOutput = stdoutPipe
    process.standardError = stderrPipe

    try process.run()

    // Mirror the watchdog pattern from CLISupport.runCLI but with a 1s
    // ceiling. If the watchdog works, the sleep is killed and we observe
    // a non-success exit within ~1-2 seconds. If the watchdog is broken,
    // we'd block for ~30s and the outer test timeout would fire.
    let didTimeOutLock = NSLock()
    var didTimeOut = false
    let timeoutSeconds: TimeInterval = 1.0
    let watchdog = DispatchWorkItem { [weak process] in
        guard let process, process.isRunning else { return }
        process.terminate()
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

    let start = Date()
    process.waitUntilExit()
    let elapsed = Date().timeIntervalSince(start)
    watchdog.cancel()

    didTimeOutLock.lock()
    let timedOut = didTimeOut
    didTimeOutLock.unlock()

    // Drain pipes so they get GC'd.
    _ = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
    _ = stderrPipe.fileHandleForReading.readDataToEndOfFile()

    #expect(timedOut, "watchdog should have signaled timeout")
    #expect(elapsed < 5.0, "process should have been killed well before 30s sleep completed; took \(elapsed)s")
    // Process was killed → non-zero exit (terminationStatus reflects the signal).
    #expect(process.terminationStatus != 0, "killed process should report non-zero exit; got \(process.terminationStatus)")
}

// F2 (phase-complete): --base-revision is now accepted on every write
// command. Verify that passing a STALE base-revision causes the engine
// to throw bundleBaseConflict (exit 4) before any write happens.
@Test func editRejectsStaleBaseRevision() throws {
    let fixture = try CLISupport.makeFixture(
        name: "f2-edit-base",
        content: "# Introduction\n\nbody.\n"
    )
    defer { CLISupport.cleanup(fixture) }

    // Capture current latest as the "stale" base, then create a new
    // revision that moves the latest forward.
    let history = try CLISupport.runCLI(["history", fixture.bundlePath])
    let staleBase = try #require(((try TestJSON.parse(history.stdout))["revisions"] as? [[String: Any]])?.first?["versionId"] as? String)
    _ = try CLISupport.runCLI([
        "revision", "create", fixture.bundlePath,
        "--content", "# Introduction\n\nadvanced.\n",
    ])

    // Read the section's current versionHash (still valid post-advance).
    let read = try CLISupport.runCLI(["read", "introduction", fixture.bundlePath])
    let versionHash = try #require((try TestJSON.parse(read.stdout))["versionHash"] as? String)

    // Edit with the STALE base-revision should be refused at the bundle
    // level, even though the section hash is still current.
    let edit = try CLISupport.runCLI([
        "edit", "introduction", fixture.bundlePath,
        "--version", versionHash,
        "--base-revision", staleBase,
        "--content", "should not land.",
    ])
    #expect(edit.exitCode == 4,
            "expected exit 4 (bundleConflict) on stale --base-revision; got \(edit.exitCode), stderr=\(edit.stderr.prefix(200))")
    let envelope = try TestJSON.parse(edit.stderr)
    #expect(envelope["error"] as? String == "bundleConflict")
    let details = try #require(envelope["details"] as? [String: Any])
    #expect(details["baseRevision"] as? String == staleBase)
}

@Test func commentRejectsStaleBaseRevision() throws {
    let fixture = try CLISupport.makeFixture(
        name: "f2-comment-base",
        content: "# Introduction\n\nbody.\n"
    )
    defer { CLISupport.cleanup(fixture) }
    let history = try CLISupport.runCLI(["history", fixture.bundlePath])
    let staleBase = try #require(((try TestJSON.parse(history.stdout))["revisions"] as? [[String: Any]])?.first?["versionId"] as? String)
    _ = try CLISupport.runCLI([
        "revision", "create", fixture.bundlePath,
        "--content", "# Introduction\n\nadvanced.\n",
    ])

    let comment = try CLISupport.runCLI([
        "comment", "introduction", fixture.bundlePath,
        "--type", "note", "--author", "alice", "--text", "stale comment",
        "--base-revision", staleBase,
    ])
    #expect(comment.exitCode == 4, "expected exit 4 (bundleConflict); got \(comment.exitCode), stderr=\(comment.stderr.prefix(200))")
    let envelope = try TestJSON.parse(comment.stderr)
    #expect(envelope["error"] as? String == "bundleConflict")
}

@Test func flagRejectsStaleBaseRevision() throws {
    let fixture = try CLISupport.makeFixture(
        name: "f2-flag-base",
        content: "# Introduction\n\nbody.\n"
    )
    defer { CLISupport.cleanup(fixture) }
    let history = try CLISupport.runCLI(["history", fixture.bundlePath])
    let staleBase = try #require(((try TestJSON.parse(history.stdout))["revisions"] as? [[String: Any]])?.first?["versionId"] as? String)
    _ = try CLISupport.runCLI([
        "revision", "create", fixture.bundlePath,
        "--content", "# Introduction\n\nadvanced.\n",
    ])

    let flag = try CLISupport.runCLI([
        "flag", "introduction", fixture.bundlePath,
        "--author", "alice",
        "--base-revision", staleBase,
    ])
    #expect(flag.exitCode == 4, "expected exit 4; got \(flag.exitCode), stderr=\(flag.stderr.prefix(200))")
    let envelope = try TestJSON.parse(flag.stderr)
    #expect(envelope["error"] as? String == "bundleConflict")
}

@Test func versionBumpRejectsStaleBaseRevision() throws {
    let fixture = try CLISupport.makeFixture(
        name: "f2-bump-base",
        content: "# Introduction\n\nbody.\n"
    )
    defer { CLISupport.cleanup(fixture) }
    let history = try CLISupport.runCLI(["history", fixture.bundlePath])
    let staleBase = try #require(((try TestJSON.parse(history.stdout))["revisions"] as? [[String: Any]])?.first?["versionId"] as? String)
    _ = try CLISupport.runCLI([
        "revision", "create", fixture.bundlePath,
        "--content", "# Introduction\n\nadvanced.\n",
    ])

    let bump = try CLISupport.runCLI([
        "version", "bump", fixture.bundlePath,
        "--base-revision", staleBase,
    ])
    #expect(bump.exitCode == 4, "expected exit 4; got \(bump.exitCode), stderr=\(bump.stderr.prefix(200))")
    let envelope = try TestJSON.parse(bump.stderr)
    #expect(envelope["error"] as? String == "bundleConflict")
}

// F4 (phase-complete): runCLI's concurrent pipe drain must handle
// outputs larger than the Darwin pipe buffer (16-64 KiB) without
// deadlocking. Generate a bundle with many revisions whose history
// listing exceeds 100 KiB, then assert the call returns cleanly.
@Test func runCLIHandlesLargeOutputWithoutDeadlock() throws {
    let fixture = try CLISupport.makeFixture(
        name: "f4-large-output",
        content: "# Introduction\n\nbody.\n"
    )
    defer { CLISupport.cleanup(fixture) }
    let baseTs = Date(timeIntervalSince1970: 1_775_000_000)

    let bundle = try DocumentBundle(at: fixture.bundlePath)
    // 200 revisions → history JSON well over 100 KiB. Each entry is
    // ~200-400 bytes (versionId + filePath + timestamp + version/revision
    // counters + boolean), giving ~50-80 KiB at minimum, often more.
    for i in 2...200 {
        let ts = baseTs.addingTimeInterval(TimeInterval(i * 60))
        _ = try bundle.createRevision(
            content: "# Intro\n\nrev \(i) with some body to give the file actual content.\n",
            timestamp: ts
        )
    }

    // Pre-fix this would have deadlocked: the child filled the pipe
    // buffer, blocked on write, and the parent never read because it
    // was waiting in waitUntilExit. Watchdog killed at 60s.
    let result = try CLISupport.runCLI(["history", fixture.bundlePath])
    #expect(result.exitCode == 0, "history failed: stderr=\(result.stderr.prefix(200))")
    // Threshold: 32 KiB. Darwin's pipe buffer is 16 KiB at the low end
    // and ~64 KiB at the high end. Any output > 32 KiB necessarily
    // exercises the drain pattern beyond the smallest-Darwin-buffer
    // boundary. (Empirical: 200 revisions produce ~45 KiB.) The test's
    // intent is "validates no deadlock on output that exceeds the
    // smallest plausible pipe buffer," which 32 KiB does.
    #expect(result.stdout.count > 32 * 1024,
            "expected >32 KiB of history output to actually exercise the pipe-drain path; got \(result.stdout.count) bytes")
    let payload = try TestJSON.parse(result.stdout)
    let revisions = try #require(payload["revisions"] as? [[String: Any]])
    #expect(revisions.count == 200)
}

// F5 (phase-complete): EditCommand on versionConflict must surface a
// real versionId in the wire envelope, not the empty string the prior
// `try?` swallowed. The happy-path conflict scenario: read section
// hash, then race a second writer to invalidate it, then attempt the
// edit and observe the envelope.
@Test func editVersionConflictEnvelopeCarriesRealVersionId() throws {
    let fixture = try CLISupport.makeFixture(
        name: "f5-edit-versionid",
        content: "# Introduction\n\noriginal.\n"
    )
    defer { CLISupport.cleanup(fixture) }

    let read = try CLISupport.runCLI(["read", "introduction", fixture.bundlePath])
    let staleHash = try #require((try TestJSON.parse(read.stdout))["versionHash"] as? String)

    // Move the section forward via a different writer (simulate a race
    // that landed first).
    _ = try CLISupport.runCLI([
        "revision", "create", fixture.bundlePath,
        "--content", "# Introduction\n\nracing writer landed.\n",
    ])

    // Edit with the stale section hash → versionConflict.
    let edit = try CLISupport.runCLI([
        "edit", "introduction", fixture.bundlePath,
        "--version", staleHash,
        "--content", "losing edit.",
    ])
    #expect(edit.exitCode == 2, "expected exit 2 (versionConflict); got \(edit.exitCode), stderr=\(edit.stderr.prefix(200))")
    let envelope = try TestJSON.parse(edit.stderr)
    #expect(envelope["error"] as? String == "versionConflict")
    let details = try #require(envelope["details"] as? [String: Any])
    let versionId = try #require(details["versionId"] as? String,
                                 "envelope must carry versionId; F5 regression if empty/missing")
    #expect(!versionId.isEmpty, "versionId must be non-empty (F5 regression)")
    #expect(versionId.hasPrefix("V0001."),
            "versionId should look canonical; got '\(versionId)'")
}

// T13 (phase-complete): exercise CLISupport.runCLI's actual implementation
// against /bin/sleep via the new executableURL test affordance. The prior
// subprocessTimeoutFiresOnHangingChild test validates the watchdog
// PATTERN by replicating it inline; this test validates that runCLI
// itself wires the pattern correctly. A regression that broke the
// watchdog cancel/fire path inside runCLI would not fail the inline
// test (it doesn't touch runCLI) but would fail this one.
@Test func runCLITimesOutOnHangingChild() throws {
    let start = Date()
    do {
        _ = try CLISupport.runCLI(
            ["30"],
            timeoutSeconds: 1.0,
            executableURL: URL(fileURLWithPath: "/bin/sleep")
        )
        Issue.record("expected CLITestError.timedOut, got success Output")
    } catch let err as CLITestError {
        if case .timedOut(let seconds, _) = err {
            #expect(seconds == 1.0)
        } else {
            Issue.record("expected .timedOut, got \(err)")
        }
    } catch {
        Issue.record("expected CLITestError.timedOut, got \(error)")
    }
    let elapsed = Date().timeIntervalSince(start)
    #expect(elapsed < 5.0, "runCLI should have fired the watchdog within ~1-2s; took \(elapsed)s")
}
