---
type: session
agent: the-agency/jordan/captain
workstream: the-agency
date: 2026-04-20
trigger: autonomous-overnight-compact
mode: phase-0-complete-phase-1-entry-ready
---

# Captain handoff — AUTONOMOUS OVERNIGHT: Phase 0 COMPLETE; Phase 1 entry ready

## Principal's directives (verbatim this session)

> "Execute autonomously and overnight. Hopefully, we are finished in the morning. No BS stops, because I feel my context being heavy."
> "Do it overnight and we can review in the morning."
> "We can roll back if we need to do so."
> "You can't estimate / I can't estimate. Just do / Just do it now."

## Overnight execution summary

**Branch:** `v46.0-structural-reset` (cut from `contrib/claude-tools-worktree-sync` HEAD)

**Commits landed on this branch (newest first):**
1. `044823f8` — feat(v46.0): Phase 0 complete — tools 9-21 + manifests + skeletons + shim template + gate-check macOS fix
2. `a4808493` — feat(v46.0): Phase 0 partial — tools 4-8 (agency-sweep, import-link-check, subagent triplet)
3. `0401f768` — feat(v46.0): Phase 0 partial — git-safe ls-files + git-rename-tree + ref-inventory-gen + allowlist (3/20 tools)

Plus Plan v4 commit `9360ea8e` inherited from the cut-point.

**Rollback anchor tag:** `v45.3-pre-reset` created on pre-reset HEAD (9360ea8e range) and **pushed to origin**. Principal can `git reset --hard v45.3-pre-reset` at any time.

## Plan v4 Phase 0 — COMPLETE (all sub-phases)

### Phase 0a — Baseline captured ✓

At `usr/jordan/captain/reset-baseline-20260419/`:
- `content-inventory.sha256` — 2230 tracked files
- `bats-baseline.txt` — full BATS run captured
- `ref-inventory-pre.txt` — 2012-line pre-rename reference manifest (via new ref-inventory-gen tool)
- `hookify-rule-count.txt` — 41 rules
- `skill-count.txt` — 62 skills
- `settings-checksum.txt`, `claude-md-checksum.txt` — SHA digests
- `baseline-symlink-check.txt` — documents ONE known pre-existing symlink (`claude/principals/jordan/resources/cloud` — iCloud link, gets archived during Phase 3 per PHASE-0A-NOTES.md)
- `sensitive-dirs-sha256.txt` — 270-file SHA manifest (regenerated after initial 12MB variant tripped commit-precheck size gate; now excludes `.claude/worktrees/`)
- `env-file-inventory.txt` — `.env*` enumeration for Phase 3c
- `PHASE-CURSOR.txt` — chain-hash JSONL with phase-0a-init + phase-0-done entries
- `PHASE-0A-NOTES.md` — known-exception documentation

### Phase 0b — 20 tools + 1 hookify rule + allowlist (all BATS-green)

All tools ship at `claude/tools/` with BATS at `tests/tools/`. Each meets or exceeds the min-test-count declared in Plan v4 §3 Phase 0b table.

| # | Tool | BATS tests (min) |
|---|---|---|
| 1 | `git-safe ls-files` (subcommand) | 5 (4) |
| 2 | `git-rename-tree` | 12 (10) — all canaries pass |
| 3 | `ref-inventory-gen` | 11 (10) |
| 4 | `agency-sweep` | 17 (16) |
| 5 | `import-link-check` | 11 (10) |
| 6 | `subagent-scope-check` | 7 (6) |
| 7 | `subagent-diff-verify` | 11 (10) |
| 8 | `subagent-overlap-check` | 6 (5) |
| 9 | `audit-log-merge` | 5 (4) |
| 10 | `audit-log-reconcile` | 6 (6) |
| 11 | `hookify-rule-canary` | 8 (8) |
| 12 | `agency-verify-v46` (customer + internal) | 10 (10) |
| 13 | `agency-migrate-prep` | 10 (10) |
| 14 | `agency-update-migrate` (standalone — NOT wired into `agency` CLI) | 6 (6) |
| 15 | `agency-update-migrate-back` | 8 (8) |
| 16 | `agency-health-v46` | 6 (6) |
| 17 | `agency-report` | 4 (4) |
| 18 | `gate-check` (11 phases: 0, 1, 2, 3, 3.5, 3.6, 4, 4.5, 5, 6, 7) | 74 (73) |
| 19 | `smoke-battery` | 12 (12) |
| 20 | `reset-rollback` | 6 (6) |
| 21 | `hookify.block-git-clean-during-reset` rule + canary | canary PASS via hookify-rule-canary |

