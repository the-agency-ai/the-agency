// What Problem: Tests need to run without XCTest (no full Xcode SDK available).
// Using a simple assertion-based test runner that compiles with just the
// Swift command line tools.
//
// How & Why: Standalone test functions with assert(). Each test function
// throws on failure. Phase 1A alignment: tests validate against CLI JSON
// spec shapes (camelCase, no custom CodingKeys). All JSON fixtures use
// shared decoder with .iso8601 date strategy. ~27 tests covering:
// - SectionTreeNode (leaf, 2-level, 3-level tree)
// - SectionsResponse (wrapper + flattened())
// - Section (read response with versionId)
// - Comment (new fields: commentId, slug, resolved, context optional)
// - Resolution (new fields: by, timestamp)
// - Flag (slug not section_slug)
// - Response types (EditResult, ResolveResult, FlagResult, ClearFlagResult)
// - Error types (CLIErrorResponse, CLIErrorDetails)
// - Mock service (new methods: addComment, resolveComment, flagSection, clearFlag)
//
// Written: 2026-04-05 during mdpal-app Phase 1 scaffold
// Updated: 2026-04-06 Phase 1A model alignment (CLI JSON spec dispatch #23)
// Updated: 2026-04-15 Phase 1B.1 — CLIProcess + RealCLIService init tests
// Updated: 2026-04-17 Phase 1B.2 — RealCLIService.listSections tests
//          (happy-path 3-level tree; empty bundle; argv shape; non-zero
//          exit; malformed JSON; missing required field)
// Updated: 2026-04-17 Phase 1B.3 — RealCLIService readSection / listComments /
//          listFlags tests. listComments/listFlags prove end-to-end Date
//          decode via the shared iso8601 decoder hoisted in 1B.2.
// Updated: 2026-04-17 Phase 1B.4 — RealCLIService.editSection tests with
//          typed versionConflict envelope mapping; rewrote the pre-existing
//          CLIErrorResponse tests to match dispatch #23's wire format
//          (discriminator is the TOP-LEVEL `error` field, not nested in
//          `details`); added sectionNotFound, bundleConflict, and
//          unknown-kind-fallback envelope tests.
// Updated: 2026-04-17 Phase 1B.5 — RealCLIService mutation tests:
//          addComment (happy+optional-args+envelope), resolveComment
//          (happy+exit), flagSection (happy+note-omission+envelope),
//          clearFlag (happy+envelope). CLIServiceProtocol is now fully
//          covered end-to-end against canned JSON.
// Updated: 2026-04-17 Phase 1B.6 — CLIServiceFactory tests (Mock vs Real
//          resolution), ProcessResult stderr-sanitization tests (ANSI
//          strip + length cap), DefaultProcessRunner maxOutputBytes
//          enforcement. Phase 1B housekeeping complete.

import Foundation
@testable import MarkdownPalAppLib

// MARK: - Test Infrastructure

struct TestFailure: Error, CustomStringConvertible {
    let message: String
    let file: String
    let line: Int
    var description: String { "\(file):\(line): \(message)" }
}

func expect<T: Equatable>(
    _ actual: T, equals expected: T,
    _ message: String = "",
    file: String = #file, line: Int = #line
) throws {
    guard actual == expected else {
        throw TestFailure(
            message: "Expected \(expected), got \(actual). \(message)",
            file: file, line: line
        )
    }
}

func expectTrue(
    _ condition: Bool,
    _ message: String = "",
    file: String = #file, line: Int = #line
) throws {
    guard condition else {
        throw TestFailure(message: "Expected true. \(message)", file: file, line: line)
    }
}

func expectFalse(
    _ condition: Bool,
    _ message: String = "",
    file: String = #file, line: Int = #line
) throws {
    guard !condition else {
        throw TestFailure(message: "Expected false. \(message)", file: file, line: line)
    }
}

func expectNil<T>(
    _ value: T?,
    _ message: String = "",
    file: String = #file, line: Int = #line
) throws {
    guard value == nil else {
        throw TestFailure(message: "Expected nil, got \(value!). \(message)", file: file, line: line)
    }
}

func expectNotNil<T>(
    _ value: T?,
    _ message: String = "",
    file: String = #file, line: Int = #line
) throws {
    guard value != nil else {
        throw TestFailure(message: "Expected non-nil. \(message)", file: file, line: line)
    }
}

func expectThrows<E: Error>(
    _ type: E.Type,
    _ block: () async throws -> Void,
    file: String = #file, line: Int = #line
) async throws {
    do {
        try await block()
        throw TestFailure(message: "Expected \(type) to be thrown", file: file, line: line)
    } catch is E {
        // Expected
    } catch is TestFailure {
        throw TestFailure(message: "Expected \(type) to be thrown", file: file, line: line)
    }
}

/// Shared ISO 8601 decoder for all JSON fixtures.
func makeDecoder() -> JSONDecoder {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    return decoder
}

// MARK: - SectionTreeNode Tests

func testSectionTreeNodeDecodesFromCLIJSON() throws {
    let json = """
    {
        "slug": "overview",
        "heading": "Overview",
        "level": 1,
        "versionHash": "a3f2b1",
        "children": []
    }
    """
    let data = json.data(using: .utf8)!
    let node = try JSONDecoder().decode(SectionTreeNode.self, from: data)

    try expect(node.slug, equals: "overview")
    try expect(node.heading, equals: "Overview")
    try expect(node.level, equals: 1)
    try expect(node.versionHash, equals: "a3f2b1")
    try expectTrue(node.children.isEmpty)
    try expect(node.id, equals: "overview")
}

func testSectionTreeNodeDecodes2LevelTree() throws {
    let json = """
    {
        "slug": "authentication",
        "heading": "Authentication",
        "level": 1,
        "versionHash": "c7d4e9",
        "children": [
            {
                "slug": "authentication/oauth",
                "heading": "OAuth Flow",
                "level": 2,
                "versionHash": "f1a2b3",
                "children": []
            },
            {
                "slug": "authentication/tokens",
                "heading": "Token Management",
                "level": 2,
                "versionHash": "b5c6d7",
                "children": []
            }
        ]
    }
    """
    let data = json.data(using: .utf8)!
    let node = try JSONDecoder().decode(SectionTreeNode.self, from: data)

    try expect(node.slug, equals: "authentication")
    try expect(node.children.count, equals: 2)
    try expect(node.children[0].slug, equals: "authentication/oauth")
    try expect(node.children[1].slug, equals: "authentication/tokens")
}

func testSectionTreeNodeDecodes3LevelTree() throws {
    let json = """
    {
        "slug": "root",
        "heading": "Root",
        "level": 1,
        "versionHash": "aaa",
        "children": [
            {
                "slug": "root/child",
                "heading": "Child",
                "level": 2,
                "versionHash": "bbb",
                "children": [
                    {
                        "slug": "root/child/grandchild",
                        "heading": "Grandchild",
                        "level": 3,
                        "versionHash": "ccc",
                        "children": []
                    }
                ]
            }
        ]
    }
    """
    let data = json.data(using: .utf8)!
    let node = try JSONDecoder().decode(SectionTreeNode.self, from: data)

    try expect(node.children.count, equals: 1)
    try expect(node.children[0].children.count, equals: 1)
    try expect(node.children[0].children[0].slug, equals: "root/child/grandchild")
    try expect(node.children[0].children[0].level, equals: 3)
}

// MARK: - SectionsResponse Tests

func testSectionsResponseDecodesFromCLIJSON() throws {
    let json = """
    {
        "sections": [
            {
                "slug": "overview",
                "heading": "Overview",
                "level": 1,
                "versionHash": "a3f2b1",
                "children": []
            }
        ],
        "count": 1,
        "versionId": "v1-20260406"
    }
    """
    let data = json.data(using: .utf8)!
    let response = try JSONDecoder().decode(SectionsResponse.self, from: data)

    try expect(response.sections.count, equals: 1)
    try expect(response.count, equals: 1)
    try expect(response.versionId, equals: "v1-20260406")
}

func testFlattenedReturnsDepthFirstOrder() throws {
    let tree = SectionsResponse(
        sections: [
            SectionTreeNode(slug: "a", heading: "A", level: 1, versionHash: "1", children: [
                SectionTreeNode(slug: "a/b", heading: "B", level: 2, versionHash: "2"),
                SectionTreeNode(slug: "a/c", heading: "C", level: 2, versionHash: "3"),
            ]),
            SectionTreeNode(slug: "d", heading: "D", level: 1, versionHash: "4"),
        ],
        count: 4,
        versionId: "v1"
    )

    let flat = tree.flattened()
    try expect(flat.count, equals: 4)
    try expect(flat[0].slug, equals: "a")
    try expect(flat[1].slug, equals: "a/b")
    try expect(flat[2].slug, equals: "a/c")
    try expect(flat[3].slug, equals: "d")
}

func testFlattenedOnLeafReturnsJustSelf() throws {
    let tree = SectionsResponse(
        sections: [
            SectionTreeNode(slug: "leaf", heading: "Leaf", level: 1, versionHash: "x"),
        ],
        count: 1,
        versionId: "v1"
    )

    let flat = tree.flattened()
    try expect(flat.count, equals: 1)
    try expect(flat[0].slug, equals: "leaf")
}

// MARK: - Section (Read Response) Tests

func testSectionDecodesFromCLIJSON() throws {
    let json = """
    {
        "slug": "overview",
        "heading": "Overview",
        "level": 1,
        "content": "This is the overview.",
        "versionHash": "a3f2b1",
        "versionId": "v1-20260406"
    }
    """
    let data = json.data(using: .utf8)!
    let section = try JSONDecoder().decode(Section.self, from: data)

    try expect(section.slug, equals: "overview")
    try expect(section.content, equals: "This is the overview.")
    try expect(section.versionHash, equals: "a3f2b1")
    try expect(section.versionId, equals: "v1-20260406")
}

// MARK: - Comment Model Tests

func testResolvedCommentDetection() throws {
    let unresolved = Comment(
        commentId: "c001", type: .question, author: "claude",
        slug: "auth", timestamp: Date(),
        context: "ctx", text: "q?", resolved: false
    )

    let resolved = Comment(
        commentId: "c002", type: .suggestion, author: "jordan",
        slug: "data", timestamp: Date(),
        context: "ctx", text: "suggestion", resolved: true,
        resolution: Resolution(
            response: "agreed", by: "jordan", timestamp: Date()
        )
    )

    try expectFalse(unresolved.isResolved)
    try expectTrue(resolved.isResolved)
}

func testCommentDecodesFromCLIJSON() throws {
    let json = """
    {
        "commentId": "c001",
        "type": "question",
        "author": "claude",
        "slug": "authentication",
        "timestamp": "2026-03-10T14:00:00Z",
        "context": "OAuth2 bearer token",
        "text": "Does this handle refresh?",
        "resolved": false,
        "resolution": null,
        "priority": "high",
        "tags": []
    }
    """
    let decoder = makeDecoder()
    let data = json.data(using: .utf8)!
    let comment = try decoder.decode(Comment.self, from: data)

    try expect(comment.commentId, equals: "c001")
    try expect(comment.id, equals: "c001")
    try expect(comment.type, equals: .question)
    try expect(comment.slug, equals: "authentication")
    try expect(comment.priority, equals: .high)
    try expectFalse(comment.isResolved)
    try expectFalse(comment.resolved)
}

func testCommentWithResolutionDecodesFromCLIJSON() throws {
    let json = """
    {
        "commentId": "c002",
        "type": "suggestion",
        "author": "jordan",
        "slug": "data-model",
        "timestamp": "2026-03-09T10:30:00Z",
        "context": "PostgreSQL with JSONB columns",
        "text": "Consider SQLite for local case.",
        "resolved": true,
        "resolution": {
            "response": "Agreed. SQLite for local.",
            "by": "jordan",
            "timestamp": "2026-03-10T09:00:00Z"
        },
        "priority": "normal",
        "tags": ["storage"]
    }
    """
    let decoder = makeDecoder()
    let data = json.data(using: .utf8)!
    let comment = try decoder.decode(Comment.self, from: data)

    try expectTrue(comment.isResolved)
    try expectTrue(comment.resolved)
    try expectNotNil(comment.resolution)
    try expect(comment.resolution!.response, equals: "Agreed. SQLite for local.")
    try expect(comment.resolution!.by, equals: "jordan")
    try expect(comment.tags, equals: ["storage"])
}

func testCommentWithNilContextDecodes() throws {
    let json = """
    {
        "commentId": "c005",
        "type": "note",
        "author": "claude",
        "slug": "overview",
        "timestamp": "2026-03-11T17:00:00Z",
        "context": null,
        "text": "A note without context.",
        "resolved": false,
        "resolution": null,
        "priority": "normal",
        "tags": []
    }
    """
    let decoder = makeDecoder()
    let data = json.data(using: .utf8)!
    let comment = try decoder.decode(Comment.self, from: data)

    try expectNil(comment.context)
}

// MARK: - Flag Model Tests

func testFlagDecodesFromCLIJSON() throws {
    let json = """
    {
        "slug": "authentication/oauth",
        "note": "Discuss OAuth flow",
        "author": "jordan",
        "timestamp": "2026-03-10T14:00:00Z"
    }
    """
    let decoder = makeDecoder()
    let data = json.data(using: .utf8)!
    let flag = try decoder.decode(Flag.self, from: data)

    try expect(flag.slug, equals: "authentication/oauth")
    try expect(flag.note, equals: "Discuss OAuth flow")
    try expect(flag.id, equals: "authentication/oauth")
}

func testFlagWithNilNoteDecodesCorrectly() throws {
    let json = """
    {
        "slug": "open-questions",
        "note": null,
        "author": "claude",
        "timestamp": "2026-03-11T17:30:00Z"
    }
    """
    let decoder = makeDecoder()
    let data = json.data(using: .utf8)!
    let flag = try decoder.decode(Flag.self, from: data)

    try expectNil(flag.note)
    try expect(flag.slug, equals: "open-questions")
}

