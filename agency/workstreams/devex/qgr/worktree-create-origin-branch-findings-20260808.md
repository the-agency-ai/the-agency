# QG Findings — worktree-create origin-branch DWIM (v2.2.0)

Boundary: pr-prep
Agent: the-agency/jordan/devex
Reviewed artifact: commit `b9a4f89b` (diff vs `origin/main`)
Date: 2026-08-08

Two reviewer agents ran in parallel against the changed files
(`agency/tools/worktree-create`, `src/tests/tools/worktree-create.bats`).

---

## Reviewer 1 — code correctness

Verified bash 3.2.57 compatibility empirically; all 24 tests passing at review time (git 2.50.1).

| # | Sev | Location | Finding |
|---|-----|----------|---------|
| 1 | HIGH | worktree-create:207 | New `elif` also fires when the branch name defaulted to the worktree name. On a fresh clone / adopter repo, `worktree-create devex` would check out a months-stale `origin/devex` instead of branching from HEAD. Only signal is an `echo` agents do not read. Suggested gating the remote path on an explicit `--branch`. |
| 2 | MEDIUM | worktree-create:207 | `origin` hard-coded. A repo whose remote is `upstream` still hits the exact bug being fixed; with both `origin` and `upstream` carrying the branch, origin wins with no diagnostic. |
| 3 | MEDIUM | worktree-create:204-214 | No fetch before consulting the remote-tracking ref. A branch never fetched still falls to case 3 and produces the empty-branch failure the change claims to fix. |
| 4 | MEDIUM | bats:275-295 | "existing local branch is reused" tests nothing: comment describes a local-only commit that was never written, and `local-work` has no origin counterpart, so local-vs-remote precedence is unverified. |
| 5 | LOW | worktree-create:142-144 | Trailing `--branch` with no value dies on `$2: unbound variable` under `set -u`. |
| 6 | LOW | worktree-create:171,210 | `BRANCH` unvalidated; `--branch HEAD` matches `refs/remotes/origin/HEAD` then fails in plumbing. |
| 7 | LOW | bats:40-41 | `--initial-branch` fallback leaves bare HEAD on `master` on git < 2.28, producing an unborn-HEAD fixture. |

Explicitly cleared: bash 3.2 portability, `--track -b` correctness/ordering (available since git 2.9), quoting and word splitting, `set -euo pipefail` interactions, ambiguous-ref risk (`show-ref --verify` requires fully-qualified refs), case ordering, and the `CALLER_PROJECT_ROOT` capture (confirmed load-bearing).

## Reviewer 2 — test quality and isolation

Verified empirically that the live checkout was byte-identical before and after a run, and that bats 1.13 removes `BATS_TEST_TMPDIR`. No leak observed; findings are about margin.

| # | Sev | Location | Finding |
|---|-----|----------|---------|
| 1 | HIGH | bats:68 + tool:50 | Leak prevention rests on exactly one line of the tool, and no test asserts it. `cd "$TEST_REPO"` is not a second line of defense — the `rev-parse --show-toplevel` fallback never runs while `AGENCY_PROJECT_ROOT` is set. A regression leaks first and fails second, with no cleanup: `test_isolation_teardown` watches `.git/config` and agent dirs, neither of which `git worktree add` touches. |
| 2 | HIGH | bats:20-23 | `setup()` leaves `AGENCY_PROJECT_ROOT` at the ambient value — in an agency session, the live repo root. Safe today only because the other 20 tests exit before the creation path. |
| 3 | MEDIUM | bats:279-281 | Same as reviewer 1 #4 — precedence untested, comment describes a commit that does not exist. |
| 4 | MEDIUM | bats:40-41 | Same as reviewer 1 #7. |
| 5 | MEDIUM | bats:239-240 | Origin path asserted only by exit status and SHA; a lucky SHA match would pass. Tool prints a distinctive marker that should be asserted. |
| 6 | MEDIUM | — | Missing cases: no `--branch` at all; branch already checked out elsewhere; worktree dir already exists; slash-bearing branch name; `--workstream`/`--agent` combined with `--branch`. |
| 7 | LOW | bats:5-11 | Header contradicts itself — still claims no real worktrees are created. |
| 8 | LOW | bats:237 | Bare `git` assertion relies on `set -e`; reports only a line number on failure. |
| 9 | LOW | bats:71-73 | Custom `teardown()` drops the tmpdir `rm -rf` the default helper does. |
| 10 | LOW | bats:43 | Fixture rebuilt three times; empty-bare `git clone` emits an uncaptured warning. |
