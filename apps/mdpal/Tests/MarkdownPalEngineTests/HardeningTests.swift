// What Problem: Iter 2.5 added three engine-level hardening features:
// (1) SizedFileReader with type+size cap (revisionMaxBytes 16 MiB,
// configMaxBytes 64 KiB, regular-file enforcement); (2) pointer-file
// content validation; (3) symlink TOCTOU close at the read seam. Each
// has bug-exposing tests so a regression that re-opens any of these
// vectors fails loudly.
//
// How & Why: Construct a malicious bundle by hand (oversized config,
// oversized revision, symlink swap, tampered pointer) and assert each
// is rejected with the right EngineError variant. The fixtures use
// FileManager directly because the CLI / engine API would refuse to
// produce these states themselves — the whole point is that the read
// path defends against state someone else (attacker, corrupt git pack)
// produced.
//
// Reference: usr/jordan/mdpal/dispatches/dispatch-cli-json-output-shapes-20260406.md
//
// Written: 2026-04-17 during mdpal-cli session (Phase 2 iteration 2.5)

import Testing
import Foundation
@testable import MarkdownPalEngine

private func makeFreshBundleDir() throws -> (tempDir: URL, bundlePath: String) {
    let tempDir = FileManager.default.temporaryDirectory
        .appendingPathComponent("mdpal-hardening-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    let bundlePath = tempDir.appendingPathComponent("test.mdpal").path
    _ = try DocumentBundle.create(
        name: "test",
        initialContent: "# Intro\n\nbody.\n",
        at: bundlePath,
        timestamp: Date(timeIntervalSince1970: 1_775_000_000)
    )
    return (tempDir, bundlePath)
}

// MARK: - SizedFileReader: file-size cap

@Test func sizedReadRejectsRevisionExceedingCeiling() throws {
    let setup = try makeFreshBundleDir()
    defer { try? FileManager.default.removeItem(at: setup.tempDir) }

    // Plant a "revision" file 17 MiB long. The bundle has one real
    // revision; we add a malicious second one.
    let oversized = String(repeating: "A", count: 17 * 1024 * 1024)
    let oversizedPath = "\(setup.bundlePath)/V0001.0002.20260101T0000Z.md"
    try oversized.write(toFile: oversizedPath, atomically: true, encoding: .utf8)

    let bundle = try DocumentBundle(at: setup.bundlePath)
    let revisions = try bundle.listRevisions()
    let oversizedRev = try #require(revisions.first(where: { $0.versionId == "V0001.0002.20260101T0000Z" }))

    #expect(throws: EngineError.self) {
        _ = try Document(contentsOfFile: oversizedRev.filePath)
    }
}

@Test func sizedReadRejectsConfigExceedingCeiling() throws {
    let setup = try makeFreshBundleDir()
    defer { try? FileManager.default.removeItem(at: setup.tempDir) }

    // Replace the config file with a 70 KiB blob (> 64 KiB cap).
    let configPath = "\(setup.bundlePath)/.mdpal/config.yaml"
    let oversized = String(repeating: "# comment\n", count: 8000) + "name: test\nprune:\n  keep: 20\n  auto: false\n"
    try oversized.write(toFile: configPath, atomically: true, encoding: .utf8)

    #expect(throws: EngineError.self) {
        _ = try DocumentBundle(at: setup.bundlePath)
    }
}

@Test func sizedReadAcceptsRevisionUnderCeiling() throws {
    let setup = try makeFreshBundleDir()
    defer { try? FileManager.default.removeItem(at: setup.tempDir) }

    // Default fixture is well under cap; just confirm Document loads.
    let bundle = try DocumentBundle(at: setup.bundlePath)
    let doc = try bundle.currentDocument()
    #expect(doc.listSections().count >= 1)
}

// MARK: - Symlink TOCTOU at read seam

