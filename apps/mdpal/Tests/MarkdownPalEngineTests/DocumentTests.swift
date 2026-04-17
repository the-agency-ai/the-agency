// What Problem: Iteration 1.2 introduces the Document class, DocumentMetadata,
// the Comment/Flag value types, and the Yams metadata serializer. Each piece
// needs unit and integration tests covering the happy path, round-trip
// fidelity, and the error paths the engine guarantees.
//
// How & Why: Swift Testing framework (matches ParserTests.swift). Tests
// exercise the public API directly — no mocks, no test doubles. Fixture
// documents are inline strings for determinism. Round-trip tests verify
// that serialize → decode → encode → parse → identical, which is the only
// way to catch silent metadata mutation.
//
// Written: 2026-04-07 during mdpal-cli session (iteration 1.2)

import Testing
import Foundation
@testable import MarkdownPalEngine

// MARK: - CommentType

@Test func commentTypeRawValues() {
    #expect(CommentType.question.rawValue == "question")
    #expect(CommentType.suggestion.rawValue == "suggestion")
    #expect(CommentType.note.rawValue == "note")
    #expect(CommentType.directive.rawValue == "directive")
    #expect(CommentType.decision.rawValue == "decision")
}

@Test func commentTypeFromRawValue() {
    #expect(CommentType(rawValue: "note") == .note)
    #expect(CommentType(rawValue: "unknown") == nil)
}

// MARK: - Priority

@Test func priorityCases() {
    #expect(Priority.allCases.count == 3)
    #expect(Priority.low.rawValue == "low")
    #expect(Priority.normal.rawValue == "normal")
    #expect(Priority.high.rawValue == "high")
}

// MARK: - Comment

@Test func commentDefaults() {
    let now = Date()
    let comment = Comment(
        id: "c001",
        type: .note,
        author: "jordan",
        sectionSlug: "intro",
        versionHash: "abc123",
        timestamp: now,
        context: "context text",
        text: "comment text"
    )
    #expect(comment.priority == .normal)
    #expect(comment.tags == [])
    #expect(comment.resolution == nil)
    #expect(comment.isResolved == false)
}

@Test func commentResolved() {
    let now = Date()
    let resolution = Resolution(response: "fixed", resolvedDate: now, resolvedBy: "jordan")
    let comment = Comment(
        id: "c001",
        type: .question,
        author: "claude",
        sectionSlug: "intro",
        versionHash: "abc123",
        timestamp: now,
        context: "ctx",
        text: "Is this right?",
        resolution: resolution
    )
    #expect(comment.isResolved == true)
    #expect(comment.resolution?.response == "fixed")
}

// MARK: - CommentFilter

@Test func commentFilterMatchesAll() {
    let filter = CommentFilter()
    let comment = Comment(
        id: "c001", type: .note, author: "jordan",
        sectionSlug: "intro", versionHash: "h",
        timestamp: Date(), context: "", text: "t"
    )
    #expect(filter.matches(comment))
}

@Test func commentFilterBySection() {
    let filter = CommentFilter(sectionSlug: "intro")
    let match = Comment(
        id: "c001", type: .note, author: "jordan",
        sectionSlug: "intro", versionHash: "h",
        timestamp: Date(), context: "", text: "t"
    )
    let nonMatch = Comment(
        id: "c002", type: .note, author: "jordan",
        sectionSlug: "other", versionHash: "h",
        timestamp: Date(), context: "", text: "t"
    )
    #expect(filter.matches(match))
    #expect(!filter.matches(nonMatch))
}

@Test func commentFilterByType() {
    let filter = CommentFilter(type: .question)
    let match = Comment(
        id: "c001", type: .question, author: "jordan",
        sectionSlug: "intro", versionHash: "h",
        timestamp: Date(), context: "", text: "t"
    )
    let nonMatch = Comment(
        id: "c002", type: .note, author: "jordan",
        sectionSlug: "intro", versionHash: "h",
        timestamp: Date(), context: "", text: "t"
    )
    #expect(filter.matches(match))
    #expect(!filter.matches(nonMatch))
}

