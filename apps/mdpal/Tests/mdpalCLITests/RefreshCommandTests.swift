// What Problem: `mdpal refresh <slug> <bundle>` updates each unresolved
// comment anchored to the slug so its versionHash matches the section's
// current hash. Wire shape: {slug, versionHash, commentsUpdated,
// versionId}. A new revision is always written.
//
// How & Why: Build a fixture, add a comment, edit the section so the
// comment goes stale, refresh, verify the wire shape and that
// commentsUpdated reports the right count. Test the no-op path
// (commentsUpdated == 0) too.
//
// Reference: usr/jordan/mdpal/dispatches/dispatch-cli-json-output-shapes-20260406.md
//
// Written: 2026-04-17 during mdpal-cli session (Phase 2 iteration 2.4)

import Testing
import Foundation

private let fixtureContent = """
# Introduction

Body.
"""

@Test func refreshUpdatesStaleCommentHashes() throws {
    let fixture = try CLISupport.makeFixture(name: "refresh-stale", content: fixtureContent)
    defer { CLISupport.cleanup(fixture) }

    // Add a comment.
    _ = try CLISupport.runCLI([
        "comment", "introduction", fixture.bundlePath,
        "--type", "question", "--author", "alice", "--text", "Q?",
    ])

    // Edit the section so the comment's versionHash goes stale.
    let listResult = try CLISupport.runCLI(["sections", fixture.bundlePath])
    let listPayload = try TestJSON.parse(listResult.stdout)
    let sections = try #require(listPayload["sections"] as? [[String: Any]])
    let hash = try #require(sections.first?["versionHash"] as? String)
    _ = try CLISupport.runCLI([
        "edit", "introduction", fixture.bundlePath,
        "--version", hash,
        "--content", "Updated body.",
    ])

    let result = try CLISupport.runCLI(["refresh", "introduction", fixture.bundlePath])
    #expect(result.exitCode == 0, "stderr: \(result.stderr)")

    let payload = try TestJSON.parse(result.stdout)
    #expect(payload["slug"] as? String == "introduction")
    #expect(payload["commentsUpdated"] as? Int == 1)
    let versionHash = try #require(payload["versionHash"] as? String)
    #expect(!versionHash.isEmpty)
    let versionId = try #require(payload["versionId"] as? String)
    // Revisions added: rev 1 (fixture create) + rev 2 (comment add) +
    // rev 3 (edit) + rev 4 (refresh). Refresh's revision is the latest.
    #expect(versionId.hasPrefix("V0001.0004."))
}

@Test func refreshWithNoStaleCommentsReportsZero() throws {
    let fixture = try CLISupport.makeFixture(name: "refresh-noop", content: fixtureContent)
    defer { CLISupport.cleanup(fixture) }

    // Add a comment but don't edit — the hash is current.
    _ = try CLISupport.runCLI([
        "comment", "introduction", fixture.bundlePath,
        "--type", "note", "--author", "alice", "--text", "fresh",
    ])

    let result = try CLISupport.runCLI(["refresh", "introduction", fixture.bundlePath])
    #expect(result.exitCode == 0, "stderr: \(result.stderr)")
    let payload = try TestJSON.parse(result.stdout)
    #expect(payload["commentsUpdated"] as? Int == 0)
}

@Test func refreshOnUnknownSectionFails() throws {
    let fixture = try CLISupport.makeFixture(name: "refresh-missing", content: fixtureContent)
    defer { CLISupport.cleanup(fixture) }

    let result = try CLISupport.runCLI(["refresh", "no-such-section", fixture.bundlePath])
    #expect(result.exitCode == 3)
    let envelope = try TestJSON.parse(result.stderr)
    #expect(envelope["error"] as? String == "sectionNotFound")
}

