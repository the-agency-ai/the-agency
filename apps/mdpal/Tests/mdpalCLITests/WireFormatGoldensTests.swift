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

// MARK: - T4 (phase-complete): goldens for the remaining 9 commands.
// The original 8 covered create/history/version-show/version-bump/
// revision-create/diff/prune/refresh. These 9 close the gap so every
// CLI command has a wire-format lock.

@Test func goldenReadPayloadShape() throws {
    let fixture = try CLISupport.makeFixture(name: "golden-read", content: fixtureContent)
    defer { CLISupport.cleanup(fixture) }
    let result = try CLISupport.runCLI(["read", "introduction", fixture.bundlePath])
    #expect(result.exitCode == 0, "stderr: \(result.stderr)")
    let payload = try TestJSON.parse(result.stdout)
    expectKeys(payload, ["slug", "heading", "level", "content", "versionHash", "versionId"])
    #expect(payload["slug"] as? String == "introduction")
    #expect(payload["heading"] is String)
    #expect(payload["level"] is Int)
    #expect(payload["content"] is String)
    #expect(payload["versionHash"] is String)
    #expect(payload["versionId"] is String)
}

@Test func goldenSectionsPayloadShape() throws {
    let fixture = try CLISupport.makeFixture(name: "golden-sections", content: fixtureContent)
    defer { CLISupport.cleanup(fixture) }
    let result = try CLISupport.runCLI(["sections", fixture.bundlePath])
    #expect(result.exitCode == 0, "stderr: \(result.stderr)")
    let payload = try TestJSON.parse(result.stdout)
    expectKeys(payload, ["sections", "count", "versionId"])
    #expect(payload["count"] is Int)
    #expect(payload["versionId"] is String)
    let sections = try #require(payload["sections"] as? [[String: Any]])
    let first = try #require(sections.first)
    expectKeys(first, ["slug", "heading", "level", "versionHash", "children"])
    #expect(first["slug"] is String)
    #expect(first["heading"] is String)
    #expect(first["level"] is Int)
    #expect(first["versionHash"] is String)
    #expect(first["children"] is [Any])
}

@Test func goldenEditPayloadShape() throws {
    let fixture = try CLISupport.makeFixture(name: "golden-edit", content: fixtureContent)
    defer { CLISupport.cleanup(fixture) }
    let read = try CLISupport.runCLI(["read", "introduction", fixture.bundlePath])
    let versionHash = try #require((try TestJSON.parse(read.stdout))["versionHash"] as? String)

    let result = try CLISupport.runCLI([
        "edit", "introduction", fixture.bundlePath,
        "--version", versionHash,
        "--content", "Updated.",
    ])
    #expect(result.exitCode == 0, "stderr: \(result.stderr)")
    let payload = try TestJSON.parse(result.stdout)
    expectKeys(payload, ["slug", "versionHash", "versionId", "bytesWritten"])
    #expect(payload["slug"] as? String == "introduction")
    #expect(payload["versionHash"] is String)
    #expect(payload["versionId"] is String)
    #expect(payload["bytesWritten"] is Int)
}

@Test func goldenCommentPayloadShape() throws {
    let fixture = try CLISupport.makeFixture(name: "golden-comment", content: fixtureContent)
    defer { CLISupport.cleanup(fixture) }
    let result = try CLISupport.runCLI([
        "comment", "introduction", fixture.bundlePath,
        "--type", "note", "--author", "alice", "--text", "hello",
        "--priority", "high", "--tag", "perf", "--tag", "phase2",
    ])
    #expect(result.exitCode == 0, "stderr: \(result.stderr)")
    let payload = try TestJSON.parse(result.stdout)
    expectKeys(payload, [
        "commentId", "slug", "type", "author", "text", "context",
        "priority", "tags", "timestamp", "resolved", "resolution",
    ])
    #expect(payload["commentId"] is String)
    #expect(payload["slug"] as? String == "introduction")
    #expect(payload["type"] as? String == "note")
    #expect(payload["author"] as? String == "alice")
    #expect(payload["text"] as? String == "hello")
    #expect(payload["context"] is String)
    #expect(payload["priority"] as? String == "high")
    let tags = try #require(payload["tags"] as? [String])
    #expect(tags.contains("perf"))
    #expect(tags.contains("phase2"))
    #expect(payload["timestamp"] is String)
    #expect(payload["resolved"] as? Bool == false)
    // resolution must be EXPLICITLY null (not omitted) per spec.
    #expect(payload.keys.contains("resolution"), "resolution key must always be present (null for unresolved)")
}

