// What Problem: `mdpal comment`, `mdpal comments`, `mdpal resolve`
// are the comment lifecycle. Wire shapes (per dispatched spec) are
// strict: commentId, slug (renamed from sectionSlug), resolved boolean,
// resolution.{response, by, timestamp}.
//
// How & Why: Build a fixture, add comments, list with filters, resolve,
// verify wire shapes. Cover error paths.
//
// Reference: usr/jordan/mdpal/dispatches/dispatch-cli-json-output-shapes-20260406.md
//
// Written: 2026-04-17 during mdpal-cli session (Phase 2 iteration 2.3)

import Testing
import Foundation

private let fixtureContent = """
# Introduction

Welcome.

# Architecture

Design here.
"""

@Test func commentAddReturnsCommentPayload() throws {
    let fixture = try CLISupport.makeFixture(name: "comment-add", content: fixtureContent)
    defer { CLISupport.cleanup(fixture) }

    let result = try CLISupport.runCLI([
        "comment", "introduction", fixture.bundlePath,
        "--type", "question",
        "--author", "jordan",
        "--text", "Why this approach?",
    ])
    #expect(result.exitCode == 0, "stderr: \(result.stderr)")

    let payload = try TestJSON.parse(result.stdout)
    #expect((payload["commentId"] as? String)?.hasPrefix("c") == true)
    #expect(payload["slug"] as? String == "introduction")
    #expect(payload["type"] as? String == "question")
    #expect(payload["author"] as? String == "jordan")
    #expect(payload["text"] as? String == "Why this approach?")
    #expect(payload["resolved"] as? Bool == false)
    // engine field name `sectionSlug` must not leak.
    #expect(payload["sectionSlug"] == nil)
    #expect(payload["id"] == nil, "engine field name `id` must not leak; spec uses `commentId`")
}

@Test func commentRejectsUnknownType() throws {
    let fixture = try CLISupport.makeFixture(name: "comment-bad-type", content: fixtureContent)
    defer { CLISupport.cleanup(fixture) }

    let result = try CLISupport.runCLI([
        "comment", "introduction", fixture.bundlePath,
        "--type", "bogus",
        "--author", "jordan",
        "--text", "x",
    ])
    #expect(result.exitCode != 0)
    let envelope = try TestJSON.parse(result.stderr)
    #expect(envelope["error"] as? String == "invalidArgument")
}

@Test func commentRejectsUnknownPriority() throws {
    let fixture = try CLISupport.makeFixture(name: "comment-bad-pri", content: fixtureContent)
    defer { CLISupport.cleanup(fixture) }

    let result = try CLISupport.runCLI([
        "comment", "introduction", fixture.bundlePath,
        "--type", "note",
        "--author", "jordan",
        "--text", "x",
        "--priority", "urgent",
    ])
    #expect(result.exitCode != 0)
    let envelope = try TestJSON.parse(result.stderr)
    #expect(envelope["error"] as? String == "invalidArgument")
}

@Test func commentRejectsNonexistentSection() throws {
    let fixture = try CLISupport.makeFixture(name: "comment-no-sec", content: fixtureContent)
    defer { CLISupport.cleanup(fixture) }

    let result = try CLISupport.runCLI([
        "comment", "no-such-section", fixture.bundlePath,
        "--type", "note",
        "--author", "jordan",
        "--text", "x",
    ])
    #expect(result.exitCode == 3)
    let envelope = try TestJSON.parse(result.stderr)
    #expect(envelope["error"] as? String == "sectionNotFound")
}

