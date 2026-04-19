// What Problem: `mdpal history <bundle>` lists every revision newest-
// first, marking the latest with `latest: true`. Top-level fields:
// {revisions, count, currentVersion}. mdpal-app's version-history view
// drives this.
//
// How & Why: Build a fixture, append revisions, call history, verify
// order and the latest marker.
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

@Test func historySingleRevisionMarksLatest() throws {
    let fixture = try CLISupport.makeFixture(name: "history-one", content: fixtureContent)
    defer { CLISupport.cleanup(fixture) }

    let result = try CLISupport.runCLI(["history", fixture.bundlePath])
    #expect(result.exitCode == 0, "stderr: \(result.stderr)")

    let payload = try TestJSON.parse(result.stdout)
    let revisions = try #require(payload["revisions"] as? [[String: Any]])
    #expect(revisions.count == 1)
    #expect(payload["count"] as? Int == 1)
    #expect(payload["currentVersion"] as? Int == 1)
    let only = try #require(revisions.first)
    #expect(only["latest"] as? Bool == true)
    #expect((only["versionId"] as? String)?.hasPrefix("V0001.0001.") == true)
    let filePath = try #require(only["filePath"] as? String)
    #expect(filePath.hasSuffix(".md"))
    // filePath is a basename, NOT an absolute path.
    #expect(!filePath.hasPrefix("/"))
}

@Test func historyMultipleRevisionsAreNewestFirst() throws {
    let fixture = try CLISupport.makeFixture(name: "history-many", content: fixtureContent)
    defer { CLISupport.cleanup(fixture) }

    // Add a second revision via edit (each successful edit appends).
    let listResult = try CLISupport.runCLI(["sections", fixture.bundlePath])
    let listPayload = try TestJSON.parse(listResult.stdout)
    let sections = try #require(listPayload["sections"] as? [[String: Any]])
    let firstHash = try #require(sections.first?["versionHash"] as? String)
    let editResult = try CLISupport.runCLI([
        "edit", "introduction", fixture.bundlePath,
        "--version", firstHash,
        "--content", "Updated content.",
    ])
    #expect(editResult.exitCode == 0, "stderr: \(editResult.stderr)")

    let result = try CLISupport.runCLI(["history", fixture.bundlePath])
    #expect(result.exitCode == 0, "stderr: \(result.stderr)")

    let payload = try TestJSON.parse(result.stdout)
    let revisions = try #require(payload["revisions"] as? [[String: Any]])
    #expect(revisions.count == 2)
    #expect(payload["count"] as? Int == 2)
    // Newest-first: revision 2 before revision 1.
    #expect(revisions[0]["revision"] as? Int == 2)
    #expect(revisions[1]["revision"] as? Int == 1)
    #expect(revisions[0]["latest"] as? Bool == true)
    #expect(revisions[1]["latest"] as? Bool == false)
}

@Test func historyOnInvalidBundleFails() throws {
    let result = try CLISupport.runCLI(["history", "/nonexistent/missing.mdpal"])
    #expect(result.exitCode != 0)
    let envelope = try TestJSON.parse(result.stderr)
    let errorValue = try #require(envelope["error"] as? String)
    // Either fileError (path missing) or invalidBundlePath depending on
    // resolution order — both are acceptable.
    #expect(["fileError", "invalidBundlePath"].contains(errorValue))
}

// QG coverage T6: timestamp field per revision must be ISO-8601 (per spec
// type table). Pre-fix this field was emitted but never asserted.
@Test func historyEmitsIso8601TimestampPerRevision() throws {
    let fixture = try CLISupport.makeFixture(name: "history-timestamp", content: fixtureContent)
    defer { CLISupport.cleanup(fixture) }

    let result = try CLISupport.runCLI(["history", fixture.bundlePath])
    #expect(result.exitCode == 0)
    let payload = try TestJSON.parse(result.stdout)
    let revisions = try #require(payload["revisions"] as? [[String: Any]])
    let first = try #require(revisions.first)
    let timestamp = try #require(first["timestamp"] as? String)
    // ISO-8601 form ends in Z and has T as date/time separator.
    #expect(timestamp.contains("T"))
    #expect(timestamp.hasSuffix("Z"))
    // Format like "2026-04-17T06:47:00Z" — at least 20 chars.
    #expect(timestamp.count >= 20)
}

// QG fix F5 bug-exposing test: an empty bundle (no revisions) must emit
// `currentVersion: null` (explicit null, key present). Pre-fix it emitted
// `currentVersion: 0` — a fabricated value that mdpal-app could mistake
// for a real document version.
@Test func historyOnEmptyBundleEmitsCurrentVersionNull() throws {
    // Construct a bundle then manually delete its single revision file so
    // listRevisions returns []. We use the engine type directly because
    // the CLI has no command to delete a revision in isolation.
    let tempDir = FileManager.default.temporaryDirectory
        .appendingPathComponent("mdpal-history-empty-\(UUID().uuidString)")
    let bundlePath = tempDir.appendingPathComponent("empty.mdpal").path
    try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: tempDir) }

    let createResult = try CLISupport.runCLI([
        "create", "empty",
        "--dir", tempDir.path,
    ])
    #expect(createResult.exitCode == 0, "stderr: \(createResult.stderr)")
    // Delete every revision file at the bundle root.
    let entries = try FileManager.default.contentsOfDirectory(atPath: bundlePath)
    for entry in entries where entry.hasSuffix(".md") && entry != "latest.md" {
        try FileManager.default.removeItem(atPath: "\(bundlePath)/\(entry)")
    }

    let result = try CLISupport.runCLI(["history", bundlePath])
    #expect(result.exitCode == 0, "stderr: \(result.stderr)")
    let payload = try TestJSON.parse(result.stdout)
    #expect((payload["revisions"] as? [[String: Any]])?.isEmpty == true)
    #expect(payload["count"] as? Int == 0)
    // The KEY must be present; value must be NSNull (explicit null).
    #expect(payload["currentVersion"] is NSNull, "currentVersion must be explicit null on empty bundle, got \(String(describing: payload["currentVersion"]))")
}
