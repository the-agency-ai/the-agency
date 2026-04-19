---
type: plan
workstream: the-agency
slug: structural-reset
principal: jordan
agent: the-agency/jordan/captain
date_started: 2026-04-19
stage: plan
status: in-progress
pvr: agency/workstreams/the-agency/pvr-the-agency-structural-reset-20260419.md
ad: agency/workstreams/the-agency/ad-the-agency-structural-reset-20260419.md
pvr_mar: agency/workstreams/the-agency/research/mar-pvr-structural-reset-20260419.md
ad_mar: agency/workstreams/the-agency/research/mar-ad-structural-reset-20260419.md
related_issues: [270, 287, 332, 333, 334, 335, 336, 337]
---

# Plan — The-Agency Structural Reset (v46.0)

Executable plan for the structural reset. All PVR + A&D MAR findings folded in as binding commitments. 9 phases, 5 subagent briefs, 8+ tooling artifacts, explicit file lists.

**Time budget (rebaselined per F-OPS-01):** ~120 min captain-time, with Phase 4 subagent fan-out happening in parallel.

## Pre-Plan invariants

- **Branch:** `v46.0-structural-reset` cut from `contrib/claude-tools-worktree-sync` HEAD
- **Merge order:** PR #294 merges first; reset PR follows
- **Hookify bypass:** `AGENCY_ALLOW_RAW=1` per-command only, captain-only, audit-logged
- **Subagent constraint:** no subagent reads CLAUDE.md, invokes skills with @imports, or operates outside its file-list manifest
- **Atomicity:** single PR, single merge, single release
- **Phase cursor:** `usr/jordan/captain/reset-baseline-20260419/PHASE-CURSOR.txt` updated at every gate pass

## Phase 0 — Pre-reset baseline + tooling (~10 min)

### 0.1. Create branch + pre-reset tag
```bash
./agency/tools/git-captain checkout-branch v46.0-structural-reset
AGENCY_ALLOW_RAW=1 git tag v45.3-pre-reset
./agency/tools/git-captain push  # push branch
./agency/tools/git-captain push-tag v45.3-pre-reset  # push tag (REQUIRED per F-OPS-05)
```

### 0.2. Create baseline directory
```bash
mkdir -p usr/jordan/captain/reset-baseline-20260419
```

### 0.3. Capture baseline artifacts (V1 + V5)
```bash
BASELINE="usr/jordan/captain/reset-baseline-20260419"

# Fleet health JSON
./agency/tools/agency-health --json all > "$BASELINE/agency-health-pre.json"

# Test suite baseline
bats tests/ > "$BASELINE/bats-output-pre.txt" 2>&1

# File inventory + content hashes
AGENCY_ALLOW_RAW=1 git ls-files claude/ | sort > "$BASELINE/file-inventory-pre.txt"
AGENCY_ALLOW_RAW=1 git ls-files -z claude/ | xargs -0 sha256sum > "$BASELINE/content-inventory-pre.sha256"

# Counts
echo "skills: $(ls .claude/skills | wc -l)" > "$BASELINE/counts-pre.txt"
echo "hookify-rules: $(ls agency/hookify/*.md | wc -l)" >> "$BASELINE/counts-pre.txt"
echo "hook-scripts: $(ls agency/hooks/*.sh | wc -l)" >> "$BASELINE/counts-pre.txt"
echo "tools: $(ls agency/tools/ | wc -l)" >> "$BASELINE/counts-pre.txt"
echo "reference-docs: $(ls agency/REFERENCE-*.md | wc -l)" >> "$BASELINE/counts-pre.txt"
echo "readme-docs: $(ls agency/README-*.md | wc -l)" >> "$BASELINE/counts-pre.txt"
echo "tests: $(bats --count tests/)" >> "$BASELINE/counts-pre.txt"

# Checksums of critical files
sha256sum .claude/settings.json > "$BASELINE/settings-json-pre.sha256"
sha256sum CLAUDE.md > "$BASELINE/claude-md-pre.sha256"

# Git state
./agency/tools/git-safe log --oneline -5 HEAD > "$BASELINE/git-head-pre.txt"

# Phase cursor init
echo "phase-0-baseline-captured" > "$BASELINE/PHASE-CURSOR.txt"
```

### 0.4. Build `ref-inventory-gen` tool (V9)

