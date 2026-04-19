# Starter Sunset — Plan

**Date:** 2026-04-01
**Status:** Complete
**Author:** captain
**PVR:** `starter-sunset-pvr-20260401.md`
**A&D:** `starter-sunset-architecture-20260401.md`

## Overview

Sunset the-agency-starter repo, consolidate `agency-*` tools into a single `agency` CLI, add handoff type support, and implement `agency update`. Starter packs evolution into skills is deferred to DevEx work.

**Deferred PVR criteria (intentionally incomplete at plan end):**
- PVR 4.3 / Success Criterion #4: "Starter packs evolved into platform knowledge for `/environment-setup`" — deferred to DevEx service composition work
- PVR Success Criterion #9: "Platform setup work from DevEx agent integrated" — same deferral

## Phase 1: Agency CLI Scaffold + Registry Refactor

Build the `agency` CLI dispatcher, extract existing tools into lib subcommands, and refactor registry.json so Phase 3 can consume it cleanly.

### 1.1: Create `agency` dispatcher and subcommands
- Create `agency/tools/agency` — thin dispatcher with `AGENCY_ARGS` pattern per A&D Section 2.1
- Create `agency/tools/lib/_agency-init` — extract logic from current `agency-init`
- Create `agency/tools/lib/_agency-verify` — extract logic from current `agency-verify`
- Create `agency/tools/lib/_agency-whoami` — extract logic from current `agency-whoami`
- Create `agency/tools/lib/_agency-feedback` — extract logic from current `agency-feedback`, update target repo to `the-agency`
- Create `agency/tools/lib/_agency-update` — stub (implemented in Phase 3)
- Add `_agency_help` function to dispatcher
- Make `agency` executable
- Test: `agency help`, `agency whoami`, `agency verify` produce expected output

### 1.2: Wire permissions and clean up old tools
- Update `.claude/settings.json`: replace 5 `agency-*` entries with `agency` + `agency *`
- Update `agency/config/settings-template.json` if it exists
- Delete old tools: `agency-init`, `agency-update`, `agency-verify`, `agency-whoami`, `agency-feedback`
- Update any skills/commands that reference old tool names (grep for `agency-init`, `agency-verify`, etc.)
- Validate: `jq . .claude/settings.json > /dev/null`

### 1.3: Preconditions, framework section, and version
- Add precondition checks to `_agency-init`: `.git/`, `.claude/`, branch check (main/master), already-initialized check (`agency.yaml`)
- Add `framework` section to agency.yaml output (`version`, `installed_at`, `source_commit`)
- Implement `_agency_version` in dispatcher — reads `framework.version` and `framework.source_commit` from agency.yaml
- Dynamic bootstrap handoff content (computed counts, not hardcoded)
- Test: init on bare repo, init on already-initialized repo (warns), init on non-main branch (blocks), `agency version` reads from agency.yaml

### 1.4: Registry.json refactor
- Lift `protected_paths` from per-component nesting to top-level array
- Remove `starter_version`, `install_hooks`
- Remove `starter_version` from `manifest.json`
- Keep component list for reference
- This must complete before Phase 3 (agency update reads top-level protected_paths)

## Phase 2: Handoff Type System

Add type awareness to the handoff tool and session hook.

### 2.1: Update handoff tool
- Add `--type <type>` flag to `handoff write` command (default: `session`)
- Write YAML frontmatter with `type`, `date`, `branch`, `trigger` fields
- Ensure `handoff archive` preserves frontmatter as-is
- Ensure `handoff read` outputs raw content (no change needed)
- Test: `handoff write --type agency-bootstrap`, verify frontmatter; `handoff write` (no type), verify defaults to `session`

### 2.2: Update session-handoff.sh hook
- Add frontmatter type parsing (`sed` with default fallback)
- Add type-aware prefix injection (agency-bootstrap, agency-update, session)
- Test: bootstrap handoff triggers onboarding prefix; missing type falls back to session; malformed frontmatter falls back to session

### 2.3: Wire bootstrap handoff into `_agency-init`
- After framework copy, `_agency-init` writes the bootstrap handoff file directly (not via the handoff tool — init runs before the tool is available in the target project). Write the file with correct YAML frontmatter and computed content per A&D Section 2.4.
- Verify: run init, then simulate SessionStart, confirm bootstrap prefix injected

## Phase 3: Agency Update

Implement the `agency update` subcommand. Depends on Phase 1 (CLI exists) and Phase 2 (handoff types).

### 3.1: Source detection and framework sync
- Implement source detection: `$AGENCY_SOURCE` → `../the-agency/` → error with instructions
- Framework sync via rsync, respecting protected paths (read from registry.json top-level array — refactored in Phase 1.4)
- Settings merge via `settings-merge` tool
- Update `framework` section in agency.yaml (`updated_at`, `source_commit`, `version`)

### 3.2: Manifest update and change detection
- Update manifest.json file hashes
- Compute change summary (new/updated/removed files) for handoff content
- Test: run update with known diff, verify manifest reflects changes

### 3.3: Update handoff integration
- Read current handoff to extract summary of previous session state
- Archive existing handoff via `handoff archive`
- Write new handoff with `type: agency-update`, including update diff summary and previous state summary
- Test: run update, verify handoff archived, new handoff has correct type and content

## Phase 4: Starter Sunset

Remove all starter-specific artifacts. Depends on Phases 1 and 2.