// MARK: - Response Type Tests

func testEditResultDecodesFromCLIJSON() throws {
    let json = """
    {
        "slug": "overview",
        "versionHash": "new123",
        "versionId": "v2-20260406",
        "bytesWritten": 1024
    }
    """
    let data = json.data(using: .utf8)!
    let result = try JSONDecoder().decode(EditResult.self, from: data)

    try expect(result.slug, equals: "overview")
    try expect(result.versionHash, equals: "new123")
    try expect(result.versionId, equals: "v2-20260406")
    try expect(result.bytesWritten, equals: 1024)
}

func testResolveResultDecodesFromCLIJSON() throws {
    let json = """
    {
        "commentId": "c001",
        "resolved": true,
        "resolution": {
            "response": "Fixed in v2.",
            "by": "jordan",
            "timestamp": "2026-04-06T01:00:00Z"
        }
    }
    """
    let decoder = makeDecoder()
    let data = json.data(using: .utf8)!
    let result = try decoder.decode(ResolveResult.self, from: data)

    try expect(result.commentId, equals: "c001")
    try expectTrue(result.resolved)
    try expect(result.resolution.response, equals: "Fixed in v2.")
    try expect(result.resolution.by, equals: "jordan")
}

func testFlagResultDecodesFromCLIJSON() throws {
    let json = """
    {
        "slug": "overview",
        "flagged": true,
        "author": "jordan",
        "note": "Needs review",
        "timestamp": "2026-04-06T01:00:00Z"
    }
    """
    let decoder = makeDecoder()
    let data = json.data(using: .utf8)!
    let result = try decoder.decode(FlagResult.self, from: data)

    try expect(result.slug, equals: "overview")
    try expectTrue(result.flagged)
    try expect(result.author, equals: "jordan")
    try expect(result.note, equals: "Needs review")
}

func testClearFlagResultDecodesFromCLIJSON() throws {
    let json = """
    {
        "slug": "overview",
        "flagged": false
    }
    """
    let data = json.data(using: .utf8)!
    let result = try JSONDecoder().decode(ClearFlagResult.self, from: data)

    try expect(result.slug, equals: "overview")
    try expectFalse(result.flagged)
}

// MARK: - Error Type Tests

func testCLIErrorResponseDecodesFromJSON() throws {
    // Envelope without details (some error kinds carry no structured
    // details). Dispatch #23: discriminator is the top-level `error` field.
    let json = """
    {
        "error": "parseError",
        "message": "Malformed markdown at line 42"
    }
    """
    let data = json.data(using: .utf8)!
    let error = try JSONDecoder().decode(CLIErrorResponse.self, from: data)

    try expect(error.error, equals: "parseError")
    try expect(error.message, equals: "Malformed markdown at line 42")
    try expectNil(error.details)
}

