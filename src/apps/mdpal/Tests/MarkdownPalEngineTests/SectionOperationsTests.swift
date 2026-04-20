// What Problem: Iteration 1.3 adds section, comment, and flag operations
// on Document. Each operation needs unit tests covering the happy path,
// optimistic concurrency, error paths, and the new path-style addressing.
//
// How & Why: Swift Testing framework. Tests exercise the public Document
// API directly — no mocks. Fixture documents are inline strings. Each test
// is focused on one behavior and uses exact equality where possible.
//
// Written: 2026-04-07 during mdpal-cli session (iteration 1.3)

import Testing
import Foundation
@testable import MarkdownPalEngine

// MARK: - Helpers

private let sampleDocument = """
# Introduction

Intro body.

## Background

Background body.

## Goals

Goals body.

# Methods

Methods body.

## OAuth

OAuth flow body.
"""

private func makeDoc(_ content: String = sampleDocument) throws -> Document {
    try Document(content: content, parser: MarkdownParser())
}

// MARK: - listSections

@Test func listSectionsFlat() throws {
    let doc = try makeDoc()
    let sections = doc.listSections()

    // Expect 5 sections: intro, intro/background, intro/goals, methods, methods/oauth
    #expect(sections.count == 5)
    #expect(sections.map { $0.slug } == [
        "introduction",
        "introduction/background",
        "introduction/goals",
        "methods",
        "methods/oauth",
    ])
    #expect(sections[0].level == 1)
    #expect(sections[0].heading == "Introduction")
    #expect(sections[0].childCount == 2)
    #expect(sections[1].level == 2)
    #expect(sections[1].childCount == 0)
    #expect(sections[3].level == 1)
    #expect(sections[3].childCount == 1)
}

@Test func listSectionsEmpty() throws {
    let doc = try makeDoc("Just some text, no headings.")
    #expect(doc.listSections().isEmpty)
}

// MARK: - readSection

@Test func readSectionTopLevel() throws {
    let doc = try makeDoc()
    let section = try doc.readSection("introduction")
    #expect(section.slug == "introduction")
    #expect(section.heading == "Introduction")
    #expect(section.level == 1)
    #expect(section.content == "Intro body.")
    #expect(section.children.count == 2)
    #expect(section.children[0].slug == "introduction/background")
    #expect(section.lineRange == nil)
}

@Test func readSectionNested() throws {
    let doc = try makeDoc()
    let section = try doc.readSection("methods/oauth")
    #expect(section.slug == "methods/oauth")
    #expect(section.heading == "OAuth")
    #expect(section.level == 2)
    #expect(section.content == "OAuth flow body.")
    #expect(section.children.isEmpty)
}

@Test func readSectionDeeplyNested() throws {
    let content = """
    # L1

    L1 body.

    ## L2

    L2 body.

    ### L3

    L3 body.

    #### L4

    L4 body.
    """
    let doc = try Document(content: content, parser: MarkdownParser())
    let section = try doc.readSection("l1/l2/l3/l4")
    #expect(section.slug == "l1/l2/l3/l4")
    #expect(section.heading == "L4")
    #expect(section.level == 4)
    #expect(section.content == "L4 body.")
}

@Test func readSectionSlugNormalization() throws {
    let content = """
    # My Section!

    body.

    ## **Bold** Heading

    body2.
    """
    let doc = try Document(content: content, parser: MarkdownParser())
    let s1 = try doc.readSection("my-section")
    #expect(s1.heading == "My Section!")
    let s2 = try doc.readSection("my-section/bold-heading")
    #expect(s2.heading == "Bold Heading")
}

@Test func listSectionsSiblingCollisionDisambiguation() throws {
    let content = """
    # Setup

    First setup.

    # Setup

    Second setup.

    # Setup

    Third setup.
    """
    let doc = try Document(content: content, parser: MarkdownParser())
    let slugs = doc.listSections().map { $0.slug }
    #expect(slugs == ["setup", "setup-1", "setup-2"])

    // Each is independently readable.
    #expect(try doc.readSection("setup").content == "First setup.")
    #expect(try doc.readSection("setup-1").content == "Second setup.")
    #expect(try doc.readSection("setup-2").content == "Third setup.")
}

@Test func readSectionVersionHashStableUntilEdit() throws {
    let doc = try makeDoc()
    let s1 = try doc.readSection("introduction")
    let s2 = try doc.readSection("introduction")
    #expect(s1.versionHash == s2.versionHash)

    // Hash CHANGES after an edit.
    _ = try doc.editSection("introduction", newContent: "New body.", versionHash: s1.versionHash)
    let s3 = try doc.readSection("introduction")
    #expect(s3.versionHash != s1.versionHash)
}

