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

// **Phase 3 iter 3.6.** Scale benchmark at 1000 revisions. Same gate as
// the 100-revision test (MDPAL_RUN_BENCHMARKS=1); same shape but with
// looser thresholds proportional to scale. Catches pathological N^2
// regressions that wouldn't show at 100 revisions.
@Test func bundleWith1000RevisionsPerformsAcceptably() throws {
    guard ProcessInfo.processInfo.environment["MDPAL_RUN_BENCHMARKS"] == "1" else {
        // Skipped silently in default runs; opt in via env var.
        // Skipped by default since 1000-revision setup is slow on its own.
        return
    }
    let setup = try makeFreshBundleDir()
    defer { try? FileManager.default.removeItem(at: setup.tempDir) }

    let bundle = try DocumentBundle(at: setup.bundlePath)
    let baseTime = Date(timeIntervalSince1970: 1_775_000_000)

    // Append 999 revisions (1 + 999 = 1000 total).
    for i in 2...1000 {
        let ts = baseTime.addingTimeInterval(TimeInterval(i * 60))
        _ = try bundle.createRevision(
            content: "# Intro\n\nrev \(i).\n",
            timestamp: ts
        )
    }

    // Hot paths: listRevisions and currentDocument should stay O(n)
    // per call. Linear over 1000 should comfortably fit in 30s on
    // any plausibly-loaded CI runner.
    let listStart = Date()
    let revisions = try bundle.listRevisions()
    let listElapsed = Date().timeIntervalSince(listStart)
    #expect(revisions.count == 1000)
    #expect(listElapsed < 30.0, "listRevisions on 1000-rev bundle took \(listElapsed)s — should be < 30s")

    let currentStart = Date()
    let doc = try bundle.currentDocument()
    let currentElapsed = Date().timeIntervalSince(currentStart)
    #expect(!doc.listSections().isEmpty)
    #expect(currentElapsed < 30.0, "currentDocument on 1000-rev bundle took \(currentElapsed)s — should be < 30s")

    // Diff across the full range — N^2 territory if implemented poorly.
    let diffStart = Date()
    let firstId = try #require(revisions.first?.versionId)
    let lastId = try #require(revisions.last?.versionId)
    let diffs = try bundle.diff(baseRevision: firstId, targetRevision: lastId)
    let diffElapsed = Date().timeIntervalSince(diffStart)
    #expect(!diffs.isEmpty)
    #expect(diffElapsed < 60.0, "diff across 1000-rev range took \(diffElapsed)s — should be < 60s")

    // Prune to keep 100 — exercises the merge-forward path under load.
    let pruneStart = Date()
    let pruneResult = try bundle.prune(keep: 100)
    let pruneElapsed = Date().timeIntervalSince(pruneStart)
    #expect(pruneResult.remainingRevisions == 100)
    #expect(pruneResult.prunedRevisions.count == 900)
    #expect(pruneElapsed < 120.0, "prune of 900 revisions took \(pruneElapsed)s — should be < 120s")
}

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

// MARK: - Phase 2 phase-complete additions

// T1: SizedFileReader generic readUTF8 — non-UTF8 + size-attr fallback.

@Test func sizedReadRejectsNonUTF8Bytes() throws {
    let setup = try makeFreshBundleDir()
    defer { try? FileManager.default.removeItem(at: setup.tempDir) }

    // Write raw bytes that are NOT valid UTF-8 (lone continuation bytes
    // 0xFF 0xFE 0xFD form no valid scalar).
    let path = "\(setup.bundlePath)/V0001.0002.20260101T0000Z.md"
    try Data([0xFF, 0xFE, 0xFD]).write(to: URL(fileURLWithPath: path))

    do {
        _ = try SizedFileReader.readRevisionUTF8(at: path)
        Issue.record("expected fileError on non-UTF-8 bytes but call succeeded")
    } catch let error as EngineError {
        if case .fileError = error {
            // Hot path (size attr available): String(contentsOfFile:encoding:.utf8)
            // throws an NSCocoaErrorDomain "isn't in the correct format" error
            // (Cocoa Code 259). Fallback path: explicit "non-UTF-8 bytes".
            // Either presents as fileError; the discriminator is what mdpal-app
            // routes on, so the message form is best-effort.
        } else {
            Issue.record("expected .fileError, got \(error)")
        }
    }
}

// T2: rawRevisionContent — verbatim bytes + unknown-versionId rejection.

@Test func rawRevisionContentRejectsUnknownVersionId() throws {
    let setup = try makeFreshBundleDir()
    defer { try? FileManager.default.removeItem(at: setup.tempDir) }

    let bundle = try DocumentBundle(at: setup.bundlePath)
    do {
        _ = try bundle.rawRevisionContent(versionId: "V0099.0099.20260101T0000Z")
        Issue.record("expected bundleConflict on unknown versionId")
    } catch let error as EngineError {
        if case .bundleConflict = error {
            // expected
        } else {
            Issue.record("expected .bundleConflict, got \(error)")
        }
    }
}

