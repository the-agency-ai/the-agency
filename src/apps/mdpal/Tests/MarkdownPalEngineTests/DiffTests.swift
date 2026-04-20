// What Problem: The Diff API powers `mdpal diff <rev1> <rev2> <bundle>`
// (CLI command, iteration 2.4) and any future app-side diff view. We
// need to verify that Document.diff(against:) and DocumentBundle.diff
// classify added/removed/modified/unchanged correctly, preserve target
// document order, and surface bundleConflict for unknown revisions.
//
// How & Why: Swift Testing tests against the engine API directly. Inline
// fixtures keep each test self-contained; bundle tests use a temp
// directory. Each test focuses on one behavior so failures point at a
// specific contract.
//
// Reference: usr/jordan/mdpal/dispatches/dispatch-cli-json-output-shapes-20260406.md
//
// Written: 2026-04-17 during mdpal-cli session (Phase 2 iteration 2.4)

import Testing
import Foundation
@testable import MarkdownPalEngine

// MARK: - Helpers

private func makeDoc(_ content: String) throws -> Document {
    try Document(content: content, parser: MarkdownParser())
}

private let baseDoc = """
# Introduction

Intro body.

# Architecture

Old architecture body.

# Testing

Testing body.
"""

private let targetDoc = """
# Introduction

Intro body.

# Architecture

New architecture body, with substantially more content than before.

# Deployment

A brand new section.
"""

// MARK: - Document.diff

@Test func diffClassifiesAddedRemovedModifiedUnchanged() throws {
    let base = try makeDoc(baseDoc)
    let target = try makeDoc(targetDoc)

    let diffs = try target.diff(against: base)

    // Map slug -> type for assertions independent of order.
    let typeBySlug = Dictionary(uniqueKeysWithValues: diffs.map { ($0.slug, $0.type) })

    #expect(typeBySlug["introduction"] == .unchanged)
    #expect(typeBySlug["architecture"] == .modified)
    #expect(typeBySlug["deployment"] == .added)
    #expect(typeBySlug["testing"] == .removed)
    #expect(diffs.count == 4)
}

@Test func diffPreservesTargetDocumentOrderThenAppendsRemoved() throws {
    let base = try makeDoc(baseDoc)
    let target = try makeDoc(targetDoc)

    let diffs = try target.diff(against: base)

    // Target document order: introduction, architecture, deployment.
    // Then removed slugs from base order: testing.
    #expect(diffs.map { $0.slug } == [
        "introduction",
        "architecture",
        "deployment",
        "testing",
    ])
}

@Test func diffOfIdenticalDocumentsIsAllUnchanged() throws {
    let a = try makeDoc(baseDoc)
    let b = try makeDoc(baseDoc)

    let diffs = try a.diff(against: b)
    #expect(diffs.allSatisfy { $0.type == .unchanged })
    #expect(diffs.count == 3)
    // Unchanged sections carry an empty summary by convention.
    #expect(diffs.allSatisfy { $0.summary.isEmpty })
}

@Test func diffOfEmptyAgainstEmptyIsEmpty() throws {
    let a = try makeDoc("")
    let b = try makeDoc("")
    let diffs = try a.diff(against: b)
    #expect(diffs.isEmpty)
}

@Test func diffAllAdded() throws {
    let base = try makeDoc("")
    let target = try makeDoc(targetDoc)
    let diffs = try target.diff(against: base)
    #expect(diffs.allSatisfy { $0.type == .added })
    #expect(diffs.map { $0.slug } == ["introduction", "architecture", "deployment"])
}

@Test func diffAllRemoved() throws {
    let base = try makeDoc(baseDoc)
    let target = try makeDoc("")
    let diffs = try target.diff(against: base)
    #expect(diffs.allSatisfy { $0.type == .removed })
    #expect(diffs.map { $0.slug } == ["introduction", "architecture", "testing"])
}

@Test func diffSummaryForAddedSection() throws {
    let base = try makeDoc(baseDoc)
    let target = try makeDoc(targetDoc)
    let diffs = try target.diff(against: base)
    let added = try #require(diffs.first(where: { $0.slug == "deployment" }))
    #expect(added.type == .added)
    #expect(added.summary == "New section")
}