Write new tool `agency/tools/ref-inventory-gen`:
```bash
#!/usr/bin/env bash
# Scans for `claude/` path references across active code.
# Excludes: history/, workstreams/*/transcripts/, workstreams/*/history/,
#           CHANGELOG*.md, release-notes-*.md, .git/, node_modules/, dist/
# Includes: .claude/**/*, claude/tools/**, claude/hooks/**.sh, claude/hookify/**.md,
#           claude/REFERENCE-*.md, claude/README-*.md, CLAUDE.md,
#           tests/**, usr/**/*.{md,json,sh,yaml},
#           .gitignore, .gitattributes, package.json, pyproject.toml
# Outputs: file:line:pattern-hit
set -euo pipefail
PATTERNS='claude/|@claude/|["'"'"']claude/|claude/$|\$CLAUDE_PROJECT_DIR/claude'
./agency/tools/git-safe ls-files ... | xargs grep -nE "$PATTERNS" ...
```

Capture pre-sweep inventory:
```bash
./agency/tools/ref-inventory-gen > "$BASELINE/ref-inventory-pre.txt"
echo "pre-sweep-refs: $(wc -l < "$BASELINE/ref-inventory-pre.txt")" >> "$BASELINE/counts-pre.txt"
```

### 0.5. Build `gate-check.sh` suite

Scripts at `agency/tools/reset/`:
- `gate-check-0.sh` — baseline artifacts exist
- `gate-check-1.sh` — Great Rename gate (canary `git log --follow` passes)
- `gate-check-2.sh` — subdir reorg gate (file counts)
- `gate-check-3.sh` — cruft removal gate (deleted paths absent)
- `gate-check-3-5.sh` — workstream merge gate
- `gate-check-4.sh` — ref-sweep gate (ref-inventory diff empty modulo allowlist)
- `gate-check-4-5.sh` — captain smoke battery
- `gate-check-5.sh` — hookify rule validation
- `gate-check-6.sh` — release notes quality
- `gate-check-7.sh` — post-merge master smoke

Each exits 0 (pass) or nonzero (block). Receipts under `$BASELINE/gate-{N}-receipt.txt`.

### 0.6. Build `agency-archive-then-delete` wrapper (R-1)

New tool `agency/tools/agency-archive-then-delete`:
```bash
#!/usr/bin/env bash
# Usage: agency-archive-then-delete <path> [--confirmed-zero-value=<rationale>]
# Refuses git rm / rm inside agency/ unless:
#  (a) flotsam path with matching stem already exists, OR
#  (b) --confirmed-zero-value=<rationale> is passed
# Writes audit line to $AUDIT_LOG on success.
```

### 0.7. Build `subagent-scope-check.sh` (F-OPS-02 / R-4)

Script `agency/tools/reset/subagent-scope-check.sh`:
```bash
#!/usr/bin/env bash
# Usage: subagent-scope-check.sh <subagent-id> <manifest-path> <changed-files-list>
# Verifies changed-files is a subset of manifest.
# Exits 0 if OK, nonzero if any out-of-scope edit.
```

### 0.8. Build `hookify-rule-canary` tool (F10)

Script `agency/tools/reset/hookify-rule-canary.sh`:
```bash
#!/usr/bin/env bash
# For each rule in agency/hookify/*.md + agency/hooks/*.sh:
#   - Static check: grep for hardcoded `claude/` — any hit = bug
#   - Dynamic check: trigger a canary (e.g., attempt raw git for block-raw-git)
#   - Record result
# Outputs pass/fail per rule.
```

### 0.9. Build `reset-audit-log` helper

```bash
#!/usr/bin/env bash
# Usage: reset-audit-log <command> <exit-code> <phase> <rationale>
# Appends JSONL entry to usr/jordan/captain/reset-audit-20260419.log
# Used by AGENCY_ALLOW_RAW wrapper or captain manually before each raw invocation
```

### 0.10. Build `migrate` + `migrate-back` flags for `_agency-update` (R-6)

New flags in `agency/tools/lib/_agency-update`:
- `--migrate`: rewrites adopter's `.claude/settings.json` hook paths + `CLAUDE.md` @imports from `claude/` → `agency/`
- `--migrate-back`: reverses for rollback

BATS tests required (`tests/tools/agency-update-migrate.bats`) before Gate 6.

### 0.11. Pre-compute subagent file-list manifests (F4 / R-4 / F-OPS-02)

Produces explicit file lists per subagent. Captain runs scripted scan to assign files to subagents by glob. Outputs to `$BASELINE/subagent-{A..E}-manifest.txt`.

Canonical glob ownership:
- **Subagent A — Tools:** `agency/tools/**` (all files inside)
- **Subagent B — Claude Code discovery:** `.claude/skills/**`, `.claude/commands/**`, `.claude/agents/**` (NOT `.claude/settings.json` — captain owns)
- **Subagent C — Hooks + hookify:** `agency/hooks/**.sh`, `agency/hookify/**.md`
- **Subagent D — Agency docs:** `agency/REFERENCE/**`, `agency/README/**`, `agency/CLAUDE-THEAGENCY.md` (NOT root `CLAUDE.md` — captain owns)
- **Subagent E — Tests + starter-packs + templates:** `tests/**`, `agency/starter-packs/**`, `agency/templates/**`

