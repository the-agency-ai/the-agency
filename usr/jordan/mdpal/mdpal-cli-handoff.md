---
type: handoff
agent: the-agency/jordan/mdpal-cli
workstream: mdpal
date: 2026-04-15
trigger: session-compact
---

## Identity

the-agency/jordan/mdpal-cli — headless Markdown Pal engine + CLI tool. Branch `mdpal-cli`. Worktree at `.claude/worktrees/mdpal-cli/`.

## Continuation state (mid-session, compacting now)

**Phase 1 implementation COMPLETE.** Iteration 1.4 landed. Phase-level QG ran. Awaiting Jordan's direction on which path to take for `/phase-complete` commit.

| # | Commit | Tests | Status |
|---|--------|-------|--------|
| 1.1 | `9cf480b` | 33 | ✅ |
| 1.2 | `abbc746` | 80 | ✅ |
| 1.3 | `904131e` | 124 | ✅ |
| 1.4 | `1a18718` | 175 | ✅ (landed this session) |

## What was done this session (Apr 14 → Apr 15)

1. **Worktree sync** — merged 120 commits from main (bootloader refactor, session skills, receipt infrastructure, git-safe family, block-raw-tools)
2. **Stash disposition** — dropped housekeeping backup files per captain #270
3. **Merge from main** (post D40-R3/R4/R5) — clean, confirmed via dispatch #308
4. **Iteration 1.4 final QG fixes** (the 15 remaining findings from WIP commit 95000fc):
   - VersionId ASCII-digit guard (reject leading +/-)
   - VersionId DateFormatter cached at static scope
   - BundleConfig strict `prune.auto` (reject non-bool) + `keep > 0` validation
   - New `EngineError.invalidBundlePath` case; 4 sites migrated from `bundleConflict`
   - `listRevisions` docstring corrected (silent-skip is intentional, documented)
   - 20 new tests added (155 → 175) covering: leading-sign rejection, strict auto, YAML snapshot equality, corrupt config, reload-after-write, listRevisions filtering, empty bundle paths, phantom-file renumbering, auto-prune, prune gate sequential
5. **Iteration 1.4 committed** as `1a18718` with full commit message + auto-dispatch #332 to captain
6. **Phase-level deep QG** — 4 reviewers in parallel (code, security, design, test) against the full phase scope (36 files, 6,476 insertions)

## Current state: AWAITING JORDAN'S DIRECTION on /phase-complete

Phase QG surfaced **2 CRITICAL + 7 HIGH + 12 MEDIUM** findings. I presented them to Jordan with three paths:

1. **Fix all CRITICAL + HIGH** then phase-commit (~6-8 fixes + 2 new tests + amend A&D) — most thorough
2. **Fix only CRITICAL** (C1 + C2), defer HIGH to Phase 1.5 sprint, phase-commit Phase 1 as MVP — pragmatic
3. **Phase-commit as-is** with all findings tracked as known issues — fastest

**The 2 CRITICAL findings:**

- **C1. Prune violates append-only invariant** (reviewer-code)
  `DocumentBundle.prune` → `latestDoc.save(to: latest.filePath)` serializes the WHOLE document — reformatting body whitespace on every save. With `prune.auto: true`, every save silently rewrites supposedly-immutable revision content. Fix: rewrite ONLY metadata block via `parser.findMetadataBlock` / `writeMetadataBlock` against raw file string.

- **C2. Symlink-as-revision attack** (reviewer-security)
  Malicious `.mdpal` bundle (delivered via git/tar/zip) can ship `V0001.0001.20260407T1200Z.md` as symlink to `/etc/passwd` or `~/.ssh/id_rsa`. `currentDocument()` follows it (arbitrary read); `prune()` calls `removeItem` on it (arbitrary deletion). Fix: check `attributesOfItem.type == .typeRegular` in `listRevisions` and before `removeItem` in `prune`.

**The 7 HIGH findings (summarized):**
- H1. Revision metadata drift — `createRevision(content:)` doesn't update embedded DocumentInfo
- H2. `DocumentInfo.blank()` non-POSIX DateFormatter — same locale bug VersionId fixed
- H3. Empty slug for non-ASCII headings (e.g., `# 日本語` → `""`)
- H4. Slug suffix scheme `-1, -2` vs A&D §4.3 `-2, -3` — public contract drift
- H5. Diff API completely missing — A&D §3.1 specifies it (blocks Phase 2 `mdpal diff` CLI)
- H6. No end-to-end Bundle+Document integration test
- H7. Byte-equal round-trip not asserted (only structural)

**Full QG findings captured in-conversation prior to compact** — after compact, resume by re-reading this handoff, then Jordan's decision.

## Next action (after compact)

**Wait for Jordan's choice of path (1, 2, or 3).** Then:
- Execute the chosen fix plan
- Write the phase-complete QGR receipt: `usr/jordan/mdpal/qgr-phase-complete-1-{stage-hash}-{timestamp}.md`
- Run `/git-safe-commit` with the Phase 1 commit message (no squash — 4 iteration commits each have QGRs)
- Update plan file `usr/jordan/mdpal/plan-mdpal-20260406.md` with Phase 1 completion + append full QGR

## Infrastructure notes (MUST preserve across compact)

### git-safe-commit auto-dispatch cascade (flagged as #125 to captain)

Every `./claude/tools/git-safe-commit` invocation creates an untracked `usr/jordan/mdpal-cli/dispatches/commit-to-captain-*.md` auto-dispatch file. Committing that file creates another. Infinite loop. Steady state at end of session-compact: **exactly 1 untracked dispatch file** (cannot be cleaned without breaking the loop).

Workaround until fixed: accept the 1 untracked file. Raw `git commit` is blocked by hookify. Coord-commit skill still funnels through git-safe-commit.

### Dispatch loop active

Monitor task `bdfugi8tc` running `dispatch-monitor` every 10 seconds (persistent, 1-hour timeout remaining). Captured 3 event-driven dispatches this session (#270, #261, #301).

### Cron timer a9859c05

**FIRED at 03:03 Apr 15** — was the autonomous-resume trigger. Session is now past that point; timer is done. No replacement scheduled.

### ISCP schema version

Worktree on `ISCP_SCHEMA_VERSION=1`. Verified. Safe.

### Sparse worktree reminder

`git status` shows ~1310 "D" framework files — sparse-worktree normal state per captain #163, NOT a git-commit bug. Always stage specific files, never `git add .` or `git add -A`.

## Dispatches sent this session

| ID | To | Subject |
|----|-----|---------|
| 268 | captain | Stash conflict flag (resolved) |
| 273 | captain | Re: Day 40 check-in |
| 308 | captain | Re: Merge from main — clean |
| 332 | captain | Auto-commit notification for 1a18718 |
| flag #125 | captain | git-safe-commit auto-dispatch cascade bug |

## Key Artifacts

- PVR: `usr/jordan/mdpal/pvr-mdpal-20260403-1447.md`
- A&D: `usr/jordan/mdpal/ad-mdpal-20260404.md` (needs Phase 1 amendments for H1, H4, H5 deviations)
- Plan: `usr/jordan/mdpal/plan-mdpal-20260406.md` (needs Phase 1 completion update)
- Iteration QGRs: `usr/jordan/mdpal/qgr-iteration-complete-{1-1, 1-2, 1-3, 1-4}-*.md`

## Continuation instruction after /compact

Re-read this handoff. Check `dispatch list` for any new arrivals. Then: resume at "Awaiting Jordan's direction on which of 3 phase-complete paths to take." Do NOT start fixing findings autonomously — phase-complete requires principal approval per `/phase-complete` skill protocol.
