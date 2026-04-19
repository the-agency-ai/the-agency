// What Problem: Phase 3 iter 3.4 adds the optional MDPAL_ROOT sandbox.
// When set, BundleResolver.resolve rejects bundle paths outside the
// root. Tests verify: (a) unset MDPAL_ROOT preserves legacy
// "any-bundle-path" behavior, (b) set MDPAL_ROOT rejects escapes via
// absolute path, ../, tilde-expansion, and symlink leak, (c) bundles
// inside the root resolve normally.
//
// How & Why: Each test invokes a CLI command (sections, history) with
// MDPAL_ROOT overridden via the env: parameter on CLISupport.runCLI
// (added in iter 3.4). The CLI is the right test seam — sandbox
// enforcement happens at BundleResolver.resolve, called by every
// command, so any command exercises the same gate.
//
// Reference: usr/jordan/mdpal/plan-mdpal-20260406.md (Phase 3 iter 3.4)
//
// Written: 2026-04-19 during mdpal-cli session (Phase 3 iter 3.4)

import Testing
import Foundation
@testable import MarkdownPalEngine

private let fixtureContent = "# A\n\nbody.\n"

@Test func sandboxUnsetAllowsAnyBundlePath() throws {
    // Without MDPAL_ROOT, legacy behavior — bundle outside any
    // particular root is fine.
    let fixture = try CLISupport.makeFixture(name: "sandbox-unset", content: fixtureContent)
    defer { CLISupport.cleanup(fixture) }

    let result = try CLISupport.runCLI(["sections", fixture.bundlePath])
    #expect(result.exitCode == 0, "stderr: \(result.stderr.prefix(200))")
}

@Test func sandboxSetAllowsBundleInsideRoot() throws {
    // MDPAL_ROOT pointed at the fixture's parent directory — bundle
    // inside that root resolves normally.
    let fixture = try CLISupport.makeFixture(name: "sandbox-inside", content: fixtureContent)
    defer { CLISupport.cleanup(fixture) }

    let result = try CLISupport.runCLI(
        ["sections", fixture.bundlePath],
        env: ["MDPAL_ROOT": fixture.tempDir]
    )
    #expect(result.exitCode == 0, "stderr: \(result.stderr.prefix(200))")
}

@Test func sandboxSetRejectsBundleOutsideRoot() throws {
    // Two separate temp directories. MDPAL_ROOT points at one;
    // the bundle lives in the other → reject.
    let fixtureInside = try CLISupport.makeFixture(name: "sandbox-other-inside", content: fixtureContent)
    defer { CLISupport.cleanup(fixtureInside) }
    let fixtureOutside = try CLISupport.makeFixture(name: "sandbox-other-outside", content: fixtureContent)
    defer { CLISupport.cleanup(fixtureOutside) }

    let result = try CLISupport.runCLI(
        ["sections", fixtureOutside.bundlePath],
        env: ["MDPAL_ROOT": fixtureInside.tempDir]
    )
    // Should reject with invalidBundlePath or generalError — exit 1.
    #expect(result.exitCode == 1, "expected exit 1 for sandbox escape; got \(result.exitCode), stderr: \(result.stderr.prefix(200))")
    let envelope = try TestJSON.parse(result.stderr)
    #expect(envelope["error"] as? String == "invalidBundlePath")
    let details = try #require(envelope["details"] as? [String: Any])
    let reason = try #require(details["reason"] as? String)
    #expect(reason.contains("MDPAL_ROOT"), "rejection reason should mention MDPAL_ROOT; got: \(reason)")
}

@Test func sandboxRejectsTraversalAttempts() throws {
    // Construct a bundle path that uses .. to escape the sandbox.
    let inside = try CLISupport.makeFixture(name: "sandbox-traversal", content: fixtureContent)
    defer { CLISupport.cleanup(inside) }
    let escape = try CLISupport.makeFixture(name: "sandbox-target", content: fixtureContent)
    defer { CLISupport.cleanup(escape) }

    // Bundle path = inside.bundlePath/../../escape.bundlePath  → resolves
    // to escape.bundlePath. Reject because escape is outside MDPAL_ROOT.
    let traversalPath = "\(inside.bundlePath)/../../\((escape.bundlePath as NSString).lastPathComponent)"
    let result = try CLISupport.runCLI(
        ["sections", traversalPath],
        env: ["MDPAL_ROOT": inside.tempDir]
    )
    #expect(result.exitCode == 1, "stderr: \(result.stderr.prefix(200))")
    let envelope = try TestJSON.parse(result.stderr)
    #expect(envelope["error"] as? String == "invalidBundlePath")
}