**Captain owns:** `CLAUDE.md` (repo root), `.claude/settings.json`, audit log, gate artifacts.

Manifest file format: one path per line.

### 0.12. Pre-merge hash manifests for supply-chain check (R-12)

```bash
AGENCY_ALLOW_RAW=1 git ls-files -z claude/hooks | xargs -0 sha256sum > "$BASELINE/hooks-hashes-pre.sha256"
AGENCY_ALLOW_RAW=1 git ls-files -z claude/tools | xargs -0 sha256sum > "$BASELINE/tools-hashes-pre.sha256"
AGENCY_ALLOW_RAW=1 git ls-files -z .claude    | xargs -0 sha256sum > "$BASELINE/dot-claude-hashes-pre.sha256"
```

### Gate 0
`gate-check-0.sh` passes. Phase cursor → `phase-0-gate-passed`.

## Phase 1 — Great Rename (~3 min)

### 1.1. Execute rename (pure move)
```bash
AGENCY_ALLOW_RAW=1 git mv claude agency
```

Log via `reset-audit-log "git mv claude agency" $? "1" "Phase 1 — Great Rename tree move"`.

### 1.2. Verify rename detection (canary set per F7 / V5)

Canary list (8 files — expanded per F7 / V5):
1. `agency/tools/git-safe` (bash tool — typical)
2. `agency/REFERENCE/REFERENCE-AGENT-DISCIPLINE.md` (will be nested after Phase 2)
3. `agency/hooks/block-raw-tools.sh` (hook script)
4. `agency/README/README-ENFORCEMENT.md` (will be nested after Phase 2)
5. `agency/workstreams/the-agency/seeds/seed-true-installer-bootstrap-20260419.md` (deep nested)
6. `agency/assets/theagency-logo-constellation.svg` (BINARY — rename detection edge case)
7. `agency/starter-packs/nextjs-app/README.md` (nested in starter-pack)
8. `agency/workstreams/the-agency/qgr/the-agency-jordan-captain-the-agency-worktree-sync-helper-refactor-qgr-pr-prep-20260419-1401-6155d28.md` (historical path-string — per R8)

For each: `AGENCY_ALLOW_RAW=1 git log --follow <path> | head -3` must show commits BEFORE the rename.

Post-Phase-1 exhaustive check (R-9):
```bash
AGENCY_ALLOW_RAW=1 git diff --name-status v45.3-pre-reset HEAD | grep "^R" | wc -l  # rename count
AGENCY_ALLOW_RAW=1 git diff --name-status v45.3-pre-reset HEAD | grep -E "^(A|D)" | wc -l  # should be ~0
```

If any file shows A+D (delete+create) instead of R (rename), HARD STOP — gate 1 fails.

### 1.3. Commit
```bash
./agency/tools/git-safe-commit "feat(v46.0): Great Rename — claude/ → agency/ (pure move, no content edits)" --no-work-item --body "..."
```

Also check for symlinks pre-move (V5): `AGENCY_ALLOW_RAW=1 git ls-files -s claude/ | awk '$1==120000{print $4}'` — must be empty.

### Gate 1
`gate-check-1.sh`:
- All 8 canary `git log --follow` succeed
- Exhaustive rename-count check passes (A+D count == 0)
- `git status` clean

Phase cursor → `phase-1-gate-passed`.

## Phase 2 — Subdir reorganization (~5 min)

### 2.1. Create subdirs
```bash
mkdir -p agency/REFERENCE agency/README
```

### 2.2. Move REFERENCE files
```bash
AGENCY_ALLOW_RAW=1 git mv agency/REFERENCE-*.md agency/REFERENCE/
```

Exception: `REFERENCE-WORKNOTE-mvh-build.md` + `REFERENCE-WORKNOTE-parallel-agent-case-study.md` + `REFERENCE-QUALITY-GATE-MONOFOLK.md` + `REFERENCE-EXTRACTION_PLAN.md` — consider archiving instead of moving if they're framework-internal. Default: move; decide per-file in Phase 3 (part of cruft review).

### 2.3. Move README files
```bash
AGENCY_ALLOW_RAW=1 git mv agency/README-ENFORCEMENT.md agency/README/
AGENCY_ALLOW_RAW=1 git mv agency/README-SAFE-TOOLS.md agency/README/
AGENCY_ALLOW_RAW=1 git mv agency/README-RECEIPT-INFRASTRUCTURE.md agency/README/
```

Top-level stay at `agency/` root: `README-THEAGENCY.md`, `README-GETTINGSTARTED.md`, `CLAUDE-THEAGENCY.md`.

