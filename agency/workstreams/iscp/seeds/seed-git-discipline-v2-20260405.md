---
type: seed
date: 2026-04-05
source: captain session 20 — 1B1 discussion with Jordan
status: ready-for-define
scope: git commit flow, dispatch-on-commit, captain auto-merge, QGR enforcement, MAR, git-pr tool
---

# Seed: Git Discipline v2

## Problem

Agents in monofolk (and any project using the-agency) are blocked from committing. This slows execution — agents can't flow through plan phases and iterations without principal intervention at every commit boundary. We need agents to commit freely at defined boundaries while maintaining quality control and coordination visibility.

## Design Decisions (from discussion)

### Agent Commit Flow

1. Agents commit whenever they have a unit of work. Not gated on permission — gated on QG/MAR passing.
2. Defined boundaries that WILL commit (skills call commit tool internally):
   - PVR complete/revision → `/define` calls MAR → `git-safe-commit`
   - A&D complete/revision → `/design` calls MAR → `git-safe-commit`
   - Plan complete/revision → plan skill calls MAR → `git-safe-commit`
   - `/iteration-complete` → QG → `git-safe-commit`
   - `/phase-complete` → deep QG → `git-safe-commit`
   - `/plan-complete` → deep QG → `git-safe-commit`
3. Agents can commit outside these boundaries too — the tool doesn't police "are you at a boundary?"
4. Every commit dispatches "committed" notification to captain.
5. Agents CANNOT commit to main. Tool enforces branch check.
6. Agents CANNOT use raw `git commit`. Hookify rule blocks it, points to `/git-safe-commit`.

### QGR Enforcement in the Tool

The `agency/tools/git-safe-commit` bash tool must mechanically enforce the stage-hash receipt check:
1. Compute stage-hash of staged changes
2. Glob for matching QGR or MAR receipt
3. No receipt + no `--force` → exit 1, blocked
4. Receipt found → commit proceeds

Currently this check is only in the skill's markdown instructions — not in the bash tool. Must move to the tool for mechanical enforcement. An agent following instructions is trust; a tool that exits 1 is enforcement.

Receipt type doesn't matter (QGR or MAR) — the tool just needs *a* receipt matching the staged content.

### MAR (Multi-Agent Review) for Artifacts

MAR is the QG for non-code artifacts (PVR, A&D, Plan). Already proven in captain PVR review. Needs formalization:
- **Tool:** `agency/tools/mar` (or integrated into existing QG tool with `--type artifact`)
- **Skill:** `/mar` or integrated into `/quality-gate --artifact`
- **Hookify:** Block committing artifact files without MAR receipt
- Produces a MAR receipt with stage-hash, same format as QGR receipt

### Captain Auto-Merge

When captain receives a "committed" dispatch:
1. Auto-merge worktree branch → main (clean merges only)
2. Escalate to principal on conflict
3. Sync main → all other worktree branches
4. Dispatch "main-updated" to all agents

Rationale: merge conflicts have been extremely rare in practice. Manual confirmation on every merge is unnecessary friction.

### Captain PR Flow — `git-pr` Tool

New Enforcement Triangle:

| Layer | What |
|-------|------|
| **Tool** | `agency/tools/git-pr` — creates/updates PR via `gh`, dispatches "pr-created" |
| **Skill** | `/git-pr` — captain's PR skill |
| **Hookify** | Block raw `git push` for captain — must use `/git-pr` |

`git-pr` does:
1. Verify on PR branch (not main)
2. Check for QGR receipt
3. `gh pr create` or `gh pr update`
4. Dispatch "pr-created" to relevant agents
5. Never pushes to main directly

### Kill `/ship`

`/ship` conflates agent and captain roles (commit + push + PR in one grab-bag). Originally from monofolk where developers ship feature branches. Doesn't fit the new model.

Action: delete the skill, scrub all documentation references. Its responsibilities split into:
- Agent commit flow → `/iteration-complete` etc. → `/git-safe-commit` → dispatch
- Captain PR flow → `/git-pr` → dispatch

If a framework release workflow is needed later, that's `/release` — a separate concern.

## Dispatch Types Needed

| Type | From | To | When |
|------|------|----|------|
| `commit` | agent | captain | Agent commits on worktree |
| `main-updated` | captain | all agents | Captain merges to main |
| `pr-created` | captain | relevant agents | Captain creates/updates PR |

## Cross-Repo Dispatch Pattern (Learned)

Cross-repo dispatches use git-file-based messaging through a private collaboration repo (`the-agency-ai/collaboration-{team}`). SQLite is local-only (ISCP v1), so cross-repo is file-based.

**Structure:**
```
collaboration-monofolk/
  dispatches/
    the-agency-to-monofolk/    — outbound from the-agency captain
    monofolk-to-the-agency/    — inbound from monofolk agents
```

**Protocol:**
1. Writer creates dispatch file with `status: unread`, commits, pushes
2. Reader pulls, updates status to `read`, commits, pushes
3. Resolver updates to `resolved`, commits, pushes

**Naming:** `{type}-{slug}-{YYYYMMDD-HHMM}.md`

**Adoption pattern (from live exercise):**
1. Create collaboration repo with dispatch dirs and protocol README
2. Send adoption directive with tool manifest, config changes, smoke tests
3. Include any immediate action items (e.g., kill `/ship`)
4. Recipient creates PR in their repo with all changes
5. Recipient sends reply dispatch confirming adoption

This was exercised live for monofolk ISCP adoption (2026-04-05). The dispatch at `collaboration-monofolk/dispatches/the-agency-to-monofolk/directive-iscp-adoption-20260405-1900.md` is the reference example.

## Kill `/ship`

`/ship` is removed from the-agency and all adopting projects. Conflates agent commit and captain PR roles. Responsibilities split to `/git-safe-commit` (agents) and `/git-pr` (captain).

Action: delete skill, scrub all documentation references, remove from settings.json permissions.

## Summary

The model: agents execute freely (QG/MAR enforced mechanically), captain coordinates automatically (merge + sync + PR), everything dispatches. Principal intervention only on conflicts, phase approvals, and PR review.

```
Agent (worktree)                    Captain (main)                   Origin
─────────────────                   ──────────────                   ──────
work → QG/MAR → git-safe-commit
  └─ dispatch: "committed"  ───→   auto-merge to main
                                   sync main → all branches
                                     └─ dispatch: "main-updated"
                                   ...
                                   pr-prep → git-pr  ──────────────→ PR
                                     └─ dispatch: "pr-created"
```
