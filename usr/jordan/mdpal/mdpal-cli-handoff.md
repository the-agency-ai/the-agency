# Handoff: mdpal-cli

---
type: session-handoff
date: 2026-04-04
principal: jordan
agent: the-agency/jordan/mdpal-cli
workstream: mdpal
trigger: end-of-day
---

## Who You Are

You are **mdpal-cli**, a tech-lead agent owning the **core engine, CLI, and bundle management operations** for Markdown Pal — a section-oriented tool for structured document operations. You are building the brain; mdpal-app is building the face.

Read your role from `claude/agents/tech-lead/agent.md`. Read workstream knowledge from `claude/workstreams/mdpal/KNOWLEDGE.md`.

## Your Counterpart

**mdpal-app** owns the macOS native SwiftUI app — the human interface. You share the `mdpal` worktree and branch. Coordinate via dispatches in `usr/jordan/mdpal/dispatches/`. Read her handoff at `usr/jordan/mdpal/mdpal-app-handoff.md` on startup for shared context.

## The Product — What We're Building

Markdown Pal solves a concrete pain point: **there's no good way for principals and agents to do structured review and feedback on markdown artifacts.** Today, a principal who wants to comment on a PVR has to copy-paste into chat (losing context, burning tokens), edit the file directly (risky), or describe their feedback verbally in a 1B1 (only works for what the agent surfaces). mdpal fixes this.

**The bigger vision:** This is not just a Markdown tool. It's a paradigm shift in how agents interact with text files — from line-oriented (`sed`, `cat`, `Read`, `Edit`) to structure-oriented (`read section`, `edit section`, `comment on section`). The engine's section model is the platform; parsers are pluggable. Markdown is first. Source code, log files, config files are the aspiration.

**V1 essence — five symmetric capabilities:**

| Capability | Agent (CLI) | Principal (App) |
|-----------|-------------|-----------------|
| Read structured | `mdpal read <section>` | Section navigation + preview |
| Edit structured | `mdpal edit <section>` | Edit in app |
| Comment | `mdpal comment <section>` | Drop comments while reading |
| Flag for discussion | `mdpal flag <section>` | Mark sections for 1B1 |
| Diff / compare | `mdpal diff <rev1> <rev2>` | Side-by-side diff view |

## Current State

### PVR: Complete — pending Jordan's final sign-off

All 9 items resolved across two sessions (2026-03-29 and 2026-04-03). Post-MAR (two rounds, all findings addressed). mdpal-cli reviewed and signed off. Jordan has read it and said "I think we are on the right path."

**PVR file:** `usr/jordan/mdpal/pvr-mdpal-20260403-1447.md`

### A&D: Kicked off — mdpal-cli leads

Dispatch sent to mdpal-app (`dispatch-ad-kickoff-20260404.md`) with scope, five questions about how the app wants to consume the engine, and proposed collaboration process.

**mdpal-app has NOT yet responded.** Their response is the first thing to check in the morning.

## Key Decisions Made (full record in transcripts and PVR)

| Decision | What | Why |
|----------|------|-----|
| Language | Swift | Shared with mdpal-app — one language, one toolchain, shared types |
| Platforms | macOS 14+ primary, Linux second, Windows deferred | Swift on Linux works. Windows has active blockers. Not our market. |
| V1 product (mdpal-cli) | Engine library + CLI | CLI is the agent interface. MCP/LSP deferred. |
| Engine architecture | Two-layer API: core (format-agnostic) + bundle (product-specific) | Core is the platform. Bundle is Markdown Pal-specific. |
| Pluggable parsers | V1 architecture, not bolt-on | Jordan was explicit: "We build the architecture, we use it for Markdown and then we do something else." |
| Agent interface | CLI only | "If we just delivered a CLI that let agents access and edit markdown more effectively, that would be a win." |
| Bundle ownership | Engine provides ops, app consumes | Pruning, merge-forward, revision creation are engine logic. App calls them. |
| YAML handling | YAML in fenced code block inside HTML comment boundaries | Jordan corrected: "It is YAML in Markdown, not HTML. I am not that crazy!" |
| Coordination | Parallel with contract. mdpal-cli defines API in A&D, mdpal-app collaborates. | API contract is the priority — unblocks both agents. |

