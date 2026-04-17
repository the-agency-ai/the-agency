// What Problem: The single-process engine tests verify that the
// optimistic-concurrency check (createRevision's expectedBase, the
// same-minute file-exists guard) THROWS when it detects a conflict.
// The real-world question — "what happens when two `mdpal revision
// create` invocations actually race?" — needs a multi-process test.
//
// How & Why: Fork two `mdpal revision create` calls against the same
// bundle, in flight at the same time. The engine's atomic file-create
// with rename-or-fail semantics guarantees exactly one wins; the loser
// must surface a structured envelope. We don't pin which process wins
// (real wall-clock scheduling decides) — the assertion is "exactly one
// success and one bundleConflict, both with valid wire shapes".
//
// Reference: usr/jordan/mdpal/dispatches/dispatch-cli-json-output-shapes-20260406.md
//
// Written: 2026-04-17 during mdpal-cli session (Phase 2 iteration 2.5)

import Testing
import Foundation

@Test func twoConcurrentRevisionCreatesProduceExactlyOneSuccess() throws {
    let fixture = try CLISupport.makeFixture(
        name: "concurrent",
        content: "# Intro\n\nbody.\n"
    )
    defer { CLISupport.cleanup(fixture) }

    // Fork two subprocess invocations writing distinct content. Both
    // observe the same latest (V0001.0001) and both compute the same
    // next versionId (V0001.0002.<current-minute>). The engine's
    // file-existence guard inside writeRevision picks the winner.
    //
    // Use --base-revision pointing at the current latest so we exercise
    // the optimistic-concurrency path too: both processes pass the same
    // base; one will land first and the other's expectedBase check will
    // ALSO fail (since base no longer matches). Either failure path is
    // acceptable — we just need exactly-one-success.

    let history = try CLISupport.runCLI(["history", fixture.bundlePath])
    let historyPayload = try TestJSON.parse(history.stdout)
    let revisions = try #require(historyPayload["revisions"] as? [[String: Any]])
    let baseRevision = try #require(revisions.first?["versionId"] as? String)

    let queue = DispatchQueue(label: "concurrent-cli", attributes: .concurrent)
    let group = DispatchGroup()
    var resultA: CLISupport.Output?
    var resultB: CLISupport.Output?
    var errorA: Error?
    var errorB: Error?

    group.enter()
    queue.async {
        defer { group.leave() }
        do {
            resultA = try CLISupport.runCLI([
                "revision", "create", fixture.bundlePath,
                "--content", "# Intro\n\nA wrote this.\n",
                "--base-revision", baseRevision,
            ])
        } catch {
            errorA = error
        }
    }
    group.enter()
    queue.async {
        defer { group.leave() }
        do {
            resultB = try CLISupport.runCLI([
                "revision", "create", fixture.bundlePath,
                "--content", "# Intro\n\nB wrote this.\n",
                "--base-revision", baseRevision,
            ])
        } catch {
            errorB = error
        }
    }
    group.wait()

    // C-9: surface subprocess errors FIRST so a #require panic doesn't
    // mask the more informative throw.
    if let e = errorA { Issue.record("process A threw: \(e)"); return }
    if let e = errorB { Issue.record("process B threw: \(e)"); return }

    let a = try #require(resultA)
    let b = try #require(resultB)

    let aSucceeded = a.exitCode == 0
    let bSucceeded = b.exitCode == 0
    let successCount = (aSucceeded ? 1 : 0) + (bSucceeded ? 1 : 0)

    // Exactly-one-success is the engine invariant. Both succeeding would
    // mean we silently overwrote the loser; both failing would mean the
    // bundle is broken.
    #expect(successCount == 1, "expected exactly 1 success, got \(successCount). A.exit=\(a.exitCode), B.exit=\(b.exitCode), A.stderr=\(a.stderr.prefix(200)), B.stderr=\(b.stderr.prefix(200))")

    // Loser must have emitted a structured envelope on stderr. T-3:
    // The loser can take EITHER of two engine paths:
    //   (a) bundleBaseConflict — engine's expectedBase check caught the
    //       race after the winner landed; envelope carries
    //       details.{baseRevision, currentRevision}.
    //   (b) bundleConflict — engine's expectedBase check passed (winner
    //       hadn't linked yet) and the loser hit link(2) EEXIST;
    //       envelope has no details.
    // Both are correct — the test asserts the union: discriminator +
    // exit code, plus a non-empty message, plus IF details exists, the
    // loser's baseRevision matches what they sent.
    let loser = aSucceeded ? b : a
    #expect(loser.exitCode == 4, "loser should exit 4 (bundleConflict); got \(loser.exitCode)")
    let envelope = try TestJSON.parse(loser.stderr)
    #expect(envelope["error"] as? String == "bundleConflict")
    let message = try #require(envelope["message"] as? String)
    #expect(!message.isEmpty, "bundleConflict envelope must carry a non-empty message")
    if let details = envelope["details"] as? [String: Any] {
        // Path (a): bundleBaseConflict — verify structured fields.
        if let baseRev = details["baseRevision"] as? String {
            #expect(baseRev == baseRevision, "loser's details.baseRevision should echo what they sent")
        }
        if let currentRev = details["currentRevision"] as? String {
            #expect(currentRev != baseRevision, "loser's details.currentRevision should reflect the winner's new revision")
        }
    }
    // Path (b): bundleConflict (link EEXIST) — no details required.
    // Either path is acceptable; both indicate the engine correctly
    // refused to silently overwrite the winner.

    // Bundle integrity: history shows exactly 2 revisions
    // (the original + the winner's new one).
    let postHistory = try CLISupport.runCLI(["history", fixture.bundlePath])
    let postPayload = try TestJSON.parse(postHistory.stdout)
    let postRevisions = try #require(postPayload["revisions"] as? [[String: Any]])
    #expect(postRevisions.count == 2, "expected exactly 2 revisions after race; got \(postRevisions.count)")
}