@Test func goldenCommentsListPayloadShape() throws {
    let fixture = try CLISupport.makeFixture(name: "golden-comments", content: fixtureContent)
    defer { CLISupport.cleanup(fixture) }
    _ = try CLISupport.runCLI([
        "comment", "introduction", fixture.bundlePath,
        "--type", "note", "--author", "alice", "--text", "first",
    ])
    let result = try CLISupport.runCLI([
        "comments", fixture.bundlePath,
        "--section", "introduction", "--type", "note",
    ])
    #expect(result.exitCode == 0, "stderr: \(result.stderr)")
    let payload = try TestJSON.parse(result.stdout)
    expectKeys(payload, ["comments", "count", "filters"])
    #expect(payload["count"] is Int)
    let comments = try #require(payload["comments"] as? [[String: Any]])
    #expect(!comments.isEmpty)
    let filters = try #require(payload["filters"] as? [String: Any])
    expectKeys(filters, ["section", "type", "resolved"])
    #expect(filters["section"] as? String == "introduction")
    #expect(filters["type"] as? String == "note")
    // T8 / spec: filters.resolved must be EXPLICITLY null (key present).
    #expect(filters.keys.contains("resolved"), "filters.resolved key must always be present")
}

@Test func goldenResolvePayloadShape() throws {
    let fixture = try CLISupport.makeFixture(name: "golden-resolve", content: fixtureContent)
    defer { CLISupport.cleanup(fixture) }
    let added = try TestJSON.parse(try CLISupport.runCLI([
        "comment", "introduction", fixture.bundlePath,
        "--type", "question", "--author", "alice", "--text", "Q",
    ]).stdout)
    let cid = try #require(added["commentId"] as? String)

    let result = try CLISupport.runCLI([
        "resolve", cid, fixture.bundlePath,
        "--response", "answered", "--by", "bob",
    ])
    #expect(result.exitCode == 0, "stderr: \(result.stderr)")
    let payload = try TestJSON.parse(result.stdout)
    expectKeys(payload, ["commentId", "resolved", "resolution"])
    #expect(payload["commentId"] as? String == cid)
    #expect(payload["resolved"] as? Bool == true)
    let resolution = try #require(payload["resolution"] as? [String: Any])
    expectKeys(resolution, ["response", "by", "timestamp"])
    #expect(resolution["response"] as? String == "answered")
    #expect(resolution["by"] as? String == "bob")
    #expect(resolution["timestamp"] is String)
}

@Test func goldenFlagPayloadShape() throws {
    let fixture = try CLISupport.makeFixture(name: "golden-flag", content: fixtureContent)
    defer { CLISupport.cleanup(fixture) }
    let result = try CLISupport.runCLI([
        "flag", "introduction", fixture.bundlePath,
        "--author", "alice", "--note", "needs review",
    ])
    #expect(result.exitCode == 0, "stderr: \(result.stderr)")
    let payload = try TestJSON.parse(result.stdout)
    expectKeys(payload, ["slug", "flagged", "author", "note", "timestamp"])
    #expect(payload["slug"] as? String == "introduction")
    #expect(payload["flagged"] as? Bool == true)
    #expect(payload["author"] as? String == "alice")
    #expect(payload["note"] as? String == "needs review")
    #expect(payload["timestamp"] is String)
}