## What Was Done This Session (2026-04-03)

1. **Bootstrap:** Read all seed materials (5 files), agent registration, tech-lead role, workstream knowledge, both agent handoffs. Merged main to pick up latest commits.
2. **`/discuss` session with Jordan** — resolved three discussion items plus PVR items 5-9:
   - Item 1: Swift cross-platform — Swift confirmed, research conducted
   - Item 2: Structured editing vision — pluggable parser architecture in V1
   - Item 3 (PVR 5): Agent interface = engine + CLI
   - PVR 6: V1 scope confirmed
   - PVR 7: Research comments triaged (r001/r006/r009 dissolved, r003/r004 to mdpal-app, r002/r005/r008 to A&D)
   - PVR 8: mdpal is infrastructure for Agency workflows (the pain point is real and specific)
   - PVR 9: Nothing else fills the gap. Jordan wants to build this. 13 years at Apple, never shipped his own app.
3. **Reviewed mdpal-app's post-MAR PVR** — signed off with 4 minor notes
4. **Sent A&D kickoff dispatch** to mdpal-app
5. **Added review-prototype-20250310.jsx** to workstream seeds
6. **Full transcript captured:** `usr/jordan/mdpal/transcripts/discuss-swift-crossplatform-20260403.md`

## Plan for Tomorrow (2026-04-04)

### Morning — Check State

1. **Check for Jordan's PVR sign-off.** He said "I think we are on the right path" — may have formally approved overnight, or may want to discuss. If not yet approved, ask.
2. **Check for mdpal-app's response** to the A&D kickoff dispatch (`dispatch-ad-kickoff-20260404.md`). She should have answers to the five questions about how the app wants to consume the engine.
3. **Merge main** if there are new commits.

### Mid-Morning — A&D Draft (Priority: Engine API Contract)

Start the A&D with the engine API contract — this is the critical path that unblocks mdpal-app.

**The API contract needs to answer:**
- What does `engine.readSection("authentication")` return? (Raw Markdown? Structured data? Both?)
- How does the app hold a `Document` in memory vs. the CLI's stateless parse-operate-exit?
- What does the pluggable parser protocol look like? (What parsers implement: section detection, boundary identification, content extraction, address computation. What the engine provides: comment storage, version hashing, metadata management.)
- How are errors surfaced? (Version conflicts, section not found, parse failures)

**Approach:** Use `/design` or `/discuss` with Jordan to drive toward completeness. The tech-lead A&D checklist: architecture, data model, interfaces, dependencies, technology choices, trade-offs, failure modes, security, deployment, open questions.

### Afternoon — Remaining A&D Sections

After the API contract is solid, work through:

4. **Section addressing spec** — slug computation, disambiguation for duplicate headings, path-style nesting, sub-section granularity decision (V1 stops at section level, probably)
5. **Comment and flag data model** — metadata block schema, YAML structure, comment lifecycle states, flag lifecycle
6. **Bundle operations** — create, revise, prune algorithm, metadata merge-forward (r005)
7. **Concurrent write strategy** (r002) — must design now even though it's a Phase 2 concern, so the API doesn't paint us into a corner
8. **Version bump enforcement** (r008) — engine-enforced vs. convention
9. **CLI command spec** — full interface for each of the ~15 commands

### End of Day — Review Cycle

10. **Send A&D draft to mdpal-app** via dispatch for review of app-facing API surface
11. **Iterate** via dispatches or joint `/discuss` with Jordan
12. **MAR when ready** — same process as PVR (parallel agents, fix cycle, validation)

## Key Files

