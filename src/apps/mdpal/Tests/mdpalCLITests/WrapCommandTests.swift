// What Problem: Phase 3 iter 3.2 ships `mdpal wrap <source> <name>` —
// pancake to packaged conversion. Tests verify the happy path produces a
// valid bundle with the source content as the initial revision, and the
// edge cases per Phase 3 plan decisions: single-file only (no
// directories), wrap-over-existing fails, --review-metadata embeds the
// `review:` block in the bundle's metadata.
//
// How & Why: Each test creates a temp source .md file (or directory),
// invokes `mdpal wrap`, and asserts on (a) exit code, (b) wire payload
// shape, (c) on-disk bundle contents. The metadata-embedding tests also
// reload the bundle via Document(contentsOfFile:) and inspect
// metadata.unknownTopLevelYAML to confirm the `review:` block round-tripped.
//
// Reference: usr/jordan/mdpal/plan-mdpal-20260406.md (Phase 3 iter 3.2)
//
// Written: 2026-04-19 during mdpal-cli session (Phase 3 iter 3.2)

import Testing
import Foundation
@testable import MarkdownPalEngine

private func makeSourceFile(content: String) throws -> (parentDir: URL, sourcePath: String) {
    let parentDir = FileManager.default.temporaryDirectory
        .appendingPathComponent("mdpal-wrap-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: parentDir, withIntermediateDirectories: true)
    let sourcePath = parentDir.appendingPathComponent("source.md").path
    try content.write(toFile: sourcePath, atomically: true, encoding: .utf8)
    return (parentDir, sourcePath)
}

@Test func wrapHappyPathCreatesBundleFromSource() throws {
    let setup = try makeSourceFile(content: "# Hello\n\nWorld.\n")
    defer { try? FileManager.default.removeItem(at: setup.parentDir) }

    let result = try CLISupport.runCLI([
        "wrap", setup.sourcePath, "wrapped",
        "--dir", setup.parentDir.path,
    ])
    #expect(result.exitCode == 0, "stderr: \(result.stderr.prefix(300))")

    let payload = try TestJSON.parse(result.stdout)
    #expect(payload["bundle"] as? String == "wrapped.mdpal")
    let path = try #require(payload["path"] as? String)
    #expect(path.hasSuffix("/wrapped.mdpal"))
    #expect(payload["versionId"] is String)
    #expect(payload["version"] as? Int == 1)
    #expect(payload["revision"] as? Int == 1)

    // Verify on-disk: the bundle exists and the initial revision contains the source body.
    let bundle = try DocumentBundle(at: path)
    let document = try bundle.currentDocument()
    let intro = try document.readSection("hello")
    #expect(intro.content.contains("World."))
    // No --review-metadata, so unknownTopLevelYAML should be empty.
    #expect(document.metadata.unknownTopLevelYAML.isEmpty)
}

@Test func wrapEmbedsReviewMetadataWhenProvided() throws {
    let setup = try makeSourceFile(content: "# Topic\n\nbody.\n")
    defer { try? FileManager.default.removeItem(at: setup.parentDir) }

    // Write a review metadata YAML file alongside the source.
    let reviewYAML = """
    origin: the-agency/jordan/captain
    artifactType: pvr
    reviewRound: 2
    correlationId: c-abc123
    """
    let reviewPath = setup.parentDir.appendingPathComponent("review.yaml").path
    try reviewYAML.write(toFile: reviewPath, atomically: true, encoding: .utf8)

    let result = try CLISupport.runCLI([
        "wrap", setup.sourcePath, "with-review",
        "--dir", setup.parentDir.path,
        "--review-metadata", reviewPath,
    ])
    #expect(result.exitCode == 0, "stderr: \(result.stderr.prefix(300))")
    let payload = try TestJSON.parse(result.stdout)
    let path = try #require(payload["path"] as? String)

    // Verify the bundle's first revision has the review block via the
    // engine's unknown-YAML round-trip path (Phase 3 iter 3.1).
    let bundle = try DocumentBundle(at: path)
    let document = try bundle.currentDocument()
    let captured = try #require(document.metadata.unknownTopLevelYAML["review"],
                                "wrap with --review-metadata should embed `review:` in bundle metadata")
    #expect(captured.contains("origin"))
    #expect(captured.contains("the-agency/jordan/captain"))
    #expect(captured.contains("artifactType"))
    #expect(captured.contains("pvr"))
    #expect(captured.contains("reviewRound"))
    #expect(captured.contains("correlationId"))

    // And the body content is preserved.
    let topic = try document.readSection("topic")
    #expect(topic.content.contains("body."))
}

