// What Problem: `mdpal flag`, `mdpal flags`, `mdpal clear-flag`
// implement the section flag lifecycle. Wire shapes per dispatched spec.
//
// How & Why: Build a fixture, flag sections, list, clear, verify.
//
// Reference: usr/jordan/mdpal/dispatches/dispatch-cli-json-output-shapes-20260406.md
//
// Written: 2026-04-17 during mdpal-cli session (Phase 2 iteration 2.3)

import Testing
import Foundation

private let fixtureContent = """
# Introduction

Welcome.

# Architecture

Design here.
"""

@Test func flagSetsFlagAndReturnsPayload() throws {
    let fixture = try CLISupport.makeFixture(name: "flag-set", content: fixtureContent)
    defer { CLISupport.cleanup(fixture) }

    let result = try CLISupport.runCLI([
        "flag", "introduction", fixture.bundlePath,
        "--author", "jordan",
        "--note", "needs review",
    ])
    #expect(result.exitCode == 0, "stderr: \(result.stderr)")

    let payload = try TestJSON.parse(result.stdout)
    #expect(payload["slug"] as? String == "introduction")
    #expect(payload["flagged"] as? Bool == true)
    #expect(payload["author"] as? String == "jordan")
    #expect(payload["note"] as? String == "needs review")
    #expect(payload["timestamp"] != nil)
    // engine field `sectionSlug` must not leak.
    #expect(payload["sectionSlug"] == nil)
}

@Test func flagWithoutNote() throws {
    let fixture = try CLISupport.makeFixture(name: "flag-no-note", content: fixtureContent)
    defer { CLISupport.cleanup(fixture) }

    let result = try CLISupport.runCLI([
        "flag", "introduction", fixture.bundlePath,
        "--author", "jordan",
    ])
    #expect(result.exitCode == 0, "stderr: \(result.stderr)")
    let payload = try TestJSON.parse(result.stdout)
    #expect(payload["note"] is NSNull, "missing --note should serialize as null")
}

@Test func flagNonexistentSectionReturnsExitCode3() throws {
    let fixture = try CLISupport.makeFixture(name: "flag-missing", content: fixtureContent)
    defer { CLISupport.cleanup(fixture) }

    let result = try CLISupport.runCLI([
        "flag", "nope", fixture.bundlePath,
        "--author", "jordan",
    ])
    #expect(result.exitCode == 3)
    let envelope = try TestJSON.parse(result.stderr)
    #expect(envelope["error"] as? String == "sectionNotFound")
}

@Test func flagsListReturnsAllFlagsWithCount() throws {
    let fixture = try CLISupport.makeFixture(name: "flags-list", content: fixtureContent)
    defer { CLISupport.cleanup(fixture) }

    _ = try CLISupport.runCLI(["flag", "introduction", fixture.bundlePath, "--author", "alice"])
    _ = try CLISupport.runCLI(["flag", "architecture", fixture.bundlePath, "--author", "bob", "--note", "tbd"])

    let result = try CLISupport.runCLI(["flags", fixture.bundlePath])
    #expect(result.exitCode == 0, "stderr: \(result.stderr)")
    let payload = try TestJSON.parse(result.stdout)
    let flags = try #require(payload["flags"] as? [[String: Any]])
    #expect(flags.count == 2)
    #expect(payload["count"] as? Int == 2)

    // List entries should NOT carry `flagged: true` (that's only on the
    // single-flag payload from `flag` command — see FlagListEntryPayload).
    let first = try #require(flags.first)
    #expect(first["flagged"] == nil, "list entries should not carry redundant `flagged` field")
    #expect(first["slug"] != nil)
    #expect(first["author"] != nil)
}

@Test func flagsListEmptyBundle() throws {
    let fixture = try CLISupport.makeFixture(name: "flags-empty", content: fixtureContent)
    defer { CLISupport.cleanup(fixture) }

    let result = try CLISupport.runCLI(["flags", fixture.bundlePath])
    #expect(result.exitCode == 0)
    let payload = try TestJSON.parse(result.stdout)
    #expect((payload["flags"] as? [Any])?.isEmpty == true)
    #expect(payload["count"] as? Int == 0)
}

@Test func clearFlagRemovesFlag() throws {
    let fixture = try CLISupport.makeFixture(name: "clear-flag", content: fixtureContent)
    defer { CLISupport.cleanup(fixture) }

    _ = try CLISupport.runCLI(["flag", "introduction", fixture.bundlePath, "--author", "alice"])

    let result = try CLISupport.runCLI(["clear-flag", "introduction", fixture.bundlePath])
    #expect(result.exitCode == 0, "stderr: \(result.stderr)")
    let payload = try TestJSON.parse(result.stdout)
    #expect(payload["slug"] as? String == "introduction")
    #expect(payload["flagged"] as? Bool == false)

    // Verify the flag is actually gone via flags list.
    let listResult = try CLISupport.runCLI(["flags", fixture.bundlePath])
    let listPayload = try TestJSON.parse(listResult.stdout)
    #expect((listPayload["flags"] as? [Any])?.isEmpty == true)
}

@Test func clearFlagOnUnflaggedSectionReturnsExitCode1() throws {
    let fixture = try CLISupport.makeFixture(name: "clear-no-flag", content: fixtureContent)
    defer { CLISupport.cleanup(fixture) }

    let result = try CLISupport.runCLI(["clear-flag", "introduction", fixture.bundlePath])
    #expect(result.exitCode != 0)
    let envelope = try TestJSON.parse(result.stderr)
    #expect(envelope["error"] as? String == "sectionNotFlagged")
}
