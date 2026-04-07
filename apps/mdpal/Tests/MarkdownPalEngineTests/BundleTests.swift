// What Problem: Iteration 1.4 introduces DocumentBundle, BundleConfig,
// VersionId, RevisionInfo, and PruneResult. Each piece needs unit tests
// covering happy paths, error conditions, the dual-latest mechanism,
// pruning with comment merge-forward, and concurrency-conflict gating.
//
// How & Why: Swift Testing framework. Each test creates a fresh bundle
// in NSTemporaryDirectory and cleans it up via defer so tests are isolated
// and can run in parallel safely. Fixture content is inline strings.
//
// Written: 2026-04-07 during mdpal-cli session (iteration 1.4)

import Testing
import Foundation
@testable import MarkdownPalEngine

// MARK: - Helpers

private func uniqueBundlePath() -> String {
    NSTemporaryDirectory() + "mdpal-bundle-test-\(UUID().uuidString).mdpal"
}

private func cleanup(_ path: String) {
    try? FileManager.default.removeItem(atPath: path)
}

private let initialBody = """
# Section A

Body A.

# Section B

Body B.
"""

/// Build a fixed UTC date for tests, avoiding magic Unix epoch numbers.
private func fixtureDate(
    year: Int = 2026, month: Int = 4, day: Int = 7,
    hour: Int = 12, minute: Int = 0
) -> Date {
    var components = DateComponents()
    components.year = year
    components.month = month
    components.day = day
    components.hour = hour
    components.minute = minute
    components.second = 0
    components.timeZone = TimeZone(identifier: "UTC")
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    return calendar.date(from: components)!
}

// MARK: - VersionId

@Test func versionIdFormatBasic() {
    let date = fixtureDate() // 2026-04-07T12:00:00Z
    let id = VersionId.format(version: 1, revision: 3, timestamp: date)
    #expect(id == "V0001.0003.20260407T1200Z")
}

@Test func versionIdFormatWideValues() {
    let date = fixtureDate()
    let id = VersionId.format(version: 42, revision: 999, timestamp: date)
    #expect(id == "V0042.0999.20260407T1200Z")
}

@Test func versionIdParseValid() throws {
    let comps = try #require(VersionId.parse("V0001.0003.20260407T1200Z"))
    #expect(comps.version == 1)
    #expect(comps.revision == 3)
    #expect(comps.timestamp == fixtureDate())
}

@Test func versionIdParseRoundTrip() {
    let date = fixtureDate()
    let id = VersionId.format(version: 7, revision: 42, timestamp: date)
    let parsed = VersionId.parse(id)
    #expect(parsed?.version == 7)
    #expect(parsed?.revision == 42)
    #expect(parsed?.timestamp == date)
}

@Test func versionIdParseInvalid() {
    #expect(VersionId.parse("") == nil)
    #expect(VersionId.parse("V0001") == nil)
    #expect(VersionId.parse("X0001.0003.20260407T1200Z") == nil)
    #expect(VersionId.parse("V0001-0003-20260407T1200Z") == nil)
    #expect(VersionId.parse("V0001.0003.20260407T1200") == nil) // missing Z
    #expect(VersionId.parse("Vabcd.0003.20260407T1200Z") == nil)
    #expect(VersionId.parse("V0001.0003.99999999T9999Z") == nil) // bad date
}

// MARK: - BundleConfig

@Test func bundleConfigDefaults() {
    let config = BundleConfig.defaults(name: "MyDoc")
    #expect(config.name == "MyDoc")
    #expect(config.prune.keep == 20)
    #expect(config.prune.auto == false)
}

@Test func bundleConfigYAMLRoundTrip() throws {
    let config = BundleConfig(
        name: "TestBundle",
        prune: BundleConfig.PruneConfig(keep: 5, auto: true)
    )
    let yaml = try config.toYAML()
    #expect(yaml.contains("name: TestBundle"))
    #expect(yaml.contains("keep: 5"))
    #expect(yaml.contains("auto: true"))

    let decoded = try BundleConfig.fromYAML(yaml)
    #expect(decoded == config)
}