@Test func commentsListsAllCommentsWithCount() throws {
    let fixture = try CLISupport.makeFixture(name: "comments-list", content: fixtureContent)
    defer { CLISupport.cleanup(fixture) }

    _ = try CLISupport.runCLI([
        "comment", "introduction", fixture.bundlePath,
        "--type", "question", "--author", "alice", "--text", "Q1",
    ])
    _ = try CLISupport.runCLI([
        "comment", "architecture", fixture.bundlePath,
        "--type", "suggestion", "--author", "bob", "--text", "S1",
    ])

    let result = try CLISupport.runCLI(["comments", fixture.bundlePath])
    #expect(result.exitCode == 0, "stderr: \(result.stderr)")

    let payload = try TestJSON.parse(result.stdout)
    let comments = try #require(payload["comments"] as? [[String: Any]])
    #expect(comments.count == 2)
    #expect(payload["count"] as? Int == 2)
    let filters = try #require(payload["filters"] as? [String: Any])
    // No filters applied — all keys should be NSNull (nil).
    #expect(filters["section"] is NSNull)
    #expect(filters["type"] is NSNull)
    #expect(filters["resolved"] is NSNull)
}

@Test func commentsFilterBySection() throws {
    let fixture = try CLISupport.makeFixture(name: "comments-section", content: fixtureContent)
    defer { CLISupport.cleanup(fixture) }

    _ = try CLISupport.runCLI([
        "comment", "introduction", fixture.bundlePath,
        "--type", "question", "--author", "alice", "--text", "Q1",
    ])
    _ = try CLISupport.runCLI([
        "comment", "architecture", fixture.bundlePath,
        "--type", "note", "--author", "bob", "--text", "N1",
    ])

    let result = try CLISupport.runCLI(["comments", fixture.bundlePath, "--section", "architecture"])
    #expect(result.exitCode == 0)
    let payload = try TestJSON.parse(result.stdout)
    let comments = try #require(payload["comments"] as? [[String: Any]])
    #expect(comments.count == 1)
    #expect(comments.first?["slug"] as? String == "architecture")
    let filters = try #require(payload["filters"] as? [String: Any])
    #expect(filters["section"] as? String == "architecture")
}

@Test func commentsFilterUnresolvedAndResolvedMutuallyExclusive() throws {
    let fixture = try CLISupport.makeFixture(name: "comments-mutex", content: fixtureContent)
    defer { CLISupport.cleanup(fixture) }

    let result = try CLISupport.runCLI([
        "comments", fixture.bundlePath,
        "--unresolved", "--resolved",
    ])
    #expect(result.exitCode != 0, "expected validation error")
}

@Test func resolveAttachesResolution() throws {
    let fixture = try CLISupport.makeFixture(name: "comment-resolve", content: fixtureContent)
    defer { CLISupport.cleanup(fixture) }

    let addResult = try CLISupport.runCLI([
        "comment", "introduction", fixture.bundlePath,
        "--type", "question", "--author", "alice", "--text", "Q1",
    ])
    let added = try TestJSON.parse(addResult.stdout)
    let commentId = try #require(added["commentId"] as? String)

    let result = try CLISupport.runCLI([
        "resolve", commentId, fixture.bundlePath,
        "--response", "Decided to keep it",
        "--by", "bob",
    ])
    #expect(result.exitCode == 0, "stderr: \(result.stderr)")

    let payload = try TestJSON.parse(result.stdout)
    #expect(payload["commentId"] as? String == commentId)
    #expect(payload["resolved"] as? Bool == true)
    let resolution = try #require(payload["resolution"] as? [String: Any])
    #expect(resolution["response"] as? String == "Decided to keep it")
    #expect(resolution["by"] as? String == "bob")
    #expect(resolution["timestamp"] != nil)
    #expect(resolution["resolvedBy"] == nil, "engine field `resolvedBy` must not leak; spec uses `by`")
    #expect(resolution["resolvedDate"] == nil, "engine field `resolvedDate` must not leak; spec uses `timestamp`")
}

@Test func resolveNonexistentCommentReturnsExitCode3() throws {
    let fixture = try CLISupport.makeFixture(name: "resolve-missing", content: fixtureContent)
    defer { CLISupport.cleanup(fixture) }

    let result = try CLISupport.runCLI([
        "resolve", "c9999", fixture.bundlePath,
        "--response", "x", "--by", "bob",
    ])
    #expect(result.exitCode == 3)
    let envelope = try TestJSON.parse(result.stderr)
    #expect(envelope["error"] as? String == "commentNotFound")
}