### 2.4. Commit
```bash
./agency/tools/git-safe-commit "feat(v46.0): subdir reorg — REFERENCE/ + README/ subdirs for navigability" --no-work-item --body "..."
```

### Gate 2
`gate-check-2.sh`:
- `ls agency/REFERENCE/*.md | wc -l` == 36
- `ls agency/README/*.md | wc -l` == 3
- `ls agency/*.md` == `CLAUDE-THEAGENCY.md README-THEAGENCY.md README-GETTINGSTARTED.md`
- Canary `git log --follow agency/REFERENCE/REFERENCE-AGENT-DISCIPLINE.md` resolves through original name

Phase cursor → `phase-2-gate-passed`.

## Phase 3a — Archive moves (~5 min)

Per F2: split Phase 3. Phase 3a = archive moves (git mv, no deletion).

### 3a.1. Archive `principals/`
```bash
mkdir -p agency/workstreams/the-agency/history/flotsam/legacy-principals-20260419
AGENCY_ALLOW_RAW=1 git mv agency/principals agency/workstreams/the-agency/history/flotsam/legacy-principals-20260419/
```

### 3a.2. Archive `receipts/`
```bash
mkdir -p agency/workstreams/the-agency/history/flotsam/legacy-receipts-20260419
AGENCY_ALLOW_RAW=1 git mv agency/receipts/*.md agency/workstreams/the-agency/history/flotsam/legacy-receipts-20260419/
# remove emptied dir
rmdir agency/receipts 2>/dev/null || true
```

### 3a.3. Archive `reviews/`
```bash
mkdir -p agency/workstreams/the-agency/history/flotsam/legacy-reviews-20260419
AGENCY_ALLOW_RAW=1 git mv agency/reviews/*.md agency/workstreams/the-agency/history/flotsam/legacy-reviews-20260419/
rmdir agency/reviews 2>/dev/null || true
```

### 3a.4. Archive `logs/`
```bash
mkdir -p agency/workstreams/the-agency/history/flotsam/legacy-logs-20260419
AGENCY_ALLOW_RAW=1 git mv agency/logs agency/workstreams/the-agency/history/flotsam/legacy-logs-20260419/
```

### 3a.5. Archive `proposals/` (deferred from to-the-agency-group move)
Leave in place. Write `agency/proposals/TODO-MOVE-TO-THE-AGENCY-GROUP.md` with rationale + link to #337.

### 3a.6. HISTORICAL-PATH-NOTE.md (R8)

In each flotsam subdir:
```markdown
# Historical path note

These artifacts were created when the framework lived at `claude/`. Any
path-strings in their bodies (e.g., `agency/tools/...`, `@agency/REFERENCE-...`)
refer to the PRE-v46.0 layout and do not resolve in current tree. They are
preserved for audit-trail integrity per v46.0 structural reset policy.

To search history with path-string translation: `./agency/tools/grep-with-history`
(see release notes).
```

### 3a.7. Commit
```bash
./agency/tools/git-safe-commit "feat(v46.0): archive legacy subsystems to flotsam (principals/, receipts/, reviews/, logs/)" --no-work-item --body "..."
```

### Gate 3a
- Archive paths exist with content
- Source paths absent
- HISTORICAL-PATH-NOTE.md in each flotsam subdir

## Phase 3b — Legacy DB extraction (~3 min)

Per R-2: integrity + round-trip validation.

### 3b.1. Extract `bug.db`
```bash
FLOTSAM="agency/workstreams/the-agency/history/flotsam/legacy-bug-dbs-20260419"
mkdir -p "$FLOTSAM"

# Integrity check
sqlite3 agency/data/bug.db "PRAGMA integrity_check" | tee "$FLOTSAM/bug-db-integrity.txt"

# Extract
sqlite3 agency/data/bug.db .dump > "$FLOTSAM/bug-db.sql"

# Round-trip validation
sqlite3 :memory: < "$FLOTSAM/bug-db.sql" && echo "round-trip OK"

# Hashes
sha256sum agency/data/bug.db "$FLOTSAM/bug-db.sql" > "$FLOTSAM/bug-db-manifest.txt"
```

Repeat for `bugs.db`.

### 3b.2. Commit extractions
```bash
./agency/tools/git-safe-commit "feat(v46.0): extract legacy bug DBs to flotsam (integrity + round-trip validated)" --no-work-item --body "..."
```

### Gate 3b
- Dump files exist under `$FLOTSAM/legacy-bug-dbs-20260419/`
- Integrity check results show "ok"
- Manifest includes source + dump hashes

## Phase 3c — Confirmed-dead deletions (~3 min)

