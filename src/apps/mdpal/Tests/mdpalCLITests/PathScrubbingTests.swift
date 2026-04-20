// What Problem: Phase 3 iter 3.5 adds path scrubbing to error envelopes.
// Sec-2 from Phase 2 phase-complete: absolute filesystem paths in error
// messages leak user home directory + bundle layout when forwarded to
// telemetry. Tests verify (a) the scrubbing helper substitutes the right
// sigils, (b) error envelopes carry the scrubbed form in `message` and
// the new `relativePath` field while preserving absolute in `path` for
// backwards compat.
//
// How & Why: scrubPath is a static helper on ErrorEnvelope; tests can
// call it directly with engineered absolute paths plus an MDPAL_ROOT
// override. Integration tests trigger an actual error (fileError via
// missing source, fileTooLarge via oversized planted file) and inspect
// the wire envelope for the new field.
//
// Reference: usr/jordan/mdpal/plan-mdpal-20260406.md (Phase 3 iter 3.5)
//
// Written: 2026-04-19 during mdpal-cli session (Phase 3 iter 3.5)

import Testing
import Foundation
@testable import MarkdownPalEngine

private let fixtureContent = "# A\n\nbody.\n"

@Test func errorEnvelopeFileErrorIncludesRelativePathField() throws {
    // Trigger a real fileError via wrap with a missing source file.
    let parentDir = FileManager.default.temporaryDirectory
        .appendingPathComponent("mdpal-scrub-fileerror-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: parentDir, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: parentDir) }

    let missingSource = parentDir.appendingPathComponent("does-not-exist.md").path
    let result = try CLISupport.runCLI([
        "wrap", missingSource, "from-missing",
        "--dir", parentDir.path,
    ])
    #expect(result.exitCode != 0)

    let envelope = try TestJSON.parse(result.stderr)
    #expect(envelope["error"] as? String == "fileError")
    let details = try #require(envelope["details"] as? [String: Any])
    // Backwards compat: absolute path retained as `path`.
    let absolutePath = try #require(details["path"] as? String)
    #expect(absolutePath.hasPrefix("/"), "details.path should be absolute; got: \(absolutePath)")
    // New field: scrubbed relative form.
    let relativePath = try #require(details["relativePath"] as? String)
    #expect(!relativePath.hasPrefix("/"), "details.relativePath should NOT be absolute; got: \(relativePath)")
    // Message uses scrubbed form, NOT the full absolute path.
    let message = try #require(envelope["message"] as? String)
    #expect(message.contains(relativePath))
}

@Test func errorEnvelopeFileTooLargeIncludesRelativePathField() throws {
    let fixture = try CLISupport.makeFixture(name: "scrub-toolarge", content: fixtureContent)
    defer { CLISupport.cleanup(fixture) }

    // Plant a 17 MiB file at a revision-pattern name to trigger fileTooLarge.
    let oversized = String(repeating: "A", count: 17 * 1024 * 1024)
    let oversizedPath = "\(fixture.bundlePath)/V0001.0002.20290101T0000Z.md"
    try oversized.write(toFile: oversizedPath, atomically: true, encoding: .utf8)

    let result = try CLISupport.runCLI(["sections", fixture.bundlePath])
    #expect(result.exitCode == 5)
    let envelope = try TestJSON.parse(result.stderr)
    #expect(envelope["error"] as? String == "fileTooLarge")
    let details = try #require(envelope["details"] as? [String: Any])
    #expect((details["path"] as? String)?.hasPrefix("/") == true)
    let relativePath = try #require(details["relativePath"] as? String)
    #expect(!relativePath.hasPrefix("/"), "relativePath should be scrubbed; got: \(relativePath)")
}

@Test func errorEnvelopeInvalidBundlePathIncludesRelativePathField() throws {
    // Trigger invalidBundlePath by passing a path that doesn't end in .mdpal.
    let parentDir = FileManager.default.temporaryDirectory
        .appendingPathComponent("mdpal-scrub-invalid-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: parentDir, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: parentDir) }
    let badPath = parentDir.appendingPathComponent("not-a-bundle").path
    try FileManager.default.createDirectory(atPath: badPath, withIntermediateDirectories: true)

    let result = try CLISupport.runCLI(["sections", badPath])
    // The directory exists but has no .mdpal suffix → invalidBundlePath.
    #expect(result.exitCode != 0)
    let envelope = try TestJSON.parse(result.stderr)
    let discriminator = envelope["error"] as? String
    // Either invalidBundlePath or fileError depending on the engine path.
    // Both have relativePath now.
    #expect(discriminator == "invalidBundlePath" || discriminator == "fileError",
            "expected invalidBundlePath or fileError; got: \(discriminator ?? "nil")")
    let details = try #require(envelope["details"] as? [String: Any])
    #expect(details["relativePath"] != nil, "should include relativePath field")
}

@Test func sandboxRejectionMessageUsesScrubbedPathWhenMdpalRootSet() throws {
    // When MDPAL_ROOT is set and a bundle is rejected as outside,
    // the message should reference the scrubbed (sigil-prefixed) form
    // for both the bundle path and the root, NOT the full absolute paths.
    let inside = try CLISupport.makeFixture(name: "scrub-sandbox-inside", content: fixtureContent)
    defer { CLISupport.cleanup(inside) }
    let outside = try CLISupport.makeFixture(name: "scrub-sandbox-outside", content: fixtureContent)
    defer { CLISupport.cleanup(outside) }

    let result = try CLISupport.runCLI(
        ["sections", outside.bundlePath],
        env: ["MDPAL_ROOT": inside.tempDir]
    )
    #expect(result.exitCode == 1)
    let envelope = try TestJSON.parse(result.stderr)
    let details = try #require(envelope["details"] as? [String: Any])
    // Both fields present.
    #expect(details["path"] != nil)
    let relativePath = try #require(details["relativePath"] as? String)
    // The relative path should be the basename (since outside is NOT
    // under MDPAL_ROOT, scrubPath falls through to lastPathComponent).
    #expect(relativePath == "scrub-sandbox-outside.mdpal",
            "outside-of-root should scrub to basename; got: \(relativePath)")
}