@Test func readSectionNotFoundThrows() throws {
    let doc = try makeDoc()
    do {
        _ = try doc.readSection("nonexistent")
        Issue.record("Expected throw")
    } catch let EngineError.sectionNotFound(slug, available) {
        #expect(slug == "nonexistent")
        #expect(available.contains("introduction"))
        #expect(available.contains("methods/oauth"))
    } catch {
        Issue.record("Expected sectionNotFound, got \(error)")
    }
}

// MARK: - editSection

@Test func editSectionUpdatesContent() throws {
    let doc = try makeDoc()
    let original = try doc.readSection("introduction")
    let updated = try doc.editSection(
        "introduction",
        newContent: "New introduction body.",
        versionHash: original.versionHash
    )
    #expect(updated.content == "New introduction body.")
    #expect(updated.versionHash != original.versionHash)
    // Re-reading returns the updated content.
    let reread = try doc.readSection("introduction")
    #expect(reread.content == "New introduction body.")
    // Children survive — heading and sub-sections unchanged.
    #expect(reread.children.count == 2)
}

@Test func editSectionVersionConflictThrows() throws {
    let doc = try makeDoc()
    do {
        _ = try doc.editSection(
            "introduction",
            newContent: "x",
            versionHash: "wrong-hash-value"
        )
        Issue.record("Expected throw")
    } catch let EngineError.versionConflict(slug, expected, actual, currentContent) {
        #expect(slug == "introduction")
        #expect(expected == "wrong-hash-value")
        #expect(actual != "wrong-hash-value")
        #expect(currentContent == "Intro body.")
    } catch {
        Issue.record("Expected versionConflict, got \(error)")
    }
}

@Test func editSectionNotFoundThrows() throws {
    let doc = try makeDoc()
    do {
        _ = try doc.editSection("nope", newContent: "x", versionHash: "h")
        Issue.record("Expected throw")
    } catch EngineError.sectionNotFound {
        // expected
    } catch {
        Issue.record("Expected sectionNotFound, got \(error)")
    }
}

@Test func editSectionNestedUpdatesOnlyTarget() throws {
    let doc = try makeDoc()
    let oauth = try doc.readSection("methods/oauth")
    let methodsBefore = try doc.readSection("methods")

    _ = try doc.editSection(
        "methods/oauth",
        newContent: "New OAuth body.",
        versionHash: oauth.versionHash
    )

    let oauthAfter = try doc.readSection("methods/oauth")
    let methodsAfter = try doc.readSection("methods")
    #expect(oauthAfter.content == "New OAuth body.")
    // Parent section's own body is unchanged.
    #expect(methodsAfter.content == methodsBefore.content)
    // Methods still has OAuth as child.
    #expect(methodsAfter.children.count == 1)
}

@Test func editSectionWithChildrenChildrenRemainReachable() throws {
    let doc = try makeDoc()
    let intro = try doc.readSection("introduction")
    let backgroundBefore = try doc.readSection("introduction/background")
    let goalsBefore = try doc.readSection("introduction/goals")

    _ = try doc.editSection(
        "introduction",
        newContent: "Brand new intro body.",
        versionHash: intro.versionHash
    )

    // Children are still reachable by their original slugs.
    let backgroundAfter = try doc.readSection("introduction/background")
    let goalsAfter = try doc.readSection("introduction/goals")
    #expect(backgroundAfter.content == backgroundBefore.content)
    #expect(goalsAfter.content == goalsBefore.content)
    #expect(backgroundAfter.versionHash == backgroundBefore.versionHash)
    #expect(goalsAfter.versionHash == goalsBefore.versionHash)
}

@Test func editSectionMultiLineContent() throws {
    let doc = try makeDoc()
    let intro = try doc.readSection("introduction")
    let multiLine = """
    First paragraph.

    Second paragraph with **bold**.

    - List item 1
    - List item 2
    """
    let updated = try doc.editSection(
        "introduction",
        newContent: multiLine,
        versionHash: intro.versionHash
    )
    #expect(updated.content == multiLine)
}

@Test func editSectionEmptyNewContent() throws {
    let doc = try makeDoc()
    let intro = try doc.readSection("introduction")
    let updated = try doc.editSection(
        "introduction",
        newContent: "",
        versionHash: intro.versionHash
    )
    #expect(updated.content == "")
}