**Allowlist file:** `claude/tools/ref-sweep-allowlist.txt` (19 entries with rationale, min 14).

**Plan v4 Principle 8 honored:** every tool has BATS coverage before any invocation.

### Phase 0c — 5 disjoint subagent manifests

At `usr/jordan/captain/reset-baseline-20260419/subagent-manifests/`:
- `subagent-A-manifest.yaml` — ownership_priority=1, scope: `agency/tools/**`
- `subagent-B-manifest.yaml` — ownership_priority=2, scope: REFERENCE*.md + README* + CLAUDE-THEAGENCY.md + commands
- `subagent-C-manifest.yaml` — ownership_priority=3, scope: `tests/**` (excl. test fixture)
- `subagent-D-manifest.yaml` — ownership_priority=4, scope: `.claude/skills/**` + `agency/agents/**/agent.md`
- `subagent-E-manifest.yaml` — ownership_priority=5, scope: hooks/, hookify/, config/, tools/lib/, package.json, .gitignore

`subagent-overlap-check` across all 5: **zero overlap detected**.

### Phase 0d — Release notes + runbook skeletons + shim template

- `release-notes-v46.0.skeleton.md` — all §0d slots present (header, TL;DR, Why now, What changed with per-change impact, What's preserved, What's broken with ≥5 before/after examples, Migration summary, Rollback 3-paths, Diagnostic signatures, Contact, Link-to-A&D)
- `migration-runbook-v46.0.skeleton.md` — Prep/Update/Verify with exit codes, Common failure modes table, Rollback decision tree, Dispatch rescue detail, Contact+report
- `reset-shim.sh.template` — captain-session alias-shim scaffolding for Phase 1 (copy→source to activate; creates `.git/RESET_IN_FLIGHT` sentinel; defines `claude-tool <name>` function that routes to `agency/tools/<name>` post-rename)

### Gate 0 check — PASS

`./claude/tools/gate-check 0` returns 0 with all 10 criteria green against the real baseline.

## What is NOT done (deferred to morning principal 1B1)

### Phase 1 (The Great Rename) — READY TO START

**Phase 1 operations** (from Plan v4 §3 Phase 1):
1. Copy `reset-shim.sh.template` → `reset-shim.sh` (untracked), `source` it
2. `AGENCY_ALLOW_RAW=1 git mv claude agency` (atomic dir rename)
3. Verify 10 canaries via `git log --follow`
4. One commit: `feat(v46.0): Phase 1 — Great Rename claude/ → agency/`
5. Run `./claude/tools/gate-check 1`

**Why I stopped at Phase 0 exit:**

The captain's ability to invoke Bash tools during Phases 1-4 depends on `.claude/settings.json` hook commands resolving. Plan v4 defers settings.json rewrites to Phase 4.5. Between Phase 1 (rename) and Phase 4.5 (settings rewrite), Claude Code tries to invoke `$CLAUDE_PROJECT_DIR/claude/hooks/<x>.sh` but the files are now at `agency/hooks/<x>.sh`. Behavior is uncertain:
- If Claude Code bricks on ENOENT hooks: bad overnight outcome with no way to rollback
- If Claude Code silently ignores missing hooks: proceed OK (but block-raw-tools is gone, which changes behavior)

Principal should decide:
- **Option A**: Proceed with Phase 1 as specified (risk: possible session brick)
- **Option B**: Atomic Phase 1 + Phase 4.5 in single commit — rename + settings + @import rewrites + shim cleanup all at once. Violates Plan v4 Principle 1 (rename pure / sweep separate) but safer for autonomous execution.
- **Option C**: Break Phase 4.5 into pre-Phase-1 (settings.json update only) + post-Phase-4 (@import rewrites). Not in current Plan; needs re-MAR.

### MAR checkpoint 0→1 — DEFERRED

Per Plan v4: 3 reviewers (operations, verification, product) + 15-min fold budget + max 2 re-MAR cycles. Single-agent autonomous session is not well-suited to this; principal's morning review effectively serves as the MAR.

### Phase 2-6 + Gate 7 — DEFERRED

All remaining phases depend on Phase 1 completing.

## Blockers requiring principal 1B1

### Blocker 1: collab-monofolk repo wedged (designex Phase 1.5 ship)

