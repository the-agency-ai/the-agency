# Handoff Spec — Day 31 Reboot

Write your handoff now. This is the document that will bootstrap you on your next startup — fresh session, no resume. Make it count.

## File Location

Write to your handoff file using the handoff tool:
```
bash ./claude/tools/handoff write --trigger reboot
```

Then edit the file at: `usr/jordan/{agent}/handoff.md`

## Required Frontmatter Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `type` | string | yes | Always `session` for handoffs. (Legacy handoffs used `handoff`; readers SHOULD tolerate both.) |
| `agent` | string | yes | Fully-qualified agent identity (`repo/principal/agent`). |
| `date` | ISO-8601 | yes | Handoff write time. |
| `trigger` | string | yes | What produced this handoff (e.g., `session-end`, `compact-prepare`, `reboot`). |
| `mode` | enum | **yes (since D45)** | `continuation` or `resumption`. See "`mode:` frontmatter field" below. |
| `branch` | string | no | Git branch at handoff time. |
| `next-action` | string | strongly recommended | One-sentence description of the very next thing to do. |
| `workstream` | string | recommended | The workstream this handoff belongs to (if applicable). |

## `mode:` frontmatter field

The `mode:` field indicates the semantic framing of the handoff.

### Enum values

| Value | Meaning | Set by |
|-------|---------|--------|
| `continuation` | Agent continues in the same process after `/compact`. Post-compact pickup uses trimmed preflight. | `/compact-prepare` (via `claude/tools/session-pause --framing continuation`) |
| `resumption` | Session paused; next pickup is in a fresh process. Full sync + preflight on pickup. | `/session-end` (via `claude/tools/session-pause --framing resumption`) |

### Migration (legacy handoffs)

Prior versions of the handoff spec did not standardize `mode:`. Legacy values in circulation:

- `mode: resume` — treat as equivalent to `resumption`.
- `mode: continuation (keep working after compact)` or similar free-form suffixes — readers MUST extract the leading keyword (`continuation` or `resumption`) and ignore the suffix.
- Missing `mode:` — readers SHOULD treat as `resumption` and emit a one-line warning.

Writers MUST emit only the enum values (`continuation` or `resumption`) — no legacy forms, no suffixes.

The normalization of legacy `mode: resume` → `mode: resumption` across live handoffs lands in the session-lifecycle-refactor Iteration 5.2.

## Structure

Use this exact structure. Fill in every section. No TODOs, no placeholders.

```markdown
---
type: session
agent: {your fully qualified address}
workstream: {your workstream}
date: 2026-04-06
trigger: reboot
mode: resumption
---

## Identity

Who you are. Your fully qualified address, your workstream, your role in one sentence.

## Current State

What stage of work are you in? What phase/iteration? What was the last thing you did? What's the state of your artifacts (PVR, A&D, Plan, code)?

Be specific: commit hashes, file paths, dispatch IDs.

## Valueflow Context

The methodology you operate under:
- PVR: claude/workstreams/agency/valueflow-pvr-20260406.md
- A&D: claude/workstreams/agency/valueflow-ad-20260406.md
- MAR dispositions: claude/workstreams/agency/reviews/

Read the A&D on startup — it defines how you work.

## Active Work

What's in progress right now? What's blocked? What were you working on when you stopped?

List specific files you were editing, dispatches you were processing, reviews you were responding to.

## Key Decisions

Decisions made during your session that a fresh instance needs to know. Not everything — just the ones that would change how you approach the work.

## Open Items

What's unfinished? What needs attention on restart? Dispatches to respond to, reviews to complete, bugs to fix?

## Startup Actions

On your next startup, do these in order:
1. Set dispatch loop: /loop 5m dispatch check
2. Process unread dispatches: dispatch list
3. Process unread flags: flag list
4. Read the valueflow A&D: claude/workstreams/agency/valueflow-ad-20260406.md
5. Resume from [your specific next action]
```

## When to Write

Handoffs are manual — agents must call the tool explicitly. Write a handoff at:

- **Boundary commands:** `/iteration-complete`, `/phase-complete`, `/plan-complete`, `/pre-phase-review`
- **Before exit/restart:** Always write before ending a session or restarting
- **After `/sync-all`:** Lightweight handoff noting what synced
- **At discussion milestones:** PVR draft, key A&D decision, plan revision
- **Before context-heavy work:** Insurance against compaction or crash

Always invoke the `/handoff` skill or run `./claude/tools/handoff write` — never write the file directly. The tool archives the previous handoff to `history/` with a timestamp.

**Note:** Never use `$CLAUDE_PROJECT_DIR` in Bash tool calls — the variable is only set inside hooks, not in agent shell sessions. Use `./claude/tools/` (relative paths) instead.

## Rules

1. **Be specific, not general.** "Working on tests" is useless. "Implementing convention-based test scoping in claude/tools/commit-precheck, T1 tier with 60s budget" is useful.

2. **Include file paths.** A fresh instance doesn't know where things are. Give it paths.

3. **Include dispatch IDs.** If you have unprocessed dispatches, list the IDs.

4. **Don't dump your whole session.** This is a bootstrap document, not a transcript. What does a fresh instance need to pick up where you left off?

5. **Commit your handoff.** `git add` your handoff file and commit it to your branch before shutting down.

6. **Under 100 lines.** If it's longer, you're including too much. Summarize. Link to artifacts for detail.
