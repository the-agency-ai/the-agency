---
type: incorporation-directive
from: the-agency/jordan/captain
to: monofolk/jordan/captain
date: 2026-04-04
priority: high
---

# Dispatch: Session 18 Framework Updates — Incorporate into Monofolk

## Summary

PR incoming from the-agency with 19 commits covering addressing standards, scoped CLAUDE.md pattern, provenance headers, ISCP workstream creation, flag tool fixes, and MAR-validated quality. Monofolk needs to incorporate these framework changes.

## What Changed

### 1. Addressing Standards (CLAUDE-THEAGENCY.md)
- **Workstream addressing** formalized: `{repo}/{workstream}` — repo-scoped, no principal
- **Dispatch payload locations** codified: agent → `usr/{principal}/{project}/dispatches/`, workstream → `claude/workstreams/{workstream}/dispatches/`
- **Dropbox** concept introduced: `claude/dropbox/{principal}/{agent}/` on master for file staging across worktrees

### 2. Scoped CLAUDE.md Pattern
- **CLAUDE-{WORKSTREAM}.md** in `claude/workstreams/{name}/` — workstream-scoped agent instructions
- **CLAUDE-{AGENT}.md** in `usr/{principal}/{project}/` — agent-scoped instructions
- **Convention:** `@` import from agent registrations in `.claude/agents/{name}.md`
- Table in CLAUDE-THEAGENCY.md formalizes the three layers (Framework / Workstream / Agent)

### 3. Provenance Headers
- **New convention** replacing "comment the why": every script, module, class, method, function gets:
  - `What Problem:` — why it exists
  - `How & Why:` — approach and rationale
  - `Written:` — date and context
- Applied to all code, not just scripts. Full spec in CLAUDE-THEAGENCY.md § Provenance Headers

### 4. Flag Tool Fix
- **Data loss bug fixed**: flag queue (JSONL) was not git-added after writes, lost on session boundaries
- SessionStart hook now warns if flags exist in queue
- Principal resolution fixed (was using `$USER` instead of `AGENCY_PRINCIPAL`)

### 5. ISCP Workstream Created
- New workstream at `claude/workstreams/iscp/` — Inter-Session Communication Protocol
- Scope: flag (SQLite-backed), dispatch lifecycle, ISCP v1 notification hook, dropbox, addressing, cross-repo
- Agent registered at `.claude/agents/iscp.md` with bootstrap handoff
- Seeds include mdpal-cli/mdpal-app mining findings (worktree/master path confusion is #1 friction)

### 6. MAR Validated
- 4-agent review (code, design, test, security) on 860-line diff
- 12 findings found and fixed — zero remaining

## Directive

Incorporate these framework changes into monofolk:
1. Update `claude/CLAUDE-THEAGENCY.md` from this PR
2. Apply the flag tool fix (`claude/tools/flag`)
3. Apply session-handoff.sh flag detection (`claude/hooks/session-handoff.sh`)
4. Review and adopt scoped CLAUDE.md pattern for monofolk workstreams
5. Adopt provenance header convention going forward

If issues arise, discuss with `monofolk/jordan` (jordan-of on GitHub).

## PR Reference

See the-agency PR (created alongside this dispatch) for the full diff.