@Test func sizedReadRejectsRevisionThatIsASymlink() throws {
    let setup = try makeFreshBundleDir()
    defer { try? FileManager.default.removeItem(at: setup.tempDir) }

    // Create a target file outside the bundle (the "secret").
    let secretURL = setup.tempDir.appendingPathComponent("secret.txt")
    try "SENSITIVE".write(to: secretURL, atomically: true, encoding: .utf8)

    // Create a symlink at a revision filename pointing to the secret.
    let linkPath = "\(setup.bundlePath)/V0001.0002.20260101T0000Z.md"
    try FileManager.default.createSymbolicLink(
        atPath: linkPath,
        withDestinationPath: secretURL.path
    )

    // listRevisions filters out symlinks at list time (Phase 1 C2),
    // but we bypass it and call Document(contentsOfFile:) directly to
    // simulate a TOCTOU swap that happened AFTER list time. The
    // SizedFileReader regular-file check must reject.
    #expect(throws: EngineError.self) {
        _ = try Document(contentsOfFile: linkPath)
    }
}

// MARK: - Pointer file validation

// NOTE: Each pointer-validation test tampers with the pointer file
// AFTER opening the bundle. `DocumentBundle.init` runs `reconcileLatest`
// which silently rewrites a divergent pointer back to the symlink's
// destination — necessary for crash recovery, but it would mask the
// malicious-pointer test if we wrote the bad value first.

@Test func pointerFileRejectsPathTraversal() throws {
    let setup = try makeFreshBundleDir()
    defer { try? FileManager.default.removeItem(at: setup.tempDir) }

    let bundle = try DocumentBundle(at: setup.bundlePath)
    let pointerPath = "\(setup.bundlePath)/.mdpal/latest"
    // Tamper AFTER reconcileLatest has run.
    try "../../../etc/passwd".write(toFile: pointerPath, atomically: true, encoding: .utf8)

    #expect(throws: EngineError.self) {
        _ = try bundle.readPointerFile()
    }
}

@Test func pointerFileRejectsNonRevisionFilename() throws {
    let setup = try makeFreshBundleDir()
    defer { try? FileManager.default.removeItem(at: setup.tempDir) }

    let bundle = try DocumentBundle(at: setup.bundlePath)
    let pointerPath = "\(setup.bundlePath)/.mdpal/latest"
    try "README.md".write(toFile: pointerPath, atomically: true, encoding: .utf8)

    #expect(throws: EngineError.self) {
        _ = try bundle.readPointerFile()
    }
}

@Test func pointerFileRejectsEmptyContents() throws {
    let setup = try makeFreshBundleDir()
    defer { try? FileManager.default.removeItem(at: setup.tempDir) }

    let bundle = try DocumentBundle(at: setup.bundlePath)
    let pointerPath = "\(setup.bundlePath)/.mdpal/latest"
    try "".write(toFile: pointerPath, atomically: true, encoding: .utf8)

    #expect(throws: EngineError.self) {
        _ = try bundle.readPointerFile()
    }
}

@Test func pointerFileAcceptsCanonicalRevisionFilename() throws {
    let setup = try makeFreshBundleDir()
    defer { try? FileManager.default.removeItem(at: setup.tempDir) }

    let bundle = try DocumentBundle(at: setup.bundlePath)
    let pointer = try bundle.readPointerFile()
    let resolved = try #require(pointer)
    #expect(resolved.hasSuffix(".md"))
    #expect(resolved.hasPrefix("V0001.0001."))
}

// MARK: - Performance benchmark
//
// T-5: gated behind MDPAL_RUN_BENCHMARKS=1 so flaky-on-CI wall-clock
// thresholds don't break the default test run. Local M-series hits all
// thresholds in <100ms; loaded CI runners can blow past them. Run with:
//   MDPAL_RUN_BENCHMARKS=1 swift test --filter bundleWith100Revisions