@Test func bundleConfigYAMLDeterministic() throws {
    let config = BundleConfig.defaults(name: "Deterministic")
    let yaml1 = try config.toYAML()
    let yaml2 = try config.toYAML()
    #expect(yaml1 == yaml2)
}

@Test func bundleConfigRejectsMissingName() {
    let yaml = """
    prune:
      keep: 20
      auto: false
    """
    do {
        _ = try BundleConfig.fromYAML(yaml)
        Issue.record("Expected throw")
    } catch let EngineError.metadataError(message) {
        #expect(message.contains("name"))
    } catch {
        Issue.record("Expected metadataError, got \(error)")
    }
}

@Test func bundleConfigRejectsMissingPrune() {
    let yaml = "name: NoPrune\n"
    do {
        _ = try BundleConfig.fromYAML(yaml)
        Issue.record("Expected throw")
    } catch let EngineError.metadataError(message) {
        #expect(message.contains("prune"))
    } catch {
        Issue.record("Expected metadataError, got \(error)")
    }
}

// MARK: - RevisionInfo

@Test func revisionInfoComparable() {
    let date = fixtureDate()
    let r1 = RevisionInfo(versionId: "V0001.0001.20260407T1200Z", version: 1, revision: 1, timestamp: date, filePath: "/a")
    let r2 = RevisionInfo(versionId: "V0001.0002.20260407T1200Z", version: 1, revision: 2, timestamp: date, filePath: "/b")
    let r3 = RevisionInfo(versionId: "V0002.0000.20260407T1200Z", version: 2, revision: 0, timestamp: date, filePath: "/c")
    #expect(r1 < r2)
    #expect(r2 < r3)
    let sorted = [r3, r1, r2].sorted()
    #expect(sorted == [r1, r2, r3])
}

// MARK: - DocumentBundle.create

@Test func bundleCreateSucceeds() throws {
    let path = uniqueBundlePath()
    defer { cleanup(path) }

    let date = fixtureDate()
    let bundle = try DocumentBundle.create(
        name: "TestBundle",
        initialContent: initialBody,
        at: path,
        timestamp: date
    )

    #expect(bundle.path == path)
    #expect(bundle.config.name == "TestBundle")

    let fm = FileManager.default
    #expect(fm.fileExists(atPath: path))
    #expect(fm.fileExists(atPath: "\(path)/.mdpal/config.yaml"))
    #expect(fm.fileExists(atPath: "\(path)/.mdpal/latest"))
    #expect(fm.fileExists(atPath: "\(path)/V0001.0001.20260407T1200Z.md"))
    #expect(fm.fileExists(atPath: "\(path)/latest.md"))
}

@Test func bundleCreateFailsWhenPathExists() throws {
    let path = uniqueBundlePath()
    defer { cleanup(path) }
    try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true)
    do {
        _ = try DocumentBundle.create(name: "X", initialContent: "", at: path)
        Issue.record("Expected throw")
    } catch EngineError.bundleConflict {
        // expected
    } catch {
        Issue.record("Expected bundleConflict, got \(error)")
    }
}

@Test func bundleCreateFailsWithoutMdpalSuffix() {
    let path = NSTemporaryDirectory() + "no-suffix-\(UUID().uuidString)"
    defer { cleanup(path) }
    do {
        _ = try DocumentBundle.create(name: "X", initialContent: "", at: path)
        Issue.record("Expected throw")
    } catch EngineError.bundleConflict {
        // expected
    } catch {
        Issue.record("Expected bundleConflict, got \(error)")
    }
}

// MARK: - DocumentBundle.init (open existing)

@Test func bundleOpenExistingSucceeds() throws {
    let path = uniqueBundlePath()
    defer { cleanup(path) }
    _ = try DocumentBundle.create(name: "Open", initialContent: initialBody, at: path)
    let reopened = try DocumentBundle(at: path)
    #expect(reopened.path == path)
    #expect(reopened.config.name == "Open")
}

