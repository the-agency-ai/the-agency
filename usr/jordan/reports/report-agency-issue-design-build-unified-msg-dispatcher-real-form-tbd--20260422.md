---
report_type: agency-issue
issue_type: feature
filing_agent: the-agency/jordan/captain
filed_by: jordan
date_filed: 2026-04-22
target_repo: the-agency-ai/the-agency
github_issue: https://github.com/the-agency-ai/the-agency/issues/414
github_issue_number: 414
status: open
---

# Design + build unified `msg` dispatcher (real form, TBD — old spec swept)

**Filed:** 2026-04-22T01:26:30Z
**Target:** [the-agency-ai/the-agency](https://github.com/the-agency-ai/the-agency)
**Issue:** [#414](https://github.com/the-agency-ai/the-agency/issues/414)
**Type:** feature
**Status:** open

## Filed Body

**Type:** feature

# Design + build unified `msg` dispatcher (real form, TBD)

## Context

`REFERENCE-DISPATCH-AND-MESSAGING.md` previously documented `./agency/tools/msg` as the canonical successor for 7 retired tools:

- `collaborate`, `collaboration-respond` (cross-repo)
- `news-post`, `news-read` (broadcast)
- `message-send`, `message-read` (agent-to-agent)
- `dispatch-collaborations` (listing)

14 doc refs across REFERENCE-* files pointed at `./agency/tools/msg`. The binary never shipped, and per principal directive 2026-04-22, the **documented form was not the form we're actually building**. The spec had drifted from intent.

**Resolution for now (companion PR, v46.?):** sweep all 14 misleading `msg` refs from the docs. Replace each with the currently-shipping tool (`dispatch` / `collaborate` / `flag`) that owns the behavior today. Add a "Messaging consolidation in progress" note at the top of `REFERENCE-DISPATCH-AND-MESSAGING.md` — acknowledges direction without committing to a specific binary name or spec that will drift again.

## This issue: capture the real `msg` design

When principal is ready to flesh out the real form, this issue captures the intent so it doesn't get lost.

### Known requirements (from what `msg` was supposed to do)

- Single UX surface for messaging across the framework
- Should subsume current 4-tool stack (`dispatch`, `collaborate`, `flag`, `dispatch-monitor`) in a principled way
- Must handle intra-repo (agent ↔ agent), cross-repo (the-agency ↔ monofolk / the-agency-group), broadcast (news-post style), and self-queue (flag style)

### Open questions (principal to answer during design)

- Is `msg` the right name, or something else?
- Subcommand shape: verbs (`send`, `read`, `list`, `resolve`) or message-type-first (`dispatch`, `collab`, `flag`)?
- Does it replace the 4 current tools (migration), or coexist (wrapper)?
- SQLite ISCP-DB backing (like dispatch/flag today) or event stream / new store?
- How does monitoring work (event-driven like dispatch-monitor, polling, webhook)?
- Cross-repo authentication model — extends `collaborate`'s current mechanism or new?
- Scope of broadcast (news-post) — is this a separate use case or subset of dispatch?

### Not-in-scope

- Interim wrapper / thin shim around existing tools — rejected; re-work required when real form lands
- Re-shipping old-spec `msg` — rejected; spec is wrong

## Priority

Low-urgency, high-intent. Don't ship until principal has design clarity. Sweep PR handles the "docs lying" problem today; this issue keeps the door open for the real build.

## Context

- Principal 1B1: 2026-04-22 session, Item 4 of 6
- Related: Phase -1 audit `agency/workstreams/agency/research/latent-tool-reference-audit-20260422.md` (14 refs identified)
- Companion sweep PR: (will link when PR opened)

## Response Log

_(append responses, comments, and state changes here as they occur)_

- **2026-04-22:** Filed via `agency-issue file`. Issue created at https://github.com/the-agency-ai/the-agency/issues/414