### 3c.1. Delete injection-test workstream
```bash
./agency/tools/agency-archive-then-delete "agency/workstreams/test; rm -rf " --confirmed-zero-value="injection-test artifact — content is only a single KNOWLEDGE.md; no archive needed"
```

### 3c.2. Delete root-level empty `docs/`
```bash
./agency/tools/agency-archive-then-delete docs --confirmed-zero-value="empty after docs/plans/ deprecation fix (#335)"
```

### 3c.3. Delete legacy bug DBs (extracted in 3b)
```bash
./agency/tools/agency-archive-then-delete agency/data/bug.db
./agency/tools/agency-archive-then-delete agency/data/bugs.db
# Flotsam dumps exist from 3b.1 — wrapper permits delete
```

### 3c.4. Commit
```bash
./agency/tools/git-safe-commit "feat(v46.0): delete confirmed-dead cruft (injection-test, empty docs/, legacy bug DBs)" --no-work-item --body "..."
```

### Gate 3c
- Deleted paths absent
- Flotsam dumps preserved
- Audit log shows archive-then-delete OR confirmed-zero-value for every deletion

Phase cursor → `phase-3-gate-passed` (3a+3b+3c completed).

## Phase 3.5 — Duplicate workstream merge (~5 min)

Per F3 + A5: content-type triage before merge.

### 3.5.1. `agency/workstreams/agency/` triage
Content: PVRs, A&Ds, Plans from dispatch-monitor + documentation-sweep + receipt-infrastructure work. These are shared workstream artifacts.

Move ALL to: `agency/workstreams/the-agency/history/legacy-agency-workstream-20260419/`

```bash
mkdir -p agency/workstreams/the-agency/history/legacy-agency-workstream-20260419
AGENCY_ALLOW_RAW=1 git mv agency/workstreams/agency/* agency/workstreams/the-agency/history/legacy-agency-workstream-20260419/
rmdir agency/workstreams/agency 2>/dev/null || true
```

### 3.5.2. `agency/workstreams/captain/` triage
Content: transcripts (current session transcript + old dialogue-transcript). Captain personal-state (none found in this workstream).

Move:
- Current session transcript `dialogue-transcript-20260419.md` → `agency/workstreams/the-agency/transcripts/` (ACTIVE)
- (Old content moved through Phase 3.5.1 already? Check.)

```bash
AGENCY_ALLOW_RAW=1 git mv agency/workstreams/captain/transcripts/dialogue-transcript-20260419.md agency/workstreams/the-agency/transcripts/
rmdir -p agency/workstreams/captain/transcripts agency/workstreams/captain 2>/dev/null || true
```

### 3.5.3. `agency/workstreams/housekeeping/` triage
Content: bugs/, CLAUDE-HOUSEKEEPING.md, qgr/. Shared artifacts.

```bash
mkdir -p agency/workstreams/the-agency/history/legacy-housekeeping-20260419
AGENCY_ALLOW_RAW=1 git mv agency/workstreams/housekeeping/* agency/workstreams/the-agency/history/legacy-housekeeping-20260419/
rmdir agency/workstreams/housekeeping 2>/dev/null || true
```

### 3.5.4. `agency/workstreams/gtm/` defer marker
```bash
cat > agency/workstreams/gtm/TODO-MOVE-TO-THE-AGENCY-GROUP.md << 'EOF'
# GTM workstream — pending move to the-agency-group

This workstream holds go-to-market content for the-agency that belongs in
the collaboration repo `the-agency-group`, not in the framework repo.

Move blocked on collab repo setup (tracked as part of #337). When ready:
- Copy content to `the-agency-group/workstreams/gtm/`
- Delete this directory

— v46.0 structural reset, 2026-04-19
EOF
```

### 3.5.5. Commit
```bash
./agency/tools/git-safe-commit "feat(v46.0): consolidate duplicate workstreams into the-agency/; defer gtm/ to the-agency-group" --no-work-item --body "..."
```

### Gate 3.5
- `agency/workstreams/` contains only: `the-agency/`, per-app workstreams, `gtm/` (with TODO)
- `agency/workstreams/the-agency/history/legacy-agency-workstream-20260419/` non-empty
- `agency/workstreams/the-agency/history/legacy-housekeeping-20260419/` non-empty
- `agency/workstreams/the-agency/transcripts/dialogue-transcript-20260419.md` exists

Phase cursor → `phase-3-5-gate-passed`.

## Phase 4 — Reference sweep (subagent fan-out, ~30-45 min)

Per F-OPS-06: release notes must exist IN the PR before open — so captain drafts release notes skeleton in Phase 0 and fills during/after 4.5. See Phase 6.

### 4.0. Capture pre-sweep ref-inventory
```bash
./agency/tools/ref-inventory-gen > "$BASELINE/ref-inventory-mid.txt"
```

