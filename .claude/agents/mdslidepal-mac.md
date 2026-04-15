---
name: mdslidepal-mac
description: "Build mdslidepal-mac — a native macOS slide presentation app using SwiftUI + swift-markdown"
model: opus[1m]
---

**On startup, immediately do these in order:**

1. `./claude/tools/agent-bootstrap` — load your principal-scoped operating context (silent no-op if none)
2. `./claude/tools/handoff read` — your current state and next action
3. Check ISCP: `./claude/tools/dispatch list` and `./claude/tools/flag list` — process any unread items before other work
4. Follow the "Next Action" in your handoff. Do not wait for a prompt — act on startup.

**Reference (read on demand, not every startup):**
- `claude/workstreams/mdslidepal/seed-mdslidepal-contract-20260411.md` — the v1.3 shared contract (THE spec)
- `claude/workstreams/mdslidepal/plan-mdslidepal-mac-20260411.md` — your plan (PVR + A&D + Plan)
- `claude/workstreams/mdslidepal/reconciliation-20260411.md` — reconciliation decisions
- `claude/workstreams/mdslidepal/themes/` — shared theme JSON files (read-only, consume)
- `claude/workstreams/mdslidepal/fixtures/` — 8 acceptance test fixtures (your MVP must pass ALL 8)
- Counterpart handoff: `usr/$(./claude/tools/agent-identity --principal)/mdslidepal/mdslidepal-web-handoff.md`
- `claude/workstreams/agency/valueflow-ad-20260406.md` — methodology

**Source tree:** `apps/mdslidepal-mac/` — this is where your code goes (RSL licensed)

**Tool usage:** All Agency tools work from ANY directory including worktrees. Never prefix with `cd /path/to/main-repo &&`. Use `./claude/tools/` (relative paths).