@Test func commentFilterUnresolvedOnly() {
    let filter = CommentFilter(unresolvedOnly: true)
    let unresolved = Comment(
        id: "c001", type: .note, author: "jordan",
        sectionSlug: "intro", versionHash: "h",
        timestamp: Date(), context: "", text: "t"
    )
    let resolved = Comment(
        id: "c002", type: .note, author: "jordan",
        sectionSlug: "intro", versionHash: "h",
        timestamp: Date(), context: "", text: "t",
        resolution: Resolution(response: "ok", resolvedDate: Date(), resolvedBy: "jordan")
    )
    #expect(filter.matches(unresolved))
    #expect(!filter.matches(resolved))
}

@Test func commentFilterByAuthor() {
    let filter = CommentFilter(author: "jordan")
    let match = Comment(
        id: "c001", type: .note, author: "jordan",
        sectionSlug: "intro", versionHash: "h",
        timestamp: Date(), context: "", text: "t"
    )
    let nonMatch = Comment(
        id: "c002", type: .note, author: "claude",
        sectionSlug: "intro", versionHash: "h",
        timestamp: Date(), context: "", text: "t"
    )
    #expect(filter.matches(match))
    #expect(!filter.matches(nonMatch))
}

@Test func commentFilterCombinedANDFilters() {
    let filter = CommentFilter(
        sectionSlug: "intro",
        type: .question,
        author: "claude",
        unresolvedOnly: true
    )
    let match = Comment(
        id: "c001", type: .question, author: "claude",
        sectionSlug: "intro", versionHash: "h",
        timestamp: Date(), context: "", text: "t"
    )
    let wrongSection = Comment(
        id: "c002", type: .question, author: "claude",
        sectionSlug: "other", versionHash: "h",
        timestamp: Date(), context: "", text: "t"
    )
    let wrongType = Comment(
        id: "c003", type: .note, author: "claude",
        sectionSlug: "intro", versionHash: "h",
        timestamp: Date(), context: "", text: "t"
    )
    let wrongAuthor = Comment(
        id: "c004", type: .question, author: "jordan",
        sectionSlug: "intro", versionHash: "h",
        timestamp: Date(), context: "", text: "t"
    )
    let resolved = Comment(
        id: "c005", type: .question, author: "claude",
        sectionSlug: "intro", versionHash: "h",
        timestamp: Date(), context: "", text: "t",
        resolution: Resolution(response: "ok", resolvedDate: Date(), resolvedBy: "j")
    )
    #expect(filter.matches(match))
    #expect(!filter.matches(wrongSection))
    #expect(!filter.matches(wrongType))
    #expect(!filter.matches(wrongAuthor))
    #expect(!filter.matches(resolved))
}

@Test func commentFilterResolvedOnly() {
    let filter = CommentFilter(resolvedOnly: true)
    let unresolved = Comment(
        id: "c001", type: .note, author: "jordan",
        sectionSlug: "intro", versionHash: "h",
        timestamp: Date(), context: "", text: "t"
    )
    let resolved = Comment(
        id: "c002", type: .note, author: "jordan",
        sectionSlug: "intro", versionHash: "h",
        timestamp: Date(), context: "", text: "t",
        resolution: Resolution(response: "ok", resolvedDate: Date(), resolvedBy: "jordan")
    )
    #expect(!filter.matches(unresolved))
    #expect(filter.matches(resolved))
}

// MARK: - Flag

@Test func flagOptionalNote() {
    let now = Date()
    let f1 = Flag(sectionSlug: "intro", note: "discuss", author: "jordan", timestamp: now)
    let f2 = Flag(sectionSlug: "intro", author: "jordan", timestamp: now)
    #expect(f1.note == "discuss")
    #expect(f2.note == nil)
}

// MARK: - DocumentInfo

@Test func documentInfoBlank() {
    let info = DocumentInfo.blank()
    #expect(info.version == 1)
    #expect(info.revision == 1)
    #expect(info.versionId.hasPrefix("V0001.0001."))
    #expect(info.versionId.hasSuffix("Z"))
    #expect(info.authors == [])
}

