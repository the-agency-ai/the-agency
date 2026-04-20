// What Problem: `mdpal read <slug> <bundle>` returns a single section
// with content, versionHash, and versionId. mdpal-app uses this when
// the user clicks into a section.
//
// How & Why: Build a fixture, exercise existing slugs, nested slugs,
// not-found (with availableSlugs suggestion check), and text format.
// Wire format must be camelCase per dispatched spec.
//
// Reference: usr/jordan/mdpal/dispatches/dispatch-cli-json-output-shapes-20260406.md
//
// Written: 2026-04-17 during mdpal-cli session (Phase 2 iteration 2.1)

import Testing
import Foundation

private let fixtureContent = """
# Introduction

Welcome.

# Authentication

Auth overview.

## OAuth

OAuth flow.
"""

@Test func readReturnsFullSectionAsCamelCaseJSON() throws {
    let fixture = try CLISupport.makeFixture(name: "read-test", content: fixtureContent)
    defer { CLISupport.cleanup(fixture) }

    let result = try CLISupport.runCLI(["read", "introduction", fixture.bundlePath])
    #expect(result.exitCode == 0, "stderr: \(result.stderr)")

    let payload = try TestJSON.parse(result.stdout)
    #expect(payload["slug"] as? String == "introduction")
    #expect(payload["heading"] as? String == "Introduction")
    #expect(payload["level"] as? Int == 1)
    #expect((payload["content"] as? String)?.contains("Welcome.") == true)
    #expect((payload["versionHash"] as? String)?.isEmpty == false)
    #expect((payload["versionId"] as? String)?.hasPrefix("V") == true)
    #expect(payload["version_hash"] == nil, "snake_case key must not appear")
}

@Test func readNestedSection() throws {
    let fixture = try CLISupport.makeFixture(name: "read-nested", content: fixtureContent)
    defer { CLISupport.cleanup(fixture) }

    let result = try CLISupport.runCLI(["read", "authentication/oauth", fixture.bundlePath])
    #expect(result.exitCode == 0)
    let payload = try TestJSON.parse(result.stdout)
    #expect(payload["slug"] as? String == "authentication/oauth")
    #expect(payload["level"] as? Int == 2)
    #expect((payload["content"] as? String)?.contains("OAuth flow.") == true)
}

@Test func readNonexistentSlugReturnsExitCode3WithSuggestions() throws {
    let fixture = try CLISupport.makeFixture(name: "read-missing", content: fixtureContent)
    defer { CLISupport.cleanup(fixture) }

    // Use a near-miss slug so the engine's suggestion machinery has a
    // realistic chance of producing a non-empty availableSlugs list.
    let result = try CLISupport.runCLI(["read", "introducton", fixture.bundlePath])
    #expect(result.exitCode == 3, "expected notFound exit code, got \(result.exitCode); stderr: \(result.stderr)")

    let envelope = try TestJSON.parse(result.stderr)
    #expect(envelope["error"] as? String == "sectionNotFound")
    let details = try #require(envelope["details"] as? [String: Any])
    #expect(details["slug"] as? String == "introducton")
    let suggestions = try #require(details["availableSlugs"] as? [String])
    // Suggestions should at least include the available slugs from the doc.
    // (The exact fuzzy-match behavior is engine-side; we just check the
    // field is well-typed and non-degenerate.)
    #expect(!suggestions.isEmpty, "expected non-empty availableSlugs for a near-miss")
}

@Test func readTextFormat() throws {
    let fixture = try CLISupport.makeFixture(name: "read-text", content: fixtureContent)
    defer { CLISupport.cleanup(fixture) }

    let result = try CLISupport.runCLI(["read", "introduction", fixture.bundlePath, "--format", "text"])
    #expect(result.exitCode == 0)
    #expect(result.stdout.contains("# Introduction"))
    #expect(result.stdout.contains("slug:"))
    #expect(result.stdout.contains("versionId:"))
    #expect(result.stdout.contains("Welcome."))
    #expect(!result.stdout.contains("\"slug\""), "text format should not be JSON")
}

@Test func rootHelpListsSubcommands() throws {
    let result = try CLISupport.runCLI(["--help"])
    #expect(result.exitCode == 0)
    #expect(result.stdout.contains("sections"))
    #expect(result.stdout.contains("read"))
    // Iter 2.4 adds the bundle-management commands; check a representative
    // subset surfaces in --help.
    #expect(result.stdout.contains("create"))
    #expect(result.stdout.contains("history"))
    #expect(result.stdout.contains("version"))
    #expect(result.stdout.contains("revision"))
    #expect(result.stdout.contains("diff"))
    #expect(result.stdout.contains("prune"))
    #expect(result.stdout.contains("refresh"))
    // The tool version is also exposed via the --version flag (separate
    // from the `version` subcommand group, which targets DOCUMENT versions).
    #expect(result.stdout.contains("--version"))
}

@Test func rootVersionFlagPrintsToolVersion() throws {
    let result = try CLISupport.runCLI(["--version"])
    #expect(result.exitCode == 0)
    #expect(result.stdout.contains("0."), "expected a version number, got '\(result.stdout)'")
}
