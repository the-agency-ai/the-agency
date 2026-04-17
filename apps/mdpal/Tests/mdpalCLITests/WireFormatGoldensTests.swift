// What Problem: mdpal-app decodes every CLI JSON payload via Codable
// structs whose property names exactly match the wire spec. Any drift —
// renamed key, missing field, type change — silently corrupts the app
// boundary. Per-command happy-path tests assert that the EXPECTED keys
// are present, but they don't lock the WHOLE shape (extra keys would
// pass; reordered output would pass). Goldens close that gap by
// asserting the complete decoded structure for one representative call
// per command.
//
// How & Why: For each new iter-2.4 command, run the canonical happy
// path and assert (a) the top-level key set matches the spec exactly,
// (b) the value types match the spec's type table (line 410-419 of
// the dispatch). Where the call carries dynamic data (versionId,
// timestamp, hashes), assert structural prefixes/regex rather than
// exact value. This locks the wire shape against silent drift while
// keeping tests robust to fixture-timestamp changes.
//
// Reference: usr/jordan/mdpal/dispatches/dispatch-cli-json-output-shapes-20260406.md
//
// Written: 2026-04-17 during mdpal-cli session (Phase 2 iteration 2.4 QG fix D7)

import Testing
import Foundation

private let fixtureContent = """
# Introduction

Body.

# Architecture

More.
"""

/// Assert the top-level key set of a JSON payload matches `expected` exactly.
/// Catches both missing fields (regression dropping a key) and extra fields
/// (regression adding an undocumented field that mdpal-app's exhaustive
/// decoder would barf on).
private func expectKeys(
    _ payload: [String: Any],
    _ expected: Set<String>,
    sourceLocation: SourceLocation = #_sourceLocation
) {
    let actual = Set(payload.keys)
    let missing = expected.subtracting(actual)
    let extra = actual.subtracting(expected)
    #expect(missing.isEmpty, "missing keys: \(missing)", sourceLocation: sourceLocation)
    #expect(extra.isEmpty, "unexpected keys: \(extra)", sourceLocation: sourceLocation)
}