// Regression: DocumentInfo.blank() must produce a versionId that round-trips
// through VersionId.parse on every system, regardless of the user's default
// locale or calendar (e.g., Thai Buddhist `th_TH`, Japanese Imperial). Without
// the POSIX/Gregorian pin in formatVersionTimestamp, the formatted year would
// not match the wire format on those systems.
@Test func documentInfoBlankVersionIdRoundTrips() throws {
    let info = DocumentInfo.blank()
    let parsed = try #require(VersionId.parse(info.versionId))
    #expect(parsed.version == 1)
    #expect(parsed.revision == 1)
    // The formatted timestamp must use 4-digit Gregorian year (e.g., 2026, not
    // 2569 Buddhist or 8 Reiwa). The first 4 chars after "V0001.0001." are the
    // year — assert they parse as a Gregorian year in a sane range.
    let prefix = "V0001.0001."
    let yearStart = info.versionId.index(info.versionId.startIndex, offsetBy: prefix.count)
    let yearEnd = info.versionId.index(yearStart, offsetBy: 4)
    let yearString = String(info.versionId[yearStart..<yearEnd])
    let year = Int(yearString)
    #expect(year != nil)
    #expect((2020...2100).contains(year ?? 0), "year \(year ?? -1) outside Gregorian range — locale/calendar leak?")
}

// MARK: - DocumentMetadata

@Test func documentMetadataBlank() {
    let metadata = DocumentMetadata.blank()
    #expect(metadata.unresolvedComments.isEmpty)
    #expect(metadata.resolvedComments.isEmpty)
    #expect(metadata.flags.isEmpty)
    #expect(metadata.allComments.isEmpty)
}

@Test func documentMetadataAllComments() {
    let now = Date()
    let unresolved = Comment(
        id: "c001", type: .question, author: "claude",
        sectionSlug: "intro", versionHash: "h1",
        timestamp: now, context: "", text: "?"
    )
    let resolved = Comment(
        id: "c002", type: .suggestion, author: "claude",
        sectionSlug: "intro", versionHash: "h1",
        timestamp: now, context: "", text: "do this",
        resolution: Resolution(response: "ok", resolvedDate: now, resolvedBy: "jordan")
    )
    let metadata = DocumentMetadata(
        document: .blank(),
        unresolvedComments: [unresolved],
        resolvedComments: [resolved]
    )
    #expect(metadata.allComments.count == 2)
}

// MARK: - MetadataSerializer round-trip

@Test func metadataSerializerEncodeBlank() throws {
    let metadata = DocumentMetadata.blank()
    let yaml = try MetadataSerializer.encode(metadata)
    #expect(yaml.contains("document:"))
    #expect(yaml.contains("version_id:"))
    // No comments → no `unresolved` or `resolved` keys.
    #expect(!yaml.contains("unresolved:"))
    #expect(!yaml.contains("resolved:"))
}

@Test func metadataSerializerRoundTripBlank() throws {
    let metadata = DocumentMetadata.blank()
    let yaml = try MetadataSerializer.encode(metadata)
    let decoded = try MetadataSerializer.decode(yaml)
    #expect(decoded.document.version == metadata.document.version)
    #expect(decoded.document.revision == metadata.document.revision)
    #expect(decoded.document.versionId == metadata.document.versionId)
    #expect(decoded.unresolvedComments.isEmpty)
    #expect(decoded.resolvedComments.isEmpty)
    #expect(decoded.flags.isEmpty)
}