@Test func editSectionRejectsNewContentWithHeadings() throws {
    let doc = try makeDoc()
    let intro = try doc.readSection("introduction")
    do {
        _ = try doc.editSection(
            "introduction",
            newContent: "Some body.\n\n## New Sub-Section\n\nWith body.",
            versionHash: intro.versionHash
        )
        Issue.record("Expected throw")
    } catch let EngineError.parseError(description, _, _) {
        #expect(description.contains("headings"))
    } catch {
        Issue.record("Expected parseError, got \(error)")
    }
}

@Test func editSectionReturnedAndReReadAreEqual() throws {
    let doc = try makeDoc()
    let intro = try doc.readSection("introduction")
    let returned = try doc.editSection(
        "introduction",
        newContent: "New body.",
        versionHash: intro.versionHash
    )
    let reread = try doc.readSection("introduction")
    #expect(returned == reread)
}

// MARK: - addComment

@Test func addCommentBasic() throws {
    let doc = try makeDoc()
    let comment = try doc.addComment(NewComment(
        type: .question,
        author: "claude",
        sectionSlug: "introduction",
        text: "Why this approach?"
    ))
    #expect(comment.id == "c0001")
    #expect(comment.author == "claude")
    #expect(comment.sectionSlug == "introduction")
    #expect(comment.text == "Why this approach?")
    #expect(comment.priority == .normal)
    #expect(comment.tags == [])
    #expect(comment.context == "Intro body.")
    #expect(doc.metadata.unresolvedComments.count == 1)
}

@Test func addCommentWithCustomContextAndPriority() throws {
    let doc = try makeDoc()
    let comment = try doc.addComment(NewComment(
        type: .suggestion,
        author: "jordan",
        sectionSlug: "methods/oauth",
        text: "Use PKCE",
        context: "custom captured context",
        priority: .high,
        tags: ["security"]
    ))
    #expect(comment.context == "custom captured context")
    #expect(comment.priority == .high)
    #expect(comment.tags == ["security"])
}

@Test func addCommentNonexistentSectionThrows() throws {
    let doc = try makeDoc()
    do {
        _ = try doc.addComment(NewComment(
            type: .note,
            author: "claude",
            sectionSlug: "nope",
            text: "x"
        ))
        Issue.record("Expected throw")
    } catch EngineError.sectionNotFound {
        // expected
    } catch {
        Issue.record("Expected sectionNotFound, got \(error)")
    }
}

@Test func addCommentIdsAreSequential() throws {
    let doc = try makeDoc()
    let c1 = try doc.addComment(NewComment(type: .note, author: "a", sectionSlug: "introduction", text: "1"))
    let c2 = try doc.addComment(NewComment(type: .note, author: "a", sectionSlug: "introduction", text: "2"))
    let c3 = try doc.addComment(NewComment(type: .note, author: "a", sectionSlug: "introduction", text: "3"))
    #expect(c1.id == "c0001")
    #expect(c2.id == "c0002")
    #expect(c3.id == "c0003")
}

@Test func addCommentIdsContinueAcrossResolvedAndUnresolved() throws {
    let doc = try makeDoc()
    let c1 = try doc.addComment(NewComment(type: .note, author: "a", sectionSlug: "introduction", text: "1"))
    _ = try doc.resolveComment(id: c1.id, response: "ok", resolvedBy: "j")
    let c2 = try doc.addComment(NewComment(type: .note, author: "a", sectionSlug: "introduction", text: "2"))
    // c2 must NOT collide with c1's id, even though c1 moved lists.
    #expect(c2.id == "c0002")
}

@Test func addCommentIdFormatLexicographicallySorts() throws {
    let doc = try makeDoc()
    var ids: [String] = []
    for _ in 0..<12 {
        let c = try doc.addComment(NewComment(type: .note, author: "a", sectionSlug: "introduction", text: "x"))
        ids.append(c.id)
    }
    // Lexicographic sort matches insertion order at this scale (4-digit pad).
    #expect(ids == ids.sorted())
    #expect(ids[0] == "c0001")
    #expect(ids[11] == "c0012")
}

// MARK: - listComments

@Test func listCommentsNoFilter() throws {
    let doc = try makeDoc()
    _ = try doc.addComment(NewComment(type: .note, author: "a", sectionSlug: "introduction", text: "x"))
    _ = try doc.addComment(NewComment(type: .question, author: "b", sectionSlug: "methods", text: "y"))
    let all = doc.listComments()
    #expect(all.count == 2)
}