@Test func rawRevisionContentReturnsBytesVerbatim() throws {
    let setup = try makeFreshBundleDir()
    defer { try? FileManager.default.removeItem(at: setup.tempDir) }

    // Write a revision file with unusual whitespace and ordering that
    // Document.serialize() would normalize. rawRevisionContent must
    // return the exact bytes on disk.
    let bundle = try DocumentBundle(at: setup.bundlePath)
    let raw = "# Intro\n\n\n\n  weird   spacing   .\n\n"
    let pinnedTs = Date(timeIntervalSince1970: 1_775_001_000)
    let revision = try bundle.createRevision(content: raw, timestamp: pinnedTs)

    let readBack = try bundle.rawRevisionContent(versionId: revision.versionId)
    #expect(readBack == raw,
            "rawRevisionContent must return verbatim bytes — got: \(readBack.debugDescription)")
}

// T3: Orphan-temp reaper — age guard + regular-file check.

@Test func bundleOpenReapsAgedOrphanTempFiles() throws {
    let setup = try makeFreshBundleDir()
    defer { try? FileManager.default.removeItem(at: setup.tempDir) }

    // Plant an orphan .tmp.* file and backdate its mtime to >1 hour ago,
    // past the reaper age threshold. Bundle open should remove it.
    let orphanPath = "\(setup.bundlePath)/V0001.0002.20260101T0000Z.md.tmp.deadbeef"
    try "orphan content".write(toFile: orphanPath, atomically: true, encoding: .utf8)
    let oldDate = Date().addingTimeInterval(-7200) // 2 hours ago
    try FileManager.default.setAttributes(
        [.modificationDate: oldDate],
        ofItemAtPath: orphanPath
    )

    _ = try DocumentBundle(at: setup.bundlePath)
    #expect(!FileManager.default.fileExists(atPath: orphanPath),
            "Aged orphan .tmp.* should be reaped at bundle open")
}

@Test func bundleOpenSkipsFreshOrphanTempFiles() throws {
    let setup = try makeFreshBundleDir()
    defer { try? FileManager.default.removeItem(at: setup.tempDir) }

    // F3 (phase-complete): plant a temp file with a CURRENT mtime —
    // simulates a writer mid-flight. The reaper must skip it so we don't
    // race the in-flight link(2) into ENOENT.
    let freshPath = "\(setup.bundlePath)/V0001.0003.20260101T0000Z.md.tmp.cafebabe"
    try "in-flight content".write(toFile: freshPath, atomically: true, encoding: .utf8)
    // mtime defaults to now — no setAttributes needed.

    _ = try DocumentBundle(at: setup.bundlePath)
    #expect(FileManager.default.fileExists(atPath: freshPath),
            "Fresh orphan .tmp.* (within age threshold) must be left alone — racing in-flight writer")
}

@Test func bundleOpenSkipsNonRegularOrphanCandidates() throws {
    let setup = try makeFreshBundleDir()
    defer { try? FileManager.default.removeItem(at: setup.tempDir) }

    // Sec-3 (phase-complete): plant a DIRECTORY at a name matching the
    // reaper pattern. The type guard must reject it so we never
    // removeItem on it (recursive directory delete via reaper would be
    // unintended state loss).
    let dirPath = "\(setup.bundlePath)/V0001.0004.20260101T0000Z.md.tmp.dirtype"
    try FileManager.default.createDirectory(atPath: dirPath, withIntermediateDirectories: false)
    let oldDate = Date().addingTimeInterval(-7200)
    try FileManager.default.setAttributes(
        [.modificationDate: oldDate],
        ofItemAtPath: dirPath
    )

    _ = try DocumentBundle(at: setup.bundlePath)
    #expect(FileManager.default.fileExists(atPath: dirPath),
            "Directory matching .tmp.* pattern must NOT be reaped (regular-file guard)")
}

// T6: Pointer file rejects control characters (NUL, BEL).

@Test func pointerFileRejectsEmbeddedNUL() throws {
    let setup = try makeFreshBundleDir()
    defer { try? FileManager.default.removeItem(at: setup.tempDir) }

    let bundle = try DocumentBundle(at: setup.bundlePath)
    let pointerPath = "\(setup.bundlePath)/.mdpal/latest"
    // Embed NUL in a string. Foundation may truncate at NUL on read,
    // but the validatePointerContents check on unicodeScalars catches
    // it explicitly.
    let nul = String(UnicodeScalar(0x00)!)
    let payload = "V0001.0001.20260404T1200Z\(nul).md"
    try payload.write(toFile: pointerPath, atomically: true, encoding: .utf8)

    do {
        _ = try bundle.readPointerFile()
        Issue.record("expected metadataError on embedded NUL")
    } catch let error as EngineError {
        if case .metadataError = error {
            // expected
        } else {
            Issue.record("expected .metadataError, got \(error)")
        }
    }
}