@Test func metadataSerializerRoundTripFull() throws {
    // Use whole-second timestamps so ISO8601 round-trip is exact.
    // 1_775_390_400 = 2026-04-07T12:00:00Z
    let now = Date(timeIntervalSince1970: 1_775_390_400)
    let info = DocumentInfo(
        versionId: "V0001.0003.20260407T1200Z",
        version: 1,
        revision: 3,
        timestamp: now,
        created: now,
        authors: ["jordan", "claude"]
    )
    let unresolved = Comment(
        id: "c001",
        type: .question,
        author: "claude",
        sectionSlug: "authentication",
        versionHash: "a3f2b1",
        timestamp: now,
        context: "OAuth context",
        text: "Does this handle token refresh?",
        priority: .high,
        tags: ["security", "auth"]
    )
    let resolved = Comment(
        id: "c002",
        type: .suggestion,
        author: "jordan",
        sectionSlug: "architecture",
        versionHash: "f1a2b3",
        timestamp: now,
        context: "metadata sidecar context",
        text: "Should we use sidecar files?",
        resolution: Resolution(response: "No, single file.", resolvedDate: now, resolvedBy: "jordan")
    )
    let flag = Flag(
        sectionSlug: "deployment",
        note: "Discuss CI",
        author: "claude",
        timestamp: now
    )
    let metadata = DocumentMetadata(
        document: info,
        unresolvedComments: [unresolved],
        resolvedComments: [resolved],
        flags: [flag]
    )

    let yaml = try MetadataSerializer.encode(metadata)
    let decoded = try MetadataSerializer.decode(yaml)

    #expect(decoded.document.versionId == info.versionId)
    #expect(decoded.document.version == 1)
    #expect(decoded.document.revision == 3)
    #expect(decoded.document.authors == ["jordan", "claude"])
    #expect(decoded.document.timestamp == now)
    #expect(decoded.document.created == now)

    #expect(decoded.unresolvedComments.count == 1)
    let u = decoded.unresolvedComments[0]
    #expect(u.id == "c001")
    #expect(u.type == .question)
    #expect(u.author == "claude")
    #expect(u.sectionSlug == "authentication")
    #expect(u.versionHash == "a3f2b1")
    #expect(u.timestamp == now)
    #expect(u.priority == .high)
    #expect(u.tags == ["security", "auth"])
    #expect(u.text == "Does this handle token refresh?")
    #expect(u.context == "OAuth context")
    #expect(u.isResolved == false)

    #expect(decoded.resolvedComments.count == 1)
    let r = decoded.resolvedComments[0]
    #expect(r.id == "c002")
    #expect(r.author == "jordan")
    #expect(r.sectionSlug == "architecture")
    #expect(r.versionHash == "f1a2b3")
    #expect(r.timestamp == now)
    #expect(r.priority == .normal)
    #expect(r.tags == [])
    #expect(r.isResolved == true)
    #expect(r.resolution?.response == "No, single file.")
    #expect(r.resolution?.resolvedDate == now)
    #expect(r.resolution?.resolvedBy == "jordan")

    #expect(decoded.flags.count == 1)
    #expect(decoded.flags[0].sectionSlug == "deployment")
    #expect(decoded.flags[0].note == "Discuss CI")
    #expect(decoded.flags[0].author == "claude")
    #expect(decoded.flags[0].timestamp == now)
}

@Test func metadataSerializerDeterministicKeyOrder() throws {
    // Encoding the same metadata twice must produce identical YAML.
    // This is critical: the metadata block lives in version-controlled
    // markdown, and non-deterministic key order would create dirty diffs
    // on every save.
    let metadata = DocumentMetadata.blank()
    let yaml1 = try MetadataSerializer.encode(metadata)
    let yaml2 = try MetadataSerializer.encode(metadata)
    #expect(yaml1 == yaml2)
}

@Test func metadataSerializerKeyOrderWithFullData() throws {
    let now = Date(timeIntervalSince1970: 1_775_390_400)
    let metadata = DocumentMetadata(
        document: DocumentInfo(
            versionId: "V0001.0001.20260407T1200Z",
            version: 1,
            revision: 1,
            timestamp: now,
            created: now,
            authors: ["jordan"]
        ),
        unresolvedComments: [
            Comment(id: "c001", type: .note, author: "claude",
                    sectionSlug: "intro", versionHash: "h1",
                    timestamp: now, context: "ctx", text: "txt")
        ],
        flags: [Flag(sectionSlug: "intro", author: "claude", timestamp: now)]
    )
    // Encode 5 times — must always be identical.
    let outputs = (0..<5).map { _ in try? MetadataSerializer.encode(metadata) }
    let first = outputs[0]
    for output in outputs.dropFirst() {
        #expect(output == first)
    }
    // And the top-level key order is document → flags → unresolved.
    let yaml = first ?? ""
    let docIdx = yaml.range(of: "document:")?.lowerBound
    let flagsIdx = yaml.range(of: "flags:")?.lowerBound
    let unresolvedIdx = yaml.range(of: "unresolved:")?.lowerBound
    #expect(docIdx != nil)
    #expect(flagsIdx != nil)
    #expect(unresolvedIdx != nil)
    if let d = docIdx, let f = flagsIdx, let u = unresolvedIdx {
        #expect(d < f)
        #expect(f < u)
    }
}

