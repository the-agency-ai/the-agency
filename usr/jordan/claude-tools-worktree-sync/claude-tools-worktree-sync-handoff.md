---
type: session
agent: the-agency/jordan/captain
workstream: the-agency
date: 2026-04-19
trigger: session-compact
mode: autonomous-overnight-execution
---

# Captain handoff — pre-compact: Plan v4 committed; autonomous Phase-0-through-6 execution to begin

**⚠ Handoff agent identity bug:** writes under `claude-tools-worktree-sync` (branch-derived #274). THIS IS CAPTAIN'S handoff. Full content below.

## Principal directive (verbatim, D45 ~2026-04-19 22:50)

> Plan:
> 1. Commit to plan
> 2. /session-compact & /compact
> 3. Execute autonomously and overnight
>
> Hopefully, we are finished in the morning.
>
> No BS stops, because I feel my context being heavy.

**Translation:**
- Commit Plan v4 ✓ (done: 9360ea8e)
- Principal runs /session-compact + /compact (after this handoff)
- Captain resumes post-compact and executes Plan v4 **autonomously**, no questions
- Target: Plan v4 executed through Phase 6 by morning
- **Zero BS stops** — decide autonomously; fold MAR findings inline per zero-defer; only stop for session-compact breakpoints per plan budget

## Current state (pre-compact)

- **Branch:** `contrib/claude-tools-worktree-sync`
- **Last commit:** `9360ea8e` (Plan v4 Valueflow artifact, committed this session)
- **Working tree:** clean after this handoff commit
- **Plan v4 location:** `agency/workstreams/the-agency/plan-the-agency-structural-reset-20260419.md`
- **Plan v4 history:** v1 archived at `claude/workstreams/the-agency/history/plan-the-agency-structural-reset-20260419-1310.md`; v2 + v3 were in-conversation iterations (never committed as separate files, folded into v4)

## MAR convergence achieved

3 MAR iterations with zero-defer:
- v2 MAR: 78 findings (29 HIGH) → 49 ≥50 folded
- v3 MAR: 49 findings (1 HIGH R-3) → all ≥50 folded
- v4 MAR: 22 findings (0 HIGH, 3 MEDIUM borderline) → all folded
- LOWs folded per no-broken-windows directive

## Resume behavior — AUTONOMOUS EXECUTION

**On session-resume post-compact**, captain IMMEDIATELY (no asking):

### Step A: Re-orient (1 min)
1. Read this handoff
2. `git-safe log --oneline -5` to confirm on `9360ea8e`
3. Start dispatch monitor (silent background)
4. Start phase cursor: `usr/jordan/captain/reset-baseline-20260419/PHASE-CURSOR.txt` initialized

### Step B: Execute Phase 0 (baseline + tooling, ~90 min)

Per Plan v4 §3 Phase 0:

**0a. Pre-reset baseline:**
- `git-captain tag v45.3-pre-reset` + push
- Capture baseline inventory: content-inventory.sha256, bats-baseline.txt, ref-inventory-pre.txt (with excludes), hookify-rule-count.txt, skill-count.txt, settings-checksum.txt, claude-md-checksum.txt, baseline-symlink-check.txt (tree-wide find), sensitive-dirs-sha256.txt, env-file-inventory.txt
- PHASE-CURSOR.txt chain-hash entry for phase-0a

**0b. Tool build (20 tool rows per Plan v4):**
- New tools: git-safe ls-files subcommand, git-rename-tree, agency-sweep (with --output-patch + cascade-prevention), ref-inventory-gen, import-link-check, subagent-scope-check, subagent-diff-verify, subagent-overlap-check, audit-log-merge, audit-log-reconcile, hookify-rule-canary, agency-verify-v46 (--customer / --internal), agency-migrate-prep, agency update --migrate + --migrate-back, agency-health v46 broken-state, agency-report, gate-check-{0,1,2,3,3.5,3.6,4,4.5,5,6,7}.sh (11 gates), smoke-battery.sh, reset-rollback.sh, hookify.block-git-clean-during-reset rule
- Each tool ships BATS fixture with declared min-test-count; Gate 0 asserts ≥ declared mins
- Allowlist file: agency/tools/ref-sweep-allowlist.txt (≥14 seed entries w/ rationale per line)

**0c. Subagent manifests (declared partitioning; concrete files at Phase 4 start):**
- A=tools, B=docs, C=tests, D=discovery-bodies, E=config
- ownership_priority 1..5 (A narrowest, E broadest)

**0d. Release notes + migration runbook skeletons with §0d slot manifest**

**Gate 0 exit checks** via gate-check-0.sh (all mechanical)

**MAR checkpoint 0→1:** 3 reviewers (operations, verification, product); fold ≥50 inline; max 2 re-MAR cycles; 15 min fold budget

### Step C: Execute Phase 1 through Gate 7 per Plan v4

Follow Plan v4 §3 phase-by-phase with inline MAR checkpoints per §4 table.

### Session-compact breakpoints (pre-declared per Plan v4)

**Breakpoint 1 — Phase 0 exit (~90 min in):** if clock >120 min, `/session-compact` + write handoff + direct to `/compact`. Handoff directs next session to resume at Phase 1.

**Breakpoint 2 — Phase 3.6 exit (~210 min in cumulatively):** pre-declared natural handoff. If wall-clock > 240 min, compact before Phase 4.

**Between phases:** if a checkpoint exceeds 15-min fold budget, compact + principal 1B1 required. Principal asleep overnight — **do NOT flag principal for 1B1 during overnight**; instead compact and wait for morning principal 1B1 on resume.

### Critical overnight discipline

- **Zero-defer** but **zero principal disruption overnight**: if MAR finding needs principal 1B1 (conflict with closed blocker), capture in handoff + compact + wait for morning. Do NOT dispatch to principal overnight.
- **Decide autonomously** within scope the principal already greenlit (Plan v4).
- **Fold all MAR findings inline** that don't need principal override.
- **Commit at every phase boundary** (per Principle 3 atomic-per-phase).
- **Phase cursor + audit log** kept current at every gate pass.

### Morning target state

- Plan v4 Phase 0 through Phase 6 executed
- All phase commits on `contrib/claude-tools-worktree-sync` (or new branch `v46.0-structural-reset` if cut per §3 branching decision in PVR MAR P8)
- Full BATS green post-reset
- Release notes + migration runbook finalized
- QGR-v46.0 aggregation at `agency/workstreams/the-agency/qgr/qgr-v46.0-reset-20260419.md`
- PR created via `./agency/tools/pr-create` with complete body
- PR awaits principal review in morning

### If blocked overnight

Write a "blocker" handoff clearly stating:
- What phase blocked
- Exact blocker (file, error, finding)
- What principal needs to decide
- State preserved (phase cursor + audit log committed)
- No principal dispatches (principal asleep)

Principal sees blocker in morning handoff read; decides; captain resumes.

## Branch decision (captain autonomous per PVR MAR P8)

Plan v4 execution happens on... **decision**: continue on `contrib/claude-tools-worktree-sync`. This branch already has PR #294 open with Plan v4 + MAR triages committed. Executing Phase 0-6 on this same branch makes the PR scope grow substantially. The earlier plan said "new branch after #294 merges" — but PR #294 is OPEN not MERGED, and principal wants overnight execution.

**Override decision:** cut `v46.0-structural-reset` branch from `contrib/claude-tools-worktree-sync` HEAD (inherits Plan v4 commit) + proceed there. PR #294 stays as-is for merge later; new PR for v46.0 reset.

**Alt override:** stay on this branch, grow PR #294 scope. Cleaner at merge time because one combined PR. Principal's morning review decides.

**Captain choice:** cut new branch `v46.0-structural-reset` from current HEAD at Phase 0 entry; proceed there. Preserves PR #294's current state; clean v46.0 reset PR at end. Per-plan §3 Gate 7 exit plan.

## Flag + dispatch queue

- 11 flags already processed (3 deferred to post-v46 1B1 per earlier handoff)
- Dispatch 737 (commit-self-notify) auto-generated from Plan v4 commit — resolve post-compact
- Fresh dispatch monitor starts on session-resume

## Files critical to re-read on resume

1. `agency/workstreams/the-agency/plan-the-agency-structural-reset-20260419.md` (Plan v4 — THE execution spec)
2. `agency/workstreams/the-agency/pvr-the-agency-structural-reset-20260419.md` (PVR context)
3. `agency/workstreams/the-agency/ad-the-agency-structural-reset-20260419.md` (A&D context)
4. This handoff for directive + state

## Compact instruction

**After this handoff is written, principal runs:**
```
/session-compact
/compact
```

Post-compact, captain re-orients and begins Phase 0 autonomous execution.

## Next-action (single line)

**RESUME ACTION (post-compact): cut `v46.0-structural-reset` branch from HEAD; begin Plan v4 Phase 0 (Baseline + Tooling Build); autonomous execution through Gate 7 with session-compact breakpoints per Plan v4 budget protocol; morning target: PR created + principal review ready.**

— captain, D45 pre-compact, 2026-04-19
