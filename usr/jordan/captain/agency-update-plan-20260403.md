# Agency Update v2 + Addressing Tooling — Plan

**Date:** 2026-04-03
**Status:** Draft (MAR findings incorporated 2026-04-03)
**Author:** the-agency/jordan/captain
**PVR:** `agency-update-pvr-20260402.md`
**A&D:** `agency-update-architecture-20260402.md`

## Overview

Implement the manifest-driven `agency update` v2 with three-tier file management, build the `_address-parse` addressing library, update dispatch-create and handoff with fully qualified addresses, and migrate agency.yaml to the nested principals format.

Two bodies of work share infrastructure (`_address-parse`), so they're planned together. The A&D is approved with 14 monofolk review findings incorporated.

## Phase 1: Address Library + Input Validation

Build the foundation that everything else depends on. No external dependencies — pure library code with comprehensive tests.

### 1.1: Build `_address-parse` library

- Create `claude/tools/lib/_address-parse`
- Implement `address_parse` — segment-count dispatch (1=bare, 2=principal/agent, 3=repo/principal/agent, 4=org/repo/principal/agent)
- Implement `address_resolve` — repo from `git -C "$PROJECT_ROOT" remote -v` (explicit `-C` for worktree safety), principal from agency.yaml via `_pr_yaml_get`
- Implement `address_format` — produce `repo/principal/agent` string
- Implement `address_validate_component` — level-aware validation (org preserves case, others lowercase)
- Implement `_address_detect_repo` — parse GitHub SSH/HTTPS, GitLab nested groups
- Implement `_address_detect_principal` — find `$USER` in agency.yaml, handle flat + nested formats
- 3-segment ambiguity warning when first segment matches known org name
- Source `_path-resolve` for YAML primitives — no duplicate YAML parsing

### 1.2: Add `_validate_name()` to `_path-resolve`

- Add `_validate_name()` function per A&D Section 2.5
- Remove `_` from reserved names (regex handles it)
- Document leading digits as intentional
- Add timezone validator: `^[A-Za-z0-9/_+-]{1,64}$`
- Call `_validate_name()` in `_agency-init` on PRINCIPAL, PRINCIPAL_KEY, PROJECT_NAME before any filesystem operation

### 1.3: Tests for Phase 1

- Create `tests/tools/address-parse.bats`
- Parse all 4 input forms
- Resolve bare → fully qualified with mock git remote + mock agency.yaml
- Reject: empty, slashes, `..`, null bytes, reserved names, too long, uppercase in non-org
- Org names preserve case
- GitHub SSH, GitHub HTTPS, GitLab detection
- Principal from nested + flat agency.yaml
- Worktree context (`git -C` resolves correctly in worktree subdirs)
- YAML with colons in `display_name` — must not break parsing (fragile gate: if `_pr_yaml_get` fails on colon-containing values, file R1 and add Python helper before proceeding)
- Add `_validate_name` tests to existing `tests/tools/path-resolve.bats`
- All tests green before proceeding

## Phase 2: Dispatch + Handoff Addressing

Update dispatch-create and handoff to use fully qualified addresses. Depends on Phase 1 (`_address-parse`).

### 2.1: Rewrite `dispatch-create`

- Source `_address-parse`
- Auto-compute `created_by:` via `address_resolve` + `address_format`
- Add `--to`, `--subject`, `--reply-to`, `--priority` flags
- Validate `--to` address per segment via `address_validate_component`
- New frontmatter format per A&D Section 2.3
- File naming: `dispatch-{slug}-YYYYMMDD-HHMM.md`
- No `--from` flag — sender identity computed, not self-asserted (DD-7)

### 2.2: Update `handoff` tool

- Source `_address-parse`
- Add `agent:` field to frontmatter (fully qualified)
- Agent name from branch-to-agent mapping (main/master → captain, worktree → branch slug)
- Backward compatible: missing `agent` field still parses

### 2.3: Tests for Phase 2

- Create `tests/tools/dispatch-create.bats` per A&D test strategy
- Update `tests/tools/handoff-types.bats` — agent field present, fully qualified, backward compat
- All tests green

## Phase 3: Agency Init Updates

Update init to write per-file manifest with checksums and tiers. This gives `agency update` v2 a baseline.

### 3.1: Manifest generation in `_agency-init`

- After copying framework files, compute SHA-256 for each via `_compute_checksum`
- Write `claude/config/manifest.json` with per-file `hash`, `tier`, `version` fields
- Tier assigned from path-to-tier rules (A&D Section 2.6)
- `_compute_checksum` with file existence guard and capability probe (F5)

### 3.2: Agency.yaml nested format from init

- Write nested principals format from the start (A&D Section 2.8 item 4)
- Already partially done — verify current code writes correct structure
- Ensure `default:` entry migrates to `{ name: unknown }`

### 3.3: Update docs