// MARK: - Resolved/unresolved list-membership semantics

@Test func metadataSerializerUnresolvedListIgnoresStrayResponseField() throws {
    // A comment in the `unresolved` list with a stray `response` field
    // should be loaded as unresolved (list membership wins, not field
    // presence). This prevents accidental promotion to resolved.
    let yaml = """
    document:
      version_id: V0001.0001.20260407T1200Z
      version: 1
      revision: 1
      timestamp: 2026-04-07T12:00:00Z
      created: 2026-04-07T12:00:00Z
      authors: []
    unresolved:
      - id: c001
        type: note
        author: claude
        section: intro
        version_hash: abc
        timestamp: 2026-04-07T12:00:00Z
        text: hello
        response: stray field
        resolved_by: someone
    """
    let metadata = try MetadataSerializer.decode(yaml)
    #expect(metadata.unresolvedComments.count == 1)
    #expect(metadata.unresolvedComments[0].isResolved == false)
    #expect(metadata.unresolvedComments[0].resolution == nil)
    #expect(metadata.resolvedComments.isEmpty)
}

@Test func metadataSerializerRejectsMissingVersion() {
    let yaml = """
    document:
      version_id: V0001.0001.20260407T1200Z
      revision: 1
      timestamp: 2026-04-07T12:00:00Z
      created: 2026-04-07T12:00:00Z
      authors: []
    """
    do {
        _ = try MetadataSerializer.decode(yaml)
        Issue.record("Expected throw")
    } catch let EngineError.metadataError(message) {
        #expect(message.contains("version"))
    } catch {
        Issue.record("Expected metadataError, got \(error)")
    }
}

@Test func metadataSerializerRejectsMissingRevision() {
    let yaml = """
    document:
      version_id: V0001.0001.20260407T1200Z
      version: 1
      timestamp: 2026-04-07T12:00:00Z
      created: 2026-04-07T12:00:00Z
      authors: []
    """
    do {
        _ = try MetadataSerializer.decode(yaml)
        Issue.record("Expected throw")
    } catch EngineError.metadataError {
        // expected
    } catch {
        Issue.record("Expected metadataError, got \(error)")
    }
}

@Test func metadataSerializerRejectsVersionAsString() {
    let yaml = """
    document:
      version_id: V0001.0001.20260407T1200Z
      version: "one"
      revision: 1
      timestamp: 2026-04-07T12:00:00Z
      created: 2026-04-07T12:00:00Z
      authors: []
    """
    do {
        _ = try MetadataSerializer.decode(yaml)
        Issue.record("Expected throw")
    } catch EngineError.metadataError {
        // expected
    } catch {
        Issue.record("Expected metadataError, got \(error)")
    }
}

@Test func metadataSerializerAcceptsStringifiedVersion() throws {
    // parseInt accepts stringified integers as a tolerance affordance.
    let yaml = """
    document:
      version_id: V0001.0001.20260407T1200Z
      version: "1"
      revision: "2"
      timestamp: 2026-04-07T12:00:00Z
      created: 2026-04-07T12:00:00Z
      authors: []
    """
    let metadata = try MetadataSerializer.decode(yaml)
    #expect(metadata.document.version == 1)
    #expect(metadata.document.revision == 2)
}

@Test func metadataSerializerRejectsCommentMissingId() {
    let yaml = """
    document:
      version_id: V0001.0001.20260407T1200Z
      version: 1
      revision: 1
      timestamp: 2026-04-07T12:00:00Z
      created: 2026-04-07T12:00:00Z
      authors: []
    unresolved:
      - type: note
        author: claude
        section: intro
        version_hash: abc
        timestamp: 2026-04-07T12:00:00Z
        text: hello
    """
    do {
        _ = try MetadataSerializer.decode(yaml)
        Issue.record("Expected throw")
    } catch let EngineError.metadataError(message) {
        #expect(message.contains("id"))
    } catch {
        Issue.record("Expected metadataError, got \(error)")
    }
}