@Test func listCommentsWithFilter() throws {
    let doc = try makeDoc()
    _ = try doc.addComment(NewComment(type: .note, author: "a", sectionSlug: "introduction", text: "x"))
    _ = try doc.addComment(NewComment(type: .question, author: "b", sectionSlug: "methods", text: "y"))
    _ = try doc.addComment(NewComment(type: .note, author: "a", sectionSlug: "methods", text: "z"))

    let filtered = doc.listComments(filter: CommentFilter(sectionSlug: "methods"))
    #expect(filtered.count == 2)
    #expect(filtered.allSatisfy { $0.sectionSlug == "methods" })

    let byType = doc.listComments(filter: CommentFilter(type: .note))
    #expect(byType.count == 2)
    #expect(byType.allSatisfy { $0.type == .note })

    let byAuthor = doc.listComments(filter: CommentFilter(author: "b"))
    #expect(byAuthor.count == 1)
    #expect(byAuthor[0].author == "b")
}

@Test func listCommentsEmptyDocument() throws {
    let doc = try makeDoc()
    #expect(doc.listComments().isEmpty)
}

@Test func listCommentsMergesResolvedAndUnresolved() throws {
    let doc = try makeDoc()
    let c1 = try doc.addComment(NewComment(type: .note, author: "a", sectionSlug: "introduction", text: "x"))
    _ = try doc.addComment(NewComment(type: .note, author: "a", sectionSlug: "introduction", text: "y"))
    _ = try doc.resolveComment(id: c1.id, response: "ok", resolvedBy: "j")
    let all = doc.listComments()
    #expect(all.count == 2)
    let resolvedCount = all.filter { $0.isResolved }.count
    #expect(resolvedCount == 1)
}

// MARK: - resolveComment

@Test func resolveCommentBasic() throws {
    let doc = try makeDoc()
    let added = try doc.addComment(NewComment(
        type: .question,
        author: "claude",
        sectionSlug: "introduction",
        text: "?"
    ))
    let fixedDate = Date(timeIntervalSince1970: 1_775_390_400)
    let resolved = try doc.resolveComment(
        id: added.id,
        response: "yes",
        resolvedBy: "jordan",
        resolvedDate: fixedDate
    )
    #expect(resolved.isResolved)
    #expect(resolved.resolution?.response == "yes")
    #expect(resolved.resolution?.resolvedBy == "jordan")
    #expect(resolved.resolution?.resolvedDate == fixedDate)
    #expect(doc.metadata.unresolvedComments.isEmpty)
    #expect(doc.metadata.resolvedComments.count == 1)
    // Original fields preserved.
    #expect(resolved.id == added.id)
    #expect(resolved.text == "?")
    #expect(resolved.author == "claude")
    #expect(resolved.versionHash == added.versionHash)
    #expect(resolved.timestamp == added.timestamp)
}

@Test func resolveCommentNotFoundThrows() throws {
    let doc = try makeDoc()
    do {
        _ = try doc.resolveComment(id: "c999", response: "x", resolvedBy: "y")
        Issue.record("Expected throw")
    } catch let EngineError.commentNotFound(id) {
        #expect(id == "c999")
    } catch {
        Issue.record("Expected commentNotFound, got \(error)")
    }
}

@Test func resolveCommentAlreadyResolvedThrows() throws {
    let doc = try makeDoc()
    let added = try doc.addComment(NewComment(type: .note, author: "a", sectionSlug: "introduction", text: "x"))
    _ = try doc.resolveComment(id: added.id, response: "ok", resolvedBy: "j")
    do {
        _ = try doc.resolveComment(id: added.id, response: "again", resolvedBy: "j")
        Issue.record("Expected throw")
    } catch let EngineError.commentAlreadyResolved(id) {
        #expect(id == added.id)
    } catch {
        Issue.record("Expected commentAlreadyResolved, got \(error)")
    }
}

// MARK: - refreshSection