func testCLIErrorWithDetailsDecodesFromJSON() throws {
    // Spec-faithful shape: top-level `error` is the discriminator;
    // `details` has the case-specific fields WITHOUT a nested `type`.
    let json = """
    {
        "error": "versionConflict",
        "message": "Section 'overview' was modified since version abc",
        "details": {
            "slug": "overview",
            "expectedHash": "abc",
            "currentHash": "def",
            "currentContent": "new content here",
            "versionId": "v2"
        }
    }
    """
    let data = json.data(using: .utf8)!
    let error = try JSONDecoder().decode(CLIErrorResponse.self, from: data)

    try expect(error.error, equals: "versionConflict")
    try expectNotNil(error.details)

    if case .versionConflict(let slug, let expected, let current, let content, let versionId) = error.details! {
        try expect(slug, equals: "overview")
        try expect(expected, equals: "abc")
        try expect(current, equals: "def")
        try expect(content, equals: "new content here")
        try expect(versionId, equals: "v2")
    } else {
        throw TestFailure(message: "Expected versionConflict details", file: #file, line: #line)
    }
}

func testCLIErrorSectionNotFoundDecodes() throws {
    let json = """
    {
        "error": "sectionNotFound",
        "message": "Section 'missing' not found",
        "details": { "slug": "missing", "availableSlugs": ["architecture", "testing"] }
    }
    """
    let data = json.data(using: .utf8)!
    let error = try JSONDecoder().decode(CLIErrorResponse.self, from: data)

    try expect(error.error, equals: "sectionNotFound")
    if case .sectionNotFound(let slug, let available) = try expectNotNilUnwrap(error.details) {
        try expect(slug, equals: "missing")
        try expect(available, equals: ["architecture", "testing"])
    } else {
        throw TestFailure(message: "Expected sectionNotFound details", file: #file, line: #line)
    }
}

func testCLIErrorBundleConflictDecodes() throws {
    let json = """
    {
        "error": "bundleConflict",
        "message": "Base revision stale",
        "details": { "baseRevision": "V0001.0002", "currentRevision": "V0001.0003" }
    }
    """
    let data = json.data(using: .utf8)!
    let error = try JSONDecoder().decode(CLIErrorResponse.self, from: data)

    if case .bundleConflict(let base, let current) = try expectNotNilUnwrap(error.details) {
        try expect(base, equals: "V0001.0002")
        try expect(current, equals: "V0001.0003")
    } else {
        throw TestFailure(message: "Expected bundleConflict details", file: #file, line: #line)
    }
}

func testCLIErrorUnknownKindFallsBackToGeneric() throws {
    // Forward-compat: CLI emits a new error kind the app doesn't recognize.
    // Envelope still decodes; details fall through to .generic with any
    // string key/values harvested for diagnostics.
    let json = """
    {
        "error": "quotaExceeded",
        "message": "Hit monthly quota",
        "details": { "limit": "1000", "used": "1001" }
    }
    """
    let data = json.data(using: .utf8)!
    let error = try JSONDecoder().decode(CLIErrorResponse.self, from: data)

    try expect(error.error, equals: "quotaExceeded")
    if case .generic(let data) = try expectNotNilUnwrap(error.details) {
        try expect(data["limit"] ?? "", equals: "1000")
        try expect(data["used"] ?? "", equals: "1001")
    } else {
        throw TestFailure(message: "Expected generic fallback", file: #file, line: #line)
    }
}

// MARK: - Mock CLI Service Tests

func testListSectionsReturnsFlattenedMockData() async throws {
    let service = MockCLIService()
    let sections = try await service.listSections(bundle: BundlePath(""))

    try expect(sections.count, equals: 8)
    try expect(sections[0].slug, equals: "overview")
    try expect(sections[1].slug, equals: "authentication")
    // Children appear after parent in depth-first order
    try expect(sections[2].slug, equals: "authentication/oauth")
    try expect(sections[3].slug, equals: "authentication/tokens")
}

func testReadSectionReturnsContentForValidSlug() async throws {
    let service = MockCLIService()
    let section = try await service.readSection(slug: "authentication", bundle: BundlePath(""))

    try expect(section.heading, equals: "Authentication")
    try expect(section.versionId, equals: "v1-20260406")
    try expectFalse(section.content.isEmpty)
}

func testReadSectionThrowsForInvalidSlug() async throws {
    try await expectThrows(CLIServiceError.self) {
        let service = MockCLIService()
        _ = try await service.readSection(slug: "nonexistent", bundle: BundlePath(""))
    }
}

func testEditSectionEnforcesVersionHash() async throws {
    try await expectThrows(CLIServiceError.self) {
        let service = MockCLIService()
        _ = try await service.editSection(
            slug: "overview", content: "new content",
            versionHash: "wrong_hash", bundle: BundlePath("")
        )
    }
}

func testEditSectionReturnsEditResult() async throws {
    let service = MockCLIService()
    let result = try await service.editSection(
        slug: "overview", content: "Updated overview content.",
        versionHash: "a3f2b1", bundle: BundlePath("")
    )

    try expect(result.slug, equals: "overview")
    try expectFalse(result.versionHash == "a3f2b1", "hash should change")
    try expectTrue(result.bytesWritten > 0)
}

func testAddCommentReturnsMockComment() async throws {
    let service = MockCLIService()
    let comment = try await service.addComment(
        slug: "overview", bundle: BundlePath(""),
        type: .question, author: "claude",
        text: "Test question", context: "Some context",
        priority: .normal, tags: []
    )

    try expect(comment.type, equals: .question)
    try expect(comment.author, equals: "claude")
    try expect(comment.slug, equals: "overview")
    try expect(comment.text, equals: "Test question")
    try expectFalse(comment.resolved)
}

func testResolveCommentReturnsMockResult() async throws {
    let service = MockCLIService()
    let result = try await service.resolveComment(
        commentId: "c001", bundle: BundlePath(""),
        response: "Fixed", by: "jordan"
    )

    try expect(result.commentId, equals: "c001")
    try expectTrue(result.resolved)
    try expect(result.resolution.by, equals: "jordan")
}

func testFlagSectionReturnsMockResult() async throws {
    let service = MockCLIService()
    let result = try await service.flagSection(
        slug: "overview", bundle: BundlePath(""),
        author: "jordan", note: "Needs review"
    )

    try expect(result.slug, equals: "overview")
    try expectTrue(result.flagged)
    try expect(result.author, equals: "jordan")
}

func testClearFlagReturnsMockResult() async throws {
    let service = MockCLIService()
    let result = try await service.clearFlag(
        slug: "overview", bundle: BundlePath("")
    )

    try expect(result.slug, equals: "overview")
    try expectFalse(result.flagged)
}

// MARK: - DocumentModel (state flow)

func testDocumentModelLoadSectionsPopulatesState() async throws {
    let doc = DocumentModel(cliService: MockCLIService())
    try expect(doc.sections.count, equals: 0)
    await doc.loadSections()
    try expectTrue(doc.sections.count > 0, "sections should load from mock")
}

func testDocumentModelLoadCommentsAndFlagsPopulatesState() async throws {
    let doc = DocumentModel(cliService: MockCLIService())
    await doc.loadComments()
    await doc.loadFlags()
    try expectTrue(doc.comments.count > 0, "comments should load")
    try expectTrue(doc.flags.count > 0, "flags should load")
}

func testDocumentModelAddCommentAppendsToState() async throws {
    let doc = DocumentModel(cliService: MockCLIService())
    await doc.loadComments()
    let before = doc.comments.count
    try await doc.addComment(
        slug: "overview", type: .note, author: "jordan",
        text: "Just added", context: nil, priority: .normal, tags: []
    )
    try expect(doc.comments.count, equals: before + 1)
    let added = doc.comments.last!
    try expect(added.text, equals: "Just added")
    try expect(added.slug, equals: "overview")
    try expectFalse(added.resolved)
}

func testDocumentModelResolveCommentTriggersReload() async throws {
    let doc = DocumentModel(cliService: MockCLIService())
    await doc.loadComments()
    // Mock resolveComment returns ResolveResult; DocumentModel calls loadComments after
    try await doc.resolveComment(commentId: "c001", response: "Handled", by: "jordan")
    // State should still be populated (mock listComments returns static set — key assertion
    // is that the call completed without throwing and comments stayed non-empty).
    try expectTrue(doc.comments.count > 0)
}

func testDocumentModelToggleFlagAddsThenClearsInSequence() async throws {
    let doc = DocumentModel(cliService: ToggleTrackingService())
    // Not flagged initially
    try expectFalse(doc.isFlagged(slug: "overview"))
    try await doc.toggleFlag(slug: "overview", author: "jordan", note: "needs review")
    try expectTrue(doc.isFlagged(slug: "overview"), "toggleFlag should add a flag when none exists")

    try await doc.toggleFlag(slug: "overview", author: "jordan", note: nil)
    try expectFalse(doc.isFlagged(slug: "overview"), "toggleFlag should clear an existing flag")
}

func testDocumentModelFlagSectionIsReflectedInState() async throws {
    let doc = DocumentModel(cliService: ToggleTrackingService())
    try await doc.flagSection(slug: "api-design", author: "jordan", note: nil)
    try expectTrue(doc.isFlagged(slug: "api-design"))
    let flag = doc.flag(forSection: "api-design")!
    try expect(flag.author, equals: "jordan")
}

/// Stateful mock that reflects add/clear operations in subsequent list calls.
/// Needed to test DocumentModel.toggleFlag end-to-end (default MockCLIService
/// returns a fixed flag set regardless of mutations).
final class ToggleTrackingService: CLIServiceProtocol, @unchecked Sendable {
    private var flags: [Flag] = []
    private var comments: [Comment] = []

    func listSections(bundle: BundlePath) async throws -> [SectionTreeNode] {
        MockCLIService.mockSectionsFlat
    }
    func readSection(slug: String, bundle: BundlePath) async throws -> Section {
        MockCLIService.mockSectionContents[slug]!
    }
    func editSection(slug: String, content: String,
                     versionHash: String, bundle: BundlePath) async throws -> EditResult {
        EditResult(slug: slug, versionHash: "new", versionId: "v", bytesWritten: content.utf8.count)
    }
    func listComments(bundle: BundlePath) async throws -> [Comment] { comments }
    func listFlags(bundle: BundlePath) async throws -> [Flag] { flags }
    func addComment(slug: String, bundle: BundlePath, type: CommentType,
                    author: String, text: String, context: String?,
                    priority: Priority, tags: [String]) async throws -> Comment {
        let c = Comment(
            commentId: "c\(comments.count + 1)", type: type, author: author,
            slug: slug, timestamp: Date(), context: context, text: text,
            resolved: false, priority: priority, tags: tags
        )
        comments.append(c)
        return c
    }
    func resolveComment(commentId: String, bundle: BundlePath,
                        response: String, by: String) async throws -> ResolveResult {
        if let idx = comments.firstIndex(where: { $0.commentId == commentId }) {
            let old = comments[idx]
            comments[idx] = Comment(
                commentId: old.commentId, type: old.type, author: old.author,
                slug: old.slug, timestamp: old.timestamp, context: old.context,
                text: old.text, resolved: true,
                resolution: Resolution(response: response, by: by, timestamp: Date()),
                priority: old.priority, tags: old.tags
            )
        }
        return ResolveResult(
            commentId: commentId, resolved: true,
            resolution: Resolution(response: response, by: by, timestamp: Date())
        )
    }
    func flagSection(slug: String, bundle: BundlePath,
                     author: String, note: String?) async throws -> FlagResult {
        let now = Date()
        flags.removeAll { $0.slug == slug }
        flags.append(Flag(slug: slug, note: note, author: author, timestamp: now))
        return FlagResult(slug: slug, flagged: true, author: author, note: note, timestamp: now)
    }
    func clearFlag(slug: String, bundle: BundlePath) async throws -> ClearFlagResult {
        flags.removeAll { $0.slug == slug }
        return ClearFlagResult(slug: slug, flagged: false)
    }
}

/// Service that throws on list/read operations when `shouldFail` is true.
/// Used to verify DocumentModel's lastError wiring (Iteration 1A.3).
final class FailingToggleService: CLIServiceProtocol, @unchecked Sendable {
    var shouldFail: Bool = true
    private let inner = ToggleTrackingService()

    struct FailureError: Error, LocalizedError {
        var errorDescription: String? { "simulated CLI failure" }
    }

    func listSections(bundle: BundlePath) async throws -> [SectionTreeNode] {
        if shouldFail { throw FailureError() }
        return try await inner.listSections(bundle: bundle)
    }
    func readSection(slug: String, bundle: BundlePath) async throws -> Section {
        if shouldFail { throw FailureError() }
        return try await inner.readSection(slug: slug, bundle: bundle)
    }
    func editSection(slug: String, content: String,
                     versionHash: String, bundle: BundlePath) async throws -> EditResult {
        try await inner.editSection(slug: slug, content: content,
                                    versionHash: versionHash, bundle: bundle)
    }
    func listComments(bundle: BundlePath) async throws -> [Comment] {
        if shouldFail { throw FailureError() }
        return try await inner.listComments(bundle: bundle)
    }
    func listFlags(bundle: BundlePath) async throws -> [Flag] {
        if shouldFail { throw FailureError() }
        return try await inner.listFlags(bundle: bundle)
    }
    func addComment(slug: String, bundle: BundlePath, type: CommentType,
                    author: String, text: String, context: String?,
                    priority: Priority, tags: [String]) async throws -> Comment {
        try await inner.addComment(slug: slug, bundle: bundle, type: type,
                                   author: author, text: text, context: context,
                                   priority: priority, tags: tags)
    }
    func resolveComment(commentId: String, bundle: BundlePath,
                        response: String, by: String) async throws -> ResolveResult {
        try await inner.resolveComment(commentId: commentId, bundle: bundle,
                                       response: response, by: by)
    }
    func flagSection(slug: String, bundle: BundlePath,
                     author: String, note: String?) async throws -> FlagResult {
        try await inner.flagSection(slug: slug, bundle: bundle,
                                    author: author, note: note)
    }
    func clearFlag(slug: String, bundle: BundlePath) async throws -> ClearFlagResult {
        try await inner.clearFlag(slug: slug, bundle: bundle)
    }
}

func testDocumentModelEditSectionHappyPath() async throws {
    // MockCLIService enforces versionHash — use the real mock + real hash.
    let doc = DocumentModel(cliService: MockCLIService())
    await doc.loadSections()
    await doc.selectSection(slug: "overview")
    let base = doc.selectedSection!
    try await doc.editSection(
        slug: "overview", newContent: "New body.", versionHash: base.versionHash
    )
    try expectTrue(doc.isDirty, "editSection should mark document dirty")
    // selectedSection is refreshed via readSection after edit
    try expectTrue(doc.selectedSection != nil, "selectedSection should remain populated post-edit")
}

func testDocumentModelEditSectionThrowsOnStaleVersionHash() async throws {
    let doc = DocumentModel(cliService: MockCLIService())
    await doc.selectSection(slug: "overview")
    var threw = false
    do {
        try await doc.editSection(
            slug: "overview", newContent: "X", versionHash: "obviously-stale-hash"
        )
    } catch let CLIServiceError.versionConflict(slug, _, _) {
        threw = true
        try expect(slug, equals: "overview")
    } catch {
        throw TestFailure(
            message: "expected versionConflict, got \(error)",
            file: #file, line: #line
        )
    }
    try expectTrue(threw, "editSection should throw versionConflict on stale hash")
}

func testDocumentModelLastErrorSetOnLoadFailure() async throws {
    let svc = FailingToggleService()
    let doc = DocumentModel(cliService: svc)
    try expectTrue(doc.lastError == nil, "lastError starts nil")
    await doc.loadSections()
    try expectTrue(doc.lastError != nil, "lastError set after failing loadSections")
    try expectTrue(
        doc.lastError!.contains("simulated CLI failure"),
        "lastError should carry the underlying message, got: \(doc.lastError!)"
    )
}

func testDocumentModelLastErrorClearedOnSuccess() async throws {
    let svc = FailingToggleService()
    let doc = DocumentModel(cliService: svc)
    await doc.loadSections()
    try expectTrue(doc.lastError != nil, "precondition: lastError set after failure")
    svc.shouldFail = false
    await doc.loadSections()
    try expectTrue(doc.lastError == nil, "lastError cleared after subsequent success")
}

// Coverage: mutation paths must clear lastError on success so a stale
// error alert from a prior failure does not linger.

func testDocumentModelEditSectionClearsLastErrorOnSuccess() async throws {
    let doc = DocumentModel(cliService: MockCLIService())
    doc.lastError = "stale error from prior op"
    await doc.loadSections()
    await doc.selectSection(slug: "overview")
    let base = doc.selectedSection!
    try await doc.editSection(
        slug: "overview", newContent: "Refreshed body.", versionHash: base.versionHash
    )
    try expectTrue(doc.lastError == nil,
                   "editSection success must clear lastError; got: \(doc.lastError ?? "nil")")
}

func testDocumentModelAddCommentClearsLastErrorOnSuccess() async throws {
    let doc = DocumentModel(cliService: MockCLIService())
    doc.lastError = "stale error from prior op"
    try await doc.addComment(
        slug: "overview", type: .question, author: "alice",
        text: "What about edge cases?"
    )
    try expectTrue(doc.lastError == nil,
                   "addComment success must clear lastError; got: \(doc.lastError ?? "nil")")
}

func testDocumentModelSelectSectionFailureSetsLastError() async throws {
    let svc = FailingToggleService()
    let doc = DocumentModel(cliService: svc)
    try expectTrue(doc.lastError == nil, "lastError starts nil")
    await doc.selectSection(slug: "overview")
    try expectTrue(doc.lastError != nil,
                   "selectSection failure must set lastError")
    try expectTrue(
        doc.lastError!.contains("Failed to read section"),
        "lastError should describe the failure, got: \(doc.lastError!)"
    )
}

// MARK: - SelectionContext (1A.5)

func testSelectionContextNilClipboardReturnsNil() throws {
    try expectNil(SelectionContext.extract(from: nil, within: "Some content."))
}

func testSelectionContextEmptyClipboardReturnsNil() throws {
    try expectNil(SelectionContext.extract(from: "", within: "Some content."))
    try expectNil(SelectionContext.extract(from: "   \n  ", within: "Some content."))
}

func testSelectionContextNonMatchingClipboardReturnsNil() throws {
    // Clipboard text not present in the section content — typical case where
    // the user's clipboard came from somewhere unrelated.
    try expectNil(SelectionContext.extract(
        from: "https://example.com/secret-token",
        within: "This section has nothing to do with that URL."
    ))
}

func testSelectionContextMatchingClipboardReturnsTrimmed() throws {
    let section = "The parser handles edge cases like nested quotes and escapes."
    let clip = "  nested quotes and escapes\n"
    let got = try expectNotNilUnwrap(SelectionContext.extract(from: clip, within: section))
    try expect(got, equals: "nested quotes and escapes")
}

func testSelectionContextSubstringMatchAcrossWords() throws {
    let section = "Dispatch 23 specifies the JSON wire format for the CLI."
    let clip = "JSON wire format"
    let got = try expectNotNilUnwrap(SelectionContext.extract(from: clip, within: section))
    try expect(got, equals: "JSON wire format")
}

/// Small helper: returns the unwrapped optional or throws (used for non-nil + extract).
func expectNotNilUnwrap<T>(_ value: T?, file: String = #file, line: Int = #line) throws -> T {
    guard let unwrapped = value else {
        throw TestFailure(message: "Expected non-nil", file: file, line: line)
    }
    return unwrapped
}

// MARK: - Phase 1B.1: CLIProcess + RealCLIService

/// Test ProcessRunner that returns canned results without spawning anything.
final class FakeProcessRunner: ProcessRunner, @unchecked Sendable {
    let result: ProcessResult
    var lastExecutable: String?
    var lastArgs: [String]?
    var lastStdin: Data?

    init(result: ProcessResult) {
        self.result = result
    }

    func run(executable: String, args: [String], stdin: Data?) async throws -> ProcessResult {
        lastExecutable = executable
        lastArgs = args
        lastStdin = stdin
        return result
    }
}

/// Build a temp directory with an executable `mdpal` file inside, return the dir path.
func makeTempDirWithMdpal() throws -> String {
    let fm = FileManager.default
    let tmp = NSTemporaryDirectory() + "mdpal-test-\(UUID().uuidString)"
    try fm.createDirectory(atPath: tmp, withIntermediateDirectories: true)
    let bin = (tmp as NSString).appendingPathComponent("mdpal")
    fm.createFile(atPath: bin, contents: Data("#!/bin/sh\nexit 0\n".utf8),
                  attributes: [.posixPermissions: 0o755])
    return tmp
}

func testCLIBinaryResolverHonorsMDPALBinOverride() throws {
    let dir = try makeTempDirWithMdpal()
    defer { try? FileManager.default.removeItem(atPath: dir) }
    let bin = (dir as NSString).appendingPathComponent("mdpal")
    let resolved = try CLIBinaryResolver.resolve(
        environment: ["MDPAL_BIN": bin, "PATH": "/nonexistent"]
    )
    try expect(resolved, equals: bin)
}

func testCLIBinaryResolverThrowsWhenMDPALBinPointsNowhere() throws {
    do {
        _ = try CLIBinaryResolver.resolve(
            environment: ["MDPAL_BIN": "/definitely/not/here/mdpal", "PATH": "/usr/bin"]
        )
        throw TestFailure(message: "Expected cliNotFound to be thrown",
                          file: #file, line: #line)
    } catch CLIServiceError.cliNotFound {
        // expected — explicit override pointing nowhere is a config error
    }
}

func testCLIBinaryResolverFindsBinaryOnPATH() throws {
    let dir = try makeTempDirWithMdpal()
    defer { try? FileManager.default.removeItem(atPath: dir) }
    let resolved = try CLIBinaryResolver.resolve(
        environment: ["PATH": "/nonexistent:\(dir)"]
    )
    try expect(resolved, equals: (dir as NSString).appendingPathComponent("mdpal"))
}

func testCLIBinaryResolverThrowsWhenNothingFound() throws {
    // Use empty fallbacks so the test is deterministic regardless of whether
    // the host has a real mdpal installed in /usr/local/bin or /opt/homebrew/bin.
    do {
        _ = try CLIBinaryResolver.resolve(
            environment: ["PATH": "/nonexistent-a:/nonexistent-b"],
            fallbacks: []
        )
        throw TestFailure(message: "Expected cliNotFound to be thrown",
                          file: #file, line: #line)
    } catch CLIServiceError.cliNotFound {
        // expected
    }
}

func testCLIBinaryResolverPATHWinsOverFallbacks() throws {
    // PATH should be preferred over the fallback list when both contain mdpal.
    let dir = try makeTempDirWithMdpal()
    defer { try? FileManager.default.removeItem(atPath: dir) }
    let pathBin = (dir as NSString).appendingPathComponent("mdpal")

    let fallbackDir = try makeTempDirWithMdpal()
    defer { try? FileManager.default.removeItem(atPath: fallbackDir) }
    let fallbackBin = (fallbackDir as NSString).appendingPathComponent("mdpal")

    let resolved = try CLIBinaryResolver.resolve(
        environment: ["PATH": dir],
        fallbacks: [fallbackBin]
    )
    try expect(resolved, equals: pathBin, "PATH must win over fallbacks")
}

func testCLIBinaryResolverMDPALBinWinsOverPATH() throws {
    // MDPAL_BIN is the explicit override and must beat PATH even when both exist.
    let overrideDir = try makeTempDirWithMdpal()
    defer { try? FileManager.default.removeItem(atPath: overrideDir) }
    let overrideBin = (overrideDir as NSString).appendingPathComponent("mdpal")

    let pathDir = try makeTempDirWithMdpal()
    defer { try? FileManager.default.removeItem(atPath: pathDir) }

    let resolved = try CLIBinaryResolver.resolve(
        environment: ["MDPAL_BIN": overrideBin, "PATH": pathDir],
        fallbacks: []
    )
    try expect(resolved, equals: overrideBin, "MDPAL_BIN must win over PATH")
}

// MARK: - DefaultProcessRunner integration tests

/// Build a temp dir with a script at `mdpal-script` that does whatever the
/// caller writes. Returns the script path.
func makeTempScript(body: String) throws -> String {
    let dir = NSTemporaryDirectory() + "mdpal-script-\(UUID().uuidString)"
    try FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
    let path = (dir as NSString).appendingPathComponent("script.sh")
    let script = "#!/bin/sh\n\(body)\n"
    FileManager.default.createFile(atPath: path, contents: Data(script.utf8),
                                   attributes: [.posixPermissions: 0o755])
    return path
}

func testDefaultProcessRunnerCapturesStdoutAndExitCode() async throws {
    let script = try makeTempScript(body: "echo hello world; exit 0")
    defer { try? FileManager.default.removeItem(atPath: (script as NSString).deletingLastPathComponent) }
    let runner = DefaultProcessRunner()
    let result = try await runner.run(executable: script, args: [], stdin: nil)
    try expect(result.exitCode, equals: Int32(0))
    try expect(result.stdoutString, equals: "hello world\n")
    try expect(result.stderrString, equals: "")
}

func testDefaultProcessRunnerCapturesStderrAndNonZeroExit() async throws {
    let script = try makeTempScript(body: "echo oops 1>&2; exit 7")
    defer { try? FileManager.default.removeItem(atPath: (script as NSString).deletingLastPathComponent) }
    let runner = DefaultProcessRunner()
    let result = try await runner.run(executable: script, args: [], stdin: nil)
    try expect(result.exitCode, equals: Int32(7))
    try expect(result.stdoutString, equals: "")
    try expect(result.stderrString, equals: "oops\n")
}

func testDefaultProcessRunnerForwardsStdinToChild() async throws {
    // `cat` echoes stdin to stdout — proves stdin reaches the child.
    let runner = DefaultProcessRunner()
    let payload = "the quick brown fox\n"
    let result = try await runner.run(
        executable: "/bin/cat",
        args: [],
        stdin: Data(payload.utf8)
    )
    try expect(result.exitCode, equals: Int32(0))
    try expect(result.stdoutString, equals: payload)
}

func testDefaultProcessRunnerHandlesLargeStdoutWithoutDeadlock() async throws {
    // Validates the central correctness claim of DefaultProcessRunner:
    // pipe drains run concurrently with the child so >64KB output doesn't
    // deadlock. Emit ~256KB and confirm it all comes back.
    let script = try makeTempScript(body: "yes 'A' | head -c 262144")
    defer { try? FileManager.default.removeItem(atPath: (script as NSString).deletingLastPathComponent) }
    let runner = DefaultProcessRunner()
    let result = try await runner.run(executable: script, args: [], stdin: nil)
    try expect(result.exitCode, equals: Int32(0))
    try expect(result.stdout.count, equals: 262144,
               "must fully drain output past the ~64KB pipe-buffer boundary")
}

func testDefaultProcessRunnerThrowsWhenExecutableMissing() async throws {
    let runner = DefaultProcessRunner()
    do {
        _ = try await runner.run(
            executable: "/no/such/binary",
            args: [],
            stdin: nil
        )
        throw TestFailure(message: "Expected executionFailed",
                          file: #file, line: #line)
    } catch CLIServiceError.executionFailed {
        // expected
    }
}

func testCLIProcessRunDelegatesToRunner() async throws {
    let canned = ProcessResult(
        exitCode: 0,
        stdout: Data("hello\n".utf8),
        stderr: Data()
    )
    let runner = FakeProcessRunner(result: canned)
    let cli = CLIProcess(executable: "/usr/bin/mdpal", runner: runner)
    let stdin = Data("input\n".utf8)
    let got = try await cli.run(args: ["sections", "/tmp/bundle"], stdin: stdin)
    try expect(got.exitCode, equals: Int32(0))
    try expect(got.stdoutString, equals: "hello\n")
    try expect(runner.lastExecutable ?? "", equals: "/usr/bin/mdpal")
    try expect(runner.lastArgs ?? [], equals: ["sections", "/tmp/bundle"])
    try expect(runner.lastStdin ?? Data(), equals: stdin)
}

func testRealCLIServiceInitFailsCleanlyWhenBinaryMissing() throws {
    do {
        _ = try RealCLIService(
            environment: ["MDPAL_BIN": "/no/such/file", "PATH": "/nonexistent"],
            fileManager: .default,
            runner: FakeProcessRunner(result: ProcessResult(
                exitCode: 0, stdout: Data(), stderr: Data()
            ))
        )
        throw TestFailure(message: "Expected cliNotFound", file: #file, line: #line)
    } catch CLIServiceError.cliNotFound {
        // expected
    }
}

func testRealCLIServiceInitSucceedsWhenBinaryResolves() throws {
    let dir = try makeTempDirWithMdpal()
    defer { try? FileManager.default.removeItem(atPath: dir) }
    let bin = (dir as NSString).appendingPathComponent("mdpal")
    let svc = try RealCLIService(
        environment: ["MDPAL_BIN": bin, "PATH": "/nonexistent"],
        fileManager: .default,
        runner: FakeProcessRunner(result: ProcessResult(
            exitCode: 0, stdout: Data(), stderr: Data()
        ))
    )
    try expect(svc.executablePath, equals: bin)
}

// MARK: - Phase 1B.2: RealCLIService.listSections

/// Dispatch #23 wire-format sample: a 3-level tree with nested children +
/// one leaf at the top level. Exercises the full decode → flatten pipeline
/// past the 2-level boundary (Phase 1A's pure-flatten test only goes two
/// levels). `count` is the top-level-section count per dispatch #23.
private let listSectionsHappyJSON = """
{
  "sections": [
    {
      "slug": "introduction",
      "heading": "Introduction",
      "level": 1,
      "versionHash": "a1b2c3d4",
      "children": [
        {
          "slug": "introduction/background",
          "heading": "Background",
          "level": 2,
          "versionHash": "e5f6a7b8",
          "children": [
            {
              "slug": "introduction/background/context",
              "heading": "Context",
              "level": 3,
              "versionHash": "11223344",
              "children": []
            }
          ]
        }
      ]
    },
    {
      "slug": "architecture",
      "heading": "Architecture",
      "level": 1,
      "versionHash": "c9d0e1f2",
      "children": []
    }
  ],
  "count": 2,
  "versionId": "V0001.0003.20260406T0000Z"
}
"""

/// Run a body closure with a RealCLIService wired to a canned ProcessResult.
/// The helper owns tmp-dir lifecycle — cleanup runs even if the init throws
/// or the body throws. Fallbacks are empty so the resolver is hermetic
/// regardless of whether the host has a real mdpal installed.
private func withRealCLIServiceForTesting(
    result: ProcessResult,
    body: (RealCLIService, FakeProcessRunner) async throws -> Void
) async throws {
    let dir = try makeTempDirWithMdpal()
    defer { try? FileManager.default.removeItem(atPath: dir) }

    let bin = (dir as NSString).appendingPathComponent("mdpal")
    let runner = FakeProcessRunner(result: result)
    let svc = try RealCLIService(
        environment: ["MDPAL_BIN": bin, "PATH": "/nonexistent"],
        fileManager: .default,
        runner: runner,
        fallbacks: []
    )
    try await body(svc, runner)
}

func testRealCLIServiceListSectionsHappyPath() async throws {
    let canned = ProcessResult(
        exitCode: 0,
        stdout: Data(listSectionsHappyJSON.utf8),
        stderr: Data()
    )
    try await withRealCLIServiceForTesting(result: canned) { svc, _ in
        let sections = try await svc.listSections(bundle: BundlePath("/tmp/bundle.mdpal"))

        // Flatten contract: depth-first, parent before children, leaf after.
        // Three levels of nesting prove the recursion past the 2-level boundary.
        try expect(sections.count, equals: 4, "nested children must be flattened in")
        try expect(sections[0].slug, equals: "introduction")
        try expect(sections[1].slug, equals: "introduction/background",
                   "child must follow its parent in depth-first order")
        try expect(sections[2].slug, equals: "introduction/background/context",
                   "grandchild must follow child in depth-first order")
        try expect(sections[3].slug, equals: "architecture")
        try expect(sections[0].versionHash, equals: "a1b2c3d4")
        try expect(sections[2].level, equals: 3)
    }
}

func testRealCLIServiceListSectionsPassesBundlePathAsArgv() async throws {
    let canned = ProcessResult(
        exitCode: 0,
        stdout: Data(listSectionsHappyJSON.utf8),
        stderr: Data()
    )
    try await withRealCLIServiceForTesting(result: canned) { svc, runner in
        _ = try await svc.listSections(bundle: BundlePath("/abs/path/design.mdpal"))

        try expect(runner.lastArgs ?? [], equals: ["sections", "/abs/path/design.mdpal"],
                   "argv must be ['sections', <bundle-path>] per dispatch #23")
        try expectNil(runner.lastStdin,
                      "sections is a read command — stdin must be nil")
    }
}

func testRealCLIServiceListSectionsHandlesEmptySections() async throws {
    // Realistic first-run / empty-bundle path.
    let emptyJSON = """
    { "sections": [], "count": 0, "versionId": "V0001.0001.20260406T0000Z" }
    """
    let canned = ProcessResult(
        exitCode: 0,
        stdout: Data(emptyJSON.utf8),
        stderr: Data()
    )
    try await withRealCLIServiceForTesting(result: canned) { svc, _ in
        let sections = try await svc.listSections(bundle: BundlePath("/tmp/empty.mdpal"))
        try expect(sections.count, equals: 0, "empty sections must decode and flatten to []")
    }
}

func testRealCLIServiceListSectionsMapsNonZeroExitToExecutionFailed() async throws {
    let canned = ProcessResult(
        exitCode: 1,
        stdout: Data(),
        stderr: Data("mdpal: bundle not found: /no/such/bundle\n".utf8)
    )
    try await withRealCLIServiceForTesting(result: canned) { svc, _ in
        do {
            _ = try await svc.listSections(bundle: BundlePath("/no/such/bundle"))
            throw TestFailure(message: "Expected executionFailed", file: #file, line: #line)
        } catch let CLIServiceError.executionFailed(exitCode, stderr) {
            try expect(exitCode, equals: 1)
            try expect(stderr.contains("bundle not found"), equals: true,
                       "stderr bytes must be forwarded to the error payload")
        }
    }
}

func testRealCLIServiceListSectionsMapsMalformedJSONToParseError() async throws {
    // Exit code 0 but stdout isn't valid JSON for SectionsResponse — a real
    // scenario if the CLI drifts from the spec. Must surface as .parseError,
    // not masquerade as success or executionFailed.
    let canned = ProcessResult(
        exitCode: 0,
        stdout: Data("this is not json at all { maybe?".utf8),
        stderr: Data()
    )
    try await withRealCLIServiceForTesting(result: canned) { svc, _ in
        do {
            _ = try await svc.listSections(bundle: BundlePath("/tmp/bundle.mdpal"))
            throw TestFailure(message: "Expected parseError", file: #file, line: #line)
        } catch CLIServiceError.parseError {
            // expected
        }
    }
}

func testRealCLIServiceListSectionsMapsMissingRequiredFieldToParseError() async throws {
    // Valid JSON syntactically, but the `versionId` key is absent. JSONDecoder
    // surfaces .keyNotFound — a distinct error path from "garbage bytes" that
    // must also map to .parseError, not masquerade as success.
    let missingFieldJSON = """
    { "sections": [], "count": 0 }
    """
    let canned = ProcessResult(
        exitCode: 0,
        stdout: Data(missingFieldJSON.utf8),
        stderr: Data()
    )
    try await withRealCLIServiceForTesting(result: canned) { svc, _ in
        do {
            _ = try await svc.listSections(bundle: BundlePath("/tmp/bundle.mdpal"))
            throw TestFailure(message: "Expected parseError", file: #file, line: #line)
        } catch CLIServiceError.parseError {
            // expected — missing required field is a parse contract violation
        }
    }
}

// MARK: - Phase 1B.3: RealCLIService read-side methods
//
// Coverage rotates across the three methods since `runCommand<T>` is shared
// (1B.2). Each method gets happy-path + two error paths; the specific error
// paths rotate (readSection: exit + malformed; listComments: empty + exit;
// listFlags: empty + malformed) so the shared helper's mappings are
// jointly exercised without three-times duplication. Plus one
// path-style-slug test pinning readSection argv forwarding, one
// missing-required-field test, and one CommentsResponse.filters
// requirement-pin test.

// --- readSection ----------------------------------------------------------

/// Dispatch #23 sample for `mdpal read architecture <bundle>`.
private let readSectionHappyJSON = """
{
  "slug": "architecture",
  "heading": "Architecture",
  "level": 1,
  "content": "The system uses a section-oriented architecture...\\n\\n### Components\\n\\nEach component is...",
  "versionHash": "c9d0e1f2",
  "versionId": "V0001.0003.20260406T0000Z"
}
"""

func testRealCLIServiceReadSectionHappyPath() async throws {
    let canned = ProcessResult(
        exitCode: 0,
        stdout: Data(readSectionHappyJSON.utf8),
        stderr: Data()
    )
    try await withRealCLIServiceForTesting(result: canned) { svc, runner in
        let section = try await svc.readSection(
            slug: "architecture",
            bundle: BundlePath("/abs/path/design.mdpal")
        )

        try expect(section.slug, equals: "architecture")
        try expect(section.heading, equals: "Architecture")
        try expect(section.level, equals: 1)
        try expect(section.versionHash, equals: "c9d0e1f2")
        try expect(section.versionId, equals: "V0001.0003.20260406T0000Z")
        try expect(section.content.contains("section-oriented architecture"), equals: true)

        // argv contract: ["read", <slug>, <bundle>]
        try expect(runner.lastArgs ?? [], equals: ["read", "architecture", "/abs/path/design.mdpal"],
                   "argv must be ['read', <slug>, <bundle-path>] per dispatch #23")
        try expectNil(runner.lastStdin, "read is a read command — stdin must be nil")
    }
}

func testRealCLIServiceReadSectionMapsSectionNotFoundEnvelope() async throws {
    // 1B.4 migrated readSection to runCommandWithEnvelope; the CLI's
    // structured stderr now maps to the typed .sectionNotFound case
    // (was .executionFailed in 1B.3).
    let canned = ProcessResult(
        exitCode: 3,
        stdout: Data(),
        stderr: Data(#"{"error":"sectionNotFound","message":"Section 'missing' not found","details":{"slug":"missing","availableSlugs":["architecture","testing"]}}"#.utf8)
    )
    try await withRealCLIServiceForTesting(result: canned) { svc, _ in
        do {
            _ = try await svc.readSection(
                slug: "missing",
                bundle: BundlePath("/tmp/bundle.mdpal")
            )
            throw TestFailure(message: "Expected sectionNotFound", file: #file, line: #line)
        } catch let CLIServiceError.sectionNotFound(slug, available) {
            try expect(slug, equals: "missing")
            try expect(available, equals: ["architecture", "testing"])
        }
    }
}

func testRealCLIServiceReadSectionFallsThroughOnNonEnvelopeStderr() async throws {
    // Non-zero exit with stderr that isn't envelope-shaped — must
    // preserve 1B.3 behaviour (raw stderr via .executionFailed).
    let canned = ProcessResult(
        exitCode: 1,
        stdout: Data(),
        stderr: Data("mdpal: bundle permission denied\n".utf8)
    )
    try await withRealCLIServiceForTesting(result: canned) { svc, _ in
        do {
            _ = try await svc.readSection(
                slug: "any",
                bundle: BundlePath("/tmp/bundle.mdpal")
            )
            throw TestFailure(message: "Expected executionFailed", file: #file, line: #line)
        } catch let CLIServiceError.executionFailed(exitCode, stderr) {
            try expect(exitCode, equals: 1)
            try expect(stderr.contains("permission denied"), equals: true)
        }
    }
}

func testRealCLIServiceReadSectionPassesPathStyleSlugAsArgv() async throws {
    // Dispatch #23 allows path-style slugs like "introduction/background".
    // Process.arguments preserves each element as a single argv token, but
    // this test pins that contract so a future refactor (joining via
    // shell, splitting slug on "/") can't silently regress it.
    let canned = ProcessResult(
        exitCode: 0,
        stdout: Data(readSectionHappyJSON.utf8),
        stderr: Data()
    )
    try await withRealCLIServiceForTesting(result: canned) { svc, runner in
        _ = try await svc.readSection(
            slug: "introduction/background",
            bundle: BundlePath("/abs/path/design.mdpal")
        )
        try expect(runner.lastArgs ?? [],
                   equals: ["read", "introduction/background", "/abs/path/design.mdpal"],
                   "path-style slug must survive as one argv token")
    }
}

func testRealCLIServiceReadSectionMapsMissingRequiredFieldToParseError() async throws {
    // Section has six required fields. If the CLI ever drops one (e.g.
    // versionId, the optimistic-concurrency anchor), JSONDecoder throws
    // .keyNotFound — must surface as .parseError, same as garbage JSON.
    let missingFieldJSON = """
    {
      "slug": "architecture",
      "heading": "Architecture",
      "level": 1,
      "content": "...",
      "versionHash": "c9d0e1f2"
    }
    """
    let canned = ProcessResult(
        exitCode: 0,
        stdout: Data(missingFieldJSON.utf8),
        stderr: Data()
    )
    try await withRealCLIServiceForTesting(result: canned) { svc, _ in
        do {
            _ = try await svc.readSection(
                slug: "architecture",
                bundle: BundlePath("/tmp/bundle.mdpal")
            )
            throw TestFailure(message: "Expected parseError", file: #file, line: #line)
        } catch CLIServiceError.parseError {
            // expected — missing versionId is a contract violation
        }
    }
}

func testRealCLIServiceReadSectionMapsMalformedJSONToParseError() async throws {
    let canned = ProcessResult(
        exitCode: 0,
        stdout: Data("not valid json".utf8),
        stderr: Data()
    )
    try await withRealCLIServiceForTesting(result: canned) { svc, _ in
        do {
            _ = try await svc.readSection(
                slug: "architecture",
                bundle: BundlePath("/tmp/bundle.mdpal")
            )
            throw TestFailure(message: "Expected parseError", file: #file, line: #line)
        } catch CLIServiceError.parseError {
            // expected
        }
    }
}

// --- listComments ---------------------------------------------------------

/// Dispatch #23 sample for `mdpal comments <bundle>`. Exercises Date decoding
/// via the shared iso8601 decoder — comment `timestamp` and `resolution.timestamp`.
private let listCommentsHappyJSON = """
{
  "comments": [
    {
      "commentId": "c007",
      "slug": "architecture",
      "type": "question",
      "author": "jordan",
      "text": "Should we use dependency injection here?",
      "context": "The system uses a section-oriented architecture...",
      "priority": "normal",
      "tags": [],
      "timestamp": "2026-04-06T01:00:00Z",
      "resolved": false,
      "resolution": null
    },
    {
      "commentId": "c008",
      "slug": "testing",
      "type": "suggestion",
      "author": "mdpal-cli",
      "text": "Add performance benchmarks",
      "context": "Testing is baked in...",
      "priority": "high",
      "tags": ["perf", "phase2"],
      "timestamp": "2026-04-06T01:05:00Z",
      "resolved": true,
      "resolution": {
        "response": "Added in iteration 1.3",
        "by": "mdpal-cli",
        "timestamp": "2026-04-06T02:00:00Z"
      }
    }
  ],
  "count": 2,
  "filters": {
    "section": null,
    "type": null,
    "resolved": null
  }
}
"""

func testRealCLIServiceListCommentsHappyPath() async throws {
    let canned = ProcessResult(
        exitCode: 0,
        stdout: Data(listCommentsHappyJSON.utf8),
        stderr: Data()
    )
    try await withRealCLIServiceForTesting(result: canned) { svc, runner in
        let comments = try await svc.listComments(bundle: BundlePath("/abs/path/design.mdpal"))

        try expect(comments.count, equals: 2, "service must unwrap CommentsResponse.comments")
        try expect(comments[0].commentId, equals: "c007")
        try expect(comments[0].isResolved, equals: false)
        try expect(comments[0].type, equals: .question)
        try expect(comments[1].commentId, equals: "c008")
        try expect(comments[1].isResolved, equals: true)
        try expect(comments[1].tags, equals: ["perf", "phase2"])

        // Proves the shared iso8601 decoder is wired end-to-end:
        // a fresh JSONDecoder() without the strategy would throw here.
        // Compute the expected Date via the same formatter rather than a
        // hand-coded epoch — avoids brittle magic-number expectations.
        let iso = ISO8601DateFormatter()
        let expected = try expectNotNilUnwrap(iso.date(from: "2026-04-06T01:00:00Z"))
        try expect(comments[0].timestamp.timeIntervalSince1970,
                   equals: expected.timeIntervalSince1970,
                   "timestamp must decode as iso8601 Date — 2026-04-06T01:00:00Z")
        let resolution = try expectNotNilUnwrap(comments[1].resolution)
        try expect(resolution.by, equals: "mdpal-cli")

        // Nested Date inside Resolution — proves the shared iso8601
        // decoder reaches nested structures, not just the top level.
        let expectedResolutionTimestamp = try expectNotNilUnwrap(
            iso.date(from: "2026-04-06T02:00:00Z")
        )
        try expect(resolution.timestamp.timeIntervalSince1970,
                   equals: expectedResolutionTimestamp.timeIntervalSince1970,
                   "nested resolution.timestamp must also decode as iso8601 Date")

        // argv contract: ["comments", <bundle>]
        try expect(runner.lastArgs ?? [], equals: ["comments", "/abs/path/design.mdpal"],
                   "argv must be ['comments', <bundle-path>] per dispatch #23")
        try expectNil(runner.lastStdin)
    }
}

func testRealCLIServiceListCommentsHandlesEmpty() async throws {
    let emptyJSON = """
    { "comments": [], "count": 0, "filters": { "section": null, "type": null, "resolved": null } }
    """
    let canned = ProcessResult(
        exitCode: 0,
        stdout: Data(emptyJSON.utf8),
        stderr: Data()
    )
    try await withRealCLIServiceForTesting(result: canned) { svc, _ in
        let comments = try await svc.listComments(bundle: BundlePath("/tmp/empty.mdpal"))
        try expect(comments.count, equals: 0)
    }
}

func testRealCLIServiceListCommentsMapsNonZeroExitToExecutionFailed() async throws {
    let canned = ProcessResult(
        exitCode: 1,
        stdout: Data(),
        stderr: Data("mdpal: bundle read failure\n".utf8)
    )
    try await withRealCLIServiceForTesting(result: canned) { svc, _ in
        do {
            _ = try await svc.listComments(bundle: BundlePath("/tmp/bundle.mdpal"))
            throw TestFailure(message: "Expected executionFailed", file: #file, line: #line)
        } catch let CLIServiceError.executionFailed(exitCode, _) {
            try expect(exitCode, equals: 1)
        }
    }
}

func testRealCLIServiceListCommentsRequiresFiltersKey() async throws {
    // Pins current model requirement: CommentsResponse.filters is non-
    // optional, so a CLI payload without `filters` fails decode →
    // .parseError. If the spec or model changes to accept absent filters
    // (sensible default for no-active-filters case), this test needs to
    // be updated deliberately — guarding against silent drift.
    let noFiltersJSON = """
    { "comments": [], "count": 0 }
    """
    let canned = ProcessResult(
        exitCode: 0,
        stdout: Data(noFiltersJSON.utf8),
        stderr: Data()
    )
    try await withRealCLIServiceForTesting(result: canned) { svc, _ in
        do {
            _ = try await svc.listComments(bundle: BundlePath("/tmp/bundle.mdpal"))
            throw TestFailure(
                message: "Expected parseError — CommentsResponse.filters is currently required",
                file: #file, line: #line
            )
        } catch CLIServiceError.parseError {
            // expected — if this test starts failing, CommentsResponse.filters
            // likely became optional; update the model AND this test together.
        }
    }
}

// --- listFlags ------------------------------------------------------------

/// Dispatch #23 sample for `mdpal flags <bundle>`.
private let listFlagsHappyJSON = """
{
  "flags": [
    {
      "slug": "architecture",
      "author": "jordan",
      "note": "Needs discussion before proceeding",
      "timestamp": "2026-04-06T01:00:00Z"
    },
    {
      "slug": "testing",
      "author": "mdpal-cli",
      "note": null,
      "timestamp": "2026-04-06T02:00:00Z"
    }
  ],
  "count": 2
}
"""

func testRealCLIServiceListFlagsHappyPath() async throws {
    let canned = ProcessResult(
        exitCode: 0,
        stdout: Data(listFlagsHappyJSON.utf8),
        stderr: Data()
    )
    try await withRealCLIServiceForTesting(result: canned) { svc, runner in
        let flags = try await svc.listFlags(bundle: BundlePath("/abs/path/design.mdpal"))

        try expect(flags.count, equals: 2, "service must unwrap FlagsResponse.flags")
        try expect(flags[0].slug, equals: "architecture")
        try expect(flags[0].author, equals: "jordan")
        try expect(flags[0].note ?? "", equals: "Needs discussion before proceeding")
        try expect(flags[1].slug, equals: "testing")
        try expectNil(flags[1].note, "null note must decode to nil")

        // Date decode via shared iso8601 — 2026-04-06T01:00:00Z. Compute
        // expected via the same formatter to keep the assertion honest.
        let iso = ISO8601DateFormatter()
        let expected = try expectNotNilUnwrap(iso.date(from: "2026-04-06T01:00:00Z"))
        try expect(flags[0].timestamp.timeIntervalSince1970,
                   equals: expected.timeIntervalSince1970,
                   "timestamp must decode as iso8601 Date")

        // argv contract: ["flags", <bundle>]
        try expect(runner.lastArgs ?? [], equals: ["flags", "/abs/path/design.mdpal"],
                   "argv must be ['flags', <bundle-path>] per dispatch #23")
        try expectNil(runner.lastStdin, "flags is a read command — stdin must be nil")
    }
}

func testRealCLIServiceListFlagsHandlesEmpty() async throws {
    let emptyJSON = """
    { "flags": [], "count": 0 }
    """
    let canned = ProcessResult(
        exitCode: 0,
        stdout: Data(emptyJSON.utf8),
        stderr: Data()
    )
    try await withRealCLIServiceForTesting(result: canned) { svc, _ in
        let flags = try await svc.listFlags(bundle: BundlePath("/tmp/empty.mdpal"))
        try expect(flags.count, equals: 0)
    }
}

func testRealCLIServiceListFlagsMapsMalformedJSONToParseError() async throws {
    let canned = ProcessResult(
        exitCode: 0,
        stdout: Data("{\"flags\": not-valid }".utf8),
        stderr: Data()
    )
    try await withRealCLIServiceForTesting(result: canned) { svc, _ in
        do {
            _ = try await svc.listFlags(bundle: BundlePath("/tmp/bundle.mdpal"))
            throw TestFailure(message: "Expected parseError", file: #file, line: #line)
        } catch CLIServiceError.parseError {
            // expected
        }
    }
}

// MARK: - Phase 1B.4: RealCLIService.editSection + typed envelope mapping

private let editSectionHappyJSON = """
{
  "slug": "architecture",
  "versionHash": "f3a4b5c6",
  "versionId": "V0001.0004.20260406T0100Z",
  "bytesWritten": 1234
}
"""

private let editSectionVersionConflictStderr = """
{
  "error": "versionConflict",
  "message": "Section 'architecture' has been modified since version c9d0e1f2",
  "details": {
    "slug": "architecture",
    "expectedHash": "c9d0e1f2",
    "currentHash": "f3a4b5c6",
    "currentContent": "The updated content that someone else wrote...",
    "versionId": "V0001.0004.20260406T0100Z"
  }
}
"""

func testRealCLIServiceEditSectionHappyPath() async throws {
    let canned = ProcessResult(
        exitCode: 0,
        stdout: Data(editSectionHappyJSON.utf8),
        stderr: Data()
    )
    try await withRealCLIServiceForTesting(result: canned) { svc, runner in
        let result = try await svc.editSection(
            slug: "architecture",
            content: "New content for architecture section.",
            versionHash: "c9d0e1f2",
            bundle: BundlePath("/abs/path/design.mdpal")
        )

        try expect(result.slug, equals: "architecture")
        try expect(result.versionHash, equals: "f3a4b5c6",
                   "response versionHash is the NEW hash for subsequent edits")
        try expect(result.versionId, equals: "V0001.0004.20260406T0100Z")
        try expect(result.bytesWritten, equals: 1234)

        // argv contract: edit <slug> --version <hash> <bundle> --stdin
        try expect(runner.lastArgs ?? [],
                   equals: ["edit", "architecture", "--version", "c9d0e1f2",
                            "/abs/path/design.mdpal", "--stdin"],
                   "argv must follow dispatch #23 edit command shape")

        // Content must be forwarded on stdin (not inlined in argv).
        let expectedStdin = Data("New content for architecture section.".utf8)
        try expect(runner.lastStdin ?? Data(), equals: expectedStdin,
                   "content must be forwarded via stdin, not argv")
    }
}

func testRealCLIServiceEditSectionMapsVersionConflictEnvelope() async throws {
    // Exit 2 + structured stderr → must produce typed .versionConflict
    // (NOT .executionFailed). This proves the envelope-parsing path.
    let canned = ProcessResult(
        exitCode: 2,
        stdout: Data(),
        stderr: Data(editSectionVersionConflictStderr.utf8)
    )
    try await withRealCLIServiceForTesting(result: canned) { svc, _ in
        do {
            _ = try await svc.editSection(
                slug: "architecture",
                content: "stale update",
                versionHash: "c9d0e1f2",
                bundle: BundlePath("/tmp/bundle.mdpal")
            )
            throw TestFailure(
                message: "Expected versionConflict", file: #file, line: #line)
        } catch let CLIServiceError.versionConflict(slug, expected, current) {
            try expect(slug, equals: "architecture")
            try expect(expected, equals: "c9d0e1f2",
                       "expectedHash must carry the hash the caller supplied")
            try expect(current, equals: "f3a4b5c6",
                       "currentHash must be the fresh hash for retry")
        }
    }
}

func testRealCLIServiceEditSectionFallsThroughOnUnrecognizedEnvelope() async throws {
    // CLI emits exit != 0 with an envelope whose discriminator isn't one
    // editSection cares about. Must fall through to .executionFailed, not
    // force the unknown envelope into versionConflict.
    let unknownStderr = """
    { "error": "quotaExceeded", "message": "hit limit", "details": {"limit":"1"} }
    """
    let canned = ProcessResult(
        exitCode: 1,
        stdout: Data(),
        stderr: Data(unknownStderr.utf8)
    )
    try await withRealCLIServiceForTesting(result: canned) { svc, _ in
        do {
            _ = try await svc.editSection(
                slug: "architecture", content: "x", versionHash: "h",
                bundle: BundlePath("/tmp/b.mdpal"))
            throw TestFailure(
                message: "Expected executionFailed", file: #file, line: #line)
        } catch let CLIServiceError.executionFailed(exitCode, stderr) {
            try expect(exitCode, equals: 1)
            try expect(stderr.contains("quotaExceeded"), equals: true,
                       "raw stderr must be forwarded for diagnostics")
        }
    }
}

func testRealCLIServiceEditSectionFallsThroughOnNonEnvelopeStderr() async throws {
    // exit != 0 but stderr isn't JSON at all (e.g., /bin/sh error message).
    // Envelope decode fails; must fall through to .executionFailed.
    let canned = ProcessResult(
        exitCode: 1,
        stdout: Data(),
        stderr: Data("mdpal: bundle locked by another process\n".utf8)
    )
    try await withRealCLIServiceForTesting(result: canned) { svc, _ in
        do {
            _ = try await svc.editSection(
                slug: "architecture", content: "x", versionHash: "h",
                bundle: BundlePath("/tmp/b.mdpal"))
            throw TestFailure(message: "Expected executionFailed", file: #file, line: #line)
        } catch let CLIServiceError.executionFailed(exitCode, stderr) {
            try expect(exitCode, equals: 1)
            try expect(stderr.contains("bundle locked"), equals: true)
        }
    }
}

func testRealCLIServiceEditSectionFallsThroughOnEnvelopeMissingMessage() async throws {
    // Envelope missing required `message` field → CLIErrorResponse decode
    // fails → runCommandWithEnvelope falls through to .executionFailed
    // with raw stderr. Pins the "partial-envelope graceful-degrade" path.
    let missingMessageStderr = """
    { "error": "versionConflict", "details": { "slug": "x", "expectedHash": "a", "currentHash": "b", "currentContent": "y", "versionId": "v" } }
    """
    let canned = ProcessResult(
        exitCode: 2,
        stdout: Data(),
        stderr: Data(missingMessageStderr.utf8)
    )
    try await withRealCLIServiceForTesting(result: canned) { svc, _ in
        do {
            _ = try await svc.editSection(
                slug: "x", content: "y", versionHash: "a",
                bundle: BundlePath("/tmp/b.mdpal"))
            throw TestFailure(message: "Expected executionFailed", file: #file, line: #line)
        } catch let CLIServiceError.executionFailed(exitCode, _) {
            try expect(exitCode, equals: 2,
                       "partial envelope without message must fall through, not blow up")
        }
    }
}

func testRealCLIServiceEditSectionFallsThroughOnKnownButUnmappedTag() async throws {
    // Envelope has a discriminator the ERROR MODEL knows about
    // (sectionNotFound — decodes to a typed case) but that editSection's
    // mapper deliberately doesn't handle (editSection only maps
    // versionConflict). The mapper returns nil → .executionFailed.
    // Pins the "mapper-returns-nil for recognized-by-model tag" arm
    // distinct from "unknown discriminator".
    let sectionNotFoundStderr = """
    { "error": "sectionNotFound", "message": "not here",
      "details": { "slug": "gone", "availableSlugs": ["a"] } }
    """
    let canned = ProcessResult(
        exitCode: 3,
        stdout: Data(),
        stderr: Data(sectionNotFoundStderr.utf8)
    )
    try await withRealCLIServiceForTesting(result: canned) { svc, _ in
        do {
            _ = try await svc.editSection(
                slug: "x", content: "y", versionHash: "h",
                bundle: BundlePath("/tmp/b.mdpal"))
            throw TestFailure(message: "Expected executionFailed", file: #file, line: #line)
        } catch let CLIServiceError.executionFailed(exitCode, stderr) {
            try expect(exitCode, equals: 3)
            try expect(stderr.contains("sectionNotFound"), equals: true,
                       "stderr forwarded intact — mapper declined, not swallowed")
        }
    }
}

func testRealCLIServiceEditSectionMapsMalformedSuccessStdoutToParseError() async throws {
    // exit 0 but stdout isn't a valid EditResult.
    let canned = ProcessResult(
        exitCode: 0,
        stdout: Data("{ \"slug\": \"x\" }".utf8),
        stderr: Data()
    )
    try await withRealCLIServiceForTesting(result: canned) { svc, _ in
        do {
            _ = try await svc.editSection(
                slug: "x", content: "y", versionHash: "z",
                bundle: BundlePath("/tmp/b.mdpal"))
            throw TestFailure(message: "Expected parseError", file: #file, line: #line)
        } catch CLIServiceError.parseError {
            // expected
        }
    }
}

// MARK: - Phase 1B.5: RealCLIService mutations
//
// Four methods complete the CLIServiceProtocol surface: addComment,
// resolveComment, flagSection, clearFlag. All except resolveComment key
// off a slug and map sectionNotFound via the shared envelope machinery.
// Coverage rotates (happy+argv+envelope-where-applicable+one error path
// each) since runCommand / runCommandWithEnvelope are shared.

// --- addComment ----------------------------------------------------------

private let addCommentHappyJSON = """
{
  "commentId": "c007",
  "slug": "architecture",
  "type": "question",
  "author": "jordan",
  "text": "Should we use dependency injection here?",
  "context": "The system uses a section-oriented architecture...",
  "priority": "normal",
  "tags": [],
  "timestamp": "2026-04-06T01:00:00Z",
  "resolved": false,
  "resolution": null
}
"""

func testRealCLIServiceAddCommentHappyPath() async throws {
    let canned = ProcessResult(
        exitCode: 0,
        stdout: Data(addCommentHappyJSON.utf8),
        stderr: Data()
    )
    try await withRealCLIServiceForTesting(result: canned) { svc, runner in
        let comment = try await svc.addComment(
            slug: "architecture",
            bundle: BundlePath("/abs/path/design.mdpal"),
            type: .question,
            author: "jordan",
            text: "Should we use dependency injection here?",
            context: nil,
            priority: .normal,
            tags: []
        )

        try expect(comment.commentId, equals: "c007")
        try expect(comment.type, equals: .question)
        try expect(comment.author, equals: "jordan")
        try expect(comment.resolved, equals: false)

        // argv contract per dispatch #23 + mdpal-cli #579: --priority
        // always emitted, --context omitted when nil, --tag repeatable
        // (one per tag) and omitted when tags are empty.
        try expect(runner.lastArgs ?? [],
                   equals: [
                       "comment", "architecture", "/abs/path/design.mdpal",
                       "--type", "question",
                       "--author", "jordan",
                       "--text", "Should we use dependency injection here?",
                       "--priority", "normal",
                   ],
                   "argv must follow comment command; no --context when nil; no --tag when empty")
        try expectNil(runner.lastStdin, "comment is not stdin-fed")
    }
}

func testRealCLIServiceAddCommentEmitsContextAndRepeatableTagsWhenPresent() async throws {
    let canned = ProcessResult(
        exitCode: 0,
        stdout: Data(addCommentHappyJSON.utf8),
        stderr: Data()
    )
    try await withRealCLIServiceForTesting(result: canned) { svc, runner in
        _ = try await svc.addComment(
            slug: "architecture",
            bundle: BundlePath("/abs/b.mdpal"),
            type: .suggestion,
            author: "jordan",
            text: "foo",
            context: "surrounding text",
            priority: .high,
            tags: ["perf", "phase2"]
        )

        try expect(runner.lastArgs ?? [],
                   equals: [
                       "comment", "architecture", "/abs/b.mdpal",
                       "--type", "suggestion",
                       "--author", "jordan",
                       "--text", "foo",
                       "--priority", "high",
                       "--context", "surrounding text",
                       "--tag", "perf",
                       "--tag", "phase2",
                   ],
                   "repeatable --tag <value> per mdpal-cli #579 (not --tags comma-list)")
    }
}

func testRealCLIServiceAddCommentMapsSectionNotFoundEnvelope() async throws {
    let stderr = """
    { "error": "sectionNotFound", "message": "not here",
      "details": { "slug": "gone", "availableSlugs": ["a","b"] } }
    """
    let canned = ProcessResult(
        exitCode: 3, stdout: Data(), stderr: Data(stderr.utf8))
    try await withRealCLIServiceForTesting(result: canned) { svc, _ in
        do {
            _ = try await svc.addComment(
                slug: "gone", bundle: BundlePath("/b.mdpal"),
                type: .note, author: "a", text: "t",
                context: nil, priority: .normal, tags: [])
            throw TestFailure(message: "Expected sectionNotFound", file: #file, line: #line)
        } catch let CLIServiceError.sectionNotFound(slug, available) {
            try expect(slug, equals: "gone")
            try expect(available, equals: ["a", "b"])
        }
    }
}

// --- resolveComment ------------------------------------------------------

private let resolveCommentHappyJSON = """
{
  "commentId": "c007",
  "resolved": true,
  "resolution": {
    "response": "Yes, using protocol-based DI",
    "by": "mdpal-cli",
    "timestamp": "2026-04-06T02:00:00Z"
  }
}
"""

func testRealCLIServiceResolveCommentHappyPath() async throws {
    let canned = ProcessResult(
        exitCode: 0, stdout: Data(resolveCommentHappyJSON.utf8), stderr: Data())
    try await withRealCLIServiceForTesting(result: canned) { svc, runner in
        let result = try await svc.resolveComment(
            commentId: "c007",
            bundle: BundlePath("/abs/design.mdpal"),
            response: "Yes, using protocol-based DI",
            by: "mdpal-cli"
        )
        try expect(result.commentId, equals: "c007")
        try expect(result.resolved, equals: true)
        try expect(result.resolution.by, equals: "mdpal-cli")

        try expect(runner.lastArgs ?? [],
                   equals: [
                       "resolve", "c007", "/abs/design.mdpal",
                       "--response", "Yes, using protocol-based DI",
                       "--by", "mdpal-cli",
                   ])
    }
}

func testRealCLIServiceResolveCommentMapsNonZeroExitToExecutionFailed() async throws {
    let canned = ProcessResult(
        exitCode: 1, stdout: Data(),
        stderr: Data("mdpal: comment c999 not found\n".utf8))
    try await withRealCLIServiceForTesting(result: canned) { svc, _ in
        do {
            _ = try await svc.resolveComment(
                commentId: "c999", bundle: BundlePath("/b.mdpal"),
                response: "r", by: "a")
            throw TestFailure(message: "Expected executionFailed", file: #file, line: #line)
        } catch let CLIServiceError.executionFailed(exitCode, _) {
            try expect(exitCode, equals: 1)
        }
    }
}

// --- flagSection ----------------------------------------------------------

private let flagSectionHappyJSON = """
{
  "slug": "architecture",
  "flagged": true,
  "author": "jordan",
  "note": "Needs discussion before proceeding",
  "timestamp": "2026-04-06T01:00:00Z"
}
"""

func testRealCLIServiceFlagSectionHappyPath() async throws {
    let canned = ProcessResult(
        exitCode: 0, stdout: Data(flagSectionHappyJSON.utf8), stderr: Data())
    try await withRealCLIServiceForTesting(result: canned) { svc, runner in
        let result = try await svc.flagSection(
            slug: "architecture",
            bundle: BundlePath("/abs/design.mdpal"),
            author: "jordan",
            note: "Needs discussion before proceeding"
        )
        try expect(result.slug, equals: "architecture")
        try expect(result.flagged, equals: true)

        try expect(runner.lastArgs ?? [],
                   equals: [
                       "flag", "architecture", "/abs/design.mdpal",
                       "--author", "jordan",
                       "--note", "Needs discussion before proceeding",
                   ])
    }
}

func testRealCLIServiceFlagSectionOmitsNoteWhenNil() async throws {
    let canned = ProcessResult(
        exitCode: 0, stdout: Data(flagSectionHappyJSON.utf8), stderr: Data())
    try await withRealCLIServiceForTesting(result: canned) { svc, runner in
        _ = try await svc.flagSection(
            slug: "architecture", bundle: BundlePath("/b.mdpal"),
            author: "jordan", note: nil)
        try expect(runner.lastArgs ?? [],
                   equals: ["flag", "architecture", "/b.mdpal", "--author", "jordan"],
                   "--note flag omitted when value is nil (spec: absence == no note)")
    }
}

func testRealCLIServiceFlagSectionMapsSectionNotFoundEnvelope() async throws {
    let stderr = """
    { "error": "sectionNotFound", "message": "not here",
      "details": { "slug": "gone", "availableSlugs": ["x"] } }
    """
    let canned = ProcessResult(exitCode: 3, stdout: Data(), stderr: Data(stderr.utf8))
    try await withRealCLIServiceForTesting(result: canned) { svc, _ in
        do {
            _ = try await svc.flagSection(
                slug: "gone", bundle: BundlePath("/b.mdpal"),
                author: "a", note: nil)
            throw TestFailure(message: "Expected sectionNotFound", file: #file, line: #line)
        } catch CLIServiceError.sectionNotFound {
            // expected
        }
    }
}

// --- clearFlag ------------------------------------------------------------

func testRealCLIServiceClearFlagHappyPath() async throws {
    let canned = ProcessResult(
        exitCode: 0,
        stdout: Data(#"{"slug":"architecture","flagged":false}"#.utf8),
        stderr: Data())
    try await withRealCLIServiceForTesting(result: canned) { svc, runner in
        let result = try await svc.clearFlag(
            slug: "architecture",
            bundle: BundlePath("/abs/design.mdpal"))
        try expect(result.slug, equals: "architecture")
        try expect(result.flagged, equals: false)

        try expect(runner.lastArgs ?? [],
                   equals: ["clear-flag", "architecture", "/abs/design.mdpal"])
    }
}

func testRealCLIServiceClearFlagMapsSectionNotFoundEnvelope() async throws {
    let stderr = """
    { "error": "sectionNotFound", "message": "not here",
      "details": { "slug": "gone", "availableSlugs": [] } }
    """
    let canned = ProcessResult(exitCode: 3, stdout: Data(), stderr: Data(stderr.utf8))
    try await withRealCLIServiceForTesting(result: canned) { svc, _ in
        do {
            _ = try await svc.clearFlag(slug: "gone", bundle: BundlePath("/b.mdpal"))
            throw TestFailure(message: "Expected sectionNotFound", file: #file, line: #line)
        } catch CLIServiceError.sectionNotFound {
            // expected
        }
    }
}

// --- parseError symmetry across mutations ---------------------------------
// Earlier iterations each have a malformed-JSON → .parseError test. The
// mutation methods share `runCommand`/`runCommandWithEnvelope` but a
// regression in a specific response type's decoder (e.g., Comment,
// FlagResult) wouldn't fail any 1B.5 test without these.

func testRealCLIServiceAddCommentMapsMalformedJSONToParseError() async throws {
    let canned = ProcessResult(exitCode: 0, stdout: Data("{".utf8), stderr: Data())
    try await withRealCLIServiceForTesting(result: canned) { svc, _ in
        do {
            _ = try await svc.addComment(
                slug: "x", bundle: BundlePath("/b.mdpal"),
                type: .note, author: "a", text: "t",
                context: nil, priority: .normal, tags: [])
            throw TestFailure(message: "Expected parseError", file: #file, line: #line)
        } catch CLIServiceError.parseError {
            // expected
        }
    }
}

func testRealCLIServiceResolveCommentMapsMalformedJSONToParseError() async throws {
    let canned = ProcessResult(exitCode: 0, stdout: Data("not json".utf8), stderr: Data())
    try await withRealCLIServiceForTesting(result: canned) { svc, _ in
        do {
            _ = try await svc.resolveComment(
                commentId: "c1", bundle: BundlePath("/b.mdpal"),
                response: "r", by: "a")
            throw TestFailure(message: "Expected parseError", file: #file, line: #line)
        } catch CLIServiceError.parseError {
            // expected
        }
    }
}

func testRealCLIServiceFlagSectionMapsMalformedJSONToParseError() async throws {
    let canned = ProcessResult(exitCode: 0, stdout: Data("{\"slug\":}".utf8), stderr: Data())
    try await withRealCLIServiceForTesting(result: canned) { svc, _ in
        do {
            _ = try await svc.flagSection(
                slug: "x", bundle: BundlePath("/b.mdpal"),
                author: "a", note: nil)
            throw TestFailure(message: "Expected parseError", file: #file, line: #line)
        } catch CLIServiceError.parseError {
            // expected
        }
    }
}

func testRealCLIServiceClearFlagMapsMalformedJSONToParseError() async throws {
    let canned = ProcessResult(exitCode: 0, stdout: Data("garbage".utf8), stderr: Data())
    try await withRealCLIServiceForTesting(result: canned) { svc, _ in
        do {
            _ = try await svc.clearFlag(slug: "x", bundle: BundlePath("/b.mdpal"))
            throw TestFailure(message: "Expected parseError", file: #file, line: #line)
        } catch CLIServiceError.parseError {
            // expected
        }
    }
}

func testRealCLIServiceAddCommentFiltersEmptyTags() async throws {
    // `tags: [""]` is a common mistake source (from parsing a trailing
    // comma or empty input). Must not render as `--tag ""` for any entry.
    let canned = ProcessResult(
        exitCode: 0, stdout: Data(addCommentHappyJSON.utf8), stderr: Data())
    try await withRealCLIServiceForTesting(result: canned) { svc, runner in
        _ = try await svc.addComment(
            slug: "architecture", bundle: BundlePath("/b.mdpal"),
            type: .note, author: "a", text: "t",
            context: nil, priority: .normal, tags: ["", "real", ""])
        let argv = runner.lastArgs ?? []
        try expect(argv.contains("--tag"), equals: true,
                   "non-empty tag must still produce --tag real")
        // The only --tag entry should be the "real" one; empty tags dropped.
        let tagIndices = argv.indices.filter { argv[$0] == "--tag" }
        try expect(tagIndices.count, equals: 1, "exactly one --tag for one real tag")
        try expect(argv[tagIndices[0] + 1], equals: "real",
                   "empty-string tags must be dropped, not rendered as --tag ''")
    }
}

// MARK: - Phase 1B.6: service selection + housekeeping

// --- CLIServiceFactory ---------------------------------------------------

func testCLIServiceFactoryPicksMockWhenMDPALMockIsTruthy() throws {
    for value in ["1", "true", "TRUE", "yes", "on"] {
        let (service, resolution) = CLIServiceFactory.make(
            environment: ["MDPAL_MOCK": value, "PATH": "/nonexistent"]
        )
        try expect(service is MockCLIService, equals: true,
                   "MDPAL_MOCK=\(value) must pick MockCLIService")
        try expect(resolution, equals: .mockRequested,
                   "MDPAL_MOCK=\(value) must report .mockRequested")
    }
}

func testCLIServiceFactoryPicksRealWhenBinaryAvailable() throws {
    let dir = try makeTempDirWithMdpal()
    defer { try? FileManager.default.removeItem(atPath: dir) }
    let bin = (dir as NSString).appendingPathComponent("mdpal")

    let (service, resolution) = CLIServiceFactory.make(
        environment: ["MDPAL_BIN": bin, "PATH": "/nonexistent"]
    )
    try expect(service is RealCLIService, equals: true,
               "binary on MDPAL_BIN must produce RealCLIService")
    try expect(resolution, equals: .real(executablePath: bin))
}

func testCLIServiceFactoryFallsBackToMockWhenCLINotFound() throws {
    let (service, resolution) = CLIServiceFactory.make(
        environment: ["PATH": "/definitely/nowhere", "HOME": "/tmp"]
    )
    try expect(service is MockCLIService, equals: true,
               "missing CLI must fall back to Mock, not crash")
    if case .mockFallback(let reason) = resolution {
        try expect(reason.contains("mdpal"), equals: true,
                   "fallback reason must be diagnostic")
    } else {
        throw TestFailure(message: "Expected .mockFallback, got \(resolution)",
                          file: #file, line: #line)
    }
}

func testCLIServiceFactoryEmptyMockVarDoesNotForceMock() throws {
    // Empty MDPAL_MOCK="" (e.g., inherited-but-unset-in-shell) must NOT
    // trigger Mock — only truthy values opt in.
    let dir = try makeTempDirWithMdpal()
    defer { try? FileManager.default.removeItem(atPath: dir) }
    let bin = (dir as NSString).appendingPathComponent("mdpal")

    let (service, _) = CLIServiceFactory.make(
        environment: ["MDPAL_MOCK": "", "MDPAL_BIN": bin, "PATH": "/nonexistent"]
    )
    try expect(service is RealCLIService, equals: true,
               "empty MDPAL_MOCK must not trigger Mock — only truthy values opt in")
}

// --- stderr sanitization for UI ------------------------------------------

func testProcessResultSanitizeStripsAnsiAndControlChars() throws {
    // Simulated stderr with ANSI CSI + control chars.
    let raw = "\u{1B}[31mError\u{1B}[0m: \u{07}missing\t\"file\"\n\u{1B}[2J\u{1B}[H"
    let result = ProcessResult(
        exitCode: 1,
        stdout: Data(),
        stderr: Data(raw.utf8)
    )
    let ui = result.stderrStringForUI
    try expect(ui.contains("\u{1B}["), equals: false,
               "ANSI CSI sequences must be stripped")
    try expect(ui.contains("\u{07}"), equals: false,
               "C0 control chars (BEL) must be stripped")
    try expect(ui.contains("Error"), equals: true,
               "visible text must survive sanitization")
    try expect(ui.contains("missing\t\"file\""), equals: true,
               "tab and quote must survive")
    try expect(ui.contains("\n"), equals: true, "newline preserved")
}

func testProcessResultSanitizeCapsLength() throws {
    let raw = String(repeating: "A", count: 10000)
    let result = ProcessResult(
        exitCode: 1, stdout: Data(), stderr: Data(raw.utf8))
    let ui = result.stderrStringForUI
    // Expected = 4096 prefix + "… (truncated)" suffix = 4096 + 14 chars.
    try expect(ui.count, equals: 4096 + "… (truncated)".count,
               "UI stderr must be exactly prefix(4096) + '… (truncated)'")
    try expect(ui.hasSuffix("(truncated)"), equals: true,
               "truncation marker signals the cap")
}

// --- DefaultProcessRunner size cap ---------------------------------------

func testDefaultProcessRunnerRespectsMaxOutputBytes() async throws {
    // Ask for 512 KB but cap at 100 KB — emitted-minus-received should
    // be >0 (truncated) and the returned stdout must match the cap.
    let script = try makeTempScript(body: "yes 'A' | head -c 524288")
    defer { try? FileManager.default.removeItem(atPath: (script as NSString).deletingLastPathComponent) }

    let runner = DefaultProcessRunner(maxOutputBytes: 100 * 1024)
    let result = try await runner.run(executable: script, args: [], stdin: nil)

    try expect(result.stdout.count, equals: 100 * 1024,
               "stdout must be capped at maxOutputBytes")
    try expect(result.stderrString.contains("stdout truncated"), equals: true,
               "truncation marker must be appended to stderr")
}

// MARK: - Phase 1C.1: CLIServiceBanner message derivation

func testResolutionBannerMessageIsNilForReal() throws {
    let resolution: CLIServiceFactory.Resolution = .real(executablePath: "/usr/local/bin/mdpal")
    try expectNil(resolution.bannerMessage,
                  "production path must not surface a banner message")
}

func testResolutionBannerMessageMentionsMockWhenRequested() throws {
    let resolution: CLIServiceFactory.Resolution = .mockRequested
    let message = try expectNotNilUnwrap(resolution.bannerMessage)
    try expect(message.contains("mock mode"), equals: true,
               "mockRequested banner must tell the user they're in mock mode")
    try expect(message.contains("MDPAL_MOCK"), equals: true,
               "message must name the env var so the user can unset it")
}

func testResolutionBannerMessageIncludesReasonOnFallback() throws {
    let reason = "no `mdpal` binary found on MDPAL_BIN, PATH, or fallbacks"
    let resolution: CLIServiceFactory.Resolution = .mockFallback(reason: reason)
    let message = try expectNotNilUnwrap(resolution.bannerMessage)
    try expect(message.contains("not found"), equals: true,
               "fallback banner must name the problem")
    try expect(message.contains(reason), equals: true,
               "fallback banner must include the diagnostic reason verbatim")
}

// MARK: - Runner

@main
struct TestRunner {
    static func main() async {
        var passed = 0
        var failed = 0

        func run(_ name: String, _ test: () throws -> Void) {
            do {
                try test()
                print("  \u{2713} \(name)")
                passed += 1
            } catch {
                print("  \u{2717} \(name): \(error)")
                failed += 1
            }
        }

        func runAsync(_ name: String, _ test: () async throws -> Void) async {
            do {
                try await test()
                print("  \u{2713} \(name)")
                passed += 1
            } catch {
                print("  \u{2717} \(name): \(error)")
                failed += 1
            }
        }

        print("Running MarkdownPalApp tests...\n")

        print("SectionTreeNode:")
        run("SectionTreeNode decodes from CLI JSON", testSectionTreeNodeDecodesFromCLIJSON)
        run("SectionTreeNode decodes 2-level tree", testSectionTreeNodeDecodes2LevelTree)
        run("SectionTreeNode decodes 3-level tree", testSectionTreeNodeDecodes3LevelTree)

        print("\nSectionsResponse:")
        run("SectionsResponse decodes from CLI JSON", testSectionsResponseDecodesFromCLIJSON)
        run("flattened() returns depth-first order", testFlattenedReturnsDepthFirstOrder)
        run("flattened() on leaf returns just self", testFlattenedOnLeafReturnsJustSelf)

        print("\nSection (Read Response):")
        run("Section decodes from CLI JSON", testSectionDecodesFromCLIJSON)

        print("\nComment Model:")
        run("Resolved comment detection", testResolvedCommentDetection)
        run("Comment decodes from CLI JSON", testCommentDecodesFromCLIJSON)
        run("Comment with resolution decodes from CLI JSON", testCommentWithResolutionDecodesFromCLIJSON)
        run("Comment with nil context decodes", testCommentWithNilContextDecodes)

        print("\nFlag Model:")
        run("Flag decodes from CLI JSON", testFlagDecodesFromCLIJSON)
        run("Flag with nil note decodes correctly", testFlagWithNilNoteDecodesCorrectly)

        print("\nResponse Types:")
        run("EditResult decodes from CLI JSON", testEditResultDecodesFromCLIJSON)
        run("ResolveResult decodes from CLI JSON", testResolveResultDecodesFromCLIJSON)
        run("FlagResult decodes from CLI JSON", testFlagResultDecodesFromCLIJSON)
        run("ClearFlagResult decodes from CLI JSON", testClearFlagResultDecodesFromCLIJSON)

        print("\nError Types:")
        run("CLIErrorResponse decodes from JSON", testCLIErrorResponseDecodesFromJSON)
        run("CLIError with details decodes from JSON", testCLIErrorWithDetailsDecodesFromJSON)

        print("\nMock CLI Service:")
        await runAsync("listSections returns flattened mock data", testListSectionsReturnsFlattenedMockData)
        await runAsync("readSection returns content for valid slug", testReadSectionReturnsContentForValidSlug)
        await runAsync("readSection throws for invalid slug", testReadSectionThrowsForInvalidSlug)
        await runAsync("editSection enforces version hash", testEditSectionEnforcesVersionHash)
        await runAsync("editSection returns EditResult", testEditSectionReturnsEditResult)
        await runAsync("addComment returns mock comment", testAddCommentReturnsMockComment)
        await runAsync("resolveComment returns mock result", testResolveCommentReturnsMockResult)
        await runAsync("flagSection returns mock result", testFlagSectionReturnsMockResult)
        await runAsync("clearFlag returns mock result", testClearFlagReturnsMockResult)

        print("\nDocumentModel:")
        await runAsync("loadSections populates state", testDocumentModelLoadSectionsPopulatesState)
        await runAsync("loadComments and loadFlags populate state", testDocumentModelLoadCommentsAndFlagsPopulatesState)
        await runAsync("addComment appends to state", testDocumentModelAddCommentAppendsToState)
        await runAsync("resolveComment triggers reload", testDocumentModelResolveCommentTriggersReload)
        await runAsync("toggleFlag adds then clears", testDocumentModelToggleFlagAddsThenClearsInSequence)
        await runAsync("flagSection reflected in state", testDocumentModelFlagSectionIsReflectedInState)
        await runAsync("lastError set on load failure", testDocumentModelLastErrorSetOnLoadFailure)
        await runAsync("lastError cleared on subsequent success", testDocumentModelLastErrorClearedOnSuccess)
        await runAsync("editSection happy path", testDocumentModelEditSectionHappyPath)
        await runAsync("editSection throws on stale version hash", testDocumentModelEditSectionThrowsOnStaleVersionHash)
        await runAsync("editSection success clears lastError", testDocumentModelEditSectionClearsLastErrorOnSuccess)
        await runAsync("addComment success clears lastError", testDocumentModelAddCommentClearsLastErrorOnSuccess)
        await runAsync("selectSection failure sets lastError", testDocumentModelSelectSectionFailureSetsLastError)

        print("\nSelectionContext (1A.5):")
        run("nil clipboard returns nil", testSelectionContextNilClipboardReturnsNil)
        run("empty clipboard returns nil", testSelectionContextEmptyClipboardReturnsNil)
        run("non-matching clipboard returns nil", testSelectionContextNonMatchingClipboardReturnsNil)
        run("matching clipboard returns trimmed", testSelectionContextMatchingClipboardReturnsTrimmed)
        run("substring across words matches", testSelectionContextSubstringMatchAcrossWords)

        print("\nCLIProcess + RealCLIService (Phase 1B.1):")
        run("CLIBinaryResolver honors MDPAL_BIN override", testCLIBinaryResolverHonorsMDPALBinOverride)
        run("CLIBinaryResolver throws when MDPAL_BIN points nowhere", testCLIBinaryResolverThrowsWhenMDPALBinPointsNowhere)
        run("CLIBinaryResolver finds binary on PATH", testCLIBinaryResolverFindsBinaryOnPATH)
        run("CLIBinaryResolver throws when nothing found", testCLIBinaryResolverThrowsWhenNothingFound)
        run("CLIBinaryResolver PATH wins over fallbacks", testCLIBinaryResolverPATHWinsOverFallbacks)
        run("CLIBinaryResolver MDPAL_BIN wins over PATH", testCLIBinaryResolverMDPALBinWinsOverPATH)
        await runAsync("CLIProcess.run delegates to runner", testCLIProcessRunDelegatesToRunner)
        run("RealCLIService init fails cleanly when binary missing", testRealCLIServiceInitFailsCleanlyWhenBinaryMissing)
        run("RealCLIService init succeeds when binary resolves", testRealCLIServiceInitSucceedsWhenBinaryResolves)
        await runAsync("DefaultProcessRunner captures stdout and exit code", testDefaultProcessRunnerCapturesStdoutAndExitCode)
        await runAsync("DefaultProcessRunner captures stderr and non-zero exit", testDefaultProcessRunnerCapturesStderrAndNonZeroExit)
        await runAsync("DefaultProcessRunner forwards stdin to child", testDefaultProcessRunnerForwardsStdinToChild)
        await runAsync("DefaultProcessRunner handles large stdout without deadlock", testDefaultProcessRunnerHandlesLargeStdoutWithoutDeadlock)
        await runAsync("DefaultProcessRunner throws when executable missing", testDefaultProcessRunnerThrowsWhenExecutableMissing)

        print("\nRealCLIService.listSections (Phase 1B.2):")
        await runAsync("listSections happy path flattens 3-level tree depth-first", testRealCLIServiceListSectionsHappyPath)
        await runAsync("listSections passes bundle path as argv", testRealCLIServiceListSectionsPassesBundlePathAsArgv)
        await runAsync("listSections handles empty sections", testRealCLIServiceListSectionsHandlesEmptySections)
        await runAsync("listSections maps non-zero exit to executionFailed", testRealCLIServiceListSectionsMapsNonZeroExitToExecutionFailed)
        await runAsync("listSections maps malformed JSON to parseError", testRealCLIServiceListSectionsMapsMalformedJSONToParseError)
        await runAsync("listSections maps missing required field to parseError", testRealCLIServiceListSectionsMapsMissingRequiredFieldToParseError)

        print("\nRealCLIService read-side (Phase 1B.3):")
        await runAsync("readSection happy path decodes Section payload", testRealCLIServiceReadSectionHappyPath)
        await runAsync("readSection maps sectionNotFound envelope (1B.4)", testRealCLIServiceReadSectionMapsSectionNotFoundEnvelope)
        await runAsync("readSection falls through on non-envelope stderr", testRealCLIServiceReadSectionFallsThroughOnNonEnvelopeStderr)
        await runAsync("readSection passes path-style slug as argv", testRealCLIServiceReadSectionPassesPathStyleSlugAsArgv)
        await runAsync("readSection maps missing required field to parseError", testRealCLIServiceReadSectionMapsMissingRequiredFieldToParseError)
        await runAsync("readSection maps malformed JSON to parseError", testRealCLIServiceReadSectionMapsMalformedJSONToParseError)
        await runAsync("listComments happy path unwraps + iso8601 dates", testRealCLIServiceListCommentsHappyPath)
        await runAsync("listComments handles empty", testRealCLIServiceListCommentsHandlesEmpty)
        await runAsync("listComments maps non-zero exit to executionFailed", testRealCLIServiceListCommentsMapsNonZeroExitToExecutionFailed)
        await runAsync("listComments requires filters key (pinned)", testRealCLIServiceListCommentsRequiresFiltersKey)
        await runAsync("listFlags happy path unwraps + iso8601 dates", testRealCLIServiceListFlagsHappyPath)
        await runAsync("listFlags handles empty", testRealCLIServiceListFlagsHandlesEmpty)
        await runAsync("listFlags maps malformed JSON to parseError", testRealCLIServiceListFlagsMapsMalformedJSONToParseError)

        print("\nRealCLIService.editSection + envelope (Phase 1B.4):")
        await runAsync("editSection happy path decodes EditResult + argv + stdin", testRealCLIServiceEditSectionHappyPath)
        await runAsync("editSection maps versionConflict envelope to typed error", testRealCLIServiceEditSectionMapsVersionConflictEnvelope)
        await runAsync("editSection falls through on unrecognized envelope kind", testRealCLIServiceEditSectionFallsThroughOnUnrecognizedEnvelope)
        await runAsync("editSection falls through on non-envelope stderr", testRealCLIServiceEditSectionFallsThroughOnNonEnvelopeStderr)
        await runAsync("editSection falls through on envelope missing message", testRealCLIServiceEditSectionFallsThroughOnEnvelopeMissingMessage)
        await runAsync("editSection falls through on known-but-unmapped tag", testRealCLIServiceEditSectionFallsThroughOnKnownButUnmappedTag)
        await runAsync("editSection maps malformed stdout to parseError", testRealCLIServiceEditSectionMapsMalformedSuccessStdoutToParseError)

        print("\nCLIErrorResponse envelope (Phase 1B.4):")
        run("sectionNotFound envelope decodes", testCLIErrorSectionNotFoundDecodes)
        run("bundleConflict envelope decodes", testCLIErrorBundleConflictDecodes)
        run("unknown kind falls back to generic", testCLIErrorUnknownKindFallsBackToGeneric)

        print("\nRealCLIService mutations (Phase 1B.5):")
        await runAsync("addComment happy path + argv (minimal)", testRealCLIServiceAddCommentHappyPath)
        await runAsync("addComment emits --context and repeatable --tag when present", testRealCLIServiceAddCommentEmitsContextAndRepeatableTagsWhenPresent)
        await runAsync("addComment maps sectionNotFound envelope", testRealCLIServiceAddCommentMapsSectionNotFoundEnvelope)
        await runAsync("resolveComment happy path + argv", testRealCLIServiceResolveCommentHappyPath)
        await runAsync("resolveComment maps non-zero exit to executionFailed", testRealCLIServiceResolveCommentMapsNonZeroExitToExecutionFailed)
        await runAsync("flagSection happy path + argv", testRealCLIServiceFlagSectionHappyPath)
        await runAsync("flagSection omits --note when nil", testRealCLIServiceFlagSectionOmitsNoteWhenNil)
        await runAsync("flagSection maps sectionNotFound envelope", testRealCLIServiceFlagSectionMapsSectionNotFoundEnvelope)
        await runAsync("clearFlag happy path + argv", testRealCLIServiceClearFlagHappyPath)
        await runAsync("clearFlag maps sectionNotFound envelope", testRealCLIServiceClearFlagMapsSectionNotFoundEnvelope)
        await runAsync("addComment filters empty tags", testRealCLIServiceAddCommentFiltersEmptyTags)
        await runAsync("addComment maps malformed JSON to parseError", testRealCLIServiceAddCommentMapsMalformedJSONToParseError)
        await runAsync("resolveComment maps malformed JSON to parseError", testRealCLIServiceResolveCommentMapsMalformedJSONToParseError)
        await runAsync("flagSection maps malformed JSON to parseError", testRealCLIServiceFlagSectionMapsMalformedJSONToParseError)
        await runAsync("clearFlag maps malformed JSON to parseError", testRealCLIServiceClearFlagMapsMalformedJSONToParseError)

        print("\nCLIServiceFactory + housekeeping (Phase 1B.6):")
        run("CLIServiceFactory picks Mock when MDPAL_MOCK is truthy", testCLIServiceFactoryPicksMockWhenMDPALMockIsTruthy)
        run("CLIServiceFactory picks Real when binary available", testCLIServiceFactoryPicksRealWhenBinaryAvailable)
        run("CLIServiceFactory falls back to Mock when CLI missing", testCLIServiceFactoryFallsBackToMockWhenCLINotFound)
        run("CLIServiceFactory empty MDPAL_MOCK does not force Mock", testCLIServiceFactoryEmptyMockVarDoesNotForceMock)
        run("ProcessResult.sanitize strips ANSI + control chars", testProcessResultSanitizeStripsAnsiAndControlChars)
        run("ProcessResult.sanitize caps length with marker", testProcessResultSanitizeCapsLength)
        await runAsync("DefaultProcessRunner respects maxOutputBytes", testDefaultProcessRunnerRespectsMaxOutputBytes)

        print("\nCLIServiceBanner message derivation (Phase 1C.1):")
        run("Resolution.bannerMessage is nil for real", testResolutionBannerMessageIsNilForReal)
        run("Resolution.bannerMessage mentions mock when requested", testResolutionBannerMessageMentionsMockWhenRequested)
        run("Resolution.bannerMessage includes reason on fallback", testResolutionBannerMessageIncludesReasonOnFallback)

        print("\n\(passed + failed) tests: \(passed) passed, \(failed) failed")

        if failed > 0 {
            _Exit(1)
        }
    }
}
