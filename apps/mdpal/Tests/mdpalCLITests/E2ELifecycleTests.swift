// What Problem: Per-command tests verify each subcommand's wire shape in
// isolation, but they share fixtures via CLISupport.makeFixture (which
// uses the engine API directly to construct the bundle, bypassing the
// CLI). A real user/agent drives the WHOLE binary — they create the
// bundle via `mdpal create`, then chain every other command against
// what was produced. Integration bugs that span command boundaries
// (e.g., revision IDs from `create` failing to round-trip into
// `revision create --base-revision`, or `prune` corrupting a bundle
// such that `read` then fails) only surface at the CLI seam.
//
// How & Why: One test that drives the binary through the full happy-path
// lifecycle, asserting each step's output AND that subsequent steps see
// the previous step's effects. This is the single most-leveraged test
// added in iter 2.5 — exercises 16 of 16 dispatched commands plus the
// engine state transitions between them.
//
// Reference: usr/jordan/mdpal/dispatches/dispatch-cli-json-output-shapes-20260406.md
//
// Written: 2026-04-17 during mdpal-cli session (Phase 2 iteration 2.5)

import Testing
import Foundation

@Test func e2eFullCollaborationLifecycle() throws {
    // ---- Bootstrap: temp parent dir ----
    let parentDir = FileManager.default.temporaryDirectory
        .appendingPathComponent("mdpal-e2e-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: parentDir, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: parentDir) }

    // ---- 1. create — fresh bundle with seeded content ----
    let initialContent = """
    # Architecture

    Initial design.

    # Testing

    Initial testing notes.
    """
    let createResult = try CLISupport.runCLI([
        "create", "design",
        "--dir", parentDir.path,
        "--content", initialContent,
    ])
    #expect(createResult.exitCode == 0, "create stderr: \(createResult.stderr)")
    let createPayload = try TestJSON.parse(createResult.stdout)
    let bundlePath = try #require(createPayload["path"] as? String)
    let createVersionId = try #require(createPayload["versionId"] as? String)
    #expect(createPayload["version"] as? Int == 1)
    #expect(createPayload["revision"] as? Int == 1)

    // ---- 2. sections — verify the seeded headings round-tripped ----
    let sectionsResult = try CLISupport.runCLI(["sections", bundlePath])
    #expect(sectionsResult.exitCode == 0, "sections stderr: \(sectionsResult.stderr)")
    let sectionsPayload = try TestJSON.parse(sectionsResult.stdout)
    let sections = try #require(sectionsPayload["sections"] as? [[String: Any]])
    #expect(sections.count == 2)
    let architectureHash = try #require(sections.first?["versionHash"] as? String)
    #expect(sections.first?["slug"] as? String == "architecture")

    // ---- 3. read — fetch full architecture section ----
    let readResult = try CLISupport.runCLI(["read", "architecture", bundlePath])
    #expect(readResult.exitCode == 0, "read stderr: \(readResult.stderr)")
    let readPayload = try TestJSON.parse(readResult.stdout)
    #expect(readPayload["slug"] as? String == "architecture")
    #expect(readPayload["versionHash"] as? String == architectureHash)
    let readContent = try #require(readPayload["content"] as? String)
    #expect(readContent.contains("Initial design."))

    // ---- 4. edit — update architecture, verify hash advances ----
    let editResult = try CLISupport.runCLI([
        "edit", "architecture", bundlePath,
        "--version", architectureHash,
        "--content", "Updated design with new components.",
    ])
    #expect(editResult.exitCode == 0, "edit stderr: \(editResult.stderr)")
    let editPayload = try TestJSON.parse(editResult.stdout)
    let postEditHash = try #require(editPayload["versionHash"] as? String)
    #expect(postEditHash != architectureHash)

    // ---- 5. comment — add a question on architecture ----
    let commentResult = try CLISupport.runCLI([
        "comment", "architecture", bundlePath,
        "--type", "question", "--author", "alice", "--text", "Why this design?",
        "--tag", "design", "--tag", "review",
    ])
    #expect(commentResult.exitCode == 0, "comment stderr: \(commentResult.stderr)")
    let commentPayload = try TestJSON.parse(commentResult.stdout)
    let commentId = try #require(commentPayload["commentId"] as? String)
    let tags = try #require(commentPayload["tags"] as? [String])
    #expect(tags.contains("design") && tags.contains("review"))

    // ---- 6. comments — list, verify the comment is unresolved ----
    let listCommentsResult = try CLISupport.runCLI(["comments", bundlePath])
    #expect(listCommentsResult.exitCode == 0)
    let listCommentsPayload = try TestJSON.parse(listCommentsResult.stdout)
    let allComments = try #require(listCommentsPayload["comments"] as? [[String: Any]])
    #expect(allComments.count == 1)
    #expect(allComments.first?["resolved"] as? Bool == false)

    // ---- 7. resolve — close the comment ----
    let resolveResult = try CLISupport.runCLI([
        "resolve", commentId, bundlePath,
        "--response", "Decided per ADR-001.",
        "--by", "bob",
    ])
    #expect(resolveResult.exitCode == 0, "resolve stderr: \(resolveResult.stderr)")
    let resolvePayload = try TestJSON.parse(resolveResult.stdout)
    #expect(resolvePayload["resolved"] as? Bool == true)

    // ---- 8. flag / flags / clear-flag — flag testing, then clear ----
    let flagResult = try CLISupport.runCLI([
        "flag", "testing", bundlePath,
        "--author", "alice", "--note", "Needs more cases",
    ])
    #expect(flagResult.exitCode == 0, "flag stderr: \(flagResult.stderr)")
    #expect((try TestJSON.parse(flagResult.stdout))["flagged"] as? Bool == true)

    let flagsListResult = try CLISupport.runCLI(["flags", bundlePath])
    let flagsListPayload = try TestJSON.parse(flagsListResult.stdout)
    #expect(flagsListPayload["count"] as? Int == 1)

    let clearFlagResult = try CLISupport.runCLI(["clear-flag", "testing", bundlePath])
    #expect(clearFlagResult.exitCode == 0, "clear-flag stderr: \(clearFlagResult.stderr)")
    #expect((try TestJSON.parse(clearFlagResult.stdout))["flagged"] as? Bool == false)

    // ---- 9. revision create — append a fresh full-document revision ----
    let revCreateResult = try CLISupport.runCLI([
        "revision", "create", bundlePath,
        "--content", "# Architecture\n\nFully rewritten.\n\n# Testing\n\nFully rewritten too.\n",
    ])
    #expect(revCreateResult.exitCode == 0, "revision create stderr: \(revCreateResult.stderr)")
    let revCreatePayload = try TestJSON.parse(revCreateResult.stdout)
    let revCreateVersionId = try #require(revCreatePayload["versionId"] as? String)

    // ---- 10. diff — between original and rev-create revision ----
    let diffResult = try CLISupport.runCLI([
        "diff", createVersionId, revCreateVersionId, bundlePath,
    ])
    #expect(diffResult.exitCode == 0, "diff stderr: \(diffResult.stderr)")
    let diffPayload = try TestJSON.parse(diffResult.stdout)
    let changes = try #require(diffPayload["changes"] as? [[String: Any]])
    // Both architecture and testing changed; comment add + edit + flag ops
    // also added intermediate revisions, so changes count is meaningful
    // but exact value depends on intermediate reformatting. Just confirm
    // both top-level slugs appear as modified.
    let typeBySlug = Dictionary(uniqueKeysWithValues:
        changes.compactMap { c -> (String, String)? in
            guard let s = c["slug"] as? String, let t = c["type"] as? String else { return nil }
            return (s, t)
        }
    )
    // C-13: prior `||"unchanged"` tautology hid regressions. Both
    // sections were rewritten in the rev-create step; both MUST appear
    // as modified when diffed against the original.
    #expect(typeBySlug["architecture"] == "modified", "expected architecture modified, got \(typeBySlug["architecture"] ?? "nil")")
    #expect(typeBySlug["testing"] == "modified", "expected testing modified, got \(typeBySlug["testing"] ?? "nil")")

    // ---- 11. history — verify multiple revisions in order ----
    let historyResult = try CLISupport.runCLI(["history", bundlePath])
    #expect(historyResult.exitCode == 0, "history stderr: \(historyResult.stderr)")
    let historyPayload = try TestJSON.parse(historyResult.stdout)
    let revisions = try #require(historyPayload["revisions"] as? [[String: Any]])
    #expect(revisions.count >= 6, "expected ≥6 revisions (create+edit+comment+resolve+flag+clear+revcreate); got \(revisions.count)")
    #expect(revisions.first?["latest"] as? Bool == true)

    // ---- 12. version bump — start a new version line ----
    let bumpResult = try CLISupport.runCLI(["version", "bump", bundlePath])
    #expect(bumpResult.exitCode == 0, "version bump stderr: \(bumpResult.stderr)")
    let bumpPayload = try TestJSON.parse(bumpResult.stdout)
    #expect(bumpPayload["version"] as? Int == 2)
    #expect(bumpPayload["revision"] as? Int == 1)
    #expect(bumpPayload["previousVersion"] as? Int == 1)

    // ---- 13. version show — confirms bump persisted ----
    let showResult = try CLISupport.runCLI(["version", "show", bundlePath])
    let showPayload = try TestJSON.parse(showResult.stdout)
    #expect(showPayload["version"] as? Int == 2)

    // ---- 14. prune — keep 3, verify history shrinks ----
    let pruneResult = try CLISupport.runCLI(["prune", bundlePath, "--keep", "3"])
    #expect(pruneResult.exitCode == 0, "prune stderr: \(pruneResult.stderr)")
    let prunePayload = try TestJSON.parse(pruneResult.stdout)
    #expect(prunePayload["kept"] as? Int == 3)
    #expect((prunePayload["prunedCount"] as? Int ?? 0) > 0)

    let postPruneHistory = try CLISupport.runCLI(["history", bundlePath])
    let postPrunePayload = try TestJSON.parse(postPruneHistory.stdout)
    let postPruneRevs = try #require(postPrunePayload["revisions"] as? [[String: Any]])
    #expect(postPruneRevs.count == 3)

    // ---- 15. refresh — operate on a section in the post-bump bundle ----
    // After version bump + prune, fetch current sections and refresh one.
    let postPruneSections = try CLISupport.runCLI(["sections", bundlePath])
    let postPrunePayloadSections = try TestJSON.parse(postPruneSections.stdout)
    let currentSections = try #require(postPrunePayloadSections["sections"] as? [[String: Any]])
    let firstSlug = try #require(currentSections.first?["slug"] as? String)
    let refreshResult = try CLISupport.runCLI(["refresh", firstSlug, bundlePath])
    #expect(refreshResult.exitCode == 0, "refresh stderr: \(refreshResult.stderr)")
    let refreshPayload = try TestJSON.parse(refreshResult.stdout)
    #expect(refreshPayload["slug"] as? String == firstSlug)

    // ---- 16. final invariants — bundle still readable, version still 2 ----
    let finalShow = try CLISupport.runCLI(["version", "show", bundlePath])
    let finalShowPayload = try TestJSON.parse(finalShow.stdout)
    #expect(finalShowPayload["version"] as? Int == 2)
    let finalRead = try CLISupport.runCLI(["read", firstSlug, bundlePath])
    #expect(finalRead.exitCode == 0, "final read stderr: \(finalRead.stderr)")
}