@Test func wrapRejectsSourceDirectory() throws {
    let parentDir = FileManager.default.temporaryDirectory
        .appendingPathComponent("mdpal-wrap-dir-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: parentDir, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: parentDir) }

    // <source> is a directory, not a file. V1 must reject (V2 deferral).
    let dirSource = parentDir.appendingPathComponent("not-a-file.md").path
    try FileManager.default.createDirectory(atPath: dirSource, withIntermediateDirectories: false)

    let result = try CLISupport.runCLI([
        "wrap", dirSource, "rejected",
        "--dir", parentDir.path,
    ])
    #expect(result.exitCode != 0, "should reject directory source")
    let envelope = try TestJSON.parse(result.stderr)
    #expect(envelope["error"] as? String == "fileError")
    let details = try #require(envelope["details"] as? [String: Any])
    let description = try #require(details["description"] as? String)
    #expect(description.contains("single .md file") || description.contains("regular"),
            "should mention single-file constraint; got: \(description)")
}

@Test func wrapRejectsExistingTarget() throws {
    let setup = try makeSourceFile(content: "# A\n")
    defer { try? FileManager.default.removeItem(at: setup.parentDir) }

    // Create the target bundle first.
    _ = try CLISupport.runCLI([
        "wrap", setup.sourcePath, "collision",
        "--dir", setup.parentDir.path,
    ])

    // Wrap again to the same name → should fail with bundleConflict (exit 4).
    let result = try CLISupport.runCLI([
        "wrap", setup.sourcePath, "collision",
        "--dir", setup.parentDir.path,
    ])
    #expect(result.exitCode == 4, "expected exit 4 (bundleConflict); got \(result.exitCode), stderr: \(result.stderr.prefix(200))")
    let envelope = try TestJSON.parse(result.stderr)
    #expect(envelope["error"] as? String == "bundleConflict")
}

@Test func wrapAcceptsEmptySource() throws {
    let setup = try makeSourceFile(content: "")
    defer { try? FileManager.default.removeItem(at: setup.parentDir) }

    let result = try CLISupport.runCLI([
        "wrap", setup.sourcePath, "empty",
        "--dir", setup.parentDir.path,
    ])
    #expect(result.exitCode == 0, "wrap should accept empty source; stderr: \(result.stderr.prefix(200))")
    let payload = try TestJSON.parse(result.stdout)
    #expect(payload["bundle"] as? String == "empty.mdpal")
    let path = try #require(payload["path"] as? String)
    let bundle = try DocumentBundle(at: path)
    let document = try bundle.currentDocument()
    // Empty source → bundle with no sections.
    #expect(document.listSections().isEmpty)
}

@Test func wrapRejectsMalformedReviewMetadata() throws {
    let setup = try makeSourceFile(content: "# A\n")
    defer { try? FileManager.default.removeItem(at: setup.parentDir) }

    // Write a YAML SEQUENCE (not a mapping). Should reject — review must
    // be a mapping per the contract.
    let badYAML = """
    - origin: a
    - origin: b
    """
    let reviewPath = setup.parentDir.appendingPathComponent("bad.yaml").path
    try badYAML.write(toFile: reviewPath, atomically: true, encoding: .utf8)

    let result = try CLISupport.runCLI([
        "wrap", setup.sourcePath, "bad-review",
        "--dir", setup.parentDir.path,
        "--review-metadata", reviewPath,
    ])
    #expect(result.exitCode != 0)
    let envelope = try TestJSON.parse(result.stderr)
    #expect(envelope["error"] as? String == "metadataError")
    let message = try #require(envelope["message"] as? String)
    #expect(message.contains("mapping") || message.contains("sequence"),
            "should mention mapping requirement; got: \(message)")
}

@Test func wrapPreservesReviewMetadataAcrossSubsequentMutation() throws {
    // Integration: wrap with review metadata, then run `mdpal comment` on
    // the bundle, then verify the review: block is still there.
    let setup = try makeSourceFile(content: "# Topic\n\nbody.\n")
    defer { try? FileManager.default.removeItem(at: setup.parentDir) }

    let reviewPath = setup.parentDir.appendingPathComponent("review.yaml").path
    try "origin: a\nartifactType: pvr\n".write(toFile: reviewPath, atomically: true, encoding: .utf8)

    let wrapResult = try CLISupport.runCLI([
        "wrap", setup.sourcePath, "preserve",
        "--dir", setup.parentDir.path,
        "--review-metadata", reviewPath,
    ])
    let wrapPayload = try TestJSON.parse(wrapResult.stdout)
    let bundlePath = try #require(wrapPayload["path"] as? String)

    // Add a comment via the CLI.
    let commentResult = try CLISupport.runCLI([
        "comment", "topic", bundlePath,
        "--type", "note", "--author", "alice", "--text", "checking",
    ])
    #expect(commentResult.exitCode == 0)

    // Reload via the engine and verify review: still present.
    let bundle = try DocumentBundle(at: bundlePath)
    let document = try bundle.currentDocument()
    let captured = try #require(document.metadata.unknownTopLevelYAML["review"],
                                "review: should survive mdpal comment mutation")
    #expect(captured.contains("origin"))
    #expect(captured.contains("artifactType"))
}
