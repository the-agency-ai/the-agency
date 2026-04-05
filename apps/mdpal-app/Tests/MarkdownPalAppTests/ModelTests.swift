// What Problem: Tests need to run without XCTest (no full Xcode SDK available).
// Using a simple assertion-based test runner that compiles with just the
// Swift command line tools.
//
// How & Why: Standalone test functions with assert(). Each test function
// throws on failure. The test target is a regular Swift source file compiled
// by SPM's test target — but since XCTest isn't available, we use a
// lightweight approach. When full Xcode is available, these can be migrated
// to XCTest or Swift Testing.
//
// Written: 2026-04-05 during mdpal-app Phase 1 scaffold

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

// MARK: - Section Model Tests

func testSectionInfoDecodesFromCLIJSON() throws {
    let json = """
    {
        "slug": "authentication",
        "heading": "Authentication",
        "level": 1,
        "version_hash": "c7d4e9",
        "child_count": 2
    }
    """
    let data = json.data(using: .utf8)!
    let section = try JSONDecoder().decode(SectionInfo.self, from: data)

    try expect(section.slug, equals: "authentication")
    try expect(section.heading, equals: "Authentication")
    try expect(section.level, equals: 1)
    try expect(section.versionHash, equals: "c7d4e9")
    try expect(section.childCount, equals: 2)
    try expect(section.id, equals: "authentication")
}

func testSectionDecodesFromCLIJSON() throws {
    let json = """
    {
        "slug": "overview",
        "heading": "Overview",
        "level": 1,
        "content": "This is the overview.",
        "version_hash": "a3f2b1",
        "children": []
    }
    """
    let data = json.data(using: .utf8)!
    let section = try JSONDecoder().decode(Section.self, from: data)

    try expect(section.slug, equals: "overview")
    try expect(section.content, equals: "This is the overview.")
    try expectTrue(section.children.isEmpty)
}

func testSectionWithChildrenDecodesCorrectly() throws {
    let json = """
    {
        "slug": "authentication",
        "heading": "Authentication",
        "level": 1,
        "content": "Auth content.",
        "version_hash": "c7d4e9",
        "children": [
            {
                "slug": "authentication/oauth",
                "heading": "OAuth Flow",
                "level": 2,
                "version_hash": "f1a2b3",
                "child_count": 0
            }
        ]
    }
    """
    let data = json.data(using: .utf8)!
    let section = try JSONDecoder().decode(Section.self, from: data)

    try expect(section.children.count, equals: 1)
    try expect(section.children[0].slug, equals: "authentication/oauth")
}

// MARK: - Comment Model Tests

func testCommentStalenessDetection() throws {
    let comment = Comment(
        id: "c001", type: .question, author: "claude",
        sectionSlug: "auth", versionHash: "abc123",
        timestamp: Date(), context: "context", text: "question?",
        resolution: nil
    )

    try expectFalse(comment.isStale(currentSectionHash: "abc123"))
    try expectTrue(comment.isStale(currentSectionHash: "def456"))
}

func testResolvedCommentDetection() throws {
    let unresolved = Comment(
        id: "c001", type: .question, author: "claude",
        sectionSlug: "auth", versionHash: "abc123",
        timestamp: Date(), context: "ctx", text: "q?",
        resolution: nil
    )

    let resolved = Comment(
        id: "c002", type: .suggestion, author: "jordan",
        sectionSlug: "data", versionHash: "def456",
        timestamp: Date(), context: "ctx", text: "suggestion",
        resolution: Resolution(
            response: "agreed",
            resolvedDate: Date(),
            resolvedBy: "jordan"
        )
    )

    try expectFalse(unresolved.isResolved)
    try expectTrue(resolved.isResolved)
}

func testCommentDecodesFromCLIJSON() throws {
    let json = """
    {
        "id": "c001",
        "type": "question",
        "author": "claude",
        "section_slug": "authentication",
        "version_hash": "c7d4e9",
        "timestamp": "2026-03-10T14:00:00Z",
        "context": "OAuth2 bearer token",
        "text": "Does this handle refresh?",
        "resolution": null,
        "priority": "high",
        "tags": []
    }
    """
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    let data = json.data(using: .utf8)!
    let comment = try decoder.decode(Comment.self, from: data)

    try expect(comment.id, equals: "c001")
    try expect(comment.type, equals: .question)
    try expect(comment.sectionSlug, equals: "authentication")
    try expect(comment.priority, equals: .high)
    try expectFalse(comment.isResolved)
}