- README-GETTINGSTARTED.md: `git init → agency init → claude` flow (DD-5)
- Help text in `_agency-init`

### 3.4: Tests for Phase 3

- Update `tests/tools/agency-init.bats`
- Manifest written with checksums and tiers
- Agency.yaml nested format
- Works without prior `claude init` (DD-5, F3 — already fixed at `bc980c7`)
- Fresh repo (unborn HEAD)

## Phase 4: Settings-Merge Upgrade

Upgrade settings-merge to key-based hook merging. The permissions.deny fix is already live (`ea528fe`).

### 4.1: Key-based hook merge

- Implement hook merge by matcher + event type in `settings-merge`
- Build composite key: `event_type + ":" + matcher` (e.g., `PreToolUse:Bash`)
- Algorithm:
  1. Index target hooks by composite key → `target_map`
  2. Index template hooks by composite key → `template_map`
  3. For each key in `template_map`: replace in output (framework hook updated)
  4. For each key in `target_map` NOT in `template_map`: preserve in output (project hook)
  5. Emit merged array
- jq implementation: `reduce` over template keys, then `reduce` over target-only keys
- Framework hooks identified by presence in template — no separate registry needed
- Handle edge case: hook with no matcher (e.g., global PreToolUse) uses `event_type + ":"` as key

### 4.2: Tests for Phase 4

- Framework hook updated when template changes
- Project-specific hook preserved across merge
- Permissions.deny preserved (regression test for F2)
- `enabledPlugins` preserved

## Phase 5: Agency Update v2 Rewrite

The core work. Depends on Phases 1-4. Replace rsync with manifest-driven file loop.

### 5.1: Pre-flight validation

- Source integrity: `claude/CLAUDE-THEAGENCY.md` exists, required dirs present
- Target initialized: `agency.yaml` exists
- Clean git state warning for `claude/` changes
- Source detection: `$AGENCY_SOURCE` → `../the-agency/` → error
- Check for stale sentinel `claude/config/.update-in-progress` — if present, previous update was interrupted; warn and require `--force` to proceed

### 5.2: Manifest load and bootstrap

- Load existing manifest, validate JSON (`jq .`)
- On parse failure → bootstrap mode
- V1 manifest (no tiers) → infer from path-to-tier rules, enrich
- No manifest → bootstrap: compute checksums, config-tier = user-modified (skip)
- `--force-config` flag overrides conservative bootstrap

### 5.3: File delta computation

- Write sentinel file `claude/config/.update-in-progress` with timestamp
- For each file in source framework: compute source + target SHA-256
- Look up manifest entry (hash, tier)
- Decision matrix per A&D Section 2.6 flow
- Build action list: copy, skip, warn, new, removed

### 5.4a: Apply delta — file copy loop

- Copy files per action list (framework + scaffold tiers)
- Skip config-tier files that are user-modified (checksum mismatch, no force)
- New files: copy and add to manifest
- Removed files: warn only (no delete without `--prune`)

### 5.4b: Apply delta — settings.json merge

- `settings.json` via `settings-merge` (key-based hooks per Phase 4)
- Run settings-merge as a distinct step after file copy

### 5.4c: Apply delta — agency.yaml migration

- Agency.yaml migration: detect format (flat/nested), migrate to nested
- Backup agency.yaml before migration, restore on failure
- Freeform data (display_name, principal_github) preserved as quoted YAML, flagged for review (F7)
- Sed terminator fix `/^[^[:space:]#]/` (F8)

### 5.4d: `--prune` implementation

- `agency update --prune`: delete target files that exist in manifest but are absent from source
- Only prune framework-tier files (never config or scaffold)
- List files to prune before deleting (dry-run shows them too)
- Remove pruned files from manifest

### 5.5: Post-update actions

- Remove sentinel file `claude/config/.update-in-progress` (written at start of 5.3)
- Update manifest: new checksums, tiers for new files, bump framework_version
- Atomic manifest write: `.manifest.json.tmp` → `mv`
- Run sandbox-sync
- Write handoff with `type: agency-update`, `agent:` fully qualified
- Generate update report at `usr/{principal}/{agent}/update-report-YYYYMMDD-HHMM.md`

### 5.6: Dry run mode

- `agency update --dry-run`: display what would change, no modifications
- Uses same delta computation, skips apply step

### 5.7: Tests for Phase 5

- Create `tests/tools/agency-update.bats` per A&D test strategy
- Clean update: all framework files updated
- User-modified hook: preserved, logged as skipped
- Manifest bootstrap: config-tier files treated as user-modified
- Agency.yaml migration: flat → nested, root-level → nested, already nested (idempotent)
- Settings.json: hooks merged (key-based), permissions preserved
- `--dry-run` preview without changes
- `--prune` removes framework-tier files absent from source; leaves config/scaffold alone
- Sandbox-sync runs post-update
- Update report generated
- Manifest corruption → bootstrap mode fallback
- Interrupted update: sentinel file detected, `--force` required to proceed
- Sentinel file removed on successful completion