@Test func refreshSectionUpdatesStaleComments() throws {
    let doc = try makeDoc()
    let added = try doc.addComment(NewComment(
        type: .question,
        author: "claude",
        sectionSlug: "introduction",
        text: "?"
    ))
    let originalHash = added.versionHash
    let originalContext = added.context

    // Edit the section to invalidate the comment hash.
    let intro = try doc.readSection("introduction")
    _ = try doc.editSection(
        "introduction",
        newContent: "New body.",
        versionHash: intro.versionHash
    )

    // Comment is now stale.
    let staleComment = doc.metadata.unresolvedComments[0]
    #expect(staleComment.versionHash == originalHash)

    // Refresh updates the hash.
    let refreshed = try doc.refreshSection("introduction")
    #expect(refreshed.count == 1)
    let newHash = try doc.readSection("introduction").versionHash
    #expect(refreshed[0].versionHash == newHash)
    #expect(refreshed[0].id == added.id)
    let updatedComment = doc.metadata.unresolvedComments[0]
    #expect(updatedComment.versionHash == newHash)
    // Original context is preserved (not overwritten).
    #expect(updatedComment.context == originalContext)
}

@Test func refreshSectionMultipleStaleComments() throws {
    let doc = try makeDoc()
    let c1 = try doc.addComment(NewComment(type: .note, author: "a", sectionSlug: "introduction", text: "1"))
    let c2 = try doc.addComment(NewComment(type: .note, author: "b", sectionSlug: "introduction", text: "2"))
    let intro = try doc.readSection("introduction")
    _ = try doc.editSection("introduction", newContent: "new", versionHash: intro.versionHash)

    let refreshed = try doc.refreshSection("introduction")
    #expect(refreshed.count == 2)
    let newHash = try doc.readSection("introduction").versionHash
    #expect(refreshed.allSatisfy { $0.versionHash == newHash })
    let refreshedIds = Set(refreshed.map { $0.id })
    #expect(refreshedIds == Set([c1.id, c2.id]))
}

@Test func refreshSectionLeavesOtherSectionsAlone() throws {
    let doc = try makeDoc()
    // Add comments on TWO different sections.
    let onIntro = try doc.addComment(NewComment(type: .note, author: "a", sectionSlug: "introduction", text: "i"))
    let onMethods = try doc.addComment(NewComment(type: .note, author: "a", sectionSlug: "methods", text: "m"))

    // Edit BOTH sections so both comments are technically stale.
    let intro = try doc.readSection("introduction")
    _ = try doc.editSection("introduction", newContent: "new intro", versionHash: intro.versionHash)
    let methods = try doc.readSection("methods")
    _ = try doc.editSection("methods", newContent: "new methods", versionHash: methods.versionHash)

    // Refresh ONLY introduction. methods comment must remain stale.
    _ = try doc.refreshSection("introduction")

    let methodsComment = doc.metadata.unresolvedComments.first { $0.id == onMethods.id }!
    #expect(methodsComment.versionHash == onMethods.versionHash) // stale, unchanged
    let introComment = doc.metadata.unresolvedComments.first { $0.id == onIntro.id }!
    #expect(introComment.versionHash != onIntro.versionHash) // refreshed
}

@Test func refreshSectionNoStaleCommentsReturnsEmpty() throws {
    let doc = try makeDoc()
    let added = try doc.addComment(NewComment(type: .note, author: "a", sectionSlug: "introduction", text: "x"))
    let refreshed = try doc.refreshSection("introduction")
    #expect(refreshed.isEmpty)
    // Comment hash unchanged.
    #expect(doc.metadata.unresolvedComments[0].versionHash == added.versionHash)
}

@Test func refreshSectionNotFoundThrows() throws {
    let doc = try makeDoc()
    do {
        _ = try doc.refreshSection("nope")
        Issue.record("Expected throw")
    } catch EngineError.sectionNotFound {
        // expected
    } catch {
        Issue.record("Expected sectionNotFound, got \(error)")
    }
}

// MARK: - flagSection / listFlags / clearFlag

@Test func flagSectionBasic() throws {
    let doc = try makeDoc()
    let flag = try doc.flagSection("introduction", author: "jordan", note: "review")
    #expect(flag.sectionSlug == "introduction")
    #expect(flag.note == "review")
    #expect(flag.author == "jordan")
    #expect(doc.metadata.flags.count == 1)
}

@Test func flagSectionWithoutNote() throws {
    let doc = try makeDoc()
    let flag = try doc.flagSection("introduction", author: "jordan")
    #expect(flag.note == nil)
    #expect(doc.metadata.flags.count == 1)
}

@Test func listFlagsEmpty() throws {
    let doc = try makeDoc()
    #expect(doc.listFlags().isEmpty)
}

@Test func flagSectionNonexistentThrows() throws {
    let doc = try makeDoc()
    do {
        _ = try doc.flagSection("nope", author: "jordan")
        Issue.record("Expected throw")
    } catch EngineError.sectionNotFound {
        // expected
    } catch {
        Issue.record("Expected sectionNotFound, got \(error)")
    }
}