| File | What | Location |
|------|------|----------|
| `usr/jordan/mdpal/pvr-mdpal-20260403-1447.md` | PVR (post-MAR) | worktree |
| `usr/jordan/mdpal/pvr-mdpal-20260403-1443.md` | PVR (pre-MAR, for reference) | worktree |
| `usr/jordan/mdpal/PVR-markdown-pal.md` | PVR (session 1, items 1-4 only) | worktree |
| `usr/jordan/mdpal/transcripts/discuss-swift-crossplatform-20260403.md` | Today's discussion transcript | worktree |
| `usr/jordan/mdpal/transcripts/PVR-transcript-20260329.md` | Session 1 transcript | worktree |
| `usr/jordan/mdpal/transcripts/dialogue-transcript-20260403.md` | mdpal-app's session transcript | main checkout |
| `usr/jordan/mdpal/dispatches/dispatch-ad-kickoff-20260404.md` | A&D kickoff dispatch (sent) | worktree |
| `usr/jordan/mdpal/dispatches/dispatch-pvr-cli-signoff-20260403.md` | PVR sign-off dispatch | worktree |
| `usr/jordan/mdpal/dispatches/dispatch-pvr-cli-response-20260403.md` | PVR response dispatch | worktree |
| `usr/jordan/mdpal/dispatches/dispatch-pvr-post-mar-20260403.md` | mdpal-app's PVR review request | worktree |
| `usr/jordan/mdpal/dispatches/dispatch-pvr-review-and-completion-process-20260403.md` | mdpal-app's original PVR process dispatch | main checkout |
| `claude/workstreams/mdpal/seeds/` | All seed materials (6 files) | worktree |
| `claude/workstreams/mdpal/KNOWLEDGE.md` | Workstream knowledge | worktree |

## Technical Notes for A&D

Things I'm carrying into the A&D design work:

1. **Sub-section granularity:** The seed doc describes `paragraph:2` and `paragraph:contains("Redis")` addressing. My instinct is V1 stops at section granularity for the engine API. Sub-section addressing can be a CLI convenience layer — the CLI reads a section and can filter within it. Discuss with Jordan.

2. **Engine state model:** CLI is stateless (parse, operate, exit). App holds state (persistent AST). The engine should support both: a `Document` type that can be created from a file path (stateless) or held in memory (stateful). The stateful mode needs a strategy for external changes (file modified outside the app).

3. **YAML round-tripping:** `swift-markdown` parses `<!-- ... -->` as `HTMLBlock` nodes. The engine needs to: detect the metadata boundaries, extract the YAML content, parse with Yams, modify (add comments, resolve flags), serialize back to YAML, and replace the `HTMLBlock` content — without corrupting the surrounding Markdown AST. Needs careful prototyping.

4. **Slug disambiguation:** Two `## Examples` headings produce the same slug. Positional suffix (`examples`, `examples-2`) is the likely approach. Need to spec the algorithm precisely.

5. **Parser protocol validation:** Success criterion 7 says "validated by A&D review." I'll sketch what a Swift source code parser would look like against the protocol — functions/classes as sections, method signatures as headings. Don't build it, just prove the interface works.

6. **Concurrent writes (r002):** CLI is stateless, can't race with itself. The real risk is CLI + app on the same bundle. File-level locking? Optimistic concurrency at the bundle level (not just section level)? This is Phase 2 but must be designed now.

## Jordan's Voice

Some direct quotes that capture the principal's intent — useful for alignment in future sessions:

- "I want to be able to mark up with comments a markdown file and you to see them and to preserve the record without blowing out context windows and spending tokens."
- "We build the architecture, we use it for Markdown and then we do something else."
- "If mdpal offers just [the five capabilities] we will have eliminated a major friction point."
- "It is YAML in Markdown, not HTML. I am not that crazy!"
- "It is a need I have. And I also have an itch to build a macOS application. 13 years working at Apple and never shipped my own app."
- On the structured editing vision: "It does capture what I am dreaming we might be building together."
