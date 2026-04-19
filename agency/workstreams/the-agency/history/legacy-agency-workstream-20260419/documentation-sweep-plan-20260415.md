---
type: plan
project: documentation-sweep
workstream: agency
date: 2026-04-15
pvr: agency/workstreams/agency/documentation-sweep-pvr-20260415.md
status: reviewed
mar: 2 agents, 11 findings incorporated
---

# Plan: Documentation Sweep — Day 40 Changes + REFERENCE- Refactor

## Strategy

**Iteration 1 is SEQUENTIAL** (must complete before 2-4 run). Iterations 2, 3, 4 run in PARALLEL via subagents. Iteration 5 is final gate (MAR + RGR + PR).

## Iterations

### Iteration 1: REFERENCE- refactor (SEQUENTIAL — prerequisite for all others)

**Goal:** All reference docs moved to new naming, all references updated.

**Captain owns:** File renames + global reference updates. Not a subagent — too much cross-cutting.

**Tasks:**
1. `git mv` each `claude/docs/*.md` → `agency/REFERENCE-*.md` (keep README-* as-is)
2. Update `agency/hooks/ref-injector.sh` paths for all renamed docs
3. Add placeholder entries in ref-injector for REFERENCE-RECEIPT-INFRASTRUCTURE and REFERENCE-SAFE-TOOLS (to be created in Iter 3)
4. Update every reference to `claude/docs/` in:
   - Root `CLAUDE.md`
   - `agency/CLAUDE-THEAGENCY.md` (bootloader + Reference Docs table)
   - All skills (.claude/skills/**/*.md)
   - All hookify rules (agency/hookify/*.md)
   - README-* files
   - Workstream docs in agency/workstreams/ (if any)
5. Verify: `grep -r "claude/docs/" --exclude-dir=.git --exclude-dir=usr --exclude-dir=history` returns nothing

**Done when:** All docs renamed, all references updated, ref-injector has placeholders for new docs.

### Iteration 2: Update bootloader + READMEs (PARALLEL)

**Goal:** Core framework docs reflect D40 reality.

**Subagent 2A owns:** CLAUDE-THEAGENCY.md, README-THEAGENCY.md

**Tasks for 2A:**
1. **CLAUDE-THEAGENCY.md**:
   - Update Safe Tools section with all 4 blocked commands (git, git push, cp, gh pr create)
   - Update Key Skills table: add `/session-compact`, `/release`, rename `/session-end` note; remove `/ship`
   - Update Reference Docs table with 2 new rows (REFERENCE-RECEIPT-INFRASTRUCTURE, REFERENCE-SAFE-TOOLS)
   - Add Valueflow stream model reference (work/delivery/value)
   - Add session-preflight mention
2. **README-THEAGENCY.md**:
   - Safe tools family overview
   - Receipt infrastructure overview
   - /release rename from /ship
   - Branch protection note

**Subagent 2B owns:** README-ENFORCEMENT.md, README-GETTINGSTARTED.md

**Tasks for 2B:**
1. **README-ENFORCEMENT.md**:
   - Add block-raw-push, block-raw-cp, block-raw-pr-create rules
   - Document the hookify decision:block+exit 2 fix (enforcement was theater before)
   - Update Enforcement Triangle examples with new tools
2. **README-GETTINGSTARTED.md**:
   - Setup flow with safe tools
   - Branch protection note (requires PR approval)
   - First-release pointer (to YOUR-FIRST-RELEASE.md from Iter 3)

**Done when:** Both subagents complete, no references to /ship or /git-commit remain.

### Iteration 3: Create new docs (PARALLEL)

**Goal:** New infrastructure has both overview (README-) and spec (REFERENCE-) docs.

**Subagent 3A owns:** Receipt infrastructure docs

**Tasks for 3A:**
1. **README-RECEIPT-INFRASTRUCTURE.md** — overview: what it is, when to use, five-hash chain explanation, enforcement role
2. **REFERENCE-RECEIPT-INFRASTRUCTURE.md** — full spec: naming convention, hash computation, tool reference (diff-hash, receipt-sign, receipt-verify), format version, chain of trust

**Subagent 3B owns:** Safe tools docs + first-release guide

**Tasks for 3B:**
1. **README-SAFE-TOOLS.md** — overview of git-safe, git-captain, git-safe-commit, git-push, cp-safe, pr-create
2. **REFERENCE-SAFE-TOOLS.md** — full spec: CLI reference for each tool, exit codes, exemption rules
3. **YOUR-FIRST-RELEASE.md** — **placement: `claude/` root** (alongside README-THEAGENCY.md). Step-by-step guide: make a change → iteration-complete → phase-complete → pr-prep → release → post-merge

**Dependency:** Both subagents run after Iter 1 completes (so paths exist) and after Iter 2 (so they can reference updated READMEs). Runs parallel to Iter 4.

**Done when:** 5 new docs exist, ref-injector entries point to real files.

### Iteration 4: Update skills + workstream docs (PARALLEL)

**Goal:** Skill descriptions reflect new names and tools. Workstream docs reflect stream model.

**Subagent 4 owns:** Skills audit + workstream updates.

**Tasks:**
1. Audit all skills (.claude/skills/**/*.md) for:
   - References to `/ship` → `/release`
   - References to `/git-commit` → `/git-safe-commit`
   - References to old tool paths
   - Missing new skills in related skill lists