### 4.1: Remove starter tools and docs
- Delete tools: `starter-test`, `starter-verify`, `starter-compare`, `starter-cleanup`, `starter-update`, `starter-release`
- Delete docs: `STARTER-PACK-INTEGRATION.md`, `STARTER-RELEASE-PROCESS.md`, `REPO-RELATIONSHIP.md`
- Delete tests: `tests/tools/starter-release.bats`

### 4.2: Remove test/the-agency-starter
- Determine removal method (submodule vs nested .git)
- Remove the directory and all references
- Update test workflows if they reference it

### 4.3: Clean up archive and references
- Commit and then remove `archive-the-agency-starter/` (it served as reference during A&D)
- Grep for remaining `the-agency-starter` references in framework files, remove or update
- Update stale references in CLAUDE-THEAGENCY.md and CLAUDE.md (replace `agency-init` references with `agency init`, etc.)
- Update CI workflows to not reference starter-specific content

### 4.4: Update test/test-agency-project fixture
- Update expected file layout to match new `agency` CLI (no `agency-init`, has `agency`)
- Update any fixture-internal references to reflect handoff type frontmatter
- Commit changes inside the embedded git repo

### 4.5: Archive GitHub repo (human action)
- Update the-agency-starter README to redirect: "This repo is archived. See [the-agency](link) for the current framework."
- Archive via GitHub settings (read-only)
- **Requires principal action** — captain prepares the README, principal executes the archive

## Phase 5: Verification and Tests

### 5.1: BATS tests for agency CLI
- Test `agency init` precondition checks (no .git, no .claude, wrong branch, already initialized)
- Test `agency verify` output
- Test `agency whoami` output
- Test `agency version` output
- Test `agency help` output
- Test `agency update` source detection (with and without $AGENCY_SOURCE)

### 5.2: BATS tests for handoff types
- Test handoff tool `--type` flag
- Test session-handoff.sh type parsing
- Test default fallback for missing type
- Test frontmatter preservation through archive cycle

### 5.3: Final verification sweep
- Zero `agency-init`, `agency-update`, `agency-verify`, `agency-whoami`, `agency-feedback` as standalone tools
- Zero stale references to old tool names in skills, commands, and docs
- Zero `the-agency-starter` in framework files (historical records excluded)
- Zero `starter_version` in config files
- All BATS tests pass
- `jq` validation on all JSON configs
- `bash -n` on all shell tools (Bash 3.2 syntax check)
- CI passes

## Dependency Graph

```
Phase 1 (CLI + registry) ─────┬──────────────────────┐
                               │                      │
Phase 2 (handoff types) ──────┤                      │
                               │                      │
                               ▼                      ▼
                    Phase 3 (agency update)    Phase 4 (starter sunset)
                          needs 1+2                needs 1+2
                               │                      │
                               ▼                      ▼
                          Phase 5 (verification)
                              needs all
```

Phases 1 and 2 are independent (can run in parallel). Phase 3 needs both (CLI for dispatch, types for update handoff). Phase 4 needs both (CLI exists before removing old tools, types for test fixture updates). Phase 5 is last.

## Risk Areas

1. **Embedded git repo removal** — `test/the-agency-starter/` has its own `.git/`. Need to determine if it's a submodule or just a nested repo.
2. **Handoff tool bootstrap chicken-and-egg** — `agency init` writes the bootstrap handoff, but the handoff tool doesn't exist in the target until after init copies it. **Resolution:** init writes the file directly with correct frontmatter (Phase 2.3).
3. **Settings.json permission timing** — removing old `agency-*` permissions and adding `agency *` must be atomic (settings-merge handles this).
4. **CI breakage during transition** — removing starter tools/tests may break CI if workflows still reference them. Phase 4 handles this explicitly.
5. **GitHub repo archive requires principal** — can't be automated, must be tracked as human action (Phase 4.5).

---

## Appendix: Review Findings and Resolutions

| # | Severity | Finding | Resolution |
|---|----------|---------|------------|
| M-1 | M | Phase 4 should depend on Phase 2 | Fixed: dependency graph updated |
| M-2 | M | Registry refactor split across phases, sequencing conflict | Fixed: moved to Phase 1.4, before Phase 3 |
| M-3 | M | `_agency_version` implemented before framework section exists | Fixed: moved to Phase 1.3 alongside framework section |
| M-4 | M | No plan work for GitHub repo archival | Fixed: added Phase 4.5 with human action marker |
| m-1 | m | Feedback target update mentioned in two places | Acknowledged: Phase 1.1 does it, Phase 4.3 grep catches if missed |
| m-2 | m | No Bash 3.2 compat check in tests | Fixed: added to Phase 5.3 |
| m-3 | m | Chicken-and-egg resolution ambiguous | Fixed: Phase 2.3 commits to direct file write |
| m-4 | m | No work item for CLAUDE.md/CLAUDE-THEAGENCY.md updates | Fixed: added to Phase 4.3 |
| m-5 | m | Deferred PVR criteria not acknowledged | Fixed: added to Overview |
| n-1 | n | Dependency graph ASCII misleading | Fixed: redrawn |
| n-2 | n | 5.3 should verify zero stale refs in skills/commands | Fixed: added to Phase 5.3 |
| n-3 | n | Phase 3 might need splitting | Fixed: split into 3.1, 3.2, 3.3 |
