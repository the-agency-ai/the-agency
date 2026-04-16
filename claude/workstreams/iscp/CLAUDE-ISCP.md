# CLAUDE-ISCP — Workstream Instructions

## Scope

The ISCP workstream builds the messaging layer for The Agency:

**In scope:**
- **Flag** — agent-addressable quick-capture queue, SQLite-backed outside repo
- **Dispatch** — structured agent-to-agent/workstream messages, notification in DB + payload in git
- **ISCP v1 hook** — "you got mail" notification on defined events, checks DB for unread items
- **Dropbox** — file staging area at `claude/dropbox/{principal}/{agent}/` on master. `dropbox push` sends from worktree→master, `dropbox fetch` pulls master→worktree. Handles all branch mechanics. Tied into ISCP dispatch notifications.
- **Addressing** — agent (`{repo}/{principal}/{agent}`) and workstream (`{repo}/{workstream}`) targeting
- **DB pattern** — SQLite with abstraction layer, outside repo at `../{repo}/{TBD}/{database}`
- **Cross-repo/cross-agency dispatch** — monofolk ↔ the-agency ↔ ghostty fork

**Not in scope:**
- Tools that consume dispatches (code-review, captain-review — those are consumers, not the protocol)
- Handoff tool — related but separate lifecycle, stays as-is for now
- Application code in other workstreams

## Conventions

- **Dispatch payloads are immutable.** Once written, never overwritten. Named `{type}-{YYYYMMDD-HHMM}.md`.
- **Agent dispatch payloads** land at `usr/{principal}/{agent-project}/dispatches/`
- **Workstream dispatch payloads** land at `claude/workstreams/{workstream}/dispatches/`
- **Flags are DB-only.** No git payload — notification + content in SQLite.
- **Code reviews are a dispatch type**, not a separate system.

## Methodology

Follow the standard Agency development methodology:
1. `/define` → PVR
2. `/design` → A&D
3. Plan → Phases × Iterations
4. Quality gates at every boundary

## Review Discipline

**All design decisions go through captain for review before implementation.**

- PVR draft → dispatch to captain for review
- A&D draft → dispatch to captain for review
- Plan → captain approval before Phase 1
- Phase boundaries → `/phase-complete` with captain approval

Do not implement without captain sign-off on the design. This is foundational infrastructure — getting the design right matters more than speed.

## Seeds and Reference

- `usr/jordan/iscp/seeds/` — seed materials
- `usr/jordan/iscp/dispatches/` — incoming dispatches (check on startup)
- `claude/workstreams/the-agency/transcripts/discussion-transcript-20260404.md` — the founding discussion
- `claude/tools/flag` — current flag implementation (being replaced)
- `claude/tools/dispatch-create` — current dispatch tool (being replaced)
- `claude/tools/lib/_path-resolve` — address resolution library (has bugs)