2. Update skill frontmatter descriptions where applicable
3. Update workstream docs:
   - `agency/workstreams/agency/valueflow-ad-*.md` — add stream model if relevant
   - `agency/workstreams/agency/valueflow-plan-*.md` — same
   - `agency/REFERENCE-DEVELOPMENT-METHODOLOGY.md` (formerly claude/docs/DEVELOPMENT-METHODOLOGY.md) — add stream model section
   - `agency/REFERENCE-WORKTREE-DISCIPLINE.md` — add branch protection section
   - `agency/REFERENCE-ISCP-PROTOCOL.md` — add dispatch service seed note (coming soon)

**Scope boundary:** Iter 1 already did PATH updates. Iter 4 does CONTENT updates only.

**Done when:** No stale skill/tool references; stream model documented in methodology; branch protection documented in worktree discipline.

### Iteration 5: MAR + RGR + PR (SEQUENTIAL — final gate)

**Goal:** Review doc changes, produce RGR, stage PR.

**Tasks:**
1. End-to-end verify: `grep -r "/ship\|/git-commit\|claude/docs/" --exclude-dir=.git --exclude-dir=usr --exclude-dir=history` → should be empty
2. End-to-end test: trigger ref-injector, confirm it loads renamed + new docs
3. Captain reviews all doc changes
4. MAR the final state: 2 agents for accuracy + consistency
5. Fix findings
6. Compute hashes: A (start of sweep) → B (MAR findings) → C (triage) → D=C (auto, docs only) → E (final)
7. receipt-sign RGR with boundary=plan-complete, type=rgr, project=documentation-sweep
8. receipt-verify
9. Commit all changes
10. Create PR branch (d40-r6)
11. Bump version 40.5 → 40.6
12. pr-create → PR staged, NO admin merge (per principal directive)

**Done when:** PR exists, RGR valid, awaiting principal review in morning.

## Completion Criteria

- 5 iterations complete in correct order
- All Day 40 changes documented
- All REFERENCE- refactor complete
- 5 new docs created
- RGR receipt signed and verified
- PR staged for morning review

## What This Plan Does NOT Include

- Behavior changes (docs only)
- Monofolk Ring 2 dispatch (separate discussion)
- Receipt infrastructure Phase 2 (DevEx)
- Scaffold PVR work (DevEx)
- Dispatch service implementation (ISCP)
