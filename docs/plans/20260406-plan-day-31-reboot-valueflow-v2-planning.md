---
title: "Plan: Day 31 Reboot + Valueflow V2 Planning"
slug: plan-day-31-reboot-valueflow-v2-planning
path: docs/plans/20260406-plan-day-31-reboot-valueflow-v2-planning.md
date: 2026-04-06
status: draft
branch: main
authors:
  - Test User (principal)
  - Claude Code
session: ee9d2ca8-7d2c-47e3-bc99-932128feb706
tags: [Frontend, Infra]
---

# Plan: Day 31 Reboot + Valueflow V2 Planning

**Date:** 2026-04-06 (Day 30)
**Context:** Day 30 — valueflow PVR and A&D completed through full MAR (9/9 reviewers, 64 findings, ready for planning). Dispatch identity bugs, permission friction, and shared worktrees broke local agent communication. Monofolk responds faster than local agents. Clean reboot with curated handoffs, then V2 plan.

**Outcome:** All agents restart with working infrastructure, curated context, and the valueflow methodology. V2 plan drafted and through MAR.

**MAR round 1:** 2 reviewers (general + risk). 7 findings incorporated, 1 disagreed.

---

## Phase 1: Infrastructure Fixes (Captain, before anything pushes)

Fix locally first. Don't push broken state to origin.

### 1.1: Split mdpal worktree

**Pre-flight check:** `git -C .claude/worktrees/mdpal status --porcelain` must be empty. If not, commit or stash before proceeding. Principal confirms.

1. Merge mdpal branch to main (already done — commit 60ea84b)
2. Delete `mdpal` worktree: `git worktree remove .claude/worktrees/mdpal`
3. Create `mdpal-cli` worktree: `git worktree add .claude/worktrees/mdpal-cli -b mdpal-cli`
4. Create `mdpal-app` worktree: `git worktree add .claude/worktrees/mdpal-app -b mdpal-app`
5. Write `.agency-agent`: `mdpal-cli` and `mdpal-app` respectively
6. Merge main into both

### 1.2: Fix all .agency-agent files

Verify every worktree:
| Worktree | .agency-agent |
|----------|---------------|
| main checkout | `captain` |
| `.claude/worktrees/devex` | `devex` |
| `.claude/worktrees/iscp` | `iscp` |
| `.claude/worktrees/mdpal-cli` | `mdpal-cli` |
| `.claude/worktrees/mdpal-app` | `mdpal-app` |

### 1.3: Merge remaining ISCP work

Check iscp branch for commits not on main. Merge if any. Resolve conflicts.

### 1.4: Resolve stale dispatches and flags

**Do NOT bulk-resolve.** Review dispatch subjects for each of the 65 read-but-not-resolved dispatches. Resolve those that are truly done. Flag any that need action. Then process the 9 unread flags — most are conventions already captured.

### 1.5: Update agent registrations

All registrations must include:
- 5-minute dispatch check on startup: `/loop 5m dispatch check`
- Correct handoff path: `{agent}-handoff.md`
- ISCP startup step
- Reference to valueflow A&D

Files: `.claude/agents/captain.md`, `devex.md`, `iscp.md`, `mdpal-cli.md`, `mdpal-app.md`, `mock-and-mark.md`

---

## Phase 2: Package and Push (Captain)

### 2.1: PR all work to origin

All infrastructure fixes + session 30 work. Single PR, merge.

### 2.2: Sync all worktrees

After merge, sync every worktree with main. Verify each picks up the fixes.

---

## Phase 3: Curated Handoffs (Captain)

### 3.1: Write handoff spec

Multi-part template:
- Identity (agent address, workstream, role)
- Current State (valueflow stage, phase/iteration, last commit)
- Valueflow Context (PVR, A&D, MAR disposition paths)
- Active Work (in progress, blocked, next)
- Startup Actions (dispatch loop, process mail, read A&D, resume)

### 3.2: Captain writes all agent handoffs

**Captain writes them directly** — not via dispatch (dispatch infrastructure is the reason for the reboot). Captain has full context from this session. Each handoff curated with correct state, correct references, correct next actions.

### 3.3: Write captain Day 31 bootstrap

