---
type: mar-findings-triage
workstream: the-agency
agent: the-agency/jordan/captain
date: 2026-04-19
prs_reviewed:
  - the-agency-ai/the-agency#294 (port worktree-sync from monofolk)
  - the-agency-ai/the-agency#295 (port test-worktree-sync.sh from monofolk)
source_commits:
  - cc907ddb (PR #294)
  - 739911fb (PR #295)
monofolk_origin: monofolk PR #109
reviewers:
  - reviewer-code (code correctness + shell quoting)
  - reviewer-security (injection + trust boundaries)
  - reviewer-design (framework pattern alignment)
  - reviewer-test (coverage + regression completeness)
  - captain (own review)
---

# MAR — PRs #294 + #295 (worktree-sync port from monofolk)

## Context

Monofolk/devex upstreamed a fix for the-agency`s `worktree-sync` tool that addressed a MAIN_BRANCH resolution bug: the tool read `rev-parse --abbrev-ref HEAD` from the main checkout, which could return whatever branch the captain happened to have checked out. If captain was on a release branch, every worktree-sync-ing agent would merge that release branch into their worktree. This caused the Day 42 designex incident (the-agency#291-class).

PR #294 ships the fix: resolve MAIN_BRANCH from `origin/HEAD` symbolic-ref, with fallback to local `main` / `master`, with safety guard refusing anything outside main/master.

PR #295 ships the regression test (Test 15 in the legacy shell test harness).

## Findings by reviewer

### reviewer-code

**No critical or major issues.** Fix is correct. All downstream usages of `$MAIN_BRANCH` are properly quoted.

Minors:
- `worktree-sync:98` — symbolic-ref path does not verify local branch exists. If `origin/HEAD` resolves to `main` but no local `refs/heads/main` exists (fresh single-branch clone), downstream logic silently no-ops.
- `worktree-sync:98` — `sed 's|^origin/||'` assumes `--short` output. Defensive: `s|^refs/remotes/origin/||; s|^origin/||`.

### reviewer-security

**No security issues.** Git ref validation + shell quoting close injection paths. `MAIN_BRANCH` value cannot be tricked into command execution. Destructive operations properly guarded. Test fixtures isolated to `mktemp -d`.

### reviewer-design

Six items:
- **(medium)** Divergence from 4 existing inline `detect_main_branch` variants in sibling tools (`git-captain`, `pr-build`, `git-safe`, `pr-create`). PR introduces a 5th. Should extract shared helper to `agency/tools/lib/_main-branch-resolve`.
- **(low)** Resolution order differs slightly across tools. Commit message claims alignment with `pr-create` but that's only partially true.
- **(informational)** Error message uses `Hint:` prefix; `pr-create` uses `Fix:`. Minor idiom drift.
- **(low)** Safety guard conflict: `dispatch` tool supports `develop`/`trunk`; this PR refuses anything non-main/master. Framework internally split on the posture.
- **(low)** Error message suggests editing the tool: "update worktree-sync's safety guard". Unusual convention — framework prefers "escalate to principal" phrasing.
- **(low-medium)** Code comment references `claude/REFERENCE-WORKTREE-DISCIPLINE.md` for "Day 42 designex incident" history — but that doc has no such section. Debt trap if unfixed.
- **(informational)** Tool predates the provenance-header convention and doesn't carry What/How/Why headers. Not introduced by this PR.

### reviewer-test

Four items:
- **(medium)** Test 15 lives in `agency/tools/tests/test-worktree-sync.sh` (legacy shell harness) but framework convention is BATS in `tests/tools/*.bats`. `tests/tools/worktree-sync.bats` **already exists** with 6 prior regression tests. The new regression should be there, not in the shell file.
- **(medium)** Test 15 only covers the FALLBACK path (test repo has no `origin` remote, so resolution always falls through to the for-candidate loop). Does NOT cover: (a) symbolic-ref path with a real remote, (b) local-main-preferred-over-master mid-rename, (c) safety guard refusing non-main/master branches.
- **(medium)** `agency/tools/lib/_health-worktree:89` has the SAME `rev-parse --abbrev-ref HEAD` pattern. Not destructive (health reporting) but misleading. Same bug class, untouched by this PR.
- **(low)** `assert_contains "merged master"` brittle — any future rewording of the success message breaks the test. Existing BATS tests use looser grep patterns.
- **(low)** Test 15 hand-rolls file-absence assertion instead of using `assert_*` helpers. Inconsistent with sibling tests.
- **(medium, pre-existing)** Test 6 and Test 14 in the shell file have pre-existing failures from message drift (issue #57 rework). Not introduced by this PR but suggests the shell test file is rotting.

### captain's own review

- Fix addresses both issue #267 (hardcoded master) and #292 (reads checked-out branch). Solid.
- Safety guard is belt+suspenders — appropriate for a destructive operation (merge).
- **Merge ordering:** #295 must NOT land before #294 — the test fails without the fix.
- PR body is sparse ("Contributed from monofolk"). Should carry "Closes #267, Closes #292" or similar attribution trail for the release-version discipline.

## Three-bucket triage (captain as author)

### Disagree (0 items)

No reviewer findings I disagree with.

### Autonomous — captain revises before proposing merge (6 items)

**On PR #294 branch:**
- Add local-branch verification after symbolic-ref extraction (reviewer-code finding 1)
- Defensive sed pattern (reviewer-code finding 2)
- Fix the REFERENCE-WORKTREE-DISCIPLINE.md cross-reference (either update the doc with the incident section or remove the link)
- Soften "update worktree-sync's safety guard" error message to "escalate" phrasing

**On PR #295 branch:**
- Port Test 15 into `tests/tools/worktree-sync.bats` (canonical BATS)
- Add coverage for the three missing resolution paths

### Collaborative — requires principal input (4 items)

1. **Sibling bug in `_health-worktree:89`** — same pattern, untouched. Fix in this PR sequence or file separately?
2. **Extract `_main-branch-resolve` helper** — refactor 5 inline variants. Take now, or defer?
3. **Shell test file rot** — Test 6, Test 14 pre-existing failures. Fix here or separate ticket?
4. **Framework posture on non-main/master branches** — tools disagree. Ratify, or let destructive-vs-read-only drift stand?

## Captain leans on the collaborative items

1. Fix `_health-worktree` now — same headspace, cheap.
2. Defer helper extraction — deserves its own MAR.
3. Let the shell test file's existing failures stay; file a ticket to port or retire.
4. Let destructive vs. read-only tools differ by posture; document the distinction later.

## Merge order

- Revise both PRs per Bucket 2 actions
- Resolve Bucket 3 with principal
- Merge #294 first (the fix)
- Merge #295 second (the test, which depends on the fix)
- After merge, comment on issues #267 and #292 with "Fixed in v45.X" attribution (per the release-version discipline)

## References

- monofolk PR #109 (upstream source)
- the-agency-ai/the-agency#267 (hardcoded master)
- the-agency-ai/the-agency#292 (reads checked-out branch)
- Day 42 designex incident (the-agency#291-class — still undocumented in `REFERENCE-WORKTREE-DISCIPLINE.md`, captain will fix during revision)