@Test func metadataSerializerRejectsUnknownCommentType() {
    let yaml = """
    document:
      version_id: V0001.0001.20260407T1200Z
      version: 1
      revision: 1
      timestamp: 2026-04-07T12:00:00Z
      created: 2026-04-07T12:00:00Z
      authors: []
    unresolved:
      - id: c001
        type: rumor
        author: claude
        section: intro
        version_hash: abc
        timestamp: 2026-04-07T12:00:00Z
        text: hello
    """
    do {
        _ = try MetadataSerializer.decode(yaml)
        Issue.record("Expected throw")
    } catch let EngineError.metadataError(message) {
        #expect(message.contains("rumor"))
    } catch {
        Issue.record("Expected metadataError, got \(error)")
    }
}

@Test func metadataSerializerRejectsUnknownPriority() {
    let yaml = """
    document:
      version_id: V0001.0001.20260407T1200Z
      version: 1
      revision: 1
      timestamp: 2026-04-07T12:00:00Z
      created: 2026-04-07T12:00:00Z
      authors: []
    unresolved:
      - id: c001
        type: note
        author: claude
        section: intro
        version_hash: abc
        timestamp: 2026-04-07T12:00:00Z
        text: hello
        priority: critical
    """
    do {
        _ = try MetadataSerializer.decode(yaml)
        Issue.record("Expected throw")
    } catch let EngineError.metadataError(message) {
        #expect(message.contains("critical"))
    } catch {
        Issue.record("Expected metadataError, got \(error)")
    }
}

@Test func metadataSerializerRejectsResolvedWithoutResponse() throws {
    let yaml = """
    document:
      version_id: V0001.0001.20260407T1200Z
      version: 1
      revision: 1
      timestamp: 2026-04-07T12:00:00Z
      created: 2026-04-07T12:00:00Z
      authors: []
    resolved:
      - id: c001
        type: note
        author: claude
        section: intro
        version_hash: abc
        timestamp: 2026-04-07T12:00:00Z
        text: hello
    """
    #expect(throws: EngineError.self) {
        _ = try MetadataSerializer.decode(yaml)
    }
}

// MARK: - Document — library mode

@Test func documentInitFromContentNoMetadata() throws {
    let content = """
    # Hello

    World.
    """
    let doc = try Document(content: content, parser: MarkdownParser())
    #expect(doc.sections.root.children.count == 1)
    #expect(doc.sections.root.children[0].heading == "Hello")
    #expect(doc.metadata.unresolvedComments.isEmpty)
    #expect(doc.metadata.flags.isEmpty)
    #expect(doc.filePath == nil)
}

@Test func documentInitFromContentWithMetadata() throws {
    let content = """
    # Authentication

    OAuth flow goes here.

    <!-- begin:markdown-pal-meta
    ```yaml
    document:
      version_id: V0001.0001.20260407T1200Z
      version: 1
      revision: 1
      timestamp: 2026-04-07T12:00:00Z
      created: 2026-04-07T12:00:00Z
      authors: [jordan]
    flags:
      - section: authentication
        note: review OAuth
        author: jordan
        timestamp: 2026-04-07T12:00:00Z
    ```
    end:markdown-pal-meta -->
    """
    let doc = try Document(content: content, parser: MarkdownParser())
    #expect(doc.sections.root.children.count == 1)
    #expect(doc.sections.root.children[0].heading == "Authentication")
    #expect(doc.metadata.flags.count == 1)
    #expect(doc.metadata.flags[0].note == "review OAuth")
    #expect(doc.metadata.document.authors == ["jordan"])
}

