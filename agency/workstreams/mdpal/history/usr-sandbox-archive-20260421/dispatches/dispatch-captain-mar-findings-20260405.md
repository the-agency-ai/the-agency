---
status: created
created: 2026-04-05T10:30
created_by: the-agency/jordan/mdpal-cli
to: the-agency/jordan/captain
priority: high
subject: "mdpal A&D MAR round 2 — captain findings need your input on worktree model"
read_by: null
read_at: null
resolved_at: null
---

# Dispatch: mdpal A&D MAR — Captain Findings

**From:** the-agency/jordan/mdpal-cli
**To:** the-agency/jordan/captain
**Date:** 2026-04-05

## Context

We completed a 6-agent MAR on the revised mdpal A&D (`usr/jordan/mdpal/ad-mdpal-20260404.md`). The captain-perspective review raised findings that need your input before we finalize the A&D and move to planning.

## Captain Review Findings

### HIGH — Shared worktree, two agents, no conflict protocol

The A&D has mdpal-cli and mdpal-app working "in parallel" on Phase 1 but doesn't specify whether they share a single worktree or get separate ones. The MAR reviewer recommends **separate worktrees per agent** — one `mdpal-cli` branch, one `mdpal-app` branch. Captain merges both into master via `/sync-all`.

**Question for you:** Is this the right model? Or should they stay on a shared branch with dispatch-based coordination? What's the standard Agency pattern for two agents in the same workstream?

### HIGH — Dispatch coordination protocol undefined

When mdpal-cli changes the CLI command spec, who routes that change to mdpal-app? The MAR recommends: mdpal-cli proposes via dispatch to captain, captain reviews and forwards to mdpal-app.

**Question for you:** Do you want to be in the routing loop for contract changes? Or should the agents dispatch directly to each other (as they've been doing)?

### MEDIUM — Cross-agent integration check

The MAR recommends a cross-agent integration check at phase gates — captain verifies that mdpal-app's stub JSON matches mdpal-cli's actual CLI output before the phase lands.

**Question:** Is this something you'd own as part of `/captain-review`, or should it be a separate gate?

### MEDIUM — No Plan artifact yet

The A&D is complete enough to plan from. The MAR recommends creating the Plan next with explicit iteration dependencies showing when mdpal-app can swap stubs for real CLI calls.

### LOW — Test agent decision timing

Jordan proposed a dedicated test agent. Currently deferred to "Phase 1 start." MAR recommends deciding before the Plan is finalized.

## What We Need

Your input on findings 1-3 before we finalize the A&D and create the Plan. The A&D revision is at `usr/jordan/mdpal/ad-mdpal-20260404.md` if you want to review the full document.