@Test func bundleOpenNonexistentThrows() {
    let path = NSTemporaryDirectory() + "missing-\(UUID().uuidString).mdpal"
    do {
        _ = try DocumentBundle(at: path)
        Issue.record("Expected throw")
    } catch EngineError.fileError {
        // expected
    } catch {
        Issue.record("Expected fileError, got \(error)")
    }
}

@Test func bundleOpenWithoutMdpalSuffixThrows() throws {
    let path = NSTemporaryDirectory() + "wrongsuffix-\(UUID().uuidString)"
    try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true)
    defer { cleanup(path) }
    do {
        _ = try DocumentBundle(at: path)
        Issue.record("Expected throw")
    } catch EngineError.bundleConflict {
        // expected
    } catch {
        Issue.record("Expected bundleConflict, got \(error)")
    }
}

@Test func bundleOpenMissingConfigThrows() throws {
    let path = uniqueBundlePath()
    defer { cleanup(path) }
    try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true)
    // Create the directory but no .mdpal/config.yaml.
    do {
        _ = try DocumentBundle(at: path)
        Issue.record("Expected throw")
    } catch EngineError.bundleConflict {
        // expected
    } catch {
        Issue.record("Expected bundleConflict, got \(error)")
    }
}

// MARK: - listRevisions

@Test func listRevisionsSingleAfterCreate() throws {
    let path = uniqueBundlePath()
    defer { cleanup(path) }
    _ = try DocumentBundle.create(name: "L1", initialContent: initialBody, at: path)
    let bundle = try DocumentBundle(at: path)
    let revs = try bundle.listRevisions()
    #expect(revs.count == 1)
    #expect(revs[0].version == 1)
    #expect(revs[0].revision == 1)
}

@Test func listRevisionsMultipleSorted() throws {
    let path = uniqueBundlePath()
    defer { cleanup(path) }
    let t0 = fixtureDate()
    _ = try DocumentBundle.create(name: "L2", initialContent: initialBody, at: path, timestamp: t0)
    let bundle = try DocumentBundle(at: path)
    _ = try bundle.createRevision(content: initialBody + " r2", timestamp: t0.addingTimeInterval(60))
    _ = try bundle.createRevision(content: initialBody + " r3", timestamp: t0.addingTimeInterval(120))

    let revs = try bundle.listRevisions()
    #expect(revs.count == 3)
    #expect(revs[0].revision == 1)
    #expect(revs[1].revision == 2)
    #expect(revs[2].revision == 3)
    #expect(revs == revs.sorted())
}

// MARK: - createRevision

@Test func createRevisionIncrementsRevisionNumber() throws {
    let path = uniqueBundlePath()
    defer { cleanup(path) }
    _ = try DocumentBundle.create(name: "Inc", initialContent: initialBody, at: path)
    let bundle = try DocumentBundle(at: path)
    let r2 = try bundle.createRevision(content: initialBody + " r2")
    #expect(r2.version == 1)
    #expect(r2.revision == 2)
    let r3 = try bundle.createRevision(content: initialBody + " r3")
    #expect(r3.version == 1)
    #expect(r3.revision == 3)
}

@Test func createRevisionUpdatesLatest() throws {
    let path = uniqueBundlePath()
    defer { cleanup(path) }
    _ = try DocumentBundle.create(name: "Latest", initialContent: initialBody, at: path)
    let bundle = try DocumentBundle(at: path)
    let r2 = try bundle.createRevision(content: initialBody + " r2")

    // Symlink updated.
    let symlinkDest = try FileManager.default.destinationOfSymbolicLink(atPath: "\(path)/latest.md")
    #expect(symlinkDest == "\(r2.versionId).md")

    // Pointer file updated.
    let pointer = try bundle.readPointerFile()
    #expect(pointer == "\(r2.versionId).md")
}

// MARK: - bumpVersion

