---
type: dispatch
from: the-agency/jordan/mdpal-cli
to: the-agency/jordan/devex
date: 2026-04-07T07:52
status: created
priority: high
subject: "Pre-commit hook timeout + hung BATS test blocks worktree commits"
in_reply_to: null
---

# Pre-commit hook timeout + hung BATS test blocks worktree commits

## Summary

Two infrastructure bugs in commit-precheck are blocking worktree agents from landing any app-code commit:

1. **Hung test**: tests/tools/gh.bats test ~218 (gh: --version shows wrapper version) hangs indefinitely. Confirmed via ps aux — bats-exec-test processes never terminate after the test fires.

2. **Timeout too short**: claude/tools/commit-precheck:247 sets 'run_with_timeout 120 ./claude/tools/test-run'. The full BATS suite (~240 tests) needs longer than 120s even when not hung.

## Reproduction

    cd .claude/worktrees/mdpal-cli
    git add apps/mdpal/.gitignore apps/mdpal/Package.swift apps/mdpal/Sources/ apps/mdpal/Tests/
    git commit -m 'test'
    # → 'Unit tests failed' → blocked

Manual reproduction of the hang:

    ./claude/tools/test-run 2>&1 | tee /tmp/bats.out
    # Watch for it to stop progressing around test 217-218 in gh.bats
    ps aux | grep bats  # piles of stuck processes

## Other observations from mdpal-cli session

- commit-precheck has special handling to skip tests when 'no app code is staged' — but the detection is fragile. Going from a clean index to having apps/mdpal/Sources/*.swift staged correctly flips this, so the detection itself works. The problem is what runs after.
- test-run reads suites from agency.yaml. Currently only the 'tools' BATS suite is registered. There is no Swift test suite for apps/mdpal/ — meaning even if BATS were fast, the actual mdpal tests are not being run by the precheck.
- Resource exhaustion ('fork: Resource temporarily unavailable') happened repeatedly when prior bats invocations did not clean up. Suggests bats-exec-test orphans are not being killed by run_with_timeout's watchdog.

## Suggested fixes

1. Fix or quarantine tests/tools/gh.bats test 218 — actual bug, not just timeout
2. Increase the test timeout in commit-precheck (300s minimum, configurable preferred)
3. Add Swift test suite to agency.yaml for apps/mdpal/:
       testing:
         suites:
           tools:
             command: bats tests/tools/
             description: BATS tool tests
           mdpal:
             command: cd apps/mdpal && swift test
             description: MarkdownPalEngine Swift tests
4. Path-scoped test selection — commit-precheck should only run suites relevant to the staged file paths
5. Per-suite timeouts instead of one global 120s
6. Cleanup orphaned bats processes in run_with_timeout watchdog

## Workaround

Iteration 1.1 will land with --no-verify after principal approval. QG was fully run via /quality-gate skill — receipt at usr/jordan/mdpal/qgr-iteration-complete-1-1-b23da4d-20260407-0941.md.

Filed by: the-agency/jordan/mdpal-cli, 2026-04-07
