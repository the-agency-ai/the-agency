// What Problem: Phase 3 iter 3.3 ships `mdpal flatten <bundle>` —
// packaged to pancake conversion. Tests verify body-only default output,
// the optional --include-comments / --include-flags appendices, the
// --output file mode wire shape, and the empty-bundle error envelope.
//
// How & Why: Each test creates a temp bundle (via wrap or via
// CLISupport.makeFixture), invokes flatten with various flags, and
// asserts on stdout / file contents / exit code. The round-trip test
// (wrap-then-flatten) is the strongest invariant — body content survives
// the packaged-pancake-packaged cycle.
//
// Reference: usr/jordan/mdpal/plan-mdpal-20260406.md (Phase 3 iter 3.3)
//
// Written: 2026-04-19 during mdpal-cli session (Phase 3 iter 3.3)

import Testing
import Foundation
@testable import MarkdownPalEngine

private let fixtureContent = """
# Topic

Body of topic.

# Next

More body.
"""

@Test func flattenBodyOnlyByDefault() throws {
    let fixture = try CLISupport.makeFixture(name: "flatten-default", content: fixtureContent)
    defer { CLISupport.cleanup(fixture) }

    let result = try CLISupport.runCLI([
        "flatten", fixture.bundlePath, "--format", "text",
    ])
    #expect(result.exitCode == 0, "stderr: \(result.stderr.prefix(200))")
    // Body should contain both sections' content.
    #expect(result.stdout.contains("# Topic"))
    #expect(result.stdout.contains("Body of topic."))
    #expect(result.stdout.contains("# Next"))
    #expect(result.stdout.contains("More body."))
    // No metadata block, no comments/flags appendix.
    #expect(!result.stdout.contains("markdown-pal-meta"))
    #expect(!result.stdout.contains("## Comments"))
    #expect(!result.stdout.contains("## Flags"))
}

@Test func flattenIncludeCommentsAppendsCommentSection() throws {
    let fixture = try CLISupport.makeFixture(name: "flatten-with-comments", content: fixtureContent)
    defer { CLISupport.cleanup(fixture) }

    // Add a comment first.
    let commentResult = try CLISupport.runCLI([
        "comment", "topic", fixture.bundlePath,
        "--type", "note", "--author", "alice", "--text", "Important note",
    ])
    #expect(commentResult.exitCode == 0)

    let result = try CLISupport.runCLI([
        "flatten", fixture.bundlePath, "--include-comments", "--format", "text",
    ])
    #expect(result.exitCode == 0)
    #expect(result.stdout.contains("## Comments"))
    #expect(result.stdout.contains("alice"))
    #expect(result.stdout.contains("Important note"))
    #expect(result.stdout.contains("Section: `topic`"))
    // Body still there.
    #expect(result.stdout.contains("Body of topic."))
}

@Test func flattenIncludeFlagsAppendsFlagSection() throws {
    let fixture = try CLISupport.makeFixture(name: "flatten-with-flags", content: fixtureContent)
    defer { CLISupport.cleanup(fixture) }

    _ = try CLISupport.runCLI([
        "flag", "topic", fixture.bundlePath,
        "--author", "bob", "--note", "discuss",
    ])

    let result = try CLISupport.runCLI([
        "flatten", fixture.bundlePath, "--include-flags", "--format", "text",
    ])
    #expect(result.exitCode == 0)
    #expect(result.stdout.contains("## Flags"))
    #expect(result.stdout.contains("`topic`"))
    #expect(result.stdout.contains("bob"))
    #expect(result.stdout.contains("discuss"))
}

@Test func flattenWithOutputWritesToFileAndEmitsPayload() throws {
    let fixture = try CLISupport.makeFixture(name: "flatten-output", content: fixtureContent)
    defer { CLISupport.cleanup(fixture) }

    let outputPath = FileManager.default.temporaryDirectory
        .appendingPathComponent("flatten-out-\(UUID().uuidString).md").path
    defer { try? FileManager.default.removeItem(atPath: outputPath) }

    let result = try CLISupport.runCLI([
        "flatten", fixture.bundlePath, "--output", outputPath,
    ])
    #expect(result.exitCode == 0, "stderr: \(result.stderr.prefix(200))")

    // JSON payload on stdout.
    let payload = try TestJSON.parse(result.stdout)
    #expect(payload["path"] as? String == outputPath)
    #expect(payload["bytesWritten"] is Int)
    #expect(payload["includeComments"] as? Bool == false)
    #expect(payload["includeFlags"] as? Bool == false)

    // File written and contains body.
    let onDisk = try String(contentsOfFile: outputPath, encoding: .utf8)
    #expect(onDisk.contains("# Topic"))
    #expect(onDisk.contains("Body of topic."))
    #expect(!onDisk.contains("markdown-pal-meta"))
}

