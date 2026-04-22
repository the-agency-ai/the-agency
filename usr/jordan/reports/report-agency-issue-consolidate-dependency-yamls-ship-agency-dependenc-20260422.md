---
report_type: agency-issue
issue_type: feature
filing_agent: the-agency/jordan/captain
filed_by: jordan
date_filed: 2026-04-22
target_repo: the-agency-ai/the-agency
github_issue: https://github.com/the-agency-ai/the-agency/issues/412
github_issue_number: 412
status: open
---

# Consolidate dependency YAMLs + ship /agency-dependency-manage + dependency-manage tool

**Filed:** 2026-04-21T23:53:02Z
**Target:** [the-agency-ai/the-agency](https://github.com/the-agency-ai/the-agency)
**Issue:** [#412](https://github.com/the-agency-ai/the-agency/issues/412)
**Type:** feature
**Status:** open

## Filed Body

**Type:** feature

# Consolidate dependency YAMLs + ship `/agency-dependency-manage` + `dependency-manage` tool

## Problem

We have two competing dependency YAMLs:

- `agency/config/dependencies.yaml` — newer, richer schema (2026-04-09), has `schema_version: "1.0"`, tier organization (required/testing/optional), full provenance header. **Orphan** — no tool references it.
- `agency/config/agency-dependencies.yaml` — older, flatter, 162 lines. **Live** — `agency/tools/dependencies-check:33` and `agency/tools/dependencies-install:31` both point at it.

Current state: canonical content lives in the non-canonical file; canonical path points at the thinner content. Ambiguity blocks `agency verify`, workshop-VM bootstrap, and adopter confidence.

Surfaced during V5 Phase -1 latent-tool-reference audit (Bucket G.1 fleet work, 2026-04-22). Tagged at the time for principal 1B1; resolved 2026-04-22.

## Deliverable (target: v46.18, own PR)

### 1. Merge (section-by-section, no silent drift)

- Final path: `agency/config/dependencies.yaml` (the newer, richer file is canonical)
- Delete `agency/config/agency-dependencies.yaml`
- Re-point callers:
  - `agency/tools/dependencies-check:33` → `dependencies.yaml`
  - `agency/tools/dependencies-install:31` → `dependencies.yaml`

### 2. Comprehensive sweep

"Ensure the final document actually covers what we use." Two-stage sweep:

- **Stage A (source of truth):** Grep every binary the repo shells out to. Tools in `agency/tools/`, hooks, skills, workflows. Build a discovered-binaries set.
- **Stage B (cross-check):** Verify discovered set against any bootstrap material (Brewfile, CI install step, workshop-VM notes, `.github/workflows/*.yml`, onboarding READMEs) to catch anything used via env that doesn't show up in grep (gh auth, xcode-select, ssh, system bash version guards).
- Every binary in the discovered set must appear in the merged YAML; anything in the YAML but not in the set is flagged for removal.

### 3. Schema change: kill the "optional" tier

Collapse to two tiers:

- **required** — needed for normal runtime of the framework
- **testing** — needed to run the test suite (`bats`, `vitest`, etc.)

Rationale: an "optional" dep is a contradiction — either we use it (required) or we don't. Feature-gated paths are required when the feature is on; they're not optional.

### 4. Build `agency/tools/dependency-manage` (bash tool)

Subcommands:

- `add <name> --tier <required|testing> [--brew <formula>] [--min-version <X.Y>] [--used-by <tool>] [--why <desc>]`
- `remove <name>`
- `update <name> --<field> <value>` — mutate a single field on an existing entry
- `list [--tier <tier>]` — print the current state
- `check` — pass-through to `dependencies-check` for consistency (one UX surface)
- `audit` — list (a) declared-but-unused entries (in YAML, not grep-hit anywhere), (b) used-but-not-declared entries (grep-hit but missing from YAML)
- `install-script [--output <path>]` — emit a runnable bash script that installs or updates missing/out-of-date deps to make the host conformant. Default output: stdout; `--output` writes to file.

Conventions:
- `--help` / `--version`
- Sources `lib/_log-helper` for telemetry (RUN_ID per invocation)
- Mutations are atomic — either full YAML update or error, never partial
- Refuses `add` when the name already exists unless `--force` is passed
- Refuses `remove` when the tool is still grep-hit in the repo (audit-guard)

### 5. Build `.claude/skills/agency-dependency-manage/SKILL.md`

Shape: how-to guidance (not a wrapper). Teaches the agent:
- When to use it (adding a new tool that shells out to X, auditing if we still use Y, regenerating bootstrap)
- The merge policy (every commit that introduces a new binary dep must add/update in the YAML)
- The schema + tier rules
- How to use each subcommand
- The relationship to `dependencies-check` + `dependencies-install`
- `ref-injector` pointer to a reference doc if needed

### 6. BATS tests for `dependency-manage`

Coverage for each subcommand:
- `add` happy path + refusal-on-duplicate + refusal-on-missing-required-flag
- `remove` happy path + refusal-on-still-used
- `update` round-trip
- `list` tier filter
- `check` pass-through behavior
- `audit` detects both declared-but-unused AND used-but-not-declared correctly (red→green for each direction)
- `install-script` generates a runnable bash that succeeds against a known-missing dep in a test fixture

Isolation: mktemp per test; no repo pollution (per test-pollution incidents #387/#390).

## Acceptance

- [ ] `dependencies.yaml` contains every binary the repo shells out to
- [ ] `agency-dependencies.yaml` deleted; no callers reference it
- [ ] `dependencies-check` + `dependencies-install` work against new path
- [ ] `dependency-manage add/remove/update/list/check/audit/install-script` all work with BATS coverage
- [ ] `/agency-dependency-manage` skill discoverable via `/` autocomplete, renders correctly
- [ ] Audit run produces 0 declared-but-unused and 0 used-but-not-declared
- [ ] `install-script` emits a file that, when run on a fresh macOS with only bash + brew, produces a conformant host
- [ ] QG passes (4 reviewers + 1 scorer)
- [ ] v46.18 released

## Context

- Surfaced by: V5 Phase -1 latent-tool-reference audit 2026-04-22 → `agency/workstreams/agency/research/latent-tool-reference-audit-20260422.md`
- Principal 1B1: 2026-04-22 session
- Release target: v46.18 (post v46.17 which landed the Phase 3 prune on 2026-04-22)
- Priority: post-1B1 ordering decision (5 more governance/architecture items in queue)

## Response Log

_(append responses, comments, and state changes here as they occur)_

- **2026-04-22:** Filed via `agency-issue file`. Issue created at https://github.com/the-agency-ai/the-agency/issues/412
