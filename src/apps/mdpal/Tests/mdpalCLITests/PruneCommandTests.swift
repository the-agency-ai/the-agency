// What Problem: `mdpal prune <bundle> [--keep <n>]` removes old
// revisions while merging forward resolved comments. Wire shape:
// {pruned:[{versionId, filePath}], kept, prunedCount, commentsPreserved}.
//
// How & Why: Build a fixture, append several revisions, prune to a
// smaller count, verify the wire shape and that history reflects the
// new size. --keep validation rejects 0 / negative.
//
// Reference: usr/jordan/mdpal/dispatches/dispatch-cli-json-output-shapes-20260406.md
//
// Written: 2026-04-17 during mdpal-cli session (Phase 2 iteration 2.4)

import Testing
import Foundation

private let fixtureContent = """
# Introduction

Initial.
"""

@Test func pruneRemovesOldestRevisionsAndKeepsLatest() throws {
    let fixture = try CLISupport.makeFixture(name: "prune-keep", content: fixtureContent)
    defer { CLISupport.cleanup(fixture) }

    // Append 4 more revisions => 5 total.
    for i in 0..<4 {
        let result = try CLISupport.runCLI([
            "revision", "create", fixture.bundlePath,
            "--content", "# Introduction\n\nrev \(i + 2).\n",
        ])
        #expect(result.exitCode == 0, "stderr: \(result.stderr)")
    }

    // Prune to keep 2.
    let pruneResult = try CLISupport.runCLI([
        "prune", fixture.bundlePath,
        "--keep", "2",
    ])
    #expect(pruneResult.exitCode == 0, "stderr: \(pruneResult.stderr)")

    let payload = try TestJSON.parse(pruneResult.stdout)
    #expect(payload["kept"] as? Int == 2)
    #expect(payload["prunedCount"] as? Int == 3)
    #expect(payload["commentsPreserved"] as? Int == 0)
    let pruned = try #require(payload["pruned"] as? [[String: Any]])
    #expect(pruned.count == 3)
    let firstPruned = try #require(pruned.first)
    let prunedId = try #require(firstPruned["versionId"] as? String)
    let prunedPath = try #require(firstPruned["filePath"] as? String)
    // filePath is a basename, not absolute.
    #expect(!prunedPath.hasPrefix("/"))
    #expect(prunedPath.hasSuffix(".md"))
    #expect(prunedPath.hasPrefix(prunedId))

    // History reflects the new size.
    let history = try CLISupport.runCLI(["history", fixture.bundlePath])
    let historyPayload = try TestJSON.parse(history.stdout)
    let revs = try #require(historyPayload["revisions"] as? [[String: Any]])
    #expect(revs.count == 2)
}

@Test func pruneWhenAlreadyAtKeepSizeReportsZero() throws {
    let fixture = try CLISupport.makeFixture(name: "prune-noop", content: fixtureContent)
    defer { CLISupport.cleanup(fixture) }

    let result = try CLISupport.runCLI(["prune", fixture.bundlePath, "--keep", "5"])
    #expect(result.exitCode == 0, "stderr: \(result.stderr)")

    let payload = try TestJSON.parse(result.stdout)
    #expect(payload["prunedCount"] as? Int == 0)
    #expect(payload["kept"] as? Int == 1)
    let pruned = try #require(payload["pruned"] as? [[String: Any]])
    #expect(pruned.isEmpty)
}

@Test func pruneRejectsZeroKeep() throws {
    let fixture = try CLISupport.makeFixture(name: "prune-zero", content: fixtureContent)
    defer { CLISupport.cleanup(fixture) }

    let result = try CLISupport.runCLI(["prune", fixture.bundlePath, "--keep", "0"])
    #expect(result.exitCode != 0)
}

@Test func pruneUsesConfigDefaultWhenKeepOmitted() throws {
    // Default config keep is 20 — a freshly-created bundle is well below.
    let fixture = try CLISupport.makeFixture(name: "prune-default", content: fixtureContent)
    defer { CLISupport.cleanup(fixture) }

    let result = try CLISupport.runCLI(["prune", fixture.bundlePath])
    #expect(result.exitCode == 0, "stderr: \(result.stderr)")
    let payload = try TestJSON.parse(result.stdout)
    #expect(payload["prunedCount"] as? Int == 0)
}

// QG coverage T3: the boundary --keep N == revisions.count is the most
// dangerous off-by-one in DocumentBundle.prune (`>` vs `>=`). Pre-fix this
// case was never exercised — a regression to `>=` would silently truncate
// to N-1.
@Test func pruneWithKeepEqualToRevisionCountIsNoOp() throws {
    let fixture = try CLISupport.makeFixture(name: "prune-equal", content: fixtureContent)
    defer { CLISupport.cleanup(fixture) }

    // Append 2 more revisions => 3 total.
    for i in 0..<2 {
        _ = try CLISupport.runCLI([
            "revision", "create", fixture.bundlePath,
            "--content", "# Introduction\n\nrev \(i + 2).\n",
        ])
    }

    // Prune with --keep 3 == revisions.count → must NOT delete anything.
    let result = try CLISupport.runCLI(["prune", fixture.bundlePath, "--keep", "3"])
    #expect(result.exitCode == 0, "stderr: \(result.stderr)")
    let payload = try TestJSON.parse(result.stdout)
    #expect(payload["prunedCount"] as? Int == 0)
    #expect(payload["kept"] as? Int == 3)

    // Verify history confirms 3 revisions remain.
    let history = try CLISupport.runCLI(["history", fixture.bundlePath])
    let historyPayload = try TestJSON.parse(history.stdout)
    let revs = try #require(historyPayload["revisions"] as? [[String: Any]])
    #expect(revs.count == 3)
}

// QG coverage T4: commentsPreserved field exists to count resolved comments
// merged forward from pruned revisions. Pre-fix every prune test asserted
// commentsPreserved == 0 — the merge-forward path was never exercised at
// the CLI layer. A regression dropping the merge would have shipped silently.
@Test func pruneMergesForwardResolvedComments() throws {
    let fixture = try CLISupport.makeFixture(name: "prune-merge", content: fixtureContent)
    defer { CLISupport.cleanup(fixture) }

    // Add a comment, then resolve it, then add several plain edits so the
    // resolved-comment-bearing revision is in the prune-eligible window.
    let addResult = try CLISupport.runCLI([
        "comment", "introduction", fixture.bundlePath,
        "--type", "question", "--author", "alice", "--text", "Q?",
    ])
    let added = try TestJSON.parse(addResult.stdout)
    let cid = try #require(added["commentId"] as? String)
    _ = try CLISupport.runCLI([
        "resolve", cid, fixture.bundlePath,
        "--response", "answered", "--by", "bob",
    ])

    // Add 3 more revisions so the resolution-bearing rev is older.
    for i in 0..<3 {
        _ = try CLISupport.runCLI([
            "revision", "create", fixture.bundlePath,
            "--content", "# Introduction\n\nlater \(i).\n",
        ])
    }

    // Prune to keep only the 2 most recent — the resolution-bearing rev
    // must be in the pruned set, and its resolved comment must merge forward.
    let pruneResult = try CLISupport.runCLI([
        "prune", fixture.bundlePath, "--keep", "2",
    ])
    #expect(pruneResult.exitCode == 0, "stderr: \(pruneResult.stderr)")
    let payload = try TestJSON.parse(pruneResult.stdout)
    let preserved = try #require(payload["commentsPreserved"] as? Int)
    #expect(preserved >= 1, "expected ≥1 resolved comment merged forward; got \(preserved)")
}
