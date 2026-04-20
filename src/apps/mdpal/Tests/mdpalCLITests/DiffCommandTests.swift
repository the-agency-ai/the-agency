// What Problem: `mdpal diff <rev1> <rev2> <bundle>` returns the
// section-level diff between two revisions. Wire shape: {from, to,
// changes:[{slug, type, summary}], count}. Unchanged sections are
// omitted by default; --include-unchanged emits them.
//
// How & Why: Build a fixture with multiple revisions that exercise
// modified/added/removed; verify the wire shape and ordering.
//
// Reference: usr/jordan/mdpal/dispatches/dispatch-cli-json-output-shapes-20260406.md
//
// Written: 2026-04-17 during mdpal-cli session (Phase 2 iteration 2.4)

import Testing
import Foundation

private let initialContent = """
# Introduction

Intro body.

# Architecture

Old architecture.

# Testing

Testing body.
"""

private let updatedContent = """
# Introduction

Intro body.

# Architecture

New architecture body, much longer than before.

# Deployment

A brand new section.
"""

@Test func diffShowsAddedRemovedAndModified() throws {
    let fixture = try CLISupport.makeFixture(name: "diff-mix", content: initialContent)
    defer { CLISupport.cleanup(fixture) }

    let history0 = try CLISupport.runCLI(["history", fixture.bundlePath])
    let h0Payload = try TestJSON.parse(history0.stdout)
    let r0 = try #require((h0Payload["revisions"] as? [[String: Any]])?.first?["versionId"] as? String)

    // Replace contents with updatedContent via revision create.
    let createResult = try CLISupport.runCLI([
        "revision", "create", fixture.bundlePath,
        "--content", updatedContent,
    ])
    #expect(createResult.exitCode == 0, "stderr: \(createResult.stderr)")
    let r1 = try #require((try TestJSON.parse(createResult.stdout))["versionId"] as? String)

    let result = try CLISupport.runCLI(["diff", r0, r1, fixture.bundlePath])
    #expect(result.exitCode == 0, "stderr: \(result.stderr)")

    let payload = try TestJSON.parse(result.stdout)
    #expect(payload["from"] as? String == r0)
    #expect(payload["to"] as? String == r1)
    let changes = try #require(payload["changes"] as? [[String: Any]])
    let typeBySlug = Dictionary(uniqueKeysWithValues:
        changes.compactMap { c -> (String, String)? in
            guard let slug = c["slug"] as? String, let type = c["type"] as? String else { return nil }
            return (slug, type)
        }
    )
    #expect(typeBySlug["architecture"] == "modified")
    #expect(typeBySlug["deployment"] == "added")
    #expect(typeBySlug["testing"] == "removed")
    // Unchanged sections (introduction) are omitted by default.
    #expect(typeBySlug["introduction"] == nil)
    #expect(payload["count"] as? Int == 3)
}

@Test func diffWithIncludeUnchangedEmitsAllSections() throws {
    let fixture = try CLISupport.makeFixture(name: "diff-all", content: initialContent)
    defer { CLISupport.cleanup(fixture) }

    let history0 = try CLISupport.runCLI(["history", fixture.bundlePath])
    let h0Payload = try TestJSON.parse(history0.stdout)
    let r0 = try #require((h0Payload["revisions"] as? [[String: Any]])?.first?["versionId"] as? String)

    let createResult = try CLISupport.runCLI([
        "revision", "create", fixture.bundlePath,
        "--content", updatedContent,
    ])
    let r1 = try #require((try TestJSON.parse(createResult.stdout))["versionId"] as? String)

    let result = try CLISupport.runCLI([
        "diff", r0, r1, fixture.bundlePath,
        "--include-unchanged",
    ])
    #expect(result.exitCode == 0, "stderr: \(result.stderr)")

    let payload = try TestJSON.parse(result.stdout)
    let changes = try #require(payload["changes"] as? [[String: Any]])
    let typeBySlug = Dictionary(uniqueKeysWithValues:
        changes.compactMap { c -> (String, String)? in
            guard let slug = c["slug"] as? String, let type = c["type"] as? String else { return nil }
            return (slug, type)
        }
    )
    #expect(typeBySlug["introduction"] == "unchanged")
    #expect(typeBySlug["architecture"] == "modified")
    #expect(typeBySlug["deployment"] == "added")
    #expect(typeBySlug["testing"] == "removed")
}

@Test func diffSameRevisionEmitsNoChangesByDefault() throws {
    let fixture = try CLISupport.makeFixture(name: "diff-self", content: initialContent)
    defer { CLISupport.cleanup(fixture) }

    let history = try CLISupport.runCLI(["history", fixture.bundlePath])
    let payload = try TestJSON.parse(history.stdout)
    let id = try #require((payload["revisions"] as? [[String: Any]])?.first?["versionId"] as? String)

    let result = try CLISupport.runCLI(["diff", id, id, fixture.bundlePath])
    #expect(result.exitCode == 0, "stderr: \(result.stderr)")
    let diffPayload = try TestJSON.parse(result.stdout)
    let changes = try #require(diffPayload["changes"] as? [[String: Any]])
    #expect(changes.isEmpty)
    #expect(diffPayload["count"] as? Int == 0)
}

@Test func diffWithUnknownRevisionFailsWithBundleConflict() throws {
    let fixture = try CLISupport.makeFixture(name: "diff-missing", content: initialContent)
    defer { CLISupport.cleanup(fixture) }

    let history = try CLISupport.runCLI(["history", fixture.bundlePath])
    let payload = try TestJSON.parse(history.stdout)
    let id = try #require((payload["revisions"] as? [[String: Any]])?.first?["versionId"] as? String)

    let result = try CLISupport.runCLI([
        "diff", "V0099.0099.20260101T0000Z", id, fixture.bundlePath,
    ])
    #expect(result.exitCode == 4, "expected exit 4 for bundleConflict; got \(result.exitCode); stderr: \(result.stderr)")
    let envelope = try TestJSON.parse(result.stderr)
    #expect(envelope["error"] as? String == "bundleConflict")
}