@Test func documentSerializeRoundTrip() throws {
    let now = Date(timeIntervalSince1970: 1_775_390_400)
    let content = """
    # Section A

    Content A.

    # Section B

    Content B.
    """
    let doc = try Document(content: content, parser: MarkdownParser())
    // Add comments AND a flag so the metadata block exercises all paths.
    doc.metadata.unresolvedComments.append(Comment(
        id: "c001",
        type: .question,
        author: "claude",
        sectionSlug: "section-a",
        versionHash: "abc123",
        timestamp: now,
        context: "Content A.",
        text: "Is this right?",
        priority: .high,
        tags: ["review"]
    ))
    doc.metadata.resolvedComments.append(Comment(
        id: "c002",
        type: .suggestion,
        author: "jordan",
        sectionSlug: "section-b",
        versionHash: "def456",
        timestamp: now,
        context: "Content B.",
        text: "rename it",
        resolution: Resolution(response: "done", resolvedDate: now, resolvedBy: "jordan")
    ))
    doc.metadata.flags.append(Flag(
        sectionSlug: "section-a",
        note: "discuss",
        author: "claude",
        timestamp: now
    ))

    let serialized = try doc.serialize()
    #expect(serialized.contains("# Section A"))
    #expect(serialized.contains("# Section B"))
    #expect(serialized.contains("<!-- begin:markdown-pal-meta"))
    #expect(serialized.contains("Is this right?"))
    #expect(serialized.contains("rename it"))

    // Re-parse the serialized output.
    let doc2 = try Document(content: serialized, parser: MarkdownParser())
    #expect(doc2.sections.root.children.count == 2)

    // Unresolved comment survives intact.
    #expect(doc2.metadata.unresolvedComments.count == 1)
    let u = doc2.metadata.unresolvedComments[0]
    #expect(u.id == "c001")
    #expect(u.type == .question)
    #expect(u.author == "claude")
    #expect(u.sectionSlug == "section-a")
    #expect(u.versionHash == "abc123")
    #expect(u.timestamp == now)
    #expect(u.context == "Content A.")
    #expect(u.text == "Is this right?")
    #expect(u.priority == .high)
    #expect(u.tags == ["review"])
    #expect(u.isResolved == false)

    // Resolved comment survives intact.
    #expect(doc2.metadata.resolvedComments.count == 1)
    let r = doc2.metadata.resolvedComments[0]
    #expect(r.id == "c002")
    #expect(r.type == .suggestion)
    #expect(r.isResolved == true)
    #expect(r.resolution?.response == "done")
    #expect(r.resolution?.resolvedBy == "jordan")
    #expect(r.resolution?.resolvedDate == now)

    // Flag survives.
    #expect(doc2.metadata.flags.count == 1)
    #expect(doc2.metadata.flags[0].sectionSlug == "section-a")
    #expect(doc2.metadata.flags[0].note == "discuss")
}

@Test func documentSerializeIdempotent() throws {
    // Two consecutive serialize() calls on the same Document must produce
    // byte-identical output. This validates the deterministic key ordering
    // end-to-end through the Document API.
    let now = Date(timeIntervalSince1970: 1_775_390_400)
    let doc = try Document(content: "# A\n\nbody.\n", parser: MarkdownParser())
    doc.metadata.unresolvedComments.append(Comment(
        id: "c001", type: .note, author: "claude",
        sectionSlug: "a", versionHash: "h1",
        timestamp: now, context: "body.", text: "n"
    ))
    let s1 = try doc.serialize()
    let s2 = try doc.serialize()
    #expect(s1 == s2)
}

@Test func documentSaveToExplicitPath() throws {
    let path = NSTemporaryDirectory() + "mdpal-test-\(UUID().uuidString).md"
    defer { try? FileManager.default.removeItem(atPath: path) }
    let doc = try Document(content: "# Hi\n\nbody\n", parser: MarkdownParser())
    try doc.save(to: path)
    let written = try String(contentsOfFile: path, encoding: .utf8)
    #expect(written.contains("# Hi"))
    #expect(written.contains("<!-- begin:markdown-pal-meta"))
}

// MARK: - Document — CLI mode (file I/O)

@Test func documentContentsOfFileReadAndSave() throws {
    let path = NSTemporaryDirectory() + "mdpal-test-\(UUID().uuidString).md"
    let content = """
    # Heading

    Body content.
    """
    try content.write(toFile: path, atomically: true, encoding: .utf8)
    defer { try? FileManager.default.removeItem(atPath: path) }

    let doc = try Document(contentsOfFile: path)
    #expect(doc.filePath == path)
    #expect(doc.sections.root.children.count == 1)
    #expect(doc.sections.root.children[0].heading == "Heading")

    // Add a flag and save back.
    doc.metadata.flags.append(Flag(
        sectionSlug: "heading",
        note: "test",
        author: "tester",
        timestamp: Date(timeIntervalSince1970: 1_712_491_200)
    ))
    try doc.save()

    let reloaded = try Document(contentsOfFile: path)
    #expect(reloaded.metadata.flags.count == 1)
    #expect(reloaded.metadata.flags[0].note == "test")
}