Focused: identity, state of play (valueflow at A&D, agents rebooting, what's next). References PVR, A&D, MAR dispositions, V2 plan (when written).

### 3.4: Write "Getting to Day 31 — How We Got Here"

Curated session history. Break-glass backup — only used with principal approval. Referenced in bootstrap but not auto-loaded.

### 3.5: PRINCIPAL GATE

**Stop here. Principal reviews all curated handoffs before any agent shuts down.** Principal approves handoff quality, confirms context is correct, authorizes proceeding to reboot.

---

## Phase 4: Reboot (Principal + Captain)

### 4.1: Bring down all agents

Agents are already running (or idle). Tell each to write their current handoff (informational — captain's curated version is the one that will be used) and shut down.

### 4.2: Captain final sync

- Sync all worktrees with main
- Verify all `.agency-agent` files
- Verify dispatch queue is clean
- Package final PR if any changes, merge

### 4.3: Bring up captain fresh

No session resume — fresh start from Day 31 bootstrap handoff. Verify: identity resolves, dispatch check works, handoff reads correctly. Session resume as backup if bootstrap insufficient.

### 4.4: Bring up ISCP first — verify round-trip

ISCP is infrastructure. Bring up first. Test dispatch round-trip: captain → ISCP → captain. Verify identity in from/to, payload readable, symlinks working. **If round-trip fails, stop. Fix before bringing up more agents.**

### 4.5: Bring up remaining agents

Order: DevEx, then mdpal-cli, mdpal-app, mock-and-mark. Each:
1. Reads bootstrap handoff
2. Sets `/loop 5m dispatch check`
3. Processes any unread dispatches
4. Reports ready to captain via dispatch

### 4.6: Verify all agents

Captain sends test dispatch to each. Each replies. All identities correct, all payloads readable.

---

## Phase 5: Valueflow V2 Plan (Captain, post-reboot)

### 5.1: Write V2 implementation plan

From PVR + A&D + MAR dispositions. Covers:
- Phases and iterations for V2 deliverables
- Dependency graph (what ships first)
- Agent assignments (ISCP, DevEx, captain)
- ISCP dependencies: symlink rollout, flag categories, dispatch authority, schema versioning
- DevEx dependencies: test isolation, permissions, enforcement ladder, context budget linter
- CLAUDE-THEAGENCY.md decomposition sequencing

### 5.2: Agent MAR (autonomous)

Dispatch plan to all agents. Autonomous MAR — agents triage and act without principal unless flagged. First real test of valueflow running on itself with working infrastructure.

### 5.3: Principal review

Review plan + agent MAR dispositions. Approve or revise.

### 5.4: Begin execution

Agents start their assigned phases. Valueflow V2 is live.

---

## Critical Files

| File | Action | Phase |
|------|--------|-------|
| `.claude/worktrees/mdpal/` | DELETE (after pre-flight) | 1.1 |
| `.claude/worktrees/mdpal-cli/` | CREATE | 1.1 |
| `.claude/worktrees/mdpal-app/` | CREATE | 1.1 |
| `.claude/agents/*.md` (6 files) | UPDATE registrations | 1.5 |
| All worktree `.agency-agent` | VERIFY/FIX | 1.2 |
| `usr/jordan/*/handoff.md` | CAPTAIN WRITES ALL | 3.2 |
| `usr/jordan/captain/captain-handoff.md` | REWRITE (Day 31 bootstrap) | 3.3 |
| `usr/jordan/captain/history/how-we-got-here-day31.md` | CREATE (break-glass) | 3.4 |
| `claude/workstreams/agency/valueflow-plan-20260407.md` | CREATE (V2 plan) | 5.1 |

## Dependency Graph

```
Phase 1 (infra fixes) → Phase 2 (push) → Phase 3 (handoffs) → PRINCIPAL GATE → Phase 4 (reboot) → Phase 5 (V2 plan)
```

Strictly sequential. Principal gate between handoffs and reboot.

## Verification

- [ ] All worktrees have correct `.agency-agent`
- [ ] `dispatch check` returns correct results per agent
- [ ] mdpal worktree split clean (no lost work)
- [ ] Dispatch queue clean (stale items reviewed, not bulk-resolved)
- [ ] Round-trip test passes (captain → ISCP → captain) BEFORE other agents
- [ ] All agents report ready after startup
- [ ] Captain Day 31 bootstrap sufficient without session resume
- [ ] Principal approved all handoffs before reboot