### 4.1. Create `ref-sweep-allowlist.txt` (V9)
Format: one `pattern#rationale` per line.
```
# agency/tools/ref-inventory-gen.sh#script itself contains pattern for its grep
# agency/workstreams/the-agency/history/flotsam/**/*.md#historical artifacts
# CHANGELOG*.md#historical release notes
# agency/REFERENCE/REFERENCE-MIGRATION-V46.md#migration doc shows before/after paths
```

### 4.2. Subagent fan-out (5 parallel subagents with explicit manifests)

Per F4 / F-OPS-02 / R-4: each subagent receives file-list manifest + scope constraint + output template.

**Subagent A — Tools sweep**
- Manifest: `$BASELINE/subagent-A-manifest.txt` (every file in `agency/tools/**`)
- Task: replace `claude/` → `agency/` in all path references
- Constraint: only edit files in manifest; don't read CLAUDE.md; don't invoke skills with @imports
- Output: `$BASELINE/subagent-A-receipt.md` (files touched, ref-leakage count, test result)
- Commit: "feat(v46.0): subagent A — tools ref sweep (claude/ → agency/)"

**Subagent B — Claude Code discovery**
- Manifest: every file in `.claude/skills/**`, `.claude/commands/**`, `.claude/agents/**`
- Task: update `required_reading:` frontmatter + skill body + command body + agent registrations
- Constraint: same as A
- Output: `$BASELINE/subagent-B-receipt.md`
- Commit: "feat(v46.0): subagent B — .claude/ discovery refs"

**Subagent C — Hooks + hookify**
- Manifest: every file in `agency/hooks/**.sh` + `agency/hookify/**.md`
- Task: path references in hook scripts + rule docs
- Constraint: same as A
- Output: `$BASELINE/subagent-C-receipt.md`
- Commit: "feat(v46.0): subagent C — hook scripts + hookify rules"

**Subagent D — Agency internal docs**
- Manifest: every file in `agency/REFERENCE/**`, `agency/README/**`, `agency/CLAUDE-THEAGENCY.md`
- Task: internal cross-refs between REFERENCE docs, @imports within CLAUDE-THEAGENCY, cross-references to tools
- Constraint: same as A
- Output: `$BASELINE/subagent-D-receipt.md`
- Commit: "feat(v46.0): subagent D — internal agency docs cross-refs"

**Subagent E — Tests + starter-packs + templates**
- Manifest: `tests/**`, `agency/starter-packs/**`, `agency/templates/**`
- Task: fixture paths, starter-pack internal paths, template text
- Constraint: same as A
- Output: `$BASELINE/subagent-E-receipt.md`
- Commit: "feat(v46.0): subagent E — tests + starter-packs + templates"

### 4.3. Fan-in: captain validates each receipt (F-OPS-07)
For each subagent:
- Verify receipt exists
- `./agency/tools/reset/subagent-scope-check.sh <id> <manifest> <changed-files>` returns 0
- Receipt's ref-leakage count is 0 (after their sweep, no `claude/` in their scope)
- Any overlap with other subagent scope = reject + re-dispatch

### 4.4. Post-fan-out ref inventory + diff
```bash
./agency/tools/ref-inventory-gen > "$BASELINE/ref-inventory-post.txt"
diff "$BASELINE/ref-inventory-pre.txt" "$BASELINE/ref-inventory-post.txt" > "$BASELINE/ref-inventory-diff.txt"
# Remaining hits must be in allowlist only
```

### Gate 4
`gate-check-4.sh`:
- 5/5 subagent receipts present + valid
- Ref-inventory post-diff empty modulo `ref-sweep-allowlist.txt`
- `subagent-scope-check.sh` passes for each subagent
- Supply-chain check (R-12): no NEW files in `agency/hooks/`, `agency/tools/`, `.claude/` (sweep is edits-only)
- Line-count delta heuristic: each subagent's edits should be path-substitution only (bounded delta)

Phase cursor → `phase-4-gate-passed`.

## Phase 4.5 — CLAUDE.md + settings.json + agent @imports (~5 min, captain only)

### 4.5.1. `.claude/settings.json`
Rewrite hook paths:
- `$CLAUDE_PROJECT_DIR/claude/hooks/*.sh` → `$CLAUDE_PROJECT_DIR/agency/hooks/*.sh`

### 4.5.2. Root `CLAUDE.md`
Rewrite @imports:
- `@agency/CLAUDE-THEAGENCY.md` → `@agency/CLAUDE-THEAGENCY.md`

### 4.5.3. `agency/CLAUDE-THEAGENCY.md` internal @imports
- `@agency/REFERENCE-*.md` → `@agency/REFERENCE/REFERENCE-*.md`
- `@agency/README-*.md` → `@agency/README/README-*.md` (if any)

