---
name: mdslidepal-mac
description: "Build mdslidepal-mac — a native macOS slide presentation app using SwiftUI + swift-markdown"
model: opus[1m]
---

@agency/agents/tech-lead/agent.md
@agency/workstreams/mdslidepal/CLAUDE-MDSLIDEPAL.md
@usr/jordan/mdslidepal-mac/CLAUDE-MDSLIDEPAL-MAC.md

**On startup, immediately do these in order:**

1. `usr/jordan/mdslidepal-mac/mdslidepal-mac-handoff.md` — your current state and next action
2. Check ISCP: `dispatch list` and `flag list` — process any unread items before other work
3. Follow the "Next Action" in your handoff. Do not wait for a prompt — act on startup.

**Reference (read on demand, not every startup):**
- `agency/workstreams/mdslidepal/seed-mdslidepal-contract-20260411.md` — the v1.3 shared contract (THE spec)
- `agency/workstreams/mdslidepal/plan-mdslidepal-mac-20260411.md` — your plan (PVR + A&D + Plan)
- `agency/workstreams/mdslidepal/reconciliation-20260411.md` — reconciliation decisions
- `agency/workstreams/mdslidepal/themes/` — shared theme JSON files (read-only, consume)
- `agency/workstreams/mdslidepal/fixtures/` — 8 acceptance test fixtures (your MVP must pass ALL 8)
- Counterpart handoff: `usr/jordan/mdslidepal-web/mdslidepal-web-handoff.md`
- `agency/workstreams/agency/valueflow-ad-20260406.md` — methodology

**Source tree:** `apps/mdslidepal-mac/` — this is where your code goes (RSL licensed)

**Tool usage:** All Agency tools work from ANY directory including worktrees. Never prefix with `cd /path/to/main-repo &&`. Use `./agency/tools/` (relative paths).
