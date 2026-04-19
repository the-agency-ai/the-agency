---
boundary: phase-complete
phase: "1"
slug: "adhoc-purge"
date: 2026-04-02 01:30
commit: aa2313e
plan: monofolk-dispatch-incorporation
---

# Quality Gate Report — Monofolk Phase 1: ADHOC Purge

## Status: Already Complete

Phase 1 (ADHOC purge) was completed during the Starter Sunset work (PR #25).
All ADHOC files, tools, flags, and framework references were removed. The
`--adhoc` flag was replaced with `--no-work-item` and a rejection test was added.

## Verification

| Check | Result |
|-------|--------|
| `find . -name "*adhoc*" -o -name "*ADHOC*"` (excluding .git) | Zero results |
| Framework files grep (excl. historical records) | Zero active refs |
| `--adhoc` flag in git-safe-commit | Rejected (test exists) |
| `--no-work-item` flag | Accepted (test exists) |
| adhoc-log tool | Deleted |
| ADHOC-WORKLOG.md files | All deleted |
| settings.json adhoc-log permission | Removed |

## Residual References (acceptable)

| Location | Reason |
|----------|--------|
| `agency/agents/unknown/backups/archive/` | Session backup archives (historical) |
| `claude/principals/jordan/requests/` | Historical REQUEST files |
| `claude/principals/jordan/projects/` | Book content |
| `docs/plans/` | Historical plan files |
| `tests/tools/git-operations.bats` | Rejection test (intentional) |
| `.worktrees/mock-and-mark/` | Separate worktree checkout |

## Checks

- [x] Zero ADHOC files in framework
- [x] Zero active ADHOC references in framework files
- [x] --adhoc flag rejected with test coverage
- [x] --no-work-item replacement working with test coverage
- [x] No regressions (all BATS pass)