### 4.5.4. `agency/agents/*/agent.md`
Any @imports referencing old paths.

### 4.5.5. Commit
```bash
./claude/tools/git-safe-commit "feat(v46.0): finalize @import resolution — CLAUDE.md + settings.json + agent @imports" --no-work-item --body "..."
```

### Gate 4.5 — Captain smoke battery (V4-enhanced)
`gate-check-4-5.sh`:
- `./agency/tools/handoff read` succeeds
- `./agency/tools/dispatch list` succeeds
- `./agency/tools/flag list` succeeds
- `./agency/tools/agency-health` returns exit ≤ 1 (allow warnings, not critical)
- `bats tests/` parity vs Phase 0 baseline (no NEW failures)
- `bats tests/tools/skill-validate.bats` passes (if exists)
- Hookify dynamic canary: attempt `git status` directly → exit 2 with expected message
- `commit-precheck` on a post-reset file passes
- ISCP tool battery (dispatch-db, flag, iscp-check, iscp-migrate) passes
- Ref-injector live test: invoke one skill with `required_reading:`, confirm path resolves
- CLAUDE.md @import resolution: headless parse CLAUDE.md @tokens, `test -f` each

Phase cursor → `phase-4-5-gate-passed`.

## Phase 5 — Hookify rule validation (~10 min)

### 5.1. Static check per rule
```bash
for rule in agency/hookify/*.md; do
  if grep -qE 'claude/' "$rule"; then
    echo "STATIC FAIL: $rule contains claude/ references"
  fi
done
```

### 5.2. Dynamic canary per rule (via `hookify-rule-canary`)
```bash
./agency/tools/reset/hookify-rule-canary.sh --all
# Attempts the blocked action for each rule, verifies block fires with correct message
```

### 5.3. Commit
```bash
./agency/tools/git-safe-commit "test(v46.0): hookify rule validation — 40+ rules verified firing post-reset" --no-work-item --body "..."
```

### Gate 5
- All hookify rules static-clean (no `claude/` references)
- All rules dynamic-fire correctly
- Canary receipts preserved

Phase cursor → `phase-5-gate-passed`.

## Phase 6 — Release notes + migration guide (~10 min)

Per F-OPS-06: release notes MUST exist before PR-open.

### 6.1. Release notes

File: `CHANGELOG-2026-04-19-v46.0.md` (repo root, follows existing CHANGELOG naming).

Content:
```markdown
# v46.0 — Structural Reset (2026-04-19)

**BREAKING CHANGE.** The framework directory has moved from `claude/` to `agency/`.

## Summary
- `claude/` → `agency/` (tree rename)
- `agency/REFERENCE/` (all 36 REFERENCE docs, was flat at `claude/`)
- `agency/README/` (3 non-top README files)
- Dead subsystems archived to `agency/workstreams/the-agency/history/flotsam/`
- Duplicate workstreams merged into `the-agency/`
- Injection-test artifact, empty `docs/`, legacy bug DBs removed

## Migration (monofolk — mandatory)

Run:
```bash
agency update --migrate
```

This flag:
- Rewrites `.claude/settings.json` hook paths
- Rewrites `CLAUDE.md` @imports
- Validates paths resolve

## Post-migration checklist
1. `.claude/settings.json` points at `agency/hooks/` (no ENOENT on hook fire)
2. `CLAUDE.md` @imports resolve (fresh session starts cleanly)
3. `/handoff read` works
4. `/dispatch list` works
5. One dispatch round-trip to captain

## Rollback
`agency update --version v45.3 --migrate-back`

Manual fallback:
- Revert `.claude/settings.json` hook paths (explicit diff example below)
- Revert `CLAUDE.md` @imports (explicit diff example below)

### Example: .claude/settings.json diff
[BEFORE/AFTER diff]

### Example: CLAUDE.md @import diff
[BEFORE/AFTER diff]

### Example: skill required_reading: diff
[BEFORE/AFTER diff]
```

### 6.2. Migration reference doc

File: `agency/REFERENCE/REFERENCE-MIGRATION-V46.md` — step-by-step guide with commands.

### 6.3. Commit
```bash
./agency/tools/git-safe-commit "docs(v46.0): release notes + migration guide" --no-work-item --body "..."
```

### 6.4. Audit log commit (F9)
Commit the audit log:
```bash
cp usr/jordan/captain/reset-audit-20260419.log agency/workstreams/the-agency/history/reset-audit-20260419.log
./claude/tools/git-safe add agency/workstreams/the-agency/history/reset-audit-20260419.log
./agency/tools/git-safe-commit "docs(v46.0): commit reset audit log for historical record" --no-work-item
```

