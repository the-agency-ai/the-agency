// What Problem: `mdpal sections <bundle>` returns a JSON array of
// SectionInfo. mdpal-app's outline view depends on the exact shape:
// snake_case keys, ordered top-to-bottom, level + slug + heading +
// version_hash + child_count fields present.
//
// How & Why: Build a fixture bundle with a known structure (3 top-level
// sections, 1 nested), invoke the CLI, parse JSON, assert shape and
// content. Cover error paths (missing bundle → file_error or
// invalid_bundle_path).
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

@Test func sectionsJSONShape() throws {
    let bundle = try CLISupport.makeFixture(name: "sections-test", content: fixtureContent)
    defer { CLISupport.cleanup(bundle) }

    let result = try CLISupport.runCLI(["sections", bundle])
    #expect(result.exitCode == 0, "stderr: \(result.stderr)")

    let payload = try TestJSON.parse(result.stdout)
    let sections = payload["sections"] as? [[String: Any]]
    #expect(sections != nil, "Expected `sections` array, got: \(result.stdout)")
    #expect(sections?.count == 4)

    // Snake-case keys.
    let first = try #require(sections?.first)
    #expect(first["slug"] as? String == "introduction")
    #expect(first["heading"] as? String == "Introduction")
    #expect(first["level"] as? Int == 1)
    #expect((first["version_hash"] as? String)?.isEmpty == false)
    #expect(first["child_count"] as? Int == 0)

    // Authentication has one child (oauth).
    let auth = try #require(sections?.first(where: { $0["slug"] as? String == "authentication" }))
    #expect(auth["child_count"] as? Int == 1)
    #expect(auth["level"] as? Int == 1)

    // Nested section uses path-style slug.
    let oauth = try #require(sections?.first(where: { $0["slug"] as? String == "authentication/oauth" }))
    #expect(oauth["level"] as? Int == 2)
}

@Test func sectionsTextFormat() throws {
    let bundle = try CLISupport.makeFixture(name: "sections-text", content: fixtureContent)
    defer { CLISupport.cleanup(bundle) }

    let result = try CLISupport.runCLI(["sections", bundle, "--format", "text"])
    #expect(result.exitCode == 0)
    #expect(result.stdout.contains("introduction"))
    #expect(result.stdout.contains("authentication/oauth"))
    #expect(!result.stdout.contains("\"slug\""), "text format should not be JSON")
}

@Test func sectionsMissingBundleErrors() throws {
    let result = try CLISupport.runCLI(["sections", "/nonexistent/path/to/bundle.mdpal"])
    #expect(result.exitCode != 0)
    // Error envelope on stderr; stdout should be empty (or at least not the
    // success payload).
    #expect(!result.stdout.contains("\"sections\""))
    #expect(!result.stderr.isEmpty)
}

@Test func sectionsErrorEnvelopeIsJSON() throws {
    let result = try CLISupport.runCLI(["sections", "/nonexistent/path/to/bundle.mdpal"])
    #expect(result.exitCode != 0)
    let envelope = try TestJSON.parse(result.stderr)
    #expect((envelope["code"] as? String)?.isEmpty == false)
    #expect((envelope["message"] as? String)?.isEmpty == false)
}