@Test func diffSummaryForRemovedSection() throws {
    let base = try makeDoc(baseDoc)
    let target = try makeDoc(targetDoc)
    let diffs = try target.diff(against: base)
    let removed = try #require(diffs.first(where: { $0.slug == "testing" }))
    #expect(removed.type == .removed)
    #expect(removed.summary == "Section deleted")
}

@Test func diffSummaryForModifiedSectionIsHumanReadable() throws {
    let base = try makeDoc(baseDoc)
    let target = try makeDoc(targetDoc)
    let diffs = try target.diff(against: base)
    let modified = try #require(diffs.first(where: { $0.slug == "architecture" }))
    #expect(modified.type == .modified)
    // The summary format is human-readable; we only check it carries the
    // "Content changed" prefix and mentions chars added/removed. The
    // dispatched spec calls this field "not for programmatic use".
    #expect(modified.summary.contains("Content changed"))
    #expect(modified.summary.contains("chars added"))
    #expect(modified.summary.contains("chars removed"))
}

@Test func diffIsAsymmetric_addedReversesToRemoved() throws {
    let base = try makeDoc(baseDoc)
    let target = try makeDoc(targetDoc)

    let forward = try Dictionary(uniqueKeysWithValues:
        target.diff(against: base).map { ($0.slug, $0.type) })
    let reverse = try Dictionary(uniqueKeysWithValues:
        base.diff(against: target).map { ($0.slug, $0.type) })

    // What's added in forward should be removed in reverse and vice versa.
    #expect(forward["deployment"] == .added)
    #expect(reverse["deployment"] == .removed)
    #expect(forward["testing"] == .removed)
    #expect(reverse["testing"] == .added)
    // Modified is symmetric.
    #expect(forward["architecture"] == .modified)
    #expect(reverse["architecture"] == .modified)
}

// QG coverage T1: the modified summary's chars-added/chars-removed math
// is approximate (length delta, not LCS) but must at minimum get the
// direction right. A new>old section reports added>0 removed=0; an
// old>new section reports added=0 removed>0. Pre-fix the test only
// substring-matched ("chars added"), so a swap of new and old would
// have shipped silently.
@Test func diffSummaryReportsAddedCharsForLongerNew() throws {
    let base = try makeDoc("""
    # X

    short.
    """)
    let target = try makeDoc("""
    # X

    short, but with a substantially longer body now.
    """)
    let diffs = try target.diff(against: base)
    let modified = try #require(diffs.first(where: { $0.slug == "x" }))
    #expect(modified.type == .modified)
    // New body is longer → `chars added` count must be > 0.
    #expect(modified.summary.contains("chars added"))
    #expect(!modified.summary.contains("0 chars added"))
    // No characters removed (target body strictly grew).
    #expect(modified.summary.contains("0 chars removed"))
}

@Test func diffSummaryReportsRemovedCharsForShorterNew() throws {
    let base = try makeDoc("""
    # X

    long body that will be cut down to almost nothing.
    """)
    let target = try makeDoc("""
    # X

    short.
    """)
    let diffs = try target.diff(against: base)
    let modified = try #require(diffs.first(where: { $0.slug == "x" }))
    #expect(modified.type == .modified)
    #expect(modified.summary.contains("0 chars added"))
    #expect(!modified.summary.contains("0 chars removed"))
}

@Test func diffNestedSectionsUsePathStyleSlugs() throws {
    let base = try makeDoc("""
    # Architecture

    Top level.

    ## Components

    Component body.
    """)
    let target = try makeDoc("""
    # Architecture

    Top level.

    ## Components

    Component body, modified.

    ## Deployment

    New nested section.
    """)
    let diffs = try target.diff(against: base)
    let typeBySlug = Dictionary(uniqueKeysWithValues: diffs.map { ($0.slug, $0.type) })
    #expect(typeBySlug["architecture"] == .unchanged)
    #expect(typeBySlug["architecture/components"] == .modified)
    #expect(typeBySlug["architecture/deployment"] == .added)
}

