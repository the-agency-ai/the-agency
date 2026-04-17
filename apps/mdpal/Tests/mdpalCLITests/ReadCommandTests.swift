// What Problem: `mdpal read <slug> <bundle>` returns a single section
// with content, version_hash, and direct children. mdpal-app uses this
// when the user clicks into a section.
//
// How & Why: Build a fixture with known sections, invoke `mdpal read`
// on existing + nonexistent slugs, assert the wire format and the
// error path (section_not_found with suggestions).
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

@Test func readReturnsFullSectionAsJSON() throws {
    let bundle = try CLISupport.makeFixture(name: "read-test", content: fixtureContent)
    defer { CLISupport.cleanup(bundle) }

    let result = try CLISupport.runCLI(["read", "introduction", bundle])
    #expect(result.exitCode == 0, "stderr: \(result.stderr)")

    let payload = try TestJSON.parse(result.stdout)
    #expect(payload["slug"] as? String == "introduction")
    #expect(payload["heading"] as? String == "Introduction")
    #expect(payload["level"] as? Int == 1)
    #expect((payload["content"] as? String)?.contains("Welcome.") == true)
    #expect((payload["version_hash"] as? String)?.isEmpty == false)
    #expect(payload["children"] as? [Any] != nil)
}

@Test func readNestedSection() throws {
    let bundle = try CLISupport.makeFixture(name: "read-nested", content: fixtureContent)
    defer { CLISupport.cleanup(bundle) }

    let result = try CLISupport.runCLI(["read", "authentication/oauth", bundle])
    #expect(result.exitCode == 0)
    let payload = try TestJSON.parse(result.stdout)
    #expect(payload["slug"] as? String == "authentication/oauth")
    #expect(payload["level"] as? Int == 2)
    #expect((payload["content"] as? String)?.contains("OAuth flow.") == true)
}

@Test func readSectionWithChildren() throws {
    let bundle = try CLISupport.makeFixture(name: "read-children", content: fixtureContent)
    defer { CLISupport.cleanup(bundle) }

    let result = try CLISupport.runCLI(["read", "authentication", bundle])
    #expect(result.exitCode == 0)
    let payload = try TestJSON.parse(result.stdout)
    let children = try #require(payload["children"] as? [[String: Any]])
    #expect(children.count == 1)
    #expect(children.first?["slug"] as? String == "authentication/oauth")
}

@Test func readNonexistentSlugReturnsExitCode3() throws {
    let bundle = try CLISupport.makeFixture(name: "read-missing", content: fixtureContent)
    defer { CLISupport.cleanup(bundle) }

    let result = try CLISupport.runCLI(["read", "nonexistent-slug", bundle])
    #expect(result.exitCode == 3, "expected notFound exit code, got \(result.exitCode)")

    let envelope = try TestJSON.parse(result.stderr)
    #expect(envelope["code"] as? String == "section_not_found")
    let details = try #require(envelope["details"] as? [String: Any])
    #expect(details["slug"] as? String == "nonexistent-slug")
    #expect(details["suggestions"] != nil)
}

@Test func readTextFormat() throws {
    let bundle = try CLISupport.makeFixture(name: "read-text", content: fixtureContent)
    defer { CLISupport.cleanup(bundle) }

    let result = try CLISupport.runCLI(["read", "introduction", bundle, "--format", "text"])
    #expect(result.exitCode == 0)
    #expect(result.stdout.contains("# Introduction"))
    #expect(result.stdout.contains("slug:"))
    #expect(result.stdout.contains("Welcome."))
    #expect(!result.stdout.contains("\"slug\""), "text format should not be JSON")
}
