---
type: session
agent: the-agency/jordan/captain
date: 2026-04-22T00:00:00Z
trigger: session-end
branch: fix/great-rename-migrate-tool
mode: resumption
pause_commit_sha: 03453411
next-action: "Commit the UNCOMMITTED tool + tests (agency/tools/great-rename-migrate + src/tests/tools/great-rename-migrate.bats — 19/19 BATS passing), bump manifest 46.14 → 46.15, PR to main, merge via pr-captain-merge --principal-approved, release v46.15, dispatch fleet with tool-usage instructions. HARD DEADLINE: fleet online by 0400. Then resume V5 phase-disciplined (Phase -1 audit → Phase 3 prune → land PR #397 → Phase 4+)."
---

# Handoff — Mid-session /compact-prepare (Fleet deadline 0400 + V5 resumption)

## Situation

Principal gave hard deadline: **fleet online by 0400**. 5 worktree agents (mdslidepal-mac, mdpal-app, devex, iscp, designex) pre-date the Great Rename and collide with path conflicts on worktree-sync. Two already explicitly blocked (DevEx #827 + DesignEx transcript). Dispatches #828-#837 sent with Option A manual mapping — but agents need a MECHANICAL tool, not manual walk-through.

**Pivot:** Paused V5 structural work (branch `agency-v3-installer` was cut earlier) → cut `fix/great-rename-migrate-tool` branch from main → built `agency/tools/great-rename-migrate` tool (Bucket G.1) → wrote 19 BATS tests — ALL PASSING. Currently uncommitted.

Compact triggered before commit could land.

## What's been done this session (post-compact-prepare earlier)

### V5 direction confirmed + pivoted

- Principal chose **Option A — resume V5 AgencyV3 installer**
- Answered "why stopped V5" honestly: ABC stabilization accretion, not V5 ordering
- Confirmed V5 plan gets us to shippable `agency init` + `agency update` IF executed phase-disciplined (Phase -1 audit → Phase 3 prune FIRST, not skipped like abandoned v46.0 branch)
- Acknowledged monofolk comparison honestly: they executed rename with discipline (pre-announce dispatch + migration tool + adopter hand-hold); we didn't. Not a "they did easy work" narrative — they did the HARD work RIGHT.

### Fleet-online pivot (0400 deadline)

- Investigated GitHub state: PR #362 merged v2 base; PR #397 OPEN with QG follow-up findings — v2 PARTIAL on main
- Sent fleet rename-dispatches #828-#837 with Option A per-file mapping
- Built `agency/tools/great-rename-migrate` (bash, 250 lines): dry-run by default, --apply executes git-mv, --map custom mapping, longest-prefix-wins, refuses main/master, preserves history, skips target-exists collisions
- Wrote `src/tests/tools/great-rename-migrate.bats`: 19 tests — ALL GREEN

### Fleet/Dispatch state

- 10 outbound dispatches this session: #828-#835 (fleet), #836 (DevEx reply #827), #837 (DesignEx reply)
- 0 unread dispatches in queue

### Plan documents

- Plan v3.2 → v3.3 committed (6f36ca66) — Bucket G.1 accelerated to R4, fleet-rename gap logged
- V5 plan at `/Users/jdm/.claude/plans/melodic-inventing-platypus.md` (melodic-inventing-platypus) — approved as Option A
- No new V6 plan doc written yet

## What's IN-FLIGHT right now

### Uncommitted framework code

Two files, ~400 lines, ALL TESTS PASSING. Status: staged-ready but NOT committed.

```
agency/tools/great-rename-migrate        (NEW, 250 lines, executable)
src/tests/tools/great-rename-migrate.bats (NEW, 19 tests, all green)
```

Verified via `bats` run — 1..19, all ok.

### Branches

- `main` — 3 local-ahead coord commits (02ffe449, 1c7becf0, 6f36ca66) not on origin. Will merge naturally when next PR from this branch lands to main.
- `agency-v3-installer` — cut at 6f36ca66 for V5 work. Nothing on it yet beyond parent.
- `fix/great-rename-migrate-tool` — cut from main, where the uncommitted tool sits. **CURRENT BRANCH.**

### Principal directives carrying forward

- **Fleet online by 0400** — hard deadline. This is THE priority tonight.
- **"Make it so."** — execute V5 Option A with discipline after fleet lands.
- **"Don't stop mid-night with context heavy."** — keep working until actually done.
- **"Attention to details."** — tree-level review, not plans; file-by-file pruning.
- **"Give us more PRs."** — small PRs, frequent cadence.
- **"No DEFER."** — ACCEPT or REJECT only.
- **1B1 enforcement** — never bundle questions; one decision at a time.

## Next-action (IMMEDIATELY after /compact)

1. **Commit the uncommitted tool + tests:**
   ```
   /Users/jdm/code/the-agency/agency/tools/git-safe-commit \
     "agency/bucket-g1: great-rename-migrate tool + 19 BATS tests — unblock fleet on claude/→agency/ + tests/→src/tests/ rename" \
     --no-work-item
   ```
   (Principal rejected this commit earlier — INSTEAD they wanted /compact-prepare first. Now that compact-prepare is done, re-attempt.)

2. **Bump manifest:** `agency/config/manifest.json` → `agency_version` 46.14 → 46.15, `project.framework_version` 46.14 → 46.15, `updated_at` to current UTC. Commit.

3. **Push + PR:** 
   ```
   /Users/jdm/code/the-agency/agency/tools/git-push fix/great-rename-migrate-tool
   /Users/jdm/code/the-agency/agency/tools/pr-create
   ```
   PR title: "fix(bucket-g1): great-rename-migrate tool — fleet unblock v46.15"

4. **Merge + release:**
   ```
   /Users/jdm/code/the-agency/agency/tools/pr-merge <PR#> --principal-approved
   ```
   Auto-release via Fix D cuts v46.15 within seconds.

5. **Dispatch fleet with TOOL INSTRUCTIONS:**
   - Template: new dispatch to all 8 agents with `great-rename-migrate` usage
   - They run `git pull` on main, switch to their feature branch, `./agency/tools/great-rename-migrate --dry-run` to see plan, `--apply` to execute, commit, `worktree-sync --auto`
   - Expected: agents self-unblock within 30-60min each

6. **Verify fleet progress:** poll `gh pr list` or wait for agent dispatches back confirming unblocked. Hand-hold ones that hit residual content conflicts.

## After fleet online (V5 Phase -1)

7. **Switch to `agency-v3-installer` branch**
8. **Phase -1 audit:** latent-tool-reference grep + 13 residual open questions resolved in writing at `research/open-questions-resolutions-20260422.md`
9. **Phase 3 prune** (now, not later — earlier inventory captured the crap):
   - `agency/tools/__pycache__/dispatch-monitorcpython-313.pyc` (rm + gitignore)
   - `agency/agents/testname/` (rm)
   - `agency/agents/unknown/` (verify + rm if placeholder)
   - `agency/config/{agency-dependencies.yaml,dependencies.yaml}` (diff + pick one)
   - `agency/REFERENCE/REFERENCE-QUALITY-GATE-MONOFOLK.md` (rm)
   - `agency/config/{issue-monitor.last,tool-build-number}` (gitignore)
   - `.claude/settings.local.json`, `.claude/scheduled_tasks.lock` (gitignore)
   - `usr/test/`, `usr/jordan/{jordandm-d42-*,testname,conference,valueflow-*,mdpal,mdslidepal,personal,reports}/` (rm or gitignore)
   - `src/apps/mdpal-app/claude/` (rm stale pre-rename dir)
   - `src/archive/docs-legacy/` subset prune
   - `LICENSE` vs `agency/LICENSE.md` (diff + consolidate)

10. **Land PR #397** — monofolk v2 complete on main before V5 structural work

11. **Phase 4+**: src/ split, build tool, installer, adopter sweep, contributor polish

## Key context that must survive compact

### Tool design (great-rename-migrate)

- Bash, Bash 3.2 compatible
- Default rename map:
  - `claude/ → agency/`
  - `tests/ → src/tests/`
- Longest-prefix-wins sorting
- Refuses to run on main/master (this is a BRANCH migration tool)
- Refuses on detached HEAD
- Does NOT auto-commit — leaves staged for user review
- `--dry-run` default, `--apply` executes, `--map <file>` custom map, `--include-untracked` opt-in
- Version: 1.0.0-20260421-bucket-g1
- Location: `agency/tools/great-rename-migrate`
- Tests: `src/tests/tools/great-rename-migrate.bats` (19 tests, covers: version, help, unknown-flag, refuses-main/master, dry-run default, --apply execution, target-exists skip, longest-prefix-wins, --map custom, comments/blank ignore, empty-map refuse, no-auto-commit, content-preserve, history-preserve)

### Release cadence after fleet lands

| R | Ver | Covers |
|---|---|---|
| R4 | v46.15 | **Bucket G.1 — great-rename-migrate tool (this PR)** |
| R5 | v46.16 | PR #397 monofolk v2 complete (drive to merge) |
| R6 | v46.17 | Phase 3 prune PR (the crap inventoried above) |
| R7+ | v46.18+ | V5 Phase 4-13 in order |

### Discipline reminders for self

- **NEVER** `cd /tmp && bats ...` — changes shell CWD, broke tool calls after. Use `bats <absolute-path>` from repo root.
- **ALWAYS** use `/Users/jdm/code/the-agency/agency/tools/...` absolute paths when CWD is uncertain.
- **Wait for "Over and out"** before executing principal directions on multi-option questions.
- **1B1** — ONE decision at a time. Don't bundle.
- **No DEFER** — accept or reject.
- **Commit via git-safe-commit** — never raw git commit.

## Open items

- Uncommitted tool + tests (step 1 of next-action)
- 3 local-ahead coord commits on main (will land via PR)
- PR #397 has been OPEN since 2026-04-21 05:38Z — needs to land for monofolk v2 complete
- Multiple adopter repos (andrew-demo, presence-detect) need `agency update` working once shipped

## Stashes

- None (tool + tests uncommitted, not stashed — they will be the first commit on fix/great-rename-migrate-tool after compact)

## Related artifacts

- Plan v3.3: `agency/workstreams/agency/plan-abc-stabilization-20260421.md`
- V5 plan: `/Users/jdm/.claude/plans/melodic-inventing-platypus.md`
- Fleet dispatches sent: #828-#837
- DevEx incoming: #827 (answered via #836)
- This handoff

## Tasks carrying state

- **IMMEDIATE: Commit tool, bump manifest, PR, merge, release v46.15, dispatch fleet (fleet online by 0400)**
- After: Phase -1 audit + Phase 3 prune + PR #397 land + V5 Phase 4+