@Test func bumpVersionResetsRevisionAndIncrementsVersion() throws {
    let path = uniqueBundlePath()
    defer { cleanup(path) }
    _ = try DocumentBundle.create(name: "Bump", initialContent: initialBody, at: path)
    let bundle = try DocumentBundle(at: path)
    _ = try bundle.createRevision(content: initialBody + " r2")
    let bumped = try bundle.bumpVersion(content: initialBody + " v2")
    #expect(bumped.version == 2)
    #expect(bumped.revision == 1)
}

// MARK: - currentDocument

@Test func currentDocumentReturnsLatest() throws {
    let path = uniqueBundlePath()
    defer { cleanup(path) }
    _ = try DocumentBundle.create(name: "Cur", initialContent: initialBody, at: path)
    let bundle = try DocumentBundle(at: path)

    // Add a comment via the engine and create a new revision with the
    // serialized content.
    let doc = try bundle.currentDocument()
    _ = try doc.addComment(NewComment(
        type: .note, author: "claude", sectionSlug: "section-a", text: "tracked"
    ))
    _ = try bundle.createRevision(content: try doc.serialize())

    let reloaded = try bundle.currentDocument()
    #expect(reloaded.metadata.unresolvedComments.count == 1)
    #expect(reloaded.metadata.unresolvedComments[0].text == "tracked")
}

// MARK: - updateConfig

@Test func updateConfigPersists() throws {
    let path = uniqueBundlePath()
    defer { cleanup(path) }
    _ = try DocumentBundle.create(name: "Cfg", initialContent: initialBody, at: path)
    let bundle = try DocumentBundle(at: path)

    var newConfig = bundle.config
    newConfig.prune.keep = 5
    newConfig.prune.auto = true
    try bundle.updateConfig(newConfig)

    let reopened = try DocumentBundle(at: path)
    #expect(reopened.config.prune.keep == 5)
    #expect(reopened.config.prune.auto == true)
}

// MARK: - prune

@Test func pruneNoOpWhenWithinLimit() throws {
    let path = uniqueBundlePath()
    defer { cleanup(path) }
    _ = try DocumentBundle.create(name: "Prune", initialContent: initialBody, at: path)
    let bundle = try DocumentBundle(at: path)
    _ = try bundle.createRevision(content: initialBody + " r2")
    let result = try bundle.prune(keep: 5)
    #expect(result.prunedRevisions.isEmpty)
    #expect(result.mergedComments == 0)
    #expect(result.remainingRevisions == 2)
}

@Test func pruneRemovesOldRevisions() throws {
    let path = uniqueBundlePath()
    defer { cleanup(path) }
    let t0 = fixtureDate()
    _ = try DocumentBundle.create(name: "P", initialContent: initialBody, at: path, timestamp: t0)
    let bundle = try DocumentBundle(at: path)
    for i in 1..<5 {
        _ = try bundle.createRevision(content: initialBody + " r\(i+1)", timestamp: t0.addingTimeInterval(Double(i * 60)))
    }
    // Now have 5 revisions: 1, 2, 3, 4, 5.
    let result = try bundle.prune(keep: 2)
    #expect(result.prunedRevisions.count == 3)
    #expect(result.remainingRevisions == 2)

    let remaining = try bundle.listRevisions()
    #expect(remaining.count == 2)
    #expect(remaining.last?.revision == 5)
}

