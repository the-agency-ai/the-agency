---
type: working-doc
agent: the-agency/jordan/captain
date: 2026-04-22
purpose: Full triage of all agency issues (open + closed) → Inbox Zero
---

# Agency Issues — Full Triage (2026-04-22)

**Goal:** Inbox Zero. Every open issue resolved with real disposition. Every closed issue validated. No "Won't Fix" / "Deferred" hand-waves.

## Inventory

- **Total:** 247 issues
- **Open:** 183
- **Closed:** 64 (all `COMPLETED` close-reason — no BS closures)
- **Range:** #50 – #424
- **Label distribution:** bug (37), enhancement (34), discuss (19), hip (14), documentation (5), research (5)

## Approach

1. **Parallel classification** — 4 subagents classify ~62 issues each as `bug | feature | friction | question | meta | hip | discuss`. Each captures per issue: `what` (what user wanted), `why` (underlying motivation), `feature_deprecated` (bool + commit ref if yes), severity, notes.
2. **Consolidate** into per-kind tables in this doc.
3. **Feature clusters** — cluster feature requests by theme, 1B1 with principal per cluster, capture go/no-go.
4. **Bug fixes** — parallel subagents validate + test + fix; captain batches into PRs with QG.
5. **Closed-issue validation** — quick sweep to confirm no improperly-closed; all 64 at `COMPLETED` so unlikely but verify.
6. **Close with principal-approved wording** — deprecated-feature closure template:
   > *This feature was deprecated and therefore this specific request is no longer relevant. We will consider the What you wanted and Why you wanted it as we plan our future roadmap and features.*
   >
   > *Deprecated in commit `<sha>` as part of `<context>`. The feature path no longer exists in the framework. If a similar need applies to the replacement feature (`<name>`, tracked in `#<new-issue>`), file a new issue against that.*

## Feature Go/No-Go Axes

1. **Architectural fit** — V5 model (src/ source-of-truth, build-tool, `agency init`/`update`, dual-tracking)
2. **Project scope** — inside framework mandate (agent orchestration, methodology, hookify, receipts, skills, ISCP, session lifecycle)
3. **Name/trademark fit** — 10 reserved marks (The Agency, TheAgency, TheAgencyGroup, Valueflow, MDPal, mdpal, MockAndMark, mockandmark, Attack Kittens, Attack Kitties)
4. **User intent preservation** — What/Why captured regardless of verdict
5. **Spirit/mission fit (primary gate)** — fits:
   - the-agency as a platform
   - AI Augmented Development
   - Valueflow as an AI Augmented Development Life Cycle

## Classification Results

*[populated by subagents]*

### Bugs

| # | Title | State | Feature Deprecated? | Validity | Action |
|---|---|---|---|---|---|

### Features

| # | Title | State | Cluster | What | Why | Go/No-Go |
|---|---|---|---|---|---|---|

### Friction / Questions / Meta / Discuss / HIP

| # | Title | State | Kind | Action |
|---|---|---|---|---|

## Roadmap Signals (from deprecated-feature closures)

*What + Why captured from every deprecated-feature closure, durable input for roadmap planning.*

## Execution Log

*[timestamped actions as we go]*

- 2026-04-22T~07:05Z — Inventory fetched, inbox-zero achieved on dispatches + flags, working doc created
