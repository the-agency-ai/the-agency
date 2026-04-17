// What Problem: `mdpal version show` and `mdpal version bump` operate
// on the bundle's document version, NOT the CLI tool version. show
// returns {version, versionId, revision, timestamp}; bump returns
// {previousVersion, version, versionId, revision, timestamp} and starts
// a new version line (revision counter resets to 1).
//
// How & Why: Make a fixture, call show, verify the wire shape; bump,
// verify previousVersion matches what show reported, verify version was
// incremented and revision is 1, then call show again to confirm
// persistence.
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

@Test func versionShowReportsCurrentVersion() throws {
    let fixture = try CLISupport.makeFixture(name: "ver-show", content: fixtureContent)
    defer { CLISupport.cleanup(fixture) }

    let result = try CLISupport.runCLI(["version", "show", fixture.bundlePath])
    #expect(result.exitCode == 0, "stderr: \(result.stderr)")

    let payload = try TestJSON.parse(result.stdout)
    #expect(payload["version"] as? Int == 1)
    #expect(payload["revision"] as? Int == 1)
    let versionId = try #require(payload["versionId"] as? String)
    #expect(versionId.hasPrefix("V0001.0001."))
    // timestamp is an ISO-8601 string per JSONOutput's date strategy.
    let timestamp = try #require(payload["timestamp"] as? String)
    #expect(timestamp.contains("T"))
    #expect(timestamp.hasSuffix("Z"))
}

@Test func versionBumpIncrementsAndResetsRevision() throws {
    let fixture = try CLISupport.makeFixture(name: "ver-bump", content: fixtureContent)
    defer { CLISupport.cleanup(fixture) }

    let bumpResult = try CLISupport.runCLI(["version", "bump", fixture.bundlePath])
    #expect(bumpResult.exitCode == 0, "stderr: \(bumpResult.stderr)")

    let payload = try TestJSON.parse(bumpResult.stdout)
    #expect(payload["previousVersion"] as? Int == 1)
    #expect(payload["version"] as? Int == 2)
    #expect(payload["revision"] as? Int == 1)
    let versionId = try #require(payload["versionId"] as? String)
    #expect(versionId.hasPrefix("V0002.0001."))

    // Subsequent show reflects the bump.
    let showResult = try CLISupport.runCLI(["version", "show", fixture.bundlePath])
    #expect(showResult.exitCode == 0)
    let showPayload = try TestJSON.parse(showResult.stdout)
    #expect(showPayload["version"] as? Int == 2)
    #expect(showPayload["revision"] as? Int == 1)
}

// QG fix F6 bug-exposing test: version bump must carry the prior latest's
// content forward BYTE-FOR-BYTE. Pre-fix the implementation re-serialized
// via Document.serialize() which renormalizes whitespace and YAML key order.
@Test func versionBumpPreservesPreviousLatestByteForByte() throws {
    // Build a fixture whose serialized form differs from a parse+reserialize
    // round-trip — easiest case: a body with non-trivial whitespace
    // (multiple blank lines, trailing trailing-trailing space) that the
    // parser would normalize.
    let unusualContent = "# Introduction\n\n\n\nBody with blank lines.\n\n\n"
    let fixture = try CLISupport.makeFixture(name: "ver-bump-verbatim", content: unusualContent)
    defer { CLISupport.cleanup(fixture) }

    // Read the prior latest's bytes off disk via history.
    let history = try CLISupport.runCLI(["history", fixture.bundlePath])
    let historyPayload = try TestJSON.parse(history.stdout)
    let revisions = try #require(historyPayload["revisions"] as? [[String: Any]])
    let firstFile = try #require((revisions.first)?["filePath"] as? String)
    let priorPath = "\(fixture.bundlePath)/\(firstFile)"
    let priorBytes = try String(contentsOfFile: priorPath, encoding: .utf8)

    let bumpResult = try CLISupport.runCLI(["version", "bump", fixture.bundlePath])
    #expect(bumpResult.exitCode == 0, "stderr: \(bumpResult.stderr)")
    let bumpPayload = try TestJSON.parse(bumpResult.stdout)
    let newId = try #require(bumpPayload["versionId"] as? String)
    let newPath = "\(fixture.bundlePath)/\(newId).md"
    let newBytes = try String(contentsOfFile: newPath, encoding: .utf8)

    #expect(newBytes == priorBytes, "version bump must carry content forward verbatim")
}

@Test func versionBumpThenEditAdvancesRevisionWithinSameVersion() throws {
    let fixture = try CLISupport.makeFixture(name: "ver-bump-edit", content: fixtureContent)
    defer { CLISupport.cleanup(fixture) }

    _ = try CLISupport.runCLI(["version", "bump", fixture.bundlePath])

    let listResult = try CLISupport.runCLI(["sections", fixture.bundlePath])
    let listPayload = try TestJSON.parse(listResult.stdout)
    let sections = try #require(listPayload["sections"] as? [[String: Any]])
    let hash = try #require(sections.first?["versionHash"] as? String)

    let editResult = try CLISupport.runCLI([
        "edit", "introduction", fixture.bundlePath,
        "--version", hash,
        "--content", "After bump.",
    ])
    #expect(editResult.exitCode == 0, "stderr: \(editResult.stderr)")

    let showResult = try CLISupport.runCLI(["version", "show", fixture.bundlePath])
    let showPayload = try TestJSON.parse(showResult.stdout)
    #expect(showPayload["version"] as? Int == 2)
    #expect(showPayload["revision"] as? Int == 2)
}
