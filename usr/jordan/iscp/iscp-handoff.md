---
type: agent-bootstrap
date: 2026-04-04
agent: the-agency/jordan/iscp
workstream: iscp
---

# ISCP Bootstrap Handoff

**Agent:** the-agency/jordan/iscp
**Principal:** Jordan
**Workstream:** iscp (Inter-Session Communication Protocol)

## What This Is

You are building the messaging layer for The Agency — how agents communicate across sessions, worktrees, and repos. Three primitives unified under one protocol:

1. **Flag** — principal→agent dispatch queue. Quick-capture observations for later 1B1 discussion.
2. **Dispatch** — agent→agent or principal→agent structured messages with payloads.
3. **ISCP v1** — the notification hook that tells agents "you got mail."

## Key Decisions (from captain discussion 2026-04-04)

- **Flag** becomes agent-addressable: `/flag TEXT` (local agent), `/flag agent TEXT` (specific agent), future `/flag agency/agent TEXT` (cross-agency)
- **Persistence** moves to SQLite with a DB abstraction layer, stored **outside the repo** to avoid git pollution. Pattern: `../{repo}/{TBD}/{database}` — same pattern used for service DBs
- **Dispatch** = notification (in DB) + payload (in git at specified location). Full lifecycle: create→commit to master→propagate to worktrees→fetch→notify
- **Code reviews are just a dispatch type**, not a separate system. Deprecate the separate code-review concept.
- **ISCP v1** = a hook that fires on defined events, checks DB for unread items addressed to this agent, surfaces "you got mail" with pointer to the flag message or dispatch payload
- **Addressing** uses the Agency hierarchy: `{org}/{repo}/{principal}/{agent}`. Both agent-based and workstream-based addressing needed. Only dispatches have git payloads; flags are DB-only.
- **Cross-repo support** needed: monofolk ↔ the-agency ↔ ghostty fork

## What Exists Today

- `claude/tools/flag` — current flag tool (JSONL file, principal-scoped, just patched for git persistence but moving to SQLite)
- `claude/tools/dispatch-create` — creates dispatch files
- `.claude/skills/dispatch/SKILL.md` — dispatch management skill
- `usr/jordan/captain/dispatches/` — existing dispatch files (markdown)
- `claude/config/agency.yaml` — principal mapping, used by `_path-resolve`
- `claude/tools/lib/_path-resolve` — address resolution library (has bugs — env leak from test suite)
- CLAUDE-THEAGENCY.md § "Agent & Principal Addressing" — the addressing hierarchy definition

## Open Questions (drive through /define)

1. The `{TBD}` in the DB path pattern — what goes there?
2. Which hook events trigger ISCP v1 notifications? (SessionStart? PreToolUse? Both?)
3. Dispatch type taxonomy — what types beyond code-review?
4. DB schema for flags and dispatch notifications
5. Agent vs workstream payload locations in git
6. Cross-repo delivery mechanism — git-based? API? Filesystem?
7. Addressing scheme formalization for flag/dispatch (captain will dispatch this to you)
8. Transcript location and commit discipline — transcripts must get to master ASAP and be accessible to any workstream
9. Dropbox folder naming convention — what structure under `claude/dropbox/{principal}/{agent}/`?
10. Dropbox push/fetch mechanics — cherry-pick? Direct file copy? How to handle conflicts?

## Seed Materials

- `usr/jordan/captain/transcripts/discussion-transcript-20260404.md` — the discussion that produced these decisions
- `usr/jordan/captain/dispatches/dispatch-iscp-design-20260330.md` — earlier ISCP design thinking
- `usr/jordan/flag-queue.jsonl` — 35 flags currently in queue (the system you're replacing)

## Next Action

1. Read your agent definition at `claude/agents/iscp/agent.md`
2. Read `claude/workstreams/iscp/KNOWLEDGE.md`
3. Read the seed materials listed above
4. Run `/define` to drive toward a complete PVR for the ISCP workstream
5. Then `/design` for A&D
6. Then build the plan

You will receive an addressing scheme dispatch from captain once Item 4 of today's discussion resolves.
