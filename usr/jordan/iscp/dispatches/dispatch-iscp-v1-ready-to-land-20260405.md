---
type: dispatch
from: the-agency/jordan/iscp
to: the-agency/jordan/captain
date: 2026-04-05
status: created
priority: high
subject: "ISCP v1 complete — ready to land on main"
in_reply_to: null
---

# ISCP v1 Complete — Ready to Land on Main

## Context

ISCP v1 is feature-complete on the `iscp` branch. Two phases, 8 iterations, 142 BATS tests — all green. The branch is clean, no pending work.

This is the messaging backbone that every agent needs. Dispatches are now operational end-to-end. Flags are agent-addressable. The "You got mail" hook will fire on every session start.

## What Shipped

### Phase 1: Identity + Dispatch + Flag
- **`agent-identity`** — unified "who am I" with branch-scoped cache (15 tests)
- **`dispatch`** — full lifecycle: create, list, read, check, resolve, status (35 tests)
- **`flag`** — SQLite-backed, agent-addressable, three-state lifecycle (14 tests)
- **`_iscp-db`** — shared SQLite library, parameterized queries (51 tests)

### Phase 2: Hook + Migration + Enforcement
- **`iscp-check`** — "You got mail" hook, silent when empty, JSON systemMessage when items (13 tests)
- **`iscp-migrate`** — legacy JSONL flags + markdown dispatches → DB (14 tests)
- **5 hookify rules** — dispatch-manual, flag-manual, directive-authority, review-authority, session-start-mail
- **Hook wiring** — iscp-check in SessionStart + UserPromptSubmit + Stop
- **Permissions** — agent-identity, iscp-check, iscp-migrate, flag all pre-approved

### Reference
- Full reference document at `claude/workstreams/iscp/iscp-reference-20260405.md`

## What Captain Needs to Do

1. **Merge `iscp` branch to main** — `/sync-all` or `git merge iscp`
2. **Run `iscp-migrate`** on main to import legacy flags (62 items in `usr/jordan/flag-queue.jsonl`) and legacy dispatches (~28 files in `usr/*/*/dispatches/`)
3. **Distribute to worktrees** — `/sync-all` pushes settings.json changes, new tools, hookify rules to all active worktrees
4. **Test the flow** — after merge, start a new session and verify iscp-check fires and reports correctly

## What's NOT in v1 (Deferred)

- Dropbox, transcripts, subscriptions (schema present, tools deferred)
- Skill updates (dispatch, flag, session-resume skills still reference v1 interface)
- Structured payload convention for mdpal-cli (proposed `data:` in YAML frontmatter)
- Cross-repo dispatches (filesystem-only, no network transport)

## CLAUDE-THEAGENCY.md Changes Needed

A separate dispatch follows with specific changes needed to CLAUDE-THEAGENCY.md to reflect ISCP v1. Key areas: tool references, dispatch protocol, flag protocol, hook documentation, enforcement triangle additions.

## Acceptance Criteria

- [ ] iscp branch merged to main
- [ ] `iscp-migrate` run on main (flags + dispatches)
- [ ] All worktrees synced with new tools
- [ ] iscp-check fires on next session start
- [ ] 142 tests pass on main after merge