@Test func pruneMergesForwardResolvedComments() throws {
    let path = uniqueBundlePath()
    defer { cleanup(path) }
    let t0 = fixtureDate()
    _ = try DocumentBundle.create(name: "Merge", initialContent: initialBody, at: path, timestamp: t0)
    let bundle = try DocumentBundle(at: path)

    // Each revision contains a DIFFERENT single resolved comment with a
    // pre-assigned id. We bypass addComment's auto-id-assignment (which
    // would collide after clearing the resolved list) by constructing
    // Comments directly via @testable.
    func makeResolvedComment(id: String, text: String) -> MarkdownPalEngine.Comment {
        MarkdownPalEngine.Comment(
            id: id,
            type: .note,
            author: "a",
            sectionSlug: "section-a",
            versionHash: "h",
            timestamp: t0,
            context: "ctx",
            text: text,
            resolution: Resolution(response: "ok", resolvedDate: t0, resolvedBy: "j")
        )
    }

    // Revision 2: c0001 only.
    let doc1 = try bundle.currentDocument()
    doc1.metadata.resolvedComments = [makeResolvedComment(id: "c0001", text: "first")]
    _ = try bundle.createRevision(content: try doc1.serialize(), timestamp: t0.addingTimeInterval(60))

    // Revision 3: c0002 only.
    let doc2 = try bundle.currentDocument()
    doc2.metadata.resolvedComments = [makeResolvedComment(id: "c0002", text: "second")]
    _ = try bundle.createRevision(content: try doc2.serialize(), timestamp: t0.addingTimeInterval(120))

    // Revision 4: c0003 only.
    let doc3 = try bundle.currentDocument()
    doc3.metadata.resolvedComments = [makeResolvedComment(id: "c0003", text: "third")]
    _ = try bundle.createRevision(content: try doc3.serialize(), timestamp: t0.addingTimeInterval(180))

    // Now bundle has 4 revisions:
    //   r1: initial, no comments
    //   r2: c0001
    //   r3: c0002 only
    //   r4: c0003 only
    // Pruning to keep=1 should merge c0001 and c0002 forward into r4.
    let result = try bundle.prune(keep: 1)
    #expect(result.remainingRevisions == 1)
    #expect(result.mergedComments == 2) // c0001 and c0002 were missing from r4

    let merged = try bundle.currentDocument()
    let resolvedIds = Set(merged.metadata.resolvedComments.map { $0.id })
    #expect(resolvedIds.contains("c0001"))
    #expect(resolvedIds.contains("c0002"))
    #expect(resolvedIds.contains("c0003"))
    #expect(merged.metadata.resolvedComments.count == 3)
}

@Test func pruneRejectsZeroKeep() throws {
    let path = uniqueBundlePath()
    defer { cleanup(path) }
    _ = try DocumentBundle.create(name: "PZ", initialContent: initialBody, at: path)
    let bundle = try DocumentBundle(at: path)
    do {
        _ = try bundle.prune(keep: 0)
        Issue.record("Expected throw")
    } catch EngineError.bundleConflict {
        // expected
    } catch {
        Issue.record("Expected bundleConflict, got \(error)")
    }
}

// MARK: - Dual latest mechanism

@Test func dualLatestSymlinkAndPointerAgree() throws {
    let path = uniqueBundlePath()
    defer { cleanup(path) }
    _ = try DocumentBundle.create(name: "Dual", initialContent: initialBody, at: path)
    let bundle = try DocumentBundle(at: path)

    let symlinkDest = try FileManager.default.destinationOfSymbolicLink(atPath: "\(path)/latest.md")
    let pointer = try bundle.readPointerFile()
    #expect(symlinkDest == pointer)

    // After a new revision, both still agree.
    let r2 = try bundle.createRevision(content: initialBody + " r2")
    let symlinkDest2 = try FileManager.default.destinationOfSymbolicLink(atPath: "\(path)/latest.md")
    let pointer2 = try bundle.readPointerFile()
    #expect(symlinkDest2 == pointer2)
    #expect(symlinkDest2 == "\(r2.versionId).md")
}

@Test func latestMdResolvesToActualFile() throws {
    let path = uniqueBundlePath()
    defer { cleanup(path) }
    _ = try DocumentBundle.create(name: "Resolve", initialContent: initialBody, at: path)

    // Reading latest.md should give us the initial content (symlink follows).
    let content = try String(contentsOfFile: "\(path)/latest.md", encoding: .utf8)
    #expect(content.contains("# Section A"))
    #expect(content.contains("Body A."))
}