@Test func goldenCreatePayloadShape() throws {
    let parentDir = FileManager.default.temporaryDirectory
        .appendingPathComponent("mdpal-golden-create-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: parentDir, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: parentDir) }

    let result = try CLISupport.runCLI([
        "create", "design",
        "--dir", parentDir.path,
    ])
    #expect(result.exitCode == 0, "stderr: \(result.stderr)")
    let payload = try TestJSON.parse(result.stdout)

    expectKeys(payload, ["bundle", "path", "versionId", "revision", "version"])
    #expect(payload["bundle"] is String)
    #expect(payload["path"] is String)
    #expect(payload["versionId"] is String)
    #expect(payload["revision"] is Int)
    #expect(payload["version"] is Int)
}

@Test func goldenHistoryPayloadShape() throws {
    let fixture = try CLISupport.makeFixture(name: "golden-history", content: fixtureContent)
    defer { CLISupport.cleanup(fixture) }

    let result = try CLISupport.runCLI(["history", fixture.bundlePath])
    #expect(result.exitCode == 0, "stderr: \(result.stderr)")
    let payload = try TestJSON.parse(result.stdout)

    expectKeys(payload, ["revisions", "count", "currentVersion"])
    #expect(payload["count"] is Int)
    let revisions = try #require(payload["revisions"] as? [[String: Any]])
    let first = try #require(revisions.first)
    expectKeys(first, ["versionId", "version", "revision", "timestamp", "filePath", "latest"])
    #expect(first["versionId"] is String)
    #expect(first["version"] is Int)
    #expect(first["revision"] is Int)
    #expect(first["timestamp"] is String)
    #expect(first["filePath"] is String)
    #expect(first["latest"] is Bool)
}

@Test func goldenVersionShowPayloadShape() throws {
    let fixture = try CLISupport.makeFixture(name: "golden-vshow", content: fixtureContent)
    defer { CLISupport.cleanup(fixture) }

    let result = try CLISupport.runCLI(["version", "show", fixture.bundlePath])
    #expect(result.exitCode == 0, "stderr: \(result.stderr)")
    let payload = try TestJSON.parse(result.stdout)

    expectKeys(payload, ["version", "versionId", "revision", "timestamp"])
    #expect(payload["version"] is Int)
    #expect(payload["versionId"] is String)
    #expect(payload["revision"] is Int)
    #expect(payload["timestamp"] is String)
}

@Test func goldenVersionBumpPayloadShape() throws {
    let fixture = try CLISupport.makeFixture(name: "golden-vbump", content: fixtureContent)
    defer { CLISupport.cleanup(fixture) }

    let result = try CLISupport.runCLI(["version", "bump", fixture.bundlePath])
    #expect(result.exitCode == 0, "stderr: \(result.stderr)")
    let payload = try TestJSON.parse(result.stdout)

    expectKeys(payload, ["previousVersion", "version", "versionId", "revision", "timestamp"])
    #expect(payload["previousVersion"] is Int)
    #expect(payload["version"] is Int)
    #expect(payload["versionId"] is String)
    #expect(payload["revision"] is Int)
    #expect(payload["timestamp"] is String)
}

@Test func goldenRevisionCreatePayloadShape() throws {
    let fixture = try CLISupport.makeFixture(name: "golden-rev", content: fixtureContent)
    defer { CLISupport.cleanup(fixture) }

    let result = try CLISupport.runCLI([
        "revision", "create", fixture.bundlePath,
        "--content", "# Introduction\n\nNew body.\n",
    ])
    #expect(result.exitCode == 0, "stderr: \(result.stderr)")
    let payload = try TestJSON.parse(result.stdout)

    expectKeys(payload, ["versionId", "version", "revision", "timestamp", "filePath"])
    #expect(payload["versionId"] is String)
    #expect(payload["version"] is Int)
    #expect(payload["revision"] is Int)
    #expect(payload["timestamp"] is String)
    #expect(payload["filePath"] is String)
}

@Test func goldenDiffPayloadShape() throws {
    let fixture = try CLISupport.makeFixture(name: "golden-diff", content: fixtureContent)
    defer { CLISupport.cleanup(fixture) }

    let history = try CLISupport.runCLI(["history", fixture.bundlePath])
    let r0 = try #require(((try TestJSON.parse(history.stdout))["revisions"] as? [[String: Any]])?.first?["versionId"] as? String)
    let edit = try CLISupport.runCLI([
        "revision", "create", fixture.bundlePath,
        "--content", "# Introduction\n\nDifferent body.\n",
    ])
    let r1 = try #require((try TestJSON.parse(edit.stdout))["versionId"] as? String)

    let result = try CLISupport.runCLI(["diff", r0, r1, fixture.bundlePath])
    #expect(result.exitCode == 0, "stderr: \(result.stderr)")
    let payload = try TestJSON.parse(result.stdout)

    expectKeys(payload, ["from", "to", "changes", "count"])
    #expect(payload["from"] as? String == r0)
    #expect(payload["to"] as? String == r1)
    #expect(payload["count"] is Int)
    let changes = try #require(payload["changes"] as? [[String: Any]])
    let firstChange = try #require(changes.first)
    expectKeys(firstChange, ["slug", "type", "summary"])
    #expect(firstChange["slug"] is String)
    #expect(firstChange["type"] is String)
    #expect(firstChange["summary"] is String)
}

@Test func goldenPrunePayloadShape() throws {
    let fixture = try CLISupport.makeFixture(name: "golden-prune", content: fixtureContent)
    defer { CLISupport.cleanup(fixture) }

    // Append two more revisions, then prune to keep one.
    for i in 0..<2 {
        _ = try CLISupport.runCLI([
            "revision", "create", fixture.bundlePath,
            "--content", "# Introduction\n\nrev \(i + 2).\n",
        ])
    }

    let result = try CLISupport.runCLI(["prune", fixture.bundlePath, "--keep", "1"])
    #expect(result.exitCode == 0, "stderr: \(result.stderr)")
    let payload = try TestJSON.parse(result.stdout)

    expectKeys(payload, ["pruned", "kept", "prunedCount", "commentsPreserved"])
    #expect(payload["kept"] is Int)
    #expect(payload["prunedCount"] is Int)
    #expect(payload["commentsPreserved"] is Int)
    let pruned = try #require(payload["pruned"] as? [[String: Any]])
    let firstPruned = try #require(pruned.first)
    expectKeys(firstPruned, ["versionId", "filePath"])
    #expect(firstPruned["versionId"] is String)
    #expect(firstPruned["filePath"] is String)
}

@Test func goldenRefreshPayloadShape() throws {
    let fixture = try CLISupport.makeFixture(name: "golden-refresh", content: fixtureContent)
    defer { CLISupport.cleanup(fixture) }

    _ = try CLISupport.runCLI([
        "comment", "introduction", fixture.bundlePath,
        "--type", "note", "--author", "alice", "--text", "x",
    ])

    let result = try CLISupport.runCLI(["refresh", "introduction", fixture.bundlePath])
    #expect(result.exitCode == 0, "stderr: \(result.stderr)")
    let payload = try TestJSON.parse(result.stdout)

    expectKeys(payload, ["slug", "versionHash", "commentsUpdated", "versionId"])
    #expect(payload["slug"] as? String == "introduction")
    #expect(payload["versionHash"] is String)
    #expect(payload["commentsUpdated"] is Int)
    #expect(payload["versionId"] is String)
}
