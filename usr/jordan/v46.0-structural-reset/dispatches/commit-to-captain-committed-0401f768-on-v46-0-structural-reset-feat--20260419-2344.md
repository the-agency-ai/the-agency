---
type: commit
from: the-agency/jordan/v46.0-structural-reset
to: the-agency/jordan/captain
date: 2026-04-19T15:44
status: created
priority: normal
subject: "Committed 0401f768 on v46.0-structural-reset: feat(v46.0): Phase 0 partial — git-safe ls-files + git-rename-tree + ref-inventory-gen + allowlist (3/20 tools)

Phase 0b progress on v46.0-structural-reset branch:

Tool 1: git-safe ls-files subcommand
  - Read-only enumeration pass-through for git ls-files
  - BATS: 5 tests (min 4 per Plan v4)

Tool 2: git-rename-tree
  - Enumerate via git ls-files -z + AGENCY_ALLOW_RAW=1 git mv per file
  - Per-file JSONL audit entries
  - BATS: 12 tests (min 10) — all Plan-v4 canaries verified
  - Bash 3.2 compatible

Tool 3: ref-inventory-gen
  - Pre/post manifest classifier: rename-target / allowlisted / unknown
  - Excludes src/archive/, history/, usr/, test/test-agency-project/
  - --strict exits nonzero on any unknown (Gate 4 blocker)
  - BATS: 11 tests (min 10)

Allowlist seed: 19 entries (min 14 per Plan v4).

No regressions in existing BATS. Plan v4 Principle 8: tool-with-BATS-before-invocation."
in_reply_to: null
---

# Committed 0401f768 on v46.0-structural-reset: feat(v46.0): Phase 0 partial — git-safe ls-files + git-rename-tree + ref-inventory-gen + allowlist (3/20 tools)

Phase 0b progress on v46.0-structural-reset branch:

Tool 1: git-safe ls-files subcommand
  - Read-only enumeration pass-through for git ls-files
  - BATS: 5 tests (min 4 per Plan v4)

Tool 2: git-rename-tree
  - Enumerate via git ls-files -z + AGENCY_ALLOW_RAW=1 git mv per file
  - Per-file JSONL audit entries
  - BATS: 12 tests (min 10) — all Plan-v4 canaries verified
  - Bash 3.2 compatible

Tool 3: ref-inventory-gen
  - Pre/post manifest classifier: rename-target / allowlisted / unknown
  - Excludes src/archive/, history/, usr/, test/test-agency-project/
  - --strict exits nonzero on any unknown (Gate 4 blocker)
  - BATS: 11 tests (min 10)

Allowlist seed: 19 entries (min 14 per Plan v4).

No regressions in existing BATS. Plan v4 Principle 8: tool-with-BATS-before-invocation.

## Commit: 0401f768

**Branch:** v46.0-structural-reset
**Agent:** the-agency/jordan/v46.0-structural-reset
**Message:** housekeeping/captain: feat(v46.0): Phase 0 partial — git-safe ls-files + git-rename-tree + ref-inventory-gen + allowlist (3/20 tools)

Phase 0b progress on v46.0-structural-reset branch:

Tool 1: git-safe ls-files subcommand
  - Read-only enumeration pass-through for git ls-files
  - BATS: 5 tests (min 4 per Plan v4)

Tool 2: git-rename-tree
  - Enumerate via git ls-files -z + AGENCY_ALLOW_RAW=1 git mv per file
  - Per-file JSONL audit entries
  - BATS: 12 tests (min 10) — all Plan-v4 canaries verified
  - Bash 3.2 compatible

Tool 3: ref-inventory-gen
  - Pre/post manifest classifier: rename-target / allowlisted / unknown
  - Excludes src/archive/, history/, usr/, test/test-agency-project/
  - --strict exits nonzero on any unknown (Gate 4 blocker)
  - BATS: 11 tests (min 10)

Allowlist seed: 19 entries (min 14 per Plan v4).

No regressions in existing BATS. Plan v4 Principle 8: tool-with-BATS-before-invocation.

### Metadata
- commit_hash: 0401f768
- branch: v46.0-structural-reset
- files_changed: 20
- stage: none
- stage_hash: none
- work_item: none

### Files Changed
```
agency/tools/git-rename-tree
agency/tools/git-safe
agency/tools/ref-inventory-gen
agency/tools/ref-sweep-allowlist.txt
tests/tools/git-rename-tree.bats
tests/tools/git-safe-ls-files.bats
tests/tools/ref-inventory-gen.bats
usr/jordan/captain/reset-baseline-20260419/PHASE-0A-NOTES.md
usr/jordan/captain/reset-baseline-20260419/PHASE-CURSOR.txt
usr/jordan/captain/reset-baseline-20260419/baseline-symlink-check.txt
usr/jordan/captain/reset-baseline-20260419/bats-baseline.txt
usr/jordan/captain/reset-baseline-20260419/claude-md-checksum.txt
usr/jordan/captain/reset-baseline-20260419/content-inventory.sha256
usr/jordan/captain/reset-baseline-20260419/env-file-inventory.txt
usr/jordan/captain/reset-baseline-20260419/hookify-rule-count.txt
usr/jordan/captain/reset-baseline-20260419/ref-inventory-pre.txt
usr/jordan/captain/reset-baseline-20260419/sensitive-dirs-sha256.txt
usr/jordan/captain/reset-baseline-20260419/settings-checksum.txt
usr/jordan/captain/reset-baseline-20260419/skill-count.txt
usr/jordan/claude-tools-worktree-sync/dispatches/commit-to-captain-committed-91dcfcd7-on-contrib-claude-tools-worktre-20260419-2253.md
```
