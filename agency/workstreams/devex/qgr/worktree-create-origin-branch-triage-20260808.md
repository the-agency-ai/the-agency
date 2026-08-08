# QG Triage — worktree-create origin-branch DWIM (v2.2.0)

Boundary: pr-prep
Agent: the-agency/jordan/devex
Findings input: `worktree-create-origin-branch-findings-20260808.md`
Disposition commit: `521a0f01`
Date: 2026-08-08

17 findings from 2 reviewers, deduplicated to 14 distinct items.
**13 ACCEPT (fixed) · 1 REJECT · 0 DEFER.**

---

## ACCEPT — fixed in `521a0f01`

| Finding | Fix |
|---------|-----|
| R1-2 remote hard-coded | `find_remote_for_branch` enumerates `git remote` and probes each. Origin wins ties; several non-origin remotes carrying the branch is refused, not guessed. Enumeration rather than `refs/remotes/*/$BRANCH` globbing keeps slash-bearing names correct. |
| R1-3 no fetch / staleness invisible | Remote path now prints short SHA, commit date, subject, and ahead/behind vs HEAD, plus an explicit "only as fresh as your last fetch" note. Fresh-from-HEAD path hints to fetch. Auto-fetch deliberately not added — network side effects belong to `git-captain`, and the diagnostics solve the actual "silently stale" problem. |
| R1-4 / R2-3 precedence untested | Test rewritten. Fixture pushes `origin/local-work` at main; test points local `local-work` at stale-pr's commit; asserts the worktree lands on the local SHA, not origin's, and that the remote marker is absent. Fails if the remote check is ever hoisted above the local one. |
| R1-5 unbound `$2` | `_require_value` guard on `--branch`/`--workstream`/`--agent` in both parse loops. Test 31 asserts a usage hint and the absence of "unbound variable". |
| R1-6 BRANCH unvalidated | `git check-ref-format --branch "$BRANCH"`. Test 30 covers `--branch HEAD`. |
| R1-7 / R2-4 fixture unborn HEAD | `git -C "$upstream" symbolic-ref HEAD refs/heads/main` after init. |
| R2-1 leak undetected | `teardown()` diffs the live repo's worktree list and branch list against a `setup()` snapshot and fails the test on any change. Runs regardless of where the body aborted. Verified by deliberately reverting the `CALLER_PROJECT_ROOT` capture — guard fired with `LEAK: this test created or removed branches in the live repo`. |
| R2-2 ambient AGENCY_PROJECT_ROOT | `setup()` exports it to `${BATS_TEST_TMPDIR}/no-such-project-root`. |
| R2-5 lucky SHA match | Tests now assert the tool's own path marker (`tracking origin/...`, `creating it fresh from HEAD`) alongside SHA and content assertions. |
| R2-6 missing cases | Added: no `--branch`; name==branch resolving an origin-only branch; slash-bearing branch; worktree dir exists; branch already checked out elsewhere; illegal branch name; missing flag value. 20 → 31 tests. |
| R2-7 header contradiction | Header rewritten to describe both contracts and the isolation guards. |
| R2-8 bare assertion | Superseded — that fixture precondition is now covered by the rewritten tests. |
| R2-9 teardown tmpdir | Custom `teardown()` now calls `test_isolation_teardown` and returns the leak status; bats ≥1.7 owns `BATS_TEST_TMPDIR` removal. |

## REJECT

**R1-1 (HIGH) — gate the remote path on an explicit `--branch`.**

Rejected on correctness grounds. The suggested gate reintroduces the original bug for the name==branch case, which is how every agent worktree is created: `worktree-create devex` on a fresh clone would create a local `devex` shadowing `origin/devex`, handing the agent an empty tree whose first push is a non-fast-forward against their own real work. That is the same class of silent data loss as PR #426, just reached from the other direction. Never silently shadowing an existing remote branch is the correct git semantics.

The reviewer's underlying concern — a stale checkout being indistinguishable from a current one — is real and was accepted separately as R1-3: the tool now reports the resolved commit, its date, and its distance from HEAD. Behavior is pinned by test 26 (`default branch name also resolves an origin-only branch`) so a future change cannot silently revert it.

## DEFER

None. R2-10 (fixture rebuilt three times, ~1s total) was judged not worth the coupling of merging independent tests.

---

## Verification

- `src/tests/tools/worktree-create.bats` — 31/31 pass, 0 fail.
- Regression proof: the origin-only tests fail against the pre-fix tool and pass after.
- Leak guard proof: reverting the protection line makes the guard fire.
- Multi-remote paths smoke-tested both ways (refusal, and origin tiebreak).
- Full suite: 1179 pass / 326 fail, all pre-existing — identical failure set before and after, by stash-comparison over the affected files.