// QG fix F1 bug-exposing test: when refresh has nothing to update, repeated
// invocations within the same minute used to throw bundleConflict ("Revision
// already exists") because the engine writes a new revision unconditionally
// and the timestamp resolution is per-minute. Post-fix: skip the write,
// emit the existing latest's versionId.
@Test func refreshNoOpIsIdempotentWithinSameMinute() throws {
    let fixture = try CLISupport.makeFixture(name: "refresh-noop-retry", content: fixtureContent)
    defer { CLISupport.cleanup(fixture) }

    _ = try CLISupport.runCLI([
        "comment", "introduction", fixture.bundlePath,
        "--type", "note", "--author", "alice", "--text", "fresh",
    ])

    let first = try CLISupport.runCLI(["refresh", "introduction", fixture.bundlePath])
    #expect(first.exitCode == 0, "first call should succeed; stderr: \(first.stderr)")

    // Second call within the same minute MUST also succeed (skip-write path).
    // Pre-fix: this exited with code 4 + bundleConflict envelope.
    let second = try CLISupport.runCLI(["refresh", "introduction", fixture.bundlePath])
    #expect(second.exitCode == 0, "second call should also succeed; stderr: \(second.stderr)")
    let payload = try TestJSON.parse(second.stdout)
    #expect(payload["commentsUpdated"] as? Int == 0)
    // versionId echoes the existing latest (no new revision written).
    let versionId = try #require(payload["versionId"] as? String)
    let history = try CLISupport.runCLI(["history", fixture.bundlePath])
    let historyPayload = try TestJSON.parse(history.stdout)
    let revisions = try #require(historyPayload["revisions"] as? [[String: Any]])
    // Bundle has rev 1 (fixture) + rev 2 (comment add) — refresh added nothing.
    #expect(revisions.count == 2)
    let latestId = try #require((revisions.first)?["versionId"] as? String)
    #expect(versionId == latestId)
}

// QG coverage T2: refresh's returned versionHash MUST equal the section's
// current hash (so mdpal-app's stale-comment badge clears). Pre-fix this
// invariant was not asserted in any test, so a regression returning the
// pre-edit hash would have shipped silently.
@Test func refreshReturnsCurrentSectionVersionHash() throws {
    let fixture = try CLISupport.makeFixture(name: "refresh-hash-match", content: fixtureContent)
    defer { CLISupport.cleanup(fixture) }

    _ = try CLISupport.runCLI([
        "comment", "introduction", fixture.bundlePath,
        "--type", "question", "--author", "alice", "--text", "Q?",
    ])

    let listBefore = try CLISupport.runCLI(["sections", fixture.bundlePath])
    let beforePayload = try TestJSON.parse(listBefore.stdout)
    let beforeSections = try #require(beforePayload["sections"] as? [[String: Any]])
    let beforeHash = try #require(beforeSections.first?["versionHash"] as? String)
    _ = try CLISupport.runCLI([
        "edit", "introduction", fixture.bundlePath,
        "--version", beforeHash,
        "--content", "Updated body for hash test.",
    ])

    let result = try CLISupport.runCLI(["refresh", "introduction", fixture.bundlePath])
    #expect(result.exitCode == 0, "stderr: \(result.stderr)")
    let refreshPayload = try TestJSON.parse(result.stdout)
    let refreshHash = try #require(refreshPayload["versionHash"] as? String)

    // Round-trip through `sections` and assert the hash refresh reported
    // matches what `sections` reports for the same slug after the refresh.
    let listAfter = try CLISupport.runCLI(["sections", fixture.bundlePath])
    let afterPayload = try TestJSON.parse(listAfter.stdout)
    let afterSections = try #require(afterPayload["sections"] as? [[String: Any]])
    let afterHash = try #require(afterSections.first?["versionHash"] as? String)
    #expect(refreshHash == afterHash, "refresh hash must equal sections endpoint's hash")
}

// QG D3 bug-exposing test: refresh now accepts --base-revision for
// optimistic concurrency. A stale base must be rejected as bundleConflict.
@Test func refreshWithStaleBaseRevisionFailsWithBundleConflict() throws {
    let fixture = try CLISupport.makeFixture(name: "refresh-stale-base", content: fixtureContent)
    defer { CLISupport.cleanup(fixture) }

    // Add a comment so refresh will actually want to write.
    _ = try CLISupport.runCLI([
        "comment", "introduction", fixture.bundlePath,
        "--type", "note", "--author", "alice", "--text", "x",
    ])
    // Edit so the comment goes stale.
    let listResult = try CLISupport.runCLI(["sections", fixture.bundlePath])
    let listPayload = try TestJSON.parse(listResult.stdout)
    let sections = try #require(listPayload["sections"] as? [[String: Any]])
    let hash = try #require(sections.first?["versionHash"] as? String)
    _ = try CLISupport.runCLI([
        "edit", "introduction", fixture.bundlePath,
        "--version", hash,
        "--content", "Updated.",
    ])

    let result = try CLISupport.runCLI([
        "refresh", "introduction", fixture.bundlePath,
        "--base-revision", "V0099.0099.20260101T0000Z",
    ])
    #expect(result.exitCode == 4, "expected exit 4 for bundleConflict; got \(result.exitCode); stderr: \(result.stderr)")
    let envelope = try TestJSON.parse(result.stderr)
    #expect(envelope["error"] as? String == "bundleConflict")
    let details = try #require(envelope["details"] as? [String: Any])
    #expect(details["baseRevision"] as? String == "V0099.0099.20260101T0000Z")
}
