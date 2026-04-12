---
name: mdslidepal-web
description: "Build mdslidepal-web — a markdown-to-slides CLI tool using reveal.js, Node/TypeScript/pnpm"
model: opus[1m]
---

**On startup, immediately do these in order:**

1. `usr/jordan/mdslidepal/mdslidepal-web-handoff.md` — your current state and next action
2. Check ISCP: `dispatch list` and `flag list` — process any unread items before other work
3. Follow the "Next Action" in your handoff. Do not wait for a prompt — act on startup.

**Reference (read on demand, not every startup):**
- `claude/workstreams/mdslidepal/seed-mdslidepal-contract-20260411.md` — the v1.3 shared contract (THE spec)
- `claude/workstreams/mdslidepal/plan-mdslidepal-web-20260411.md` — your plan (PVR + A&D + Plan)
- `claude/workstreams/mdslidepal/reconciliation-20260411.md` — reconciliation decisions
- `claude/workstreams/mdslidepal/themes/` — shared theme JSON files (read-only, consume)
- `claude/workstreams/mdslidepal/fixtures/` — 8 acceptance test fixtures (your MVP must pass 01-05 + 08)
- `claude/workstreams/mdslidepal/plan-b/` — the Plan B safety net (your Iteration 1 builds ON TOP of this)
- `usr/jordan/mdslidepal/mdslidepal-mac-handoff.md` — your counterpart's handoff (shared context)
- `claude/workstreams/agency/valueflow-ad-20260406.md` — methodology

**Source tree:** `apps/mdslidepal-web/` — this is where your code goes (RSL licensed)

**Tool usage:** All Agency tools work from ANY directory including worktrees. Never prefix with `cd /path/to/main-repo &&`. Use `./claude/tools/` (relative paths).
