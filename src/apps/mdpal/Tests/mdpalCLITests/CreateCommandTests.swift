// What Problem: `mdpal create <name> [--dir <path>]` creates a new
// .mdpal bundle with an initial revision. Wire shape (per dispatched
// spec): {bundle, path, versionId, revision, version}. Errors: invalid
// names, conflicts when target already exists.
//
// How & Why: Build a fresh temp dir, run create, verify the bundle file
// tree exists, verify the wire shape. Also cover the rejection paths
// (bare ".mdpal" suffix, slash in name).
//
// Reference: usr/jordan/mdpal/dispatches/dispatch-cli-json-output-shapes-20260406.md
//
// Written: 2026-04-17 during mdpal-cli session (Phase 2 iteration 2.4)

import Testing
import Foundation

private func makeTempDir(name: String) throws -> String {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("mdpal-create-\(name)-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url.path
}

private func cleanupTempDir(_ path: String) {
    let tempRoot = FileManager.default.temporaryDirectory.path
    guard path.hasPrefix(tempRoot) else { return }
    try? FileManager.default.removeItem(atPath: path)
}

@Test func createWritesBundleAtDirAndReturnsWireShape() throws {
    let parentDir = try makeTempDir(name: "ok")
    defer { cleanupTempDir(parentDir) }

    let result = try CLISupport.runCLI([
        "create", "design",
        "--dir", parentDir,
    ])
    #expect(result.exitCode == 0, "stderr: \(result.stderr)")

    let payload = try TestJSON.parse(result.stdout)
    #expect(payload["bundle"] as? String == "design.mdpal")
    let path = try #require(payload["path"] as? String)
    #expect(path.hasSuffix("design.mdpal"))
    let versionId = try #require(payload["versionId"] as? String)
    #expect(versionId.hasPrefix("V0001.0001."))
    #expect(payload["revision"] as? Int == 1)
    #expect(payload["version"] as? Int == 1)

    // Bundle directory exists with config and revision files.
    var isDir: ObjCBool = false
    #expect(FileManager.default.fileExists(atPath: path, isDirectory: &isDir))
    #expect(isDir.boolValue)
    let configPath = "\(path)/.mdpal/config.yaml"
    #expect(FileManager.default.fileExists(atPath: configPath))
}

@Test func createRejectsExistingTarget() throws {
    let parentDir = try makeTempDir(name: "exists")
    defer { cleanupTempDir(parentDir) }

    // First create succeeds.
    let first = try CLISupport.runCLI(["create", "alpha", "--dir", parentDir])
    #expect(first.exitCode == 0, "stderr: \(first.stderr)")

    // Second create on the same name fails.
    let second = try CLISupport.runCLI(["create", "alpha", "--dir", parentDir])
    #expect(second.exitCode != 0)
    let envelope = try TestJSON.parse(second.stderr)
    #expect(envelope["error"] as? String == "invalidBundlePath")
}

@Test func createRejectsNameContainingSlash() throws {
    let parentDir = try makeTempDir(name: "slash")
    defer { cleanupTempDir(parentDir) }

    let result = try CLISupport.runCLI([
        "create", "../escape",
        "--dir", parentDir,
    ])
    #expect(result.exitCode != 0)
    let envelope = try TestJSON.parse(result.stderr)
    #expect(envelope["error"] as? String == "invalidBundlePath")
}

@Test func createRejectsNameWithMdpalSuffix() throws {
    let parentDir = try makeTempDir(name: "suffix")
    defer { cleanupTempDir(parentDir) }

    let result = try CLISupport.runCLI([
        "create", "design.mdpal",
        "--dir", parentDir,
    ])
    #expect(result.exitCode != 0)
    let envelope = try TestJSON.parse(result.stderr)
    #expect(envelope["error"] as? String == "invalidBundlePath")
}

// QG fix F3 bug-exposing tests for tightened validateName.
@Test func createRejectsNameDotDot() throws {
    let parentDir = try makeTempDir(name: "dotdot")
    defer { cleanupTempDir(parentDir) }
    let result = try CLISupport.runCLI(["create", "..", "--dir", parentDir])
    #expect(result.exitCode != 0)
    let envelope = try TestJSON.parse(result.stderr)
    #expect(envelope["error"] as? String == "invalidBundlePath")
}

@Test func createRejectsLeadingDot() throws {
    let parentDir = try makeTempDir(name: "hidden")
    defer { cleanupTempDir(parentDir) }
    let result = try CLISupport.runCLI(["create", ".secret", "--dir", parentDir])
    #expect(result.exitCode != 0)
    let envelope = try TestJSON.parse(result.stderr)
    #expect(envelope["error"] as? String == "invalidBundlePath")
}

@Test func createRejectsNameContainingBackslash() throws {
    let parentDir = try makeTempDir(name: "backslash")
    defer { cleanupTempDir(parentDir) }
    let result = try CLISupport.runCLI(["create", "foo\\bar", "--dir", parentDir])
    #expect(result.exitCode != 0)
    let envelope = try TestJSON.parse(result.stderr)
    #expect(envelope["error"] as? String == "invalidBundlePath")
}

// QG coverage T5: empty --content "" is a valid (degenerate) input. Document
// the resulting wire shape: bundle exists, version 1 revision 1, but
// `sections` returns no sections (empty body). Pre-fix this behavior was
// undocumented and untested.
@Test func createWithEmptyContentProducesEmptyBundle() throws {
    let parentDir = try makeTempDir(name: "empty-content")
    defer { cleanupTempDir(parentDir) }

    let result = try CLISupport.runCLI([
        "create", "empty",
        "--dir", parentDir,
        "--content", "",
    ])
    #expect(result.exitCode == 0, "stderr: \(result.stderr)")
    let payload = try TestJSON.parse(result.stdout)
    let path = try #require(payload["path"] as? String)
    #expect(payload["version"] as? Int == 1)
    #expect(payload["revision"] as? Int == 1)

    // sections endpoint returns an empty list for an empty bundle.
    let listing = try CLISupport.runCLI(["sections", path])
    #expect(listing.exitCode == 0, "stderr: \(listing.stderr)")
    let listed = try TestJSON.parse(listing.stdout)
    let sections = try #require(listed["sections"] as? [[String: Any]])
    #expect(sections.isEmpty)
    #expect(listed["count"] as? Int == 0)
}

@Test func createWithCustomInitialContent() throws {
    let parentDir = try makeTempDir(name: "content")
    defer { cleanupTempDir(parentDir) }

    let result = try CLISupport.runCLI([
        "create", "doc",
        "--dir", parentDir,
        "--content", "# Hello\n\nFirst body.\n",
    ])
    #expect(result.exitCode == 0, "stderr: \(result.stderr)")
    let payload = try TestJSON.parse(result.stdout)
    let bundlePath = try #require(payload["path"] as? String)

    // Round-trip through `mdpal sections` to verify the initial heading landed.
    let listing = try CLISupport.runCLI(["sections", bundlePath])
    #expect(listing.exitCode == 0, "stderr: \(listing.stderr)")
    let listed = try TestJSON.parse(listing.stdout)
    let sections = try #require(listed["sections"] as? [[String: Any]])
    #expect(sections.first?["slug"] as? String == "hello")
}
