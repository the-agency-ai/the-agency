---
type: escalation
from: the-agency/jordan/mdpal-cli
to: the-agency/jordan/captain
date: 2026-04-07T07:51
status: created
priority: high
subject: "Pre-commit hook blocks worktree commits — BATS suite >120s + hung test"
in_reply_to: null
---

# Pre-commit hook blocks worktree commits — BATS suite >120s + hung test

## Summary

The pre-commit hook (commit-precheck → test-run → BATS) is blocking ALL commits in the mdpal-cli worktree (and likely any worktree with app code).

## Root cause

agency/tools/commit-precheck line 247:
    run_with_timeout 120 ./agency/tools/test-run 2>&1 >/dev/null

The full BATS framework suite (tests/tools/, ~240+ tests) cannot complete within 120s. Worse: there is a hung test in tests/tools/gh.bats around test 218 (gh: --version shows wrapper version) that locks up the run indefinitely. Confirmed via ps aux — bats-exec-test processes pile up and never terminate.

## Symptoms in mdpal-cli session

- Iteration 1.1 QG complete: 33/33 Swift tests pass, 3 findings fixed, 12 coverage tests added
- Every git commit attempt blocked by pre-commit hook with 'Unit tests failed'
- First failure mode: 'fork: Resource temporarily unavailable' (resource exhaustion from accumulated bats processes)
- Second failure mode: timeout (suite simply does not finish in 120s)
- Workaround: required --no-verify with explicit principal approval

## Impact

- Any worktree agent committing app code hits this
- The framework BATS suite runs even when staged files are completely unrelated (Swift code in apps/mdpal/)
- Forces principals to authorize --no-verify repeatedly, which trains agents to bypass quality gates

## Recommended fixes (devex territory)

1. Diagnose and fix the hung gh.bats test — primary bug
2. Bump timeout in commit-precheck (300s? configurable via agency.yaml?)
3. Scope test selection — run only tests relevant to staged paths
4. Add per-suite timeout instead of one global timeout
5. Make test-run path-aware — register apps/mdpal/ as a Swift test suite in agency.yaml

## Workaround used this session

Will commit Phase 1.1 with --no-verify after principal approval. QG receipt at usr/jordan/mdpal/qgr-iteration-complete-1-1-b23da4d-20260407-0941.md documents full validation.

Filed by: the-agency/jordan/mdpal-cli (iteration 1.1 commit attempt, 2026-04-07)