@Test func flattenEmptyBundleEmitsBundleConflict() throws {
    // makeFixture defaults to one revision with the supplied content.
    // Empty content is allowed, but the bundle still has one revision.
    // Construct a bundle and then delete its revision file to simulate
    // the "no revisions" state.
    let fixture = try CLISupport.makeFixture(name: "flatten-empty", content: "# A\n")
    defer { CLISupport.cleanup(fixture) }

    // Delete the revision file (simulate corrupted/stripped bundle).
    let bundle = try DocumentBundle(at: fixture.bundlePath)
    let latest = try #require(try bundle.latestRevision())
    try FileManager.default.removeItem(atPath: latest.filePath)

    let result = try CLISupport.runCLI(["flatten", fixture.bundlePath])
    #expect(result.exitCode == 4, "expected exit 4 (bundleConflict); got \(result.exitCode), stderr=\(result.stderr.prefix(200))")
    let envelope = try TestJSON.parse(result.stderr)
    #expect(envelope["error"] as? String == "bundleConflict")
}

@Test func flattenJSONStdoutWrapsContent() throws {
    let fixture = try CLISupport.makeFixture(name: "flatten-json", content: fixtureContent)
    defer { CLISupport.cleanup(fixture) }

    let result = try CLISupport.runCLI(["flatten", fixture.bundlePath])
    #expect(result.exitCode == 0)
    let payload = try TestJSON.parse(result.stdout)
    let content = try #require(payload["content"] as? String)
    #expect(content.contains("# Topic"))
    #expect(payload["bytesWritten"] is Int)
    #expect(payload["includeComments"] as? Bool == false)
    #expect(payload["includeFlags"] as? Bool == false)
}

@Test func flattenRoundTripsBodyContent() throws {
    // The strongest invariant: wrap a .md, then flatten, then compare
    // the body. Should be byte-similar (whitespace normalization aside).
    let parentDir = FileManager.default.temporaryDirectory
        .appendingPathComponent("mdpal-roundtrip-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: parentDir, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: parentDir) }

    let sourcePath = parentDir.appendingPathComponent("source.md").path
    let originalBody = "# Heading One\n\nFirst paragraph.\n\n# Heading Two\n\nSecond paragraph.\n"
    try originalBody.write(toFile: sourcePath, atomically: true, encoding: .utf8)

    let wrapResult = try CLISupport.runCLI([
        "wrap", sourcePath, "round-tripped",
        "--dir", parentDir.path,
    ])
    let wrapPayload = try TestJSON.parse(wrapResult.stdout)
    let bundlePath = try #require(wrapPayload["path"] as? String)

    let flattenResult = try CLISupport.runCLI([
        "flatten", bundlePath, "--format", "text",
    ])
    #expect(flattenResult.exitCode == 0)
    // Headings + body content survive.
    #expect(flattenResult.stdout.contains("# Heading One"))
    #expect(flattenResult.stdout.contains("First paragraph."))
    #expect(flattenResult.stdout.contains("# Heading Two"))
    #expect(flattenResult.stdout.contains("Second paragraph."))
    // No metadata block.
    #expect(!flattenResult.stdout.contains("markdown-pal-meta"))
}

@Test func flattenEnginePreservesPosixNewlineConvention() throws {
    // Engine-level test: Document.flatten on a doc with empty body
    // emits a single newline (POSIX text-file convention).
    let parser = MarkdownParser()
    let document = try Document(content: "", parser: parser)
    let flattened = try document.flatten(includeComments: false, includeFlags: false)
    #expect(flattened == "\n", "empty body should flatten to single newline; got: \(flattened.debugDescription)")
}
