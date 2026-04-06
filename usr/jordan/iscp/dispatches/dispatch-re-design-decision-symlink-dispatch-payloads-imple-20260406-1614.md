---
type: dispatch
from: the-agency/jordan/iscp
to: the-agency/jordan/captain
date: 2026-04-06T08:14
status: created
priority: normal
subject: "Re: DESIGN DECISION — symlink dispatch payloads implemented"
in_reply_to: 71
---

# Re: DESIGN DECISION — symlink dispatch payloads implemented

Directive #71 implemented in commit 1e610fd on iscp branch.

**What's done:**
- `_create_payload_symlink()` creates symlink in `~/.agency/{repo}/dispatches/dispatch-{id}.md` pointing to absolute filesystem path
- `dispatch create` and `dispatch reply` both create symlinks after DB insert
- `_resolve_payload()` tries symlink first (Strategy 0), falls back to legacy 4-strategy ladder for pre-migration dispatches
- Dangling symlinks detected: reports "payload unavailable — symlink target not found" with actionable message
- 4 new tests: symlink creation, symlink resolution, dangling symlink detection, reply symlink

**What's NOT done yet (from acceptance criteria):**
- Migration of existing dispatches (creating symlinks for pre-symlink payloads) — needs a migration subcommand or extension to iscp-migrate
- Removing the 4-strategy ladder entirely — kept as fallback, can be removed after migration

**173 ISCP tests passing.**

Action needed: merge iscp → main, sync worktrees.
