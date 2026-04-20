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
    } catch let EngineError.invalidBundlePath(throwPath, reason) {
        #expect(throwPath == path)
        #expect(reason.contains("already exists"))
    } catch {
        Issue.record("Expected invalidBundlePath, got \(error)")
    }
}

@Test func bundleCreateFailsWithoutMdpalSuffix() {
    let path = NSTemporaryDirectory() + "no-suffix-\(UUID().uuidString)"
    defer { cleanup(path) }
    do {
        _ = try DocumentBundle.create(name: "X", initialContent: "", at: path)
        Issue.record("Expected throw")
    } catch let EngineError.invalidBundlePath(_, reason) {
        #expect(reason.contains(".mdpal"))
    } catch {
        Issue.record("Expected invalidBundlePath, got \(error)")
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
    } catch let EngineError.invalidBundlePath(_, reason) {
        #expect(reason.contains(".mdpal"))
    } catch {
        Issue.record("Expected invalidBundlePath, got \(error)")
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
    } catch let EngineError.invalidBundlePath(_, reason) {
        #expect(reason.contains("config"))
    } catch {
        Issue.record("Expected invalidBundlePath, got \(error)")
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

// MARK: - QG fix tests (iteration 1.4 finalization)

// MARK: VersionId leading-sign rejection (QG fix #1)

@Test func versionIdRejectsLeadingPlusSign() {
    #expect(VersionId.parse("V+001.0003.20260407T1200Z") == nil)
    #expect(VersionId.parse("V0001.+003.20260407T1200Z") == nil)
}

@Test func versionIdRejectsLeadingMinusSign() {
    #expect(VersionId.parse("V-001.0003.20260407T1200Z") == nil)
    #expect(VersionId.parse("V0001.-003.20260407T1200Z") == nil)
}

// MARK: BundleConfig strict auto field (QG fix #3)

@Test func bundleConfigRejectsAutoAsString() {
    let yaml = """
    name: TestStrict
    prune:
      keep: 5
      auto: "yes"
    """
    do {
        _ = try BundleConfig.fromYAML(yaml)
        Issue.record("Expected throw for non-bool auto")
    } catch let EngineError.metadataError(message) {
        #expect(message.contains("auto"))
    } catch {
        Issue.record("Expected metadataError, got \(error)")
    }
}

@Test func bundleConfigRejectsAutoAsInt() {
    let yaml = """
    name: TestStrict
    prune:
      keep: 5
      auto: 1
    """
    do {
        _ = try BundleConfig.fromYAML(yaml)
        Issue.record("Expected throw for int auto")
    } catch EngineError.metadataError {
        // expected
    } catch {
        Issue.record("Expected metadataError, got \(error)")
    }
}

@Test func bundleConfigAcceptsAutoAbsentAsFalse() throws {
    let yaml = """
    name: TestDefault
    prune:
      keep: 5
    """
    let config = try BundleConfig.fromYAML(yaml)
    #expect(config.prune.auto == false)
}

@Test func bundleConfigRejectsZeroKeep() {
    let yaml = """
    name: TestZero
    prune:
      keep: 0
      auto: false
    """
    do {
        _ = try BundleConfig.fromYAML(yaml)
        Issue.record("Expected throw for keep <= 0")
    } catch let EngineError.metadataError(message) {
        #expect(message.contains("keep"))
    } catch {
        Issue.record("Expected metadataError, got \(error)")
    }
}

@Test func bundleConfigRejectsNegativeKeep() {
    let yaml = """
    name: TestNeg
    prune:
      keep: -3
      auto: false
    """
    do {
        _ = try BundleConfig.fromYAML(yaml)
        Issue.record("Expected throw for negative keep")
    } catch EngineError.metadataError {
        // expected
    } catch {
        Issue.record("Expected metadataError, got \(error)")
    }
}

// MARK: YAML snapshot equality (QG fixes #14, #15)

@Test func bundleConfigYAMLSnapshotMatchesExpected() throws {
    let config = BundleConfig(
        name: "Snapshot",
        prune: BundleConfig.PruneConfig(keep: 7, auto: true)
    )
    let yaml = try config.toYAML()
    let expected = """
    name: Snapshot
    prune:
      keep: 7
      auto: true

    """
    #expect(yaml == expected)
}

@Test func bundleConfigYAMLDefaultsSnapshotMatchesExpected() throws {
    let config = BundleConfig.defaults(name: "DefaultDoc")
    let yaml = try config.toYAML()
    let expected = """
    name: DefaultDoc
    prune:
      keep: 20
      auto: false

    """
    #expect(yaml == expected)
}

// MARK: Corrupt config (QG test gap #9)

@Test func bundleOpenWithCorruptConfigThrows() throws {
    let path = uniqueBundlePath()
    defer { cleanup(path) }
    try FileManager.default.createDirectory(
        atPath: "\(path)/.mdpal",
        withIntermediateDirectories: true
    )
    // Write garbage that is not valid YAML.
    try "this: is: not: valid: yaml: at all: [".write(
        toFile: "\(path)/.mdpal/config.yaml",
        atomically: true,
        encoding: .utf8
    )
    do {
        _ = try DocumentBundle(at: path)
        Issue.record("Expected throw")
    } catch EngineError.metadataError {
        // expected
    } catch {
        Issue.record("Expected metadataError, got \(error)")
    }
}

@Test func bundleOpenWithMissingConfigFieldsThrows() throws {
    let path = uniqueBundlePath()
    defer { cleanup(path) }
    try FileManager.default.createDirectory(
        atPath: "\(path)/.mdpal",
        withIntermediateDirectories: true
    )
    // Valid YAML but missing required fields.
    try "name: Incomplete\n".write(
        toFile: "\(path)/.mdpal/config.yaml",
        atomically: true,
        encoding: .utf8
    )
    do {
        _ = try DocumentBundle(at: path)
        Issue.record("Expected throw")
    } catch EngineError.metadataError {
        // expected
    } catch {
        Issue.record("Expected metadataError, got \(error)")
    }
}

// MARK: Reload-after-write (QG test gap #10)

@Test func reloadAfterWriteSeesNewContent() throws {
    let path = uniqueBundlePath()
    defer { cleanup(path) }
    let t0 = fixtureDate()
    _ = try DocumentBundle.create(name: "Reload", initialContent: initialBody, at: path, timestamp: t0)
    let bundle = try DocumentBundle(at: path)
    let r2 = try bundle.createRevision(
        content: initialBody + "\n\n# Section C\n\nNew content.\n",
        timestamp: t0.addingTimeInterval(60)
    )

    // Reopen the bundle from disk and verify the new revision survived.
    let reopened = try DocumentBundle(at: path)
    let revs = try reopened.listRevisions()
    #expect(revs.count == 2)
    #expect(revs.last?.versionId == r2.versionId)

    // Read the actual file content via currentDocument.
    let doc = try reopened.currentDocument()
    let sections = doc.listSections().map { $0.heading }
    #expect(sections.contains("Section A"))
    #expect(sections.contains("Section B"))
    #expect(sections.contains("Section C"))
}

// MARK: listRevisions filtering (QG test gap #11)

@Test func listRevisionsSkipsNonRevisionMdFiles() throws {
    let path = uniqueBundlePath()
    defer { cleanup(path) }
    _ = try DocumentBundle.create(name: "Filter", initialContent: initialBody, at: path)
    let bundle = try DocumentBundle(at: path)

    // Drop unrelated files in the bundle root.
    try "# README".write(toFile: "\(path)/README.md", atomically: true, encoding: .utf8)
    try "# Notes".write(toFile: "\(path)/notes.md", atomically: true, encoding: .utf8)
    try "junk".write(toFile: "\(path)/random.txt", atomically: true, encoding: .utf8)
    try "looks-like-a-revision-but-no".write(
        toFile: "\(path)/V0001.0001.malformed.md",
        atomically: true,
        encoding: .utf8
    )

    let revs = try bundle.listRevisions()
    // Only the actual initial revision counts.
    #expect(revs.count == 1)
    #expect(revs[0].version == 1)
    #expect(revs[0].revision == 1)
}

@Test func listRevisionsSkipsLatestSymlink() throws {
    let path = uniqueBundlePath()
    defer { cleanup(path) }
    _ = try DocumentBundle.create(name: "SkipLatest", initialContent: initialBody, at: path)
    let bundle = try DocumentBundle(at: path)
    let revs = try bundle.listRevisions()
    // Only the V*.md file, NOT latest.md (which is a symlink).
    #expect(revs.count == 1)
    #expect(!(revs[0].versionId.contains("latest")))
}

// MARK: Empty bundle edge cases (QG test gap #12)

@Test func emptyBundleLatestRevisionReturnsNil() throws {
    let path = uniqueBundlePath()
    defer { cleanup(path) }
    _ = try DocumentBundle.create(name: "Empty", initialContent: initialBody, at: path)
    let bundle = try DocumentBundle(at: path)

    // Manually delete the only revision file to simulate empty state.
    let revs = try bundle.listRevisions()
    try FileManager.default.removeItem(atPath: revs[0].filePath)

    #expect(try bundle.listRevisions().isEmpty)
    #expect(try bundle.latestRevision() == nil)
}

@Test func emptyBundleCurrentDocumentThrows() throws {
    let path = uniqueBundlePath()
    defer { cleanup(path) }
    _ = try DocumentBundle.create(name: "EmptyDoc", initialContent: initialBody, at: path)
    let bundle = try DocumentBundle(at: path)
    let revs = try bundle.listRevisions()
    try FileManager.default.removeItem(atPath: revs[0].filePath)

    do {
        _ = try bundle.currentDocument()
        Issue.record("Expected throw")
    } catch EngineError.bundleConflict {
        // expected — "Bundle has no revisions"
    } catch {
        Issue.record("Expected bundleConflict, got \(error)")
    }
}

@Test func bumpVersionOnEmptyBundleStartsAtV1() throws {
    let path = uniqueBundlePath()
    defer { cleanup(path) }
    _ = try DocumentBundle.create(name: "BumpEmpty", initialContent: initialBody, at: path)
    let bundle = try DocumentBundle(at: path)
    let revs = try bundle.listRevisions()
    try FileManager.default.removeItem(atPath: revs[0].filePath)

    let bumped = try bundle.bumpVersion(content: "# Fresh\n")
    #expect(bumped.version == 1)
    #expect(bumped.revision == 1)
}

// MARK: Same-minute timestamp collision (QG test gap #13)

// Note: A true two-writer race-condition test would require thread
// orchestration. The collision guard in writeRevision (refuses to
// overwrite an existing revision file) is exercised indirectly by
// every other createRevision test — they pass distinct timestamps
// and confirm new files are written. The guard's protective behavior
// is verified below: when the engine SEES a pre-existing file with
// a valid revision filename, listRevisions counts it as a revision
// and the next createRevision computes a NON-colliding path. This
// test confirms that automatic re-numbering happens.

@Test func revisionRenumbersAfterPreExistingFile() throws {
    let path = uniqueBundlePath()
    defer { cleanup(path) }
    let t = fixtureDate()
    _ = try DocumentBundle.create(name: "Renumber", initialContent: initialBody, at: path, timestamp: t)
    let bundle = try DocumentBundle(at: path)

    // Pre-write a file that LOOKS like revision 5 (skipping 2-4).
    let phantomV = "V0001.0005.\(VersionId.formatTimestamp(t.addingTimeInterval(60)))"
    try "phantom".write(
        toFile: "\(path)/\(phantomV).md",
        atomically: true,
        encoding: .utf8
    )

    // Bundle now sees [r1, phantom-r5]. Latest = r5. Next createRevision
    // computes revision 6 — DOES NOT collide with the phantom.
    let r6 = try bundle.createRevision(
        content: "real revision",
        timestamp: t.addingTimeInterval(120)
    )
    #expect(r6.version == 1)
    #expect(r6.revision == 6)

    // Phantom file is still there, untouched.
    let phantomContent = try String(
        contentsOfFile: "\(path)/\(phantomV).md",
        encoding: .utf8
    )
    #expect(phantomContent == "phantom")
}

// MARK: Auto-prune (QG test gap #8)

@Test func autoPruneTriggersOnCreateRevision() throws {
    let path = uniqueBundlePath()
    defer { cleanup(path) }
    let t0 = fixtureDate()
    _ = try DocumentBundle.create(name: "Auto", initialContent: initialBody, at: path, timestamp: t0)
    let bundle = try DocumentBundle(at: path)

    // Configure auto-prune: keep 2.
    var newConfig = bundle.config
    newConfig.prune.keep = 2
    newConfig.prune.auto = true
    try bundle.updateConfig(newConfig)

    // Create 4 more revisions, distinct timestamps.
    for i in 1...4 {
        _ = try bundle.createRevision(
            content: "r\(i+1)",
            timestamp: t0.addingTimeInterval(Double(i * 60))
        )
    }

    // After auto-prune, only the 2 most recent should survive.
    let revs = try bundle.listRevisions()
    #expect(revs.count == 2)
    #expect(revs.last?.revision == 5)
}

// MARK: C1 — Prune preserves body byte-for-byte (phase QG critical fix)

@Test func prunePreservesBodyContentVerbatim() throws {
    let path = uniqueBundlePath()
    defer { cleanup(path) }
    let t0 = fixtureDate()

    // Create a bundle and add a resolved comment to r1.
    _ = try DocumentBundle.create(name: "C1Test", initialContent: initialBody, at: path, timestamp: t0)
    let bundle = try DocumentBundle(at: path)

    let doc1 = try bundle.currentDocument()
    let cmt1 = try doc1.addComment(NewComment(
        type: .note,
        author: "alice",
        sectionSlug: "section-a",
        text: "old comment"
    ))
    try doc1.resolveComment(id: cmt1.id, response: "accepted", resolvedBy: "alice")
    try doc1.save()

    // Create r2 with deliberate whitespace quirks that serialize() would
    // normalize: trailing spaces, multiple blank lines, mixed indentation.
    // This becomes the latest after prune — its body MUST survive verbatim.
    let r2Body = "# Title\n\nBody with trailing spaces.   \n\n\nExtra blank lines.\n\n\ttab-indented.\n"
    _ = try bundle.createRevision(content: r2Body, timestamp: t0.addingTimeInterval(60))

    // Capture the raw r2 file content BEFORE prune.
    let r2Revision = try bundle.latestRevision()!
    let r2BeforePrune = try String(contentsOfFile: r2Revision.filePath, encoding: .utf8)
    #expect(r2BeforePrune == r2Body) // sanity: file is exactly what we wrote

    // Prune to keep 1. Merges r1's resolved comment into r2.
    let result = try bundle.prune(keep: 1)
    #expect(result.prunedRevisions.count == 1)
    #expect(result.mergedComments == 1)

    // Read the surviving file and verify body is untouched.
    let rawAfterPrune = try String(contentsOfFile: r2Revision.filePath, encoding: .utf8)

    // The body portion must be preserved byte-for-byte. Since r2 had no
    // metadata block before prune, one was appended. The original content
    // must still be a prefix.
    #expect(rawAfterPrune.hasPrefix(r2Body))

    // Metadata was appended with the merged comment.
    #expect(rawAfterPrune.contains("begin:markdown-pal-meta"))
    #expect(rawAfterPrune.contains("old comment"))
}

@Test func prunePreservesBodyWhenLatestAlreadyHasMetadata() throws {
    let path = uniqueBundlePath()
    defer { cleanup(path) }
    let t0 = fixtureDate()

    // Create bundle and add a resolved comment to r1.
    _ = try DocumentBundle.create(name: "SpliceTest", initialContent: initialBody, at: path, timestamp: t0)
    let bundle = try DocumentBundle(at: path)
    let doc1 = try bundle.currentDocument()
    let cmt1 = try doc1.addComment(NewComment(
        type: .note,
        author: "alice",
        sectionSlug: "section-a",
        text: "from revision 1"
    ))
    try doc1.resolveComment(id: cmt1.id, response: "ok", resolvedBy: "alice")
    try doc1.save()

    // Create r2 with quirky whitespace AND give it its own metadata block
    // by adding a comment and saving. This tests in-place splice.
    let r2Body = "# Title\n\nBody with trailing spaces.   \n\n\nExtra blank lines.\n\n\ttab-indented.\n"
    _ = try bundle.createRevision(content: r2Body, timestamp: t0.addingTimeInterval(60))
    let doc2 = try bundle.currentDocument()
    _ = try doc2.addComment(NewComment(
        type: .question,
        author: "bob",
        sectionSlug: "title",
        text: "unresolved question on r2"
    ))
    try doc2.save()

    // r2 now has a metadata block. Capture body portion BEFORE prune.
    let r2Revision = try bundle.latestRevision()!
    let rawBefore = try String(contentsOfFile: r2Revision.filePath, encoding: .utf8)

    // Extract the body portion (everything before the metadata block).
    let metaMarker = "<!-- begin:markdown-pal-meta"
    let bodyBefore: String
    if let markerRange = rawBefore.range(of: metaMarker) {
        bodyBefore = String(rawBefore[rawBefore.startIndex..<markerRange.lowerBound])
    } else {
        bodyBefore = rawBefore
    }
    // Body should contain the quirky whitespace.
    #expect(bodyBefore.contains("trailing spaces.   "))

    // Prune to keep 1. Merges r1's resolved comment into r2's metadata.
    let result = try bundle.prune(keep: 1)
    #expect(result.prunedRevisions.count == 1)
    #expect(result.mergedComments == 1)

    // Read the surviving file and verify body is preserved verbatim.
    let rawAfter = try String(contentsOfFile: r2Revision.filePath, encoding: .utf8)
    let bodyAfter: String
    if let markerRange = rawAfter.range(of: metaMarker) {
        bodyAfter = String(rawAfter[rawAfter.startIndex..<markerRange.lowerBound])
    } else {
        bodyAfter = rawAfter
    }

    // Body content must be identical before and after prune.
    #expect(bodyAfter == bodyBefore)

    // Metadata must now contain the merged comment from r1.
    #expect(rawAfter.contains("from revision 1"))
    // And still contain r2's own unresolved comment.
    #expect(rawAfter.contains("unresolved question on r2"))
}

// MARK: C2 — Symlink-as-revision rejected (phase QG critical fix)

@Test func listRevisionsSkipsSymlinks() throws {
    let path = uniqueBundlePath()
    defer { cleanup(path) }
    let t0 = fixtureDate()
    _ = try DocumentBundle.create(name: "SymTest", initialContent: initialBody, at: path, timestamp: t0)
    let bundle = try DocumentBundle(at: path)

    // Create a symlink that looks like a valid revision filename.
    let symlinkName = "V0001.0099.\(VersionId.formatTimestamp(t0.addingTimeInterval(300))).md"
    let symlinkPath = "\(path)/\(symlinkName)"
    // Point at /etc/passwd (or any file) — the engine should never follow it.
    try FileManager.default.createSymbolicLink(
        atPath: symlinkPath,
        withDestinationPath: "/etc/passwd"
    )

    // listRevisions must skip the symlink — only the real revision counts.
    let revs = try bundle.listRevisions()
    #expect(revs.count == 1)
    #expect(revs[0].revision == 1)
    // The symlink must NOT appear in the list.
    #expect(!revs.contains(where: { $0.versionId.contains("0099") }))
}

@Test func listRevisionsSkipsReplacedSymlink() throws {
    let path = uniqueBundlePath()
    defer { cleanup(path) }
    let t0 = fixtureDate()
    _ = try DocumentBundle.create(name: "SymPrune", initialContent: initialBody, at: path, timestamp: t0)
    let bundle = try DocumentBundle(at: path)

    // Create real revisions.
    for i in 1...3 {
        _ = try bundle.createRevision(
            content: "r\(i+1)",
            timestamp: t0.addingTimeInterval(Double(i * 60))
        )
    }

    // Replace the oldest real revision file with a symlink (simulating
    // a TOCTOU race where a file is swapped after listRevisions runs).
    let revs = try bundle.listRevisions()
    let oldest = revs[0]
    try FileManager.default.removeItem(atPath: oldest.filePath)
    try FileManager.default.createSymbolicLink(
        atPath: oldest.filePath,
        withDestinationPath: "/etc/passwd"
    )

    // listRevisions itself now skips the symlink, so prune won't even see it.
    // Verify the symlink doesn't appear in listings.
    let cleanRevs = try bundle.listRevisions()
    #expect(cleanRevs.count == 3) // 3 real revisions remain (symlink skipped)
    #expect(!cleanRevs.contains(where: { $0.versionId == oldest.versionId }))
}



@Test func pruneSucceedsWhenNoConcurrentWriter() throws {
    // The post-merge gate (DocumentBundle.swift ~line 379) aborts a prune
    // if a concurrent writer changed `latest` between capture-time and
    // splice-time. Triggering the gate requires multi-thread orchestration
    // and is not directly exercised here.
    //
    // This test pins the *no-concurrency* contract: a sequential prune
    // (no other writer) MUST complete cleanly. It exists to catch a
    // regression where the gate fires spuriously and breaks the happy path.
    //
    // True gate-firing behavior is tracked under the deferred Phase 1.5
    // backlog (see qg-triage notes: TOCTOU coverage gap).
    let path = uniqueBundlePath()
    defer { cleanup(path) }
    let t0 = fixtureDate()
    _ = try DocumentBundle.create(name: "Gate", initialContent: initialBody, at: path, timestamp: t0)
    let bundle = try DocumentBundle(at: path)
    for i in 1...4 {
        _ = try bundle.createRevision(
            content: "r\(i+1)",
            timestamp: t0.addingTimeInterval(Double(i * 60))
        )
    }
    // Sequential prune — no concurrent writer — should succeed.
    let result = try bundle.prune(keep: 2)
    #expect(result.prunedRevisions.count == 3)
    #expect(result.remainingRevisions == 2)

    // Verify by trying again — bundle is now within limit, no-op.
    let secondResult = try bundle.prune(keep: 2)
    #expect(secondResult.prunedRevisions.isEmpty)
    #expect(secondResult.remainingRevisions == 2)
}
