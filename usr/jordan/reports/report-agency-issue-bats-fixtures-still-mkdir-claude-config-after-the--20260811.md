---
report_type: agency-issue
issue_type: bug
filing_agent: the-agency/jordan/devex-publish-path-repo-root
filed_by: jordan
date_filed: 2026-08-11
target_repo: the-agency-ai/the-agency
github_issue: https://github.com/the-agency-ai/the-agency/issues/465
github_issue_number: 465
status: open
---

# BATS fixtures still mkdir claude/config after the great-rename — 12 test files error out in setup()

**Filed:** 2026-08-11T08:17:51Z
**Target:** [the-agency-ai/the-agency](https://github.com/the-agency-ai/the-agency)
**Issue:** [#465](https://github.com/the-agency-ai/the-agency/issues/465)
**Type:** bug
**Status:** open

## Filed Body

**Type:** bug

## Summary

A large block of the BATS suite has not been *running* — the tests error out in `setup()` rather than failing an assertion, so the red has been easy to read as ordinary flakiness. Root cause is a single unswept path from the great-rename: fixtures `mkdir -p "$MOCK_REPO/claude/config"` but the tools they exercise now read `agency/config/agency.yaml`. The subsequent `cat > .../agency/config/agency.yaml` fails, `setup()` aborts, and **every test in the file errors**.

Found while checking the ISCP suites for regressions from the `-C` repo-root work (publish-path fix for `pr-captain-land`).

## Scope

Confirmed on pristine `main` — this is not caused by the `-C` branch.

**Fixed in the `-C` PR** (in blast radius; needed to prove no regression in the `dispatch` tool):
`iscp-check.bats`, `iscp-db.bats`, `dispatch-create.bats`, `flag.bats`, `agent-identity.bats`, `multi-principal.bats`, `address-parse.bats`, `iscp-migrate.bats`

That recovered **70 tests** on the targeted set alone (225 → 295 passing).

**Still broken — not touched, to keep that PR scoped:**

| File | Line(s) |
|---|---|
| `agency-update.bats` | 40, 41, 234, 250, 267 |
| `agency-init.bats` | 63 |
| `agent-create.bats` | 28 |
| `commit-prefix.bats` | 17 |
| `deploy.bats` | 20, 257 |
| `preview.bats` | 20, 263 |
| `platform-setup.bats` | 53 |
| `terminal-setup.bats` | 47, 75 |
| `provider-resolve.bats` | 19 |
| `release-plan.bats` | 32 |
| `sandbox-sync.bats` | 33 |
| `session-handoff.bats` | 25 |

## Fix

Mechanical, one token per site: `claude/config` → `agency/config` in the `mkdir -p`. In each ISCP file already fixed, the `mkdir` was the file's *only* `claude/config` reference while the body wrote to `agency/config`, so the replacement was 1:1 with no ambiguity. Worth confirming the same holds for each file above before swapping (`deploy.bats` and `preview.bats` also create `claude/tools`, which may be a separate stale path).

## Separate defect found in the same sweep

`iscp-migrate.bats` (14 tests) fails for a *different* reason after the path fix: `setup()` copies `agency/tools/iscp-migrate`, which does not exist in the repo. Either the tool was removed without removing its suite, or it was never landed. Needs a decision — restore the tool or delete the suite. Left alone for now.

## Why this matters beyond the count

These files error in `setup()`, so they report as failures without ever asserting anything. A suite that is loudly red in a way everyone has learned to scroll past provides no signal — the `-C` bug this was found alongside slipped through partly because nobody could tell which red was new. Recommend fixing the remaining twelve in one mechanical sweep and then treating the suite as gating.

## Response Log

_(append responses, comments, and state changes here as they occur)_

- **2026-08-11:** Filed via `agency-issue file`. Issue created at https://github.com/the-agency-ai/the-agency/issues/465