(See ISCP task #28 for context)

**Situation:**
- Collab-monofolk repo HEAD `ffd3f41` **contains 3 files with unresolved conflict markers** (committed broken state by monofolk/captain)
- 5 stacked `collaboration-check` stashes accumulated
- Concurrent dispatch-monitors (other agents) race with any fix attempt — my edit+stage+commit cycle was reset by another agent's stash during attempted resolution
- I attempted mechanical conflict resolution; it was undone by concurrent activity

**Pending captain work blocked on this:**
- Designex Phase 1.5 ship (dispatches #741 + #744) — monofolk-relay via `collaboration reply` + `resolve` + `push`
- **Deadline**: 2026-04-20T10:00Z (monofolk's decide-and-respond window)
- Monofolk #342 ETA response (their cross-repo inquiry about 6 deferred cleanups)

**Suggested principal resolution:**
1. Decide which side's version to keep for the 3 conflicted dispatch files:
   - `dispatch-share-token-pipeline-v1-20260417.md`
   - `dispatch-re-relay-from-monofolkdevex--9-prs-for-s-20260417.md`
   - `dispatch-patch-incoming-issue-111-principal-scope-20260415.md`
2. Either: stop concurrent dispatch-monitors OR accept race risk during fix
3. After wedge cleared: ship designex relay + reply to monofolk #342

### Blocker 2 (noted, lower priority): Two flags unprocessed pre-session

Flags captured during pre-compact work remain unprocessed in captain queue. Safe to address post-reset.

## Dispatch queue state

After overnight processing:
- 14 commit-notify dispatches bulk-resolved (#737-750 range)
- 4 designex dispatches resolved (#741, #744, #746, #749)
- 1 mdpal-cli dispatch resolved (#747)
- New commit-notify dispatches from overnight commits WILL appear on session resume

## Resume action (next captain session)

1. `/session-resume` (auto-runs worktree-sync + handoff read + dispatch check)
2. Read this handoff (you're doing it)
3. Bulk-resolve any new commit-notify dispatches from overnight
4. **PRINCIPAL 1B1**: decide Phase 1 approach (Option A/B/C above)
5. **PRINCIPAL 1B1**: decide collab-monofolk unwedge approach
6. Execute principal's Phase 1 approach; continue through remaining phases
7. Address designex ship + monofolk #342 after collab repo unwedge

## Files added this overnight session (summary)

**New tools** (`claude/tools/`):
- git-rename-tree, ref-inventory-gen, agency-sweep, import-link-check,
  subagent-scope-check, subagent-diff-verify, subagent-overlap-check,
  audit-log-merge, audit-log-reconcile, hookify-rule-canary,
  agency-verify-v46, agency-migrate-prep, agency-update-migrate,
  agency-update-migrate-back, agency-health-v46, agency-report,
  gate-check, smoke-battery, reset-rollback, ref-sweep-allowlist.txt

**Modified**:
- `claude/tools/git-safe` — added `ls-files` subcommand

**New BATS** (`tests/tools/`): one per tool, all green

**New hookify**:
- `claude/hookify/hookify.block-git-clean-during-reset.md` + `.canary`

**Baseline** (`usr/jordan/captain/reset-baseline-20260419/`):
- PHASE-CURSOR.txt (with chain-hash entries for phase-0a-init + phase-0-done)
- PHASE-0A-NOTES.md (known-exception documentation)
- 10 baseline inventory artifacts
- 5 subagent manifests
- release-notes-v46.0.skeleton.md
- migration-runbook-v46.0.skeleton.md
- reset-shim.sh.template

## Budget / context status

~3 hours of overnight autonomous execution. Plan v4 budget was ~90 min for Phase 0 — I ran over because of tool scope + BATS coverage. Principal's "no BS stops" directive kept me going through friction (mostly macOS-path and bash-3.2-compat issues that took debug cycles).

Context is heavy enough that `/session-compact` is the right move. The next session starts fresh on this handoff + Plan v4.

## Key commits to preserve

- `9360ea8e` Plan v4 artifact
- `0401f768` — tools 1-3
- `a4808493` — tools 4-8
- `044823f8` — tools 9-21 + manifests + skeletons + shim template + gate-check fix

All committed, not yet pushed to origin (v46.0-structural-reset is local-only). Principal can `git-captain push origin v46.0-structural-reset` in the morning to publish.

— captain, 2026-04-20 autonomous-overnight-compact, Phase 0 COMPLETE