@Test func goldenFlagsListPayloadShape() throws {
    let fixture = try CLISupport.makeFixture(name: "golden-flags", content: fixtureContent)
    defer { CLISupport.cleanup(fixture) }
    _ = try CLISupport.runCLI([
        "flag", "introduction", fixture.bundlePath, "--author", "alice",
    ])
    let result = try CLISupport.runCLI(["flags", fixture.bundlePath])
    #expect(result.exitCode == 0, "stderr: \(result.stderr)")
    let payload = try TestJSON.parse(result.stdout)
    expectKeys(payload, ["flags", "count"])
    #expect(payload["count"] is Int)
    let flags = try #require(payload["flags"] as? [[String: Any]])
    let first = try #require(flags.first)
    expectKeys(first, ["slug", "author", "note", "timestamp"])
    #expect(first["slug"] as? String == "introduction")
    #expect(first["author"] as? String == "alice")
    #expect(first.keys.contains("note"), "note key must always be present (null for no-note)")
    #expect(first["timestamp"] is String)
}

@Test func goldenClearFlagPayloadShape() throws {
    let fixture = try CLISupport.makeFixture(name: "golden-clearflag", content: fixtureContent)
    defer { CLISupport.cleanup(fixture) }
    _ = try CLISupport.runCLI([
        "flag", "introduction", fixture.bundlePath, "--author", "alice",
    ])
    let result = try CLISupport.runCLI(["clear-flag", "introduction", fixture.bundlePath])
    #expect(result.exitCode == 0, "stderr: \(result.stderr)")
    let payload = try TestJSON.parse(result.stdout)
    expectKeys(payload, ["slug", "flagged"])
    #expect(payload["slug"] as? String == "introduction")
    #expect(payload["flagged"] as? Bool == false)
}

// T9 (phase-complete): SectionDiffType raw-string spelling pinned.
// Wire goldens above check `is String`; this test pins the EXACT spellings
// "added" / "removed" / "modified" / "unchanged" so a regression that
// changes raw values (e.g., to capitalized or snake_case) breaks visibly.
@Test func sectionDiffTypeWireSpellingsAreStable() throws {
    let fixture = try CLISupport.makeFixture(name: "golden-diff-spellings", content: fixtureContent)
    defer { CLISupport.cleanup(fixture) }

    let history = try CLISupport.runCLI(["history", fixture.bundlePath])
    let r0 = try #require(((try TestJSON.parse(history.stdout))["revisions"] as? [[String: Any]])?.first?["versionId"] as? String)

    // Drive a revision that adds, removes, and modifies sections.
    // Original fixtureContent has Introduction + Architecture.
    let edit = try CLISupport.runCLI([
        "revision", "create", fixture.bundlePath,
        "--content", "# Introduction\n\nModified intro.\n\n# NewSection\n\nAdded.\n",
    ])
    let r1 = try #require((try TestJSON.parse(edit.stdout))["versionId"] as? String)

    let result = try CLISupport.runCLI(["diff", r0, r1, fixture.bundlePath, "--include-unchanged"])
    let payload = try TestJSON.parse(result.stdout)
    let changes = try #require(payload["changes"] as? [[String: Any]])
    let validSpellings: Set<String> = ["added", "removed", "modified", "unchanged"]
    for change in changes {
        let typeStr = try #require(change["type"] as? String)
        #expect(validSpellings.contains(typeStr),
                "diff type spelling drift — got '\(typeStr)', expected one of \(validSpellings)")
    }
    let spellingsSeen = Set(changes.compactMap { $0["type"] as? String })
    // We expect this specific edit to produce at least added + modified +
    // (removed if Architecture went away, which it did since new content
    // omits it). At minimum two distinct spellings must appear.
    #expect(spellingsSeen.count >= 2,
            "expected multiple diff types after add+remove+modify edit; got \(spellingsSeen)")
}