@Test func pointerFileRejectsEmbeddedBEL() throws {
    let setup = try makeFreshBundleDir()
    defer { try? FileManager.default.removeItem(at: setup.tempDir) }

    let bundle = try DocumentBundle(at: setup.bundlePath)
    let pointerPath = "\(setup.bundlePath)/.mdpal/latest"
    let bel = String(UnicodeScalar(0x07)!)
    let payload = "V0001.0001.\(bel)20260404T1200Z.md"
    try payload.write(toFile: pointerPath, atomically: true, encoding: .utf8)

    do {
        _ = try bundle.readPointerFile()
        Issue.record("expected metadataError on embedded BEL")
    } catch let error as EngineError {
        if case .metadataError = error {
            // expected
        } else {
            Issue.record("expected .metadataError, got \(error)")
        }
    }
}

// F1: auto-prune does NOT mutate the just-created revision file.

@Test func autoPruneDoesNotMutateJustCreatedRevisionFile() throws {
    let setup = try makeFreshBundleDir()
    defer { try? FileManager.default.removeItem(at: setup.tempDir) }

    // Configure auto-prune to keep 1, so any new revision triggers
    // pruning of all older revisions.
    let bundle = try DocumentBundle(at: setup.bundlePath)
    var cfg = bundle.config
    cfg.prune.auto = true
    cfg.prune.keep = 1
    try bundle.updateConfig(cfg)

    // Add 2 more revisions to give prune something to merge forward.
    let baseTs = Date(timeIntervalSince1970: 1_775_001_000)
    _ = try bundle.createRevision(
        content: "# Intro\n\nrev2.\n",
        timestamp: baseTs
    )
    _ = try bundle.createRevision(
        content: "# Intro\n\nrev3.\n",
        timestamp: baseTs.addingTimeInterval(120)
    )

    // After auto-prune (keep:1), only the latest remains.
    let revisions = try bundle.listRevisions()
    #expect(revisions.count == 1, "auto-prune should reduce to 1 revision")

    // The just-created revision file's bytes must be exactly what we
    // wrote — auto-prune must NOT have re-spliced metadata into it.
    let latest = try #require(revisions.last)
    let onDisk = try SizedFileReader.readRevisionUTF8(at: latest.filePath)
    #expect(onDisk == "# Intro\n\nrev3.\n",
            "Auto-prune mutated the just-created revision; F1 regression. On disk: \(onDisk.debugDescription)")
}

// Sec-4: reconcileLatest refuses to write a malformed symlink dest.

@Test func reconcileLatestRejectsMaliciousSymlinkDestination() throws {
    let setup = try makeFreshBundleDir()
    defer { try? FileManager.default.removeItem(at: setup.tempDir) }

    // Tamper: replace latest.md symlink with one whose destination is a
    // path-traversal payload. Then re-open the bundle and observe that
    // reconcileLatest LEAVES the pointer file untouched (rather than
    // writing the bad bytes).
    let symlinkPath = "\(setup.bundlePath)/latest.md"
    try FileManager.default.removeItem(atPath: symlinkPath)
    try FileManager.default.createSymbolicLink(
        atPath: symlinkPath,
        withDestinationPath: "../../etc/shadow"
    )

    // Capture pointer contents before re-open.
    let pointerPath = "\(setup.bundlePath)/.mdpal/latest"
    let beforeBytes = try String(contentsOfFile: pointerPath, encoding: .utf8)

    // Re-open. reconcileLatest sees mismatch (pointer != symlinkDest)
    // but the dest is invalid → must not write.
    _ = try DocumentBundle(at: setup.bundlePath)

    let afterBytes = try String(contentsOfFile: pointerPath, encoding: .utf8)
    #expect(beforeBytes == afterBytes,
            "reconcileLatest wrote malformed symlink dest into pointer file (Sec-4 regression)")
}

// Sec-5: validateBundlePath rejects a symlink-as-bundle.

@Test func validateBundlePathRejectsSymlinkAsBundle() throws {
    let setup = try makeFreshBundleDir()
    defer { try? FileManager.default.removeItem(at: setup.tempDir) }

    // Create a symlink that points to the real bundle, but with a
    // .mdpal-suffixed name. Old fileExists(_:isDirectory:) would follow
    // the symlink and report (true, isDir=true), so the open would
    // succeed; new attributesOfItem-based check rejects.
    let aliasPath = setup.tempDir.appendingPathComponent("alias.mdpal").path
    try FileManager.default.createSymbolicLink(
        atPath: aliasPath,
        withDestinationPath: setup.bundlePath
    )

    do {
        _ = try DocumentBundle(at: aliasPath)
        Issue.record("expected fileError on symlink-as-bundle path; open succeeded")
    } catch let error as EngineError {
        if case .fileError = error {
            // expected
        } else {
            Issue.record("expected .fileError, got \(error)")
        }
    }
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