// QG coverage D8a: non-ASCII headings (Chinese, Café, emoji) round-trip
// through the diff API without crashing the slug computation or the
// summary's character-count math.
@Test func diffHandlesNonAsciiHeadings() throws {
    let base = try makeDoc("""
    # 中文

    Body.

    # Café

    More body.
    """)
    let target = try makeDoc("""
    # 中文

    Body, modified.

    # Café

    More body.

    # 🚀 Launch

    Brand new section.
    """)
    let diffs = try target.diff(against: base)
    let typeBySlug = Dictionary(uniqueKeysWithValues: diffs.map { ($0.slug, $0.type) })
    // Slugs must not be empty even for non-ASCII headings (engine slug
    // policy may emit transliterated or escaped form; the contract is that
    // SOME non-empty slug exists).
    let slugs = diffs.map { $0.slug }
    #expect(slugs.allSatisfy { !$0.isEmpty })
    // At least one section should be classified as added (the rocket one).
    #expect(typeBySlug.values.contains(.added), "expected at least one added; got \(typeBySlug)")
}

// MARK: - DocumentBundle.diff

private func makeBundleWithRevisions(
    name: String,
    initialContent: String,
    additionalContents: [String]
) throws -> (bundle: DocumentBundle, tempDir: URL, revisionIds: [String]) {
    let tempDir = FileManager.default.temporaryDirectory
        .appendingPathComponent("mdpal-diff-test-\(UUID().uuidString)")
    let bundlePath = tempDir.appendingPathComponent("\(name).mdpal").path
    try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

    var revisionIds: [String] = []
    let baseTimestamp = Date(timeIntervalSince1970: 1_775_000_000)
    let firstBundle = try DocumentBundle.create(
        name: name,
        initialContent: initialContent,
        at: bundlePath,
        timestamp: baseTimestamp
    )
    let latestOpt = try firstBundle.latestRevision()
    let firstRev = try #require(latestOpt)
    revisionIds.append(firstRev.versionId)

    for (i, content) in additionalContents.enumerated() {
        // Bump timestamp by minutes so versionIds are distinct.
        let ts = baseTimestamp.addingTimeInterval(TimeInterval((i + 1) * 60))
        let next = try firstBundle.createRevision(content: content, timestamp: ts)
        revisionIds.append(next.versionId)
    }
    return (firstBundle, tempDir, revisionIds)
}

@Test func bundleDiffComparesNamedRevisions() throws {
    let setup = try makeBundleWithRevisions(
        name: "diff-bundle",
        initialContent: baseDoc,
        additionalContents: [targetDoc]
    )
    defer {
        try? FileManager.default.removeItem(at: setup.tempDir)
    }

    let baseId = setup.revisionIds[0]
    let targetId = setup.revisionIds[1]
    let diffs = try setup.bundle.diff(baseRevision: baseId, targetRevision: targetId)

    let typeBySlug = Dictionary(uniqueKeysWithValues: diffs.map { ($0.slug, $0.type) })
    #expect(typeBySlug["introduction"] == .unchanged)
    #expect(typeBySlug["architecture"] == .modified)
    #expect(typeBySlug["deployment"] == .added)
    #expect(typeBySlug["testing"] == .removed)
}

@Test func bundleDiffThrowsBundleConflictForUnknownBaseRevision() throws {
    let setup = try makeBundleWithRevisions(
        name: "diff-unknown-base",
        initialContent: baseDoc,
        additionalContents: [targetDoc]
    )
    defer {
        try? FileManager.default.removeItem(at: setup.tempDir)
    }

    #expect(throws: EngineError.self) {
        _ = try setup.bundle.diff(
            baseRevision: "V0099.0099.20260101T0000Z",
            targetRevision: setup.revisionIds[1]
        )
    }
}

@Test func bundleDiffThrowsBundleConflictForUnknownTargetRevision() throws {
    let setup = try makeBundleWithRevisions(
        name: "diff-unknown-target",
        initialContent: baseDoc,
        additionalContents: [targetDoc]
    )
    defer {
        try? FileManager.default.removeItem(at: setup.tempDir)
    }

    #expect(throws: EngineError.self) {
        _ = try setup.bundle.diff(
            baseRevision: setup.revisionIds[0],
            targetRevision: "V0099.0099.20260101T0000Z"
        )
    }
}

@Test func bundleDiffSameRevisionIsAllUnchanged() throws {
    let setup = try makeBundleWithRevisions(
        name: "diff-self",
        initialContent: baseDoc,
        additionalContents: []
    )
    defer {
        try? FileManager.default.removeItem(at: setup.tempDir)
    }

    let id = setup.revisionIds[0]
    let diffs = try setup.bundle.diff(baseRevision: id, targetRevision: id)
    #expect(diffs.allSatisfy { $0.type == .unchanged })
    #expect(diffs.count == 3)
}