## Phase 6: Session Hook + Docs + Verification

### 6.1: Update session-handoff.sh

- Detect `type: agency-update` handoffs
- Inject update context directing agent to run `agency verify`
- Backward compat: missing type falls back to session

### 6.2: Cross-repo commit protocol

- Add "Cross-Repo Contributions" section to CLAUDE-THEAGENCY.md
- Communication artifacts → push to main
- Executable code → PR
- Per DD-9

### 6.3: Final verification sweep

- Zero stale references to old tool names
- All BATS tests pass (existing + new)
- `jq` validation on all JSON configs
- `bash -n` on all shell tools (Bash 3.2 syntax check)
- Live test: run `agency update` on presence-detect project
- Update report reviewed

## Dependency Graph

```
Phase 1 (_address-parse + _validate_name) ──────┐
                                                  │
Phase 2 (dispatch + handoff)  ← needs Phase 1    │
Phase 3 (agency-init)         ← needs Phase 1    │
Phase 4 (settings-merge)      ← independent      │
                                                  │
Phase 5 (agency-update v2)    ← needs 1, 2, 3, 4│
                                                  │
Phase 6 (hooks + docs + verify) ← needs 5        │
```

Phases 2, 3, 4 can run in parallel after Phase 1. Phase 5 needs 1 + 2 + 3 + 4 complete (Phase 2 for handoff `agent:` field used in 5.5 post-update handoff). Phase 6 is last.

### Intra-Phase 5 Ordering

Phase 5 sub-steps have internal dependencies:

```
5.1 (pre-flight) → 5.2 (manifest load) → 5.3 (delta) → 5.4a-d (apply) → 5.5 (post-update)
5.6 (dry-run) shares 5.1-5.3, skips 5.4-5.5
```

5.4a (file copy), 5.4b (settings merge), 5.4c (yaml migration) are independent of each other but all depend on 5.3. 5.4d (prune) depends on 5.3 and runs after 5.4a.

## Risk Tracking

| Risk | Mitigation | Status |
|------|------------|--------|
| R1: YAML parsing in bash | BATS tests with edge-case YAML (including colons in display_name). Fragile gate: if `_pr_yaml_get` fails on colon-containing values, escalate to Python helper before proceeding. | Open |
| R2: Manifest file growth | ~200 lines at current scale. Monitor. | Low |
| R3: Settings.json hooks | Key-based merge (F1 resolution). DD-3 updated. | Resolved |
| R4: Migration idempotency | Every migration gets an idempotency BATS test. | Open |
| R5: Bootstrap handoff cost | Not in scope. Noted for future. | Deferred |
| R6: `_address-parse` SPOF | Comprehensive BATS as Phase 1 gate. Pure functions. | Open |
| R7: Bash 3.2 YAML limits | agency.yaml is our format. Tests cover our formats. | Open |
| R8: Manifest corruption | Validate JSON. Bootstrap fallback. Atomic write. Sentinel file for interrupted updates. | Open |
| R9: Interrupted update | Sentinel file `claude/config/.update-in-progress` detects partial state. `--force` to override. | Open |

## Estimates

6 phases, ~25-30 iterations. Phase 1 is the gate — everything depends on it. Phase 5 is the largest (~10 iterations with the 5.4 split).

## MAR Findings Log (2026-04-03)

3 parallel agents (completeness, sequencing, risk). 33 raw findings consolidated to 10 Critical/High. All incorporated above.

| # | Finding | Severity | Resolution |
|---|---------|----------|------------|
| 1 | Phase 5 missing Phase 2 dependency (handoff agent: field) | Critical | Fixed dependency graph: Phase 5 ← 1,2,3,4 |
| 2 | DD-3 says "wholesale replace" but A&D 2.7 says key-based merge | Critical | Fixed DD-3 in A&D to say "key-based merge" |
| 3 | Phase 5.4 scope too large (file copy + settings + yaml + prune) | High | Split into 5.4a/b/c/d sub-iterations |
| 4 | No transaction boundary for interrupted updates | High | Added sentinel file `.update-in-progress`, checked in 5.1 |
| 5 | `git remote -v` cwd issue in worktrees | High | Changed to `git -C "$PROJECT_ROOT" remote -v` in 1.1 |
| 6 | YAML parsing breaks on colons in display_name | High | Added fragile gate to R1 + colon test in 1.3 |
| 7 | jq hook merge algorithm is a comment stub | High | Expanded 4.1 with full composite-key algorithm |
| 8 | `--prune` tested in 5.7 but never implemented | High | Added 5.4d: `--prune` implementation |
| 9 | Iteration estimate ~20 is low | Medium | Revised to ~25-30 |
| 10 | Intra-Phase 5 ordering not documented | Medium | Added "Intra-Phase 5 Ordering" section |