// MARK: - ParserRegistry

@Test func parserRegistrySharedHasMarkdown() {
    let parser = ParserRegistry.shared.parser(for: ".md")
    #expect(parser != nil)
}

@Test func parserRegistryNormalizesExtension() {
    let withDot = ParserRegistry.shared.parser(for: ".md")
    let noDot = ParserRegistry.shared.parser(for: "md")
    let upper = ParserRegistry.shared.parser(for: ".MD")
    #expect(withDot != nil)
    #expect(noDot != nil)
    #expect(upper != nil)
}

@Test func parserRegistryReturnsNilForUnknown() {
    let parser = ParserRegistry.shared.parser(for: ".xyz")
    #expect(parser == nil)
}

@Test func parserRegistryRegisteredExtensions() {
    let exts = ParserRegistry.shared.registeredExtensions
    #expect(exts.contains(".md"))
    #expect(exts.contains(".markdown"))
}

// MARK: - EngineError specific-case throws (driven by production code)

@Test func documentContentsOfFileThrowsFileError() throws {
    let path = "/tmp/definitely-does-not-exist-\(UUID().uuidString).md"
    do {
        _ = try Document(contentsOfFile: path)
        Issue.record("Expected throw")
    } catch let EngineError.fileError(throwPath, _) {
        #expect(throwPath == path)
    } catch {
        Issue.record("Expected EngineError.fileError, got \(error)")
    }
}

@Test func documentContentsOfFileThrowsUnsupportedFormat() throws {
    let path = NSTemporaryDirectory() + "mdpal-test-\(UUID().uuidString).xyz"
    try "# Hello".write(toFile: path, atomically: true, encoding: .utf8)
    defer { try? FileManager.default.removeItem(atPath: path) }
    do {
        _ = try Document(contentsOfFile: path)
        Issue.record("Expected throw")
    } catch let EngineError.unsupportedFormat(ext) {
        #expect(ext == ".xyz")
    } catch {
        Issue.record("Expected EngineError.unsupportedFormat, got \(error)")
    }
}

@Test func documentContentsOfFileExtensionlessThrowsUnsupportedFormat() throws {
    let path = NSTemporaryDirectory() + "mdpal-test-\(UUID().uuidString)-noext"
    try "# Hello".write(toFile: path, atomically: true, encoding: .utf8)
    defer { try? FileManager.default.removeItem(atPath: path) }
    do {
        _ = try Document(contentsOfFile: path)
        Issue.record("Expected throw")
    } catch let EngineError.unsupportedFormat(ext) {
        #expect(ext == "")
    } catch {
        Issue.record("Expected EngineError.unsupportedFormat for empty extension, got \(error)")
    }
}

@Test func documentSaveWithoutPathThrowsNoFilePath() throws {
    let doc = try Document(content: "# Hi", parser: MarkdownParser())
    do {
        try doc.save()
        Issue.record("Expected throw")
    } catch EngineError.noFilePath {
        // expected
    } catch {
        Issue.record("Expected EngineError.noFilePath, got \(error)")
    }
}

@Test func metadataSerializerMalformedYAMLThrowsMetadataError() {
    do {
        _ = try MetadataSerializer.decode("not: valid: yaml: at: all: [")
        Issue.record("Expected throw")
    } catch EngineError.metadataError {
        // expected
    } catch {
        Issue.record("Expected EngineError.metadataError, got \(error)")
    }
}

@Test func metadataSerializerMissingDocumentThrowsMetadataError() {
    do {
        _ = try MetadataSerializer.decode("flags: []\n")
        Issue.record("Expected throw")
    } catch EngineError.metadataError {
        // expected
    } catch {
        Issue.record("Expected EngineError.metadataError, got \(error)")
    }
}

@Test func engineErrorParseErrorWithLineColumnPatternMatch() {
    // Verify the parseError signature accepts line/column. This is a
    // compile-time guard for the case shape, which production code in
    // iteration 1.3 will exercise once parsing reports positional errors.
    let err: EngineError = .parseError(description: "bad token", line: 5, column: 10)
    if case .parseError(let description, let line, let column) = err {
        #expect(description == "bad token")
        #expect(line == 5)
        #expect(column == 10)
    } else {
        Issue.record("Expected parseError")
    }
}
