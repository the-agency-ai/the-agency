// What Problem: `mdpal revision create <bundle> [--content | --stdin]
// [--base-revision <id>]` writes a new revision. Wire shape on success:
// {versionId, version, revision, timestamp, filePath}. With stale
// --base-revision, exit 4 + bundleConflict envelope carrying
// {baseRevision, currentRevision}.
//
// How & Why: Build a fixture, write via --content, verify the wire
// shape and that history reflects the new revision. Cover the
// optimistic-concurrency rejection path with a deliberately-stale
// baseRevision.
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

@Test func revisionCreateAppendsAndReturnsWireShape() throws {
    let fixture = try CLISupport.makeFixture(name: "rev-create", content: fixtureContent)
    defer { CLISupport.cleanup(fixture) }

    let newContent = "# Introduction\n\nUpdated.\n"
    let result = try CLISupport.runCLI([
        "revision", "create", fixture.bundlePath,
        "--content", newContent,
    ])
    #expect(result.exitCode == 0, "stderr: \(result.stderr)")

    let payload = try TestJSON.parse(result.stdout)
    let versionId = try #require(payload["versionId"] as? String)
    #expect(versionId.hasPrefix("V0001.0002."))
    #expect(payload["version"] as? Int == 1)
    #expect(payload["revision"] as? Int == 2)
    let filePath = try #require(payload["filePath"] as? String)
    // filePath is a basename, not absolute.
    #expect(!filePath.hasPrefix("/"))
    #expect(filePath.hasSuffix(".md"))
}

@Test func revisionCreateWithMatchingBaseRevisionSucceeds() throws {
    let fixture = try CLISupport.makeFixture(name: "rev-base-ok", content: fixtureContent)
    defer { CLISupport.cleanup(fixture) }

    let history = try CLISupport.runCLI(["history", fixture.bundlePath])
    let historyPayload = try TestJSON.parse(history.stdout)
    let revisions = try #require(historyPayload["revisions"] as? [[String: Any]])
    let currentLatest = try #require(revisions.first?["versionId"] as? String)

    let result = try CLISupport.runCLI([
        "revision", "create", fixture.bundlePath,
        "--content", "# Introduction\n\nMatched base.\n",
        "--base-revision", currentLatest,
    ])
    #expect(result.exitCode == 0, "stderr: \(result.stderr)")
}

@Test func revisionCreateWithStaleBaseRevisionFailsWithBundleConflict() throws {
    let fixture = try CLISupport.makeFixture(name: "rev-base-stale", content: fixtureContent)
    defer { CLISupport.cleanup(fixture) }

    let result = try CLISupport.runCLI([
        "revision", "create", fixture.bundlePath,
        "--content", "x",
        "--base-revision", "V0099.0099.20260101T0000Z",
    ])
    #expect(result.exitCode == 4, "expected exit 4 for bundleConflict; got \(result.exitCode); stderr: \(result.stderr)")
    let envelope = try TestJSON.parse(result.stderr)
    #expect(envelope["error"] as? String == "bundleConflict")
    let details = try #require(envelope["details"] as? [String: Any])
    #expect(details["baseRevision"] as? String == "V0099.0099.20260101T0000Z")
    let current = try #require(details["currentRevision"] as? String)
    #expect(current.hasPrefix("V0001.0001."))
}

@Test func revisionCreateRejectsBothContentAndStdin() throws {
    let fixture = try CLISupport.makeFixture(name: "rev-both", content: fixtureContent)
    defer { CLISupport.cleanup(fixture) }

    let result = try CLISupport.runCLI(
        [
            "revision", "create", fixture.bundlePath,
            "--content", "x", "--stdin",
        ],
        stdin: "y"
    )
    #expect(result.exitCode != 0)
}

@Test func revisionCreateReadsContentFromStdin() throws {
    let fixture = try CLISupport.makeFixture(name: "rev-stdin", content: fixtureContent)
    defer { CLISupport.cleanup(fixture) }

    let body = "# Introduction\n\nLong piped body.\n"
    let result = try CLISupport.runCLI(
        ["revision", "create", fixture.bundlePath, "--stdin"],
        stdin: body
    )
    #expect(result.exitCode == 0, "stderr: \(result.stderr)")
    let payload = try TestJSON.parse(result.stdout)
    #expect(payload["revision"] as? Int == 2)
}

// QG fix D2 bug-exposing test: stdin reads must be bounded. Pre-fix the
// CLI called readDataToEndOfFile() with no cap — a multi-GB pipe-in would
// OOM the process and write a multi-GB revision file. Post-fix: stdin
// reads abort at 16 MiB with a payloadTooLarge envelope.
@Test func revisionCreateRejectsStdinAboveCeiling() throws {
    let fixture = try CLISupport.makeFixture(name: "rev-stdin-cap", content: fixtureContent)
    defer { CLISupport.cleanup(fixture) }

    // 17 MiB of ASCII — comfortably above the 16 MiB ceiling.
    let oversized = String(repeating: "A", count: 17 * 1024 * 1024)
    let result = try CLISupport.runCLI(
        ["revision", "create", fixture.bundlePath, "--stdin"],
        stdin: oversized
    )
    #expect(result.exitCode != 0, "expected nonzero exit; stderr: \(result.stderr.prefix(200))")
    let envelope = try TestJSON.parse(result.stderr)
    #expect(envelope["error"] as? String == "payloadTooLarge")
    let details = try #require(envelope["details"] as? [String: Any])
    #expect(details["maxBytes"] != nil)

    // Verify no new revision file landed on disk despite the failed write.
    let history = try CLISupport.runCLI(["history", fixture.bundlePath])
    let historyPayload = try TestJSON.parse(history.stdout)
    let revs = try #require(historyPayload["revisions"] as? [[String: Any]])
    #expect(revs.count == 1, "no new revision should be written on rejected stdin")
}

// QG D1 / D3 verification: --base-revision check is now enforced INSIDE
// the engine's createRevision (closing the TOCTOU window between the
// CLI's check and the engine's own latest discovery). The wire-shape is
// unchanged — same exit 4 + bundleConflict envelope with details.
@Test func revisionCreateBaseConflictDetailsCarryStructuredFields() throws {
    let fixture = try CLISupport.makeFixture(name: "rev-base-details", content: fixtureContent)
    defer { CLISupport.cleanup(fixture) }

    let result = try CLISupport.runCLI([
        "revision", "create", fixture.bundlePath,
        "--content", "x",
        "--base-revision", "V0099.0099.20260101T0000Z",
    ])
    #expect(result.exitCode == 4)
    let envelope = try TestJSON.parse(result.stderr)
    #expect(envelope["error"] as? String == "bundleConflict")
    let details = try #require(envelope["details"] as? [String: Any])
    let baseRev = try #require(details["baseRevision"] as? String)
    let currentRev = try #require(details["currentRevision"] as? String)
    #expect(baseRev == "V0099.0099.20260101T0000Z")
    #expect(currentRev.hasPrefix("V0001.0001."))
}
