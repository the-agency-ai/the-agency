// What Problem: `mdpal edit` is the optimistic-concurrency write path.
// mdpal-app's editor uses this. Critical wire shapes: success payload
// (versionHash + versionId + bytesWritten) and the versionConflict
// envelope (exit 2 with currentContent in details). Argument validation
// (mutually-exclusive --content / --stdin, requires one) must surface
// as exit 1 with a usable message.
//
// How & Why: Build a fixture, read a section to obtain the version
// hash, edit with that hash (success), edit again with the OLD hash
// (conflict). Plus argument-validation cases.
//
// Reference: usr/jordan/mdpal/dispatches/dispatch-cli-json-output-shapes-20260406.md
//
// Written: 2026-04-17 during mdpal-cli session (Phase 2 iteration 2.2)

import Testing
import Foundation

private let fixtureContent = """
# Introduction

Welcome to the document.

# Conclusion

The end.
"""

private func readVersionHash(slug: String, bundle: String) throws -> String {
    let result = try CLISupport.runCLI(["read", slug, bundle])
    let payload = try TestJSON.parse(result.stdout)
    return try #require(payload["versionHash"] as? String)
}

@Test func editSuccessReturnsNewVersionHashAndId() throws {
    let fixture = try CLISupport.makeFixture(name: "edit-success", content: fixtureContent)
    defer { CLISupport.cleanup(fixture) }

    let originalHash = try readVersionHash(slug: "introduction", bundle: fixture.bundlePath)

    let result = try CLISupport.runCLI([
        "edit", "introduction", fixture.bundlePath,
        "--version", originalHash,
        "--content", "New introduction text.\n",
    ])
    #expect(result.exitCode == 0, "stderr: \(result.stderr)")

    let payload = try TestJSON.parse(result.stdout)
    #expect(payload["slug"] as? String == "introduction")
    let newHash = try #require(payload["versionHash"] as? String)
    #expect(newHash != originalHash, "edit must produce a new hash")
    let newVersionId = try #require(payload["versionId"] as? String)
    #expect(newVersionId.hasPrefix("V"))
    #expect((payload["bytesWritten"] as? Int) ?? 0 > 0)
}

@Test func editStaleVersionReturnsConflictExitCode2() throws {
    let fixture = try CLISupport.makeFixture(name: "edit-conflict", content: fixtureContent)
    defer { CLISupport.cleanup(fixture) }

    let originalHash = try readVersionHash(slug: "introduction", bundle: fixture.bundlePath)

    // First edit succeeds — moves the section's hash forward.
    let firstEdit = try CLISupport.runCLI([
        "edit", "introduction", fixture.bundlePath,
        "--version", originalHash,
        "--content", "First edit.\n",
    ])
    #expect(firstEdit.exitCode == 0, "stderr: \(firstEdit.stderr)")

    // Second edit with the STALE original hash must conflict.
    let secondEdit = try CLISupport.runCLI([
        "edit", "introduction", fixture.bundlePath,
        "--version", originalHash,
        "--content", "Second edit (stale).\n",
    ])
    #expect(secondEdit.exitCode == 2, "expected versionConflict exit code 2, got \(secondEdit.exitCode); stderr: \(secondEdit.stderr)")

    let envelope = try TestJSON.parse(secondEdit.stderr)
    #expect(envelope["error"] as? String == "versionConflict")
    let details = try #require(envelope["details"] as? [String: Any])
    #expect(details["slug"] as? String == "introduction")
    #expect(details["expectedHash"] as? String == originalHash)
    let currentHash = try #require(details["currentHash"] as? String)
    #expect(currentHash != originalHash)
    let currentContent = try #require(details["currentContent"] as? String)
    #expect(currentContent.contains("First edit"), "currentContent should reflect what won the race")
}

@Test func editViaStdin() throws {
    let fixture = try CLISupport.makeFixture(name: "edit-stdin", content: fixtureContent)
    defer { CLISupport.cleanup(fixture) }

    let hash = try readVersionHash(slug: "introduction", bundle: fixture.bundlePath)

    let result = try CLISupport.runCLI(
        [
            "edit", "introduction", fixture.bundlePath,
            "--version", hash, "--stdin",
        ],
        stdin: "Piped content via stdin.\n"
    )
    #expect(result.exitCode == 0, "stderr: \(result.stderr)")
    let payload = try TestJSON.parse(result.stdout)
    #expect((payload["versionHash"] as? String)?.isEmpty == false)
}

@Test func editNonexistentSlugReturnsExitCode3() throws {
    let fixture = try CLISupport.makeFixture(name: "edit-missing", content: fixtureContent)
    defer { CLISupport.cleanup(fixture) }

    // Use a deliberately-fake hash; sectionNotFound is checked first.
    let result = try CLISupport.runCLI([
        "edit", "no-such-section", fixture.bundlePath,
        "--version", "deadbeef",
        "--content", "x",
    ])
    #expect(result.exitCode == 3, "stderr: \(result.stderr)")
    let envelope = try TestJSON.parse(result.stderr)
    #expect(envelope["error"] as? String == "sectionNotFound")
}

@Test func editRequiresContentOrStdin() throws {
    let fixture = try CLISupport.makeFixture(name: "edit-noinput", content: fixtureContent)
    defer { CLISupport.cleanup(fixture) }

    let result = try CLISupport.runCLI([
        "edit", "introduction", fixture.bundlePath,
        "--version", "deadbeef",
    ])
    #expect(result.exitCode != 0, "expected non-zero for missing content/stdin")
    // ArgumentParser validation errors emit to stderr.
    #expect(!result.stderr.isEmpty)
}

@Test func editRejectsBothContentAndStdin() throws {
    let fixture = try CLISupport.makeFixture(name: "edit-both", content: fixtureContent)
    defer { CLISupport.cleanup(fixture) }

    let result = try CLISupport.runCLI(
        [
            "edit", "introduction", fixture.bundlePath,
            "--version", "deadbeef",
            "--content", "x", "--stdin",
        ],
        stdin: "y"
    )
    #expect(result.exitCode != 0, "expected non-zero for both --content and --stdin")
}

@Test func editTextFormat() throws {
    let fixture = try CLISupport.makeFixture(name: "edit-text", content: fixtureContent)
    defer { CLISupport.cleanup(fixture) }

    let hash = try readVersionHash(slug: "introduction", bundle: fixture.bundlePath)

    let result = try CLISupport.runCLI([
        "edit", "introduction", fixture.bundlePath,
        "--version", hash,
        "--content", "Edited via text format.\n",
        "--format", "text",
    ])
    #expect(result.exitCode == 0)
    #expect(result.stdout.contains("slug:"))
    #expect(result.stdout.contains("versionHash:"))
    #expect(result.stdout.contains("versionId:"))
    #expect(!result.stdout.contains("\"slug\""), "text format should not be JSON")
}