### Gate 6 — PR-open gate
- Release notes include WORKING examples for 3 breaking paths
- Migration reference doc complete
- `agency update --migrate` BATS test passes
- `agency update --migrate-back` BATS test passes
- Audit log committed

Phase cursor → `phase-6-gate-passed`.

## PR Creation

Per branching decision: new PR `v46.0-structural-reset`.

```bash
./agency/tools/pr-create --title "D46-R1: v46.0 — Structural Reset (breaking)" --body "$(cat release-notes.md)"
```

PR body includes full release notes + migration guide link + rollback runbook.

## Post-Merge — Gate 7 (V10)

Captain on master after merge:
```bash
./agency/tools/agency-health --json all > post-merge-health.json
bats tests/ > post-merge-bats.txt
./agency/tools/handoff read
./agency/tools/dispatch list
```

If red: `./agency/tools/git-captain revert-merge <sha>` and notify monofolk via cross-repo dispatch.

### Gate 7 — Post-merge master smoke
If passes: dispatch fleet rebase template to 9 worktree agents (V6 per-worktree rollback included).

## Fleet dispatch template (V6 + V12)

Each worktree agent receives:
```
Subject: Rebase onto master for v46.0 structural reset
Body:
1. Tag pre-rebase state: `git tag pre-v46-rebase` (in worktree)
2. Rebase: `./agency/tools/git-safe merge-from-master --remote`
3. Run smoke: handoff read, dispatch list, flag list, agency-health
4. On smoke FAILURE: `./agency/tools/git-safe reset --hard pre-v46-rebase` + report
5. On smoke SUCCESS: commit post-rebase worktree state
```

## Monofolk dispatch (post-merge)

Cross-repo dispatch to monofolk:
- Subject: "v46.0 structural reset merged — run `agency update --migrate` before next session"
- Body: release notes + link to migration guide + rollback runbook

## V8 — Migration validation on synthetic v45.3 snapshot

Before merging the reset PR, run this test in `/tmp/v45-snapshot/`:
```bash
AGENCY_ALLOW_RAW=1 git clone <repo> /tmp/v45-snapshot/
cd /tmp/v45-snapshot
AGENCY_ALLOW_RAW=1 git checkout v45.3-pre-reset
./agency/tools/agency update --migrate  # (after building the flag)
# Run monofolk smoke battery
```

Assert green before Gate 6 passes.

## Deliverables summary

Artifacts this Plan produces:
- 12 commits across 9 phases
- `usr/jordan/captain/reset-baseline-20260419/` with 10+ baseline artifacts
- 10 `gate-check-{0..6,7}.sh` scripts
- `agency/tools/ref-inventory-gen`
- `agency/tools/agency-archive-then-delete`
- `agency/tools/reset/subagent-scope-check.sh`
- `agency/tools/reset/hookify-rule-canary.sh`
- `_agency-update --migrate` + `--migrate-back` flags + BATS tests
- `ref-sweep-allowlist.txt`
- 5 subagent file-list manifests
- `CHANGELOG-2026-04-19-v46.0.md`
- `agency/REFERENCE/REFERENCE-MIGRATION-V46.md`
- Audit log
- Post-merge fleet dispatch

## Open items resolved in execution

All MAR findings folded in. If any execution-time surprise surfaces, captain falls back to rollback (v45.3-pre-reset tag).

---

## Completeness scorecard

| # | Section | Status |
|---|---|---|
| Phase 0 | Baseline + tooling | ✓ 12 items, all scripted |
| Phase 1 | Great Rename | ✓ 8-canary check + exhaustive rename validation |
| Phase 2 | Subdir reorg | ✓ Deterministic |
| Phase 3a | Archive moves | ✓ With HISTORICAL-PATH-NOTE |
| Phase 3b | DB extraction | ✓ Integrity + round-trip |
| Phase 3c | Dead-confirmed deletes | ✓ Via archive-then-delete wrapper |
| Phase 3.5 | Workstream merge | ✓ Content-type triaged |
| Phase 4 | Ref sweep | ✓ 5 subagents with explicit manifests + per-subagent commits + fan-in validation |
| Phase 4.5 | CLAUDE.md + settings.json | ✓ Captain only |
| Phase 5 | Hookify validation | ✓ Static + dynamic |
| Phase 6 | Release notes + migration | ✓ With working examples + BATS for migrate flag |
| Gate 7 | Post-merge smoke | ✓ With revert-merge path |
| Fleet dispatch | Worktree rebase | ✓ With per-worktree rollback |
| Monofolk | Cross-repo dispatch + migration test | ✓ With synthetic v45.3 snapshot |

**Score: 14/14. Plan is execution-ready after MAR clears.**

MAR queued.