// MARK: - Flag Model Tests

func testFlagDecodesFromCLIJSON() throws {
    let json = """
    {
        "section_slug": "authentication/oauth",
        "note": "Discuss OAuth flow",
        "author": "jordan",
        "timestamp": "2026-03-10T14:00:00Z"
    }
    """
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    let data = json.data(using: .utf8)!
    let flag = try decoder.decode(Flag.self, from: data)

    try expect(flag.sectionSlug, equals: "authentication/oauth")
    try expect(flag.note, equals: "Discuss OAuth flow")
    try expect(flag.id, equals: "authentication/oauth")
}

func testFlagWithNilNoteDecodesCorrectly() throws {
    let json = """
    {
        "section_slug": "open-questions",
        "note": null,
        "author": "claude",
        "timestamp": "2026-03-11T17:30:00Z"
    }
    """
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    let data = json.data(using: .utf8)!
    let flag = try decoder.decode(Flag.self, from: data)

    try expectNil(flag.note)
}

// MARK: - Mock CLI Service Tests

func testListSectionsReturnsMockData() async throws {
    let service = MockCLIService()
    let sections = try await service.listSections(content: "")

    try expect(sections.count, equals: 8)
    try expect(sections[0].slug, equals: "overview")
    try expect(sections[1].slug, equals: "authentication")
    try expect(sections[1].childCount, equals: 2)
}

func testReadSectionReturnsContentForValidSlug() async throws {
    let service = MockCLIService()
    let section = try await service.readSection(slug: "authentication", content: "")

    try expect(section.heading, equals: "Authentication")
    try expect(section.children.count, equals: 2)
    try expectFalse(section.content.isEmpty)
}

func testReadSectionThrowsForInvalidSlug() async throws {
    try await expectThrows(CLIServiceError.self) {
        let service = MockCLIService()
        _ = try await service.readSection(slug: "nonexistent", content: "")
    }
}

func testEditSectionEnforcesVersionHash() async throws {
    try await expectThrows(CLIServiceError.self) {
        let service = MockCLIService()
        _ = try await service.editSection(
            slug: "overview", newContent: "new content",
            versionHash: "wrong_hash", documentContent: ""
        )
    }
}

func testEditSectionSucceedsWithCorrectHash() async throws {
    let service = MockCLIService()
    let updated = try await service.editSection(
        slug: "overview", newContent: "Updated overview content.",
        versionHash: "a3f2b1", documentContent: ""
    )

    try expect(updated.content, equals: "Updated overview content.")
    try expectFalse(updated.versionHash == "a3f2b1", "hash should change")
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
                print("  ✓ \(name)")
                passed += 1
            } catch {
                print("  ✗ \(name): \(error)")
                failed += 1
            }
        }

        func runAsync(_ name: String, _ test: () async throws -> Void) async {
            do {
                try await test()
                print("  ✓ \(name)")
                passed += 1
            } catch {
                print("  ✗ \(name): \(error)")
                failed += 1
            }
        }

        print("Running MarkdownPalApp tests...\n")

        print("Section Model:")
        run("SectionInfo decodes from CLI JSON", testSectionInfoDecodesFromCLIJSON)
        run("Section decodes from CLI JSON", testSectionDecodesFromCLIJSON)
        run("Section with children decodes correctly", testSectionWithChildrenDecodesCorrectly)

        print("\nComment Model:")
        run("Comment staleness detection", testCommentStalenessDetection)
        run("Resolved comment detection", testResolvedCommentDetection)
        run("Comment decodes from CLI JSON", testCommentDecodesFromCLIJSON)

        print("\nFlag Model:")
        run("Flag decodes from CLI JSON", testFlagDecodesFromCLIJSON)
        run("Flag with nil note decodes correctly", testFlagWithNilNoteDecodesCorrectly)

        print("\nMock CLI Service:")
        await runAsync("listSections returns mock data", testListSectionsReturnsMockData)
        await runAsync("readSection returns content for valid slug", testReadSectionReturnsContentForValidSlug)
        await runAsync("readSection throws for invalid slug", testReadSectionThrowsForInvalidSlug)
        await runAsync("editSection enforces version hash", testEditSectionEnforcesVersionHash)
        await runAsync("editSection succeeds with correct hash", testEditSectionSucceedsWithCorrectHash)

        print("\n\(passed + failed) tests: \(passed) passed, \(failed) failed")

        if failed > 0 {
            _Exit(1)
        }
    }
}
