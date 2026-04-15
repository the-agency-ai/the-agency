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
    let json = """
    {
        "error": "SECTION_NOT_FOUND",
        "message": "Section 'nonexistent' not found"
    }
    """
    let data = json.data(using: .utf8)!
    let error = try JSONDecoder().decode(CLIErrorResponse.self, from: data)

    try expect(error.error, equals: "SECTION_NOT_FOUND")
    try expect(error.message, equals: "Section 'nonexistent' not found")
    try expectNil(error.details)
}

func testCLIErrorWithDetailsDecodesFromJSON() throws {
    let json = """
    {
        "error": "VERSION_CONFLICT",
        "message": "Section was modified",
        "details": {
            "type": "versionConflict",
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

    try expect(error.error, equals: "VERSION_CONFLICT")
    try expectNotNil(error.details)

    if case .versionConflict(let slug, let expected, let current, _, let versionId) = error.details! {
        try expect(slug, equals: "overview")
        try expect(expected, equals: "abc")
        try expect(current, equals: "def")
        try expect(versionId, equals: "v2")
    } else {
        throw TestFailure(message: "Expected versionConflict details", file: #file, line: #line)
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

        print("\nSelectionContext (1A.5):")
        run("nil clipboard returns nil", testSelectionContextNilClipboardReturnsNil)
        run("empty clipboard returns nil", testSelectionContextEmptyClipboardReturnsNil)
        run("non-matching clipboard returns nil", testSelectionContextNonMatchingClipboardReturnsNil)
        run("matching clipboard returns trimmed", testSelectionContextMatchingClipboardReturnsTrimmed)
        run("substring across words matches", testSelectionContextSubstringMatchAcrossWords)

        print("\n\(passed + failed) tests: \(passed) passed, \(failed) failed")

        if failed > 0 {
            _Exit(1)
        }
    }
}