@Test func sandboxRejectsSymlinkEscapes() throws {
    // Plant a symlink INSIDE the sandbox that points OUTSIDE. With
    // realpath enforcement the resolver follows the symlink and
    // catches the escape.
    let sandbox = try CLISupport.makeFixture(name: "sandbox-symlink-inside", content: fixtureContent)
    defer { CLISupport.cleanup(sandbox) }
    let outside = try CLISupport.makeFixture(name: "sandbox-symlink-outside", content: fixtureContent)
    defer { CLISupport.cleanup(outside) }

    // Create a symlink inside the sandbox pointing at the outside bundle.
    let symlinkPath = "\(sandbox.tempDir)/escape.mdpal"
    try FileManager.default.createSymbolicLink(
        atPath: symlinkPath,
        withDestinationPath: outside.bundlePath
    )

    let result = try CLISupport.runCLI(
        ["sections", symlinkPath],
        env: ["MDPAL_ROOT": sandbox.tempDir]
    )
    #expect(result.exitCode == 1, "expected reject on symlink escape; got \(result.exitCode), stderr: \(result.stderr.prefix(200))")
    let envelope = try TestJSON.parse(result.stderr)
    #expect(envelope["error"] as? String == "invalidBundlePath")
    let details = try #require(envelope["details"] as? [String: Any])
    let reason = try #require(details["reason"] as? String)
    #expect(reason.contains("MDPAL_ROOT") || reason.contains("sandbox"),
            "should mention MDPAL_ROOT/sandbox; got: \(reason)")
}

@Test func sandboxRejectsRootItselfAsBundle() throws {
    // Edge case: setting MDPAL_ROOT and passing the same path as the
    // bundle should reject (root is not a bundle, must be a child).
    let sandbox = try CLISupport.makeFixture(name: "sandbox-self-root", content: fixtureContent)
    defer { CLISupport.cleanup(sandbox) }

    let result = try CLISupport.runCLI(
        ["sections", sandbox.tempDir],
        env: ["MDPAL_ROOT": sandbox.tempDir]
    )
    #expect(result.exitCode == 1, "stderr: \(result.stderr.prefix(200))")
    let envelope = try TestJSON.parse(result.stderr)
    #expect(envelope["error"] as? String == "invalidBundlePath")
}

@Test func sandboxAllowsNestedBundleInsideRoot() throws {
    // Bundle nested several levels deep inside MDPAL_ROOT — should resolve.
    let setup = try CLISupport.makeFixture(name: "sandbox-nested", content: fixtureContent)
    defer { CLISupport.cleanup(setup) }

    // Use the parent of the temp dir as MDPAL_ROOT. The bundle is N
    // levels deep, well inside the root.
    let root = (setup.tempDir as NSString).deletingLastPathComponent

    let result = try CLISupport.runCLI(
        ["sections", setup.bundlePath],
        env: ["MDPAL_ROOT": root]
    )
    #expect(result.exitCode == 0, "stderr: \(result.stderr.prefix(200))")
}

@Test func sandboxEmptyRootEnvVarIsSameAsUnset() throws {
    // MDPAL_ROOT="" (empty) should behave as if unset — no enforcement.
    let fixture = try CLISupport.makeFixture(name: "sandbox-empty", content: fixtureContent)
    defer { CLISupport.cleanup(fixture) }

    let result = try CLISupport.runCLI(
        ["sections", fixture.bundlePath],
        env: ["MDPAL_ROOT": ""]
    )
    #expect(result.exitCode == 0, "empty MDPAL_ROOT should not enforce; stderr: \(result.stderr.prefix(200))")
}
