// What Problem: `mdpal sections <bundle>` returns a JSON object with
// a recursive section tree. mdpal-app's outline view depends on the
// exact shape: camelCase keys, recursive children, top-level count
// and versionId.
//
// How & Why: Build a fixture bundle with a known structure, invoke the
// CLI, parse JSON, assert shape, content, error envelopes, and edge
// cases (empty bundle, missing bundle, bundle-is-file).
//
// Reference: usr/jordan/mdpal/dispatches/dispatch-cli-json-output-shapes-20260406.md
//
// Written: 2026-04-17 during mdpal-cli session (Phase 2 iteration 2.1)

import Testing
import Foundation

private let fixtureContent = """
# Introduction

Welcome to the document.

# Authentication

## OAuth

OAuth flow.

# Conclusion

The end.
"""

@Test func sectionsJSONShapeIsCamelCase() throws {
    let fixture = try CLISupport.makeFixture(name: "sections-test", content: fixtureContent)
    defer { CLISupport.cleanup(fixture) }

    let result = try CLISupport.runCLI(["sections", fixture.bundlePath])
    #expect(result.exitCode == 0, "stderr: \(result.stderr)")

    let payload = try TestJSON.parse(result.stdout)
    let sections = try #require(payload["sections"] as? [[String: Any]])
    #expect(sections.count == 3, "expected 3 top-level sections, got \(sections.count)")

    // Top-level fields per spec: count + versionId.
    #expect(payload["count"] as? Int == 4) // 3 top + 1 nested
    let versionId = try #require(payload["versionId"] as? String)
    #expect(versionId.hasPrefix("V"), "expected versionId like V0001.0001..., got '\(versionId)'")

    // camelCase keys (NOT snake_case — contract drift would break mdpal-app).
    let first = try #require(sections.first)
    #expect(first["slug"] as? String == "introduction")
    #expect(first["heading"] as? String == "Introduction")
    #expect(first["level"] as? Int == 1)
    #expect((first["versionHash"] as? String)?.isEmpty == false)
    #expect(first["children"] != nil)
    #expect(first["version_hash"] == nil, "snake_case key should not appear")
}

@Test func sectionsRecursiveTree() throws {
    let fixture = try CLISupport.makeFixture(name: "sections-tree", content: fixtureContent)
    defer { CLISupport.cleanup(fixture) }

    let result = try CLISupport.runCLI(["sections", fixture.bundlePath])
    #expect(result.exitCode == 0)

    let payload = try TestJSON.parse(result.stdout)
    let sections = try #require(payload["sections"] as? [[String: Any]])

    // Authentication should have OAuth nested inside its children.
    let auth = try #require(sections.first(where: { $0["slug"] as? String == "authentication" }))
    let authChildren = try #require(auth["children"] as? [[String: Any]])
    #expect(authChildren.count == 1)
    #expect(authChildren.first?["slug"] as? String == "authentication/oauth")
    #expect(authChildren.first?["level"] as? Int == 2)

    // Top-level introduction has empty children array (NOT missing — must be []).
    let intro = try #require(sections.first(where: { $0["slug"] as? String == "introduction" }))
    let introChildren = try #require(intro["children"] as? [[String: Any]])
    #expect(introChildren.isEmpty)
}

@Test func sectionsTextFormat() throws {
    let fixture = try CLISupport.makeFixture(name: "sections-text", content: fixtureContent)
    defer { CLISupport.cleanup(fixture) }

    let result = try CLISupport.runCLI(["sections", fixture.bundlePath, "--format", "text"])
    #expect(result.exitCode == 0)
    #expect(result.stdout.contains("introduction"))
    #expect(result.stdout.contains("authentication/oauth"))
    #expect(!result.stdout.contains("\"slug\""), "text format should not be JSON")
}

@Test func sectionsEmptyBundle() throws {
    let fixture = try CLISupport.makeFixture(name: "sections-empty", content: "")
    defer { CLISupport.cleanup(fixture) }

    let result = try CLISupport.runCLI(["sections", fixture.bundlePath])
    #expect(result.exitCode == 0, "stderr: \(result.stderr)")

    let payload = try TestJSON.parse(result.stdout)
    let sections = try #require(payload["sections"] as? [Any])
    #expect(sections.isEmpty)
    #expect(payload["count"] as? Int == 0)
}

@Test func sectionsEmptyBundleTextFormat() throws {
    let fixture = try CLISupport.makeFixture(name: "sections-empty-text", content: "")
    defer { CLISupport.cleanup(fixture) }

    let result = try CLISupport.runCLI(["sections", fixture.bundlePath, "--format", "text"])
    #expect(result.exitCode == 0)
    #expect(result.stdout.contains("(no sections)"))
}

@Test func sectionsMissingBundleEmitsExitCode1AndErrorEnvelope() throws {
    let result = try CLISupport.runCLI(["sections", "/nonexistent/path/to/bundle.mdpal"])
    #expect(result.exitCode == 1, "expected generalError exit code, got \(result.exitCode); stderr: \(result.stderr)")

    let envelope = try TestJSON.parse(result.stderr)
    let errorCode = try #require(envelope["error"] as? String)
    // Either invalidBundlePath (preferred) or fileError — both are valid
    // for a nonexistent path. Pin which one we actually emit so a future
    // refactor doesn't silently change the discriminator.
    #expect(errorCode == "invalidBundlePath" || errorCode == "fileError",
            "expected invalidBundlePath or fileError, got '\(errorCode)'")
    #expect((envelope["message"] as? String)?.isEmpty == false)
    #expect(envelope["code"] == nil, "old `code` field should not appear — spec is `error`")
}