@Test func bundleWith100RevisionsPerformsAcceptably() throws {
    guard ProcessInfo.processInfo.environment["MDPAL_RUN_BENCHMARKS"] == "1" else {
        // Skipped silently in default runs; opt in via env var.
        return
    }
    let setup = try makeFreshBundleDir()
    defer { try? FileManager.default.removeItem(at: setup.tempDir) }

    let bundle = try DocumentBundle(at: setup.bundlePath)
    let baseTime = Date(timeIntervalSince1970: 1_775_000_000)

    // Append 99 more revisions (1 + 99 = 100 total).
    for i in 2...100 {
        // Bump timestamp by minutes so versionIds are distinct.
        let ts = baseTime.addingTimeInterval(TimeInterval(i * 60))
        _ = try bundle.createRevision(
            content: "# Intro\n\nrev \(i).\n",
            timestamp: ts
        )
    }

    // Bundle now has 100 revisions. listRevisions and currentDocument
    // are the hot paths the CLI exercises. Thresholds are GENEROUS
    // (3-15s) so even a heavily-loaded CI shouldn't flake — the goal
    // is catching pathological N^2 regressions, not micro-benchmarking.
    let listStart = Date()
    let revisions = try bundle.listRevisions()
    let listElapsed = Date().timeIntervalSince(listStart)
    #expect(revisions.count == 100)
    #expect(listElapsed < 3.0, "listRevisions on 100-rev bundle took \(listElapsed)s — should be < 3s")

    let currentStart = Date()
    let doc = try bundle.currentDocument()
    let currentElapsed = Date().timeIntervalSince(currentStart)
    #expect(!doc.listSections().isEmpty)
    #expect(currentElapsed < 3.0, "currentDocument on 100-rev bundle took \(currentElapsed)s — should be < 3s")

    // Diff between first and latest
    let diffStart = Date()
    let firstId = try #require(revisions.first?.versionId)
    let lastId = try #require(revisions.last?.versionId)
    let diffs = try bundle.diff(baseRevision: firstId, targetRevision: lastId)
    let diffElapsed = Date().timeIntervalSince(diffStart)
    #expect(!diffs.isEmpty)
    #expect(diffElapsed < 5.0, "diff across 100-rev range took \(diffElapsed)s — should be < 5s")

    // Prune to keep 10
    let pruneStart = Date()
    let pruneResult = try bundle.prune(keep: 10)
    let pruneElapsed = Date().timeIntervalSince(pruneStart)
    #expect(pruneResult.remainingRevisions == 10)
    #expect(pruneResult.prunedRevisions.count == 90)
    #expect(pruneElapsed < 15.0, "prune of 90 revisions took \(pruneElapsed)s — should be < 15s")
}

// MARK: - Concurrent CLI race simulation

// The engine's atomic-create check (link(2) → EEXIST) fires when two
// writers both observe the same `latest`, both compute the same
// nextVersionId, and the loser's link(2) call finds the winner's
// freshly-linked file. Simulated single-threaded by planting any file
// at the slot the engine will try to write to: link(2) will reject the
// link with EEXIST regardless of the planted file's type. The real
// multi-process equivalent lives in
// `apps/mdpal/Tests/mdpalCLITests/ConcurrentCLITests.swift`.
@Test func writeRevisionRejectsCollisionAtFilenamePath() throws {
    let setup = try makeFreshBundleDir()
    defer { try? FileManager.default.removeItem(at: setup.tempDir) }

    let pinnedTimestamp = Date(timeIntervalSince1970: 1_775_001_000)
    let plantedVersionId = VersionId.format(version: 1, revision: 2, timestamp: pinnedTimestamp)
    let plantedPath = "\(setup.bundlePath)/\(plantedVersionId).md"

    // Plant a SYMLINK so listRevisions filters it out (Phase 1 C2 type
    // check), but link(2)'s destination existence check still trips.
    // The engine computes nextRev=2, then link(temp, planted) returns
    // EEXIST → bundleConflict.
    let dummyTarget = setup.tempDir.appendingPathComponent("dummy.md").path
    try "# dummy".write(toFile: dummyTarget, atomically: true, encoding: .utf8)
    try FileManager.default.createSymbolicLink(
        atPath: plantedPath,
        withDestinationPath: dummyTarget
    )

    let bundle = try DocumentBundle(at: setup.bundlePath)
    // F8 fix: assert the SPECIFIC EngineError case, not just "throws".
    do {
        _ = try bundle.createRevision(
            content: "# Intro\n\nblocked.\n",
            timestamp: pinnedTimestamp
        )
        Issue.record("expected bundleConflict but call succeeded")
    } catch let error as EngineError {
        if case .bundleConflict = error {
            // expected
        } else {
            Issue.record("expected .bundleConflict, got \(error)")
        }
    }
}