@Test func flagSectionReplacesExisting() throws {
    let doc = try makeDoc()
    _ = try doc.flagSection("introduction", author: "jordan", note: "first")
    _ = try doc.flagSection("introduction", author: "claude", note: "second")
    #expect(doc.metadata.flags.count == 1)
    #expect(doc.metadata.flags[0].author == "claude")
    #expect(doc.metadata.flags[0].note == "second")
}

@Test func listFlagsReturnsAll() throws {
    let doc = try makeDoc()
    _ = try doc.flagSection("introduction", author: "jordan")
    _ = try doc.flagSection("methods", author: "claude")
    let flags = doc.listFlags()
    #expect(flags.count == 2)
}

@Test func clearFlagBasic() throws {
    let doc = try makeDoc()
    _ = try doc.flagSection("introduction", author: "jordan")
    try doc.clearFlag("introduction")
    #expect(doc.metadata.flags.isEmpty)
}

@Test func clearFlagNotFlaggedThrows() throws {
    let doc = try makeDoc()
    do {
        try doc.clearFlag("introduction")
        Issue.record("Expected throw")
    } catch let EngineError.sectionNotFlagged(slug) {
        #expect(slug == "introduction")
    } catch {
        Issue.record("Expected sectionNotFlagged, got \(error)")
    }
}

// MARK: - End-to-end integration

@Test func endToEndAddEditResolveRefreshFlag() throws {
    let doc = try makeDoc()

    // 1. Add a comment.
    let added = try doc.addComment(NewComment(
        type: .question,
        author: "claude",
        sectionSlug: "methods/oauth",
        text: "Does this support PKCE?"
    ))
    #expect(added.id == "c0001")

    // 2. Flag the same section.
    _ = try doc.flagSection("methods/oauth", author: "jordan", note: "discuss")
    #expect(doc.listFlags().count == 1)

    // 3. Edit the section content.
    let oauth = try doc.readSection("methods/oauth")
    _ = try doc.editSection(
        "methods/oauth",
        newContent: "New OAuth flow body.",
        versionHash: oauth.versionHash
    )

    // 4. Refresh stale comments.
    let refreshed = try doc.refreshSection("methods/oauth")
    #expect(refreshed.count == 1)

    // 5. Resolve the comment.
    let resolved = try doc.resolveComment(
        id: added.id,
        response: "yes, PKCE is supported",
        resolvedBy: "jordan"
    )
    #expect(resolved.isResolved)
    #expect(doc.metadata.unresolvedComments.isEmpty)
    #expect(doc.metadata.resolvedComments.count == 1)

    // 6. Add ANOTHER unresolved comment (for round-trip coverage of unresolved).
    let unresolved = try doc.addComment(NewComment(
        type: .note,
        author: "claude",
        sectionSlug: "introduction",
        text: "remember to check this"
    ))
    #expect(unresolved.id == "c0002")

    // 7. Re-flag a different section (for round-trip coverage of flags).
    _ = try doc.flagSection("methods", author: "jordan", note: "sanity check")

    // 8. Clear the methods/oauth flag created earlier.
    // (We re-flagged "methods" — different section, so the methods/oauth
    // flag is still around if we never cleared it; clear it now.)
    if doc.metadata.flags.contains(where: { $0.sectionSlug == "methods/oauth" }) {
        try doc.clearFlag("methods/oauth")
    }

    // 9. Serialize and reload — full round-trip.
    let serialized = try doc.serialize()
    let reloaded = try Document(content: serialized, parser: MarkdownParser())

    // Resolved comment survives.
    #expect(reloaded.metadata.resolvedComments.count == 1)
    #expect(reloaded.metadata.resolvedComments[0].text == "Does this support PKCE?")
    #expect(reloaded.metadata.resolvedComments[0].resolution?.response == "yes, PKCE is supported")

    // Unresolved comment survives.
    #expect(reloaded.metadata.unresolvedComments.count == 1)
    #expect(reloaded.metadata.unresolvedComments[0].text == "remember to check this")

    // Flag survives.
    #expect(reloaded.metadata.flags.count == 1)
    #expect(reloaded.metadata.flags[0].sectionSlug == "methods")
    #expect(reloaded.metadata.flags[0].note == "sanity check")

    // Section structure intact.
    #expect(reloaded.listSections().count == 5)
}