// mdpal-app coord item #2: repeatable --tag (replaces --tags comma-separated)
@Test func commentAcceptsRepeatableTagFlag() throws {
    let fixture = try CLISupport.makeFixture(name: "comment-tags", content: fixtureContent)
    defer { CLISupport.cleanup(fixture) }

    let result = try CLISupport.runCLI([
        "comment", "introduction", fixture.bundlePath,
        "--type", "note", "--author", "alice", "--text", "tagged",
        "--tag", "perf", "--tag", "phase2",
    ])
    #expect(result.exitCode == 0, "stderr: \(result.stderr)")
    let payload = try TestJSON.parse(result.stdout)
    let tags = try #require(payload["tags"] as? [String])
    #expect(tags.contains("perf"))
    #expect(tags.contains("phase2"))
    #expect(tags.count == 2)
}

// mdpal-app coord item #4: --stdin avoids ARG_MAX limits.
// D1 (phase-complete): renamed --text-stdin → --stdin for parity.
@Test func commentTextViaStdin() throws {
    let fixture = try CLISupport.makeFixture(name: "comment-stdin", content: fixtureContent)
    defer { CLISupport.cleanup(fixture) }

    let longText = String(repeating: "Long comment body. ", count: 1000)
    let result = try CLISupport.runCLI(
        [
            "comment", "introduction", fixture.bundlePath,
            "--type", "note", "--author", "alice", "--stdin",
        ],
        stdin: longText
    )
    #expect(result.exitCode == 0, "stderr: \(result.stderr)")
    let payload = try TestJSON.parse(result.stdout)
    let text = try #require(payload["text"] as? String)
    #expect(text.contains("Long comment body."))
    #expect(text.count > 10_000, "expected long text round-tripped intact, got \(text.count) chars")
}

@Test func commentRejectsBothTextAndStdin() throws {
    let fixture = try CLISupport.makeFixture(name: "comment-both", content: fixtureContent)
    defer { CLISupport.cleanup(fixture) }
    let result = try CLISupport.runCLI(
        [
            "comment", "introduction", fixture.bundlePath,
            "--type", "note", "--author", "alice", "--text", "x", "--stdin",
        ],
        stdin: "y"
    )
    #expect(result.exitCode != 0)
}

@Test func resolveResponseViaStdin() throws {
    let fixture = try CLISupport.makeFixture(name: "resolve-stdin", content: fixtureContent)
    defer { CLISupport.cleanup(fixture) }

    let added = try TestJSON.parse(try CLISupport.runCLI([
        "comment", "introduction", fixture.bundlePath,
        "--type", "question", "--author", "alice", "--text", "Q",
    ]).stdout)
    let cid = try #require(added["commentId"] as? String)

    let result = try CLISupport.runCLI(
        [
            "resolve", cid, fixture.bundlePath,
            "--stdin", "--by", "bob",
        ],
        stdin: "Long resolution explanation."
    )
    #expect(result.exitCode == 0, "stderr: \(result.stderr)")
    let payload = try TestJSON.parse(result.stdout)
    let resolution = try #require(payload["resolution"] as? [String: Any])
    #expect(resolution["response"] as? String == "Long resolution explanation.")
}

@Test func resolveAlreadyResolvedReturnsExitCode1() throws {
    let fixture = try CLISupport.makeFixture(name: "resolve-twice", content: fixtureContent)
    defer { CLISupport.cleanup(fixture) }

    let added = try TestJSON.parse(try CLISupport.runCLI([
        "comment", "introduction", fixture.bundlePath,
        "--type", "question", "--author", "alice", "--text", "Q",
    ]).stdout)
    let cid = try #require(added["commentId"] as? String)

    _ = try CLISupport.runCLI([
        "resolve", cid, fixture.bundlePath,
        "--response", "first", "--by", "bob",
    ])

    let secondResolve = try CLISupport.runCLI([
        "resolve", cid, fixture.bundlePath,
        "--response", "second", "--by", "bob",
    ])
    #expect(secondResolve.exitCode != 0)
    let envelope = try TestJSON.parse(secondResolve.stderr)
    #expect(envelope["error"] as? String == "commentAlreadyResolved")
}
