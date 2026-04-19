---
type: investigation
date: 2026-04-15
author: the-agency/jordan/captain
re: "Why is CI blocking?"
---

# CI investigation — what's "blocking" and why

## TL;DR

Nothing is actually blocking on PR #90. The "skipping" status on full-qg and
sister-gate is **by design** — they only run on fork PRs and upstream-port
branches respectively. Smoke passes.

PR #87 has no CI checks because it's in **mergeable=CONFLICTING / DIRTY**
state — GitHub doesn't even attempt CI on a conflicting PR. The conflict is
in `agency/config/manifest.json` (40.5→41.3 on contrib vs 41.1 on main from
PR #89). Resolution requires manual merge of origin/main into contrib branch,
which is blocked locally until PR #90 lands (D41-R2 introduces the
`git-safe merge-from-master --remote` flag needed to do this without raw
git).

## Workflow inventory

| File | Trigger | Runs on |
|------|---------|---------|
| `smoke-ubuntu.yml` | push to main, all PRs to main | ALL PRs (universal gate, ~90s) |
| `fork-pr-full-qg.yml` | PRs to main where `head.repo.full_name != repository` | Ring 3 fork PRs only |
| `sister-project-pr-gate.yml` | PRs to main where `head.repo == repository` AND `startsWith(head.ref, 'upstream-port/')` | Ring 2 sister-project port branches only |

This is the three-ring trust model:
- **Ring 1 (core team, same-repo branches):** smoke only. Fast. Trusted to have run local QG.
- **Ring 2 (sister projects, upstream-port/ branches):** smoke + sister-gate (full BATS).
- **Ring 3 (community forks):** smoke + full-qg (full BATS, hardest gate).

## PR-by-PR status

### PR #90 (jordan-captain-d41-r2 — Ring 1)

```
smoke         pass     ✓
full-qg       skipping  (correct — Ring 1, not a fork PR)
sister-gate   skipping  (correct — Ring 1, not upstream-port/)
```

**Verdict:** all required checks pass. PR is ready for principal review/merge.

### PR #87 (contrib/claude-tools-collaboration — Ring 1, my D41-R3 cleanup)

```
no checks reported
mergeable: CONFLICTING
mergeStateStatus: DIRTY
```

**Verdict:** GitHub's CI doesn't attempt to run because the PR has merge
conflicts. The conflict is `agency/config/manifest.json` — contrib branch
bumped 40.5→41.3 directly (skipping 41.1 from PR #89 and 41.2 from PR #90).

**Resolution path:**
1. Land PR #90 first → main has v41.2 + the new git-safe --remote flag.
2. Captain sync local main with origin (now possible via `git-captain sync-main`
   from D41-R2).
3. Switch to contrib branch, run `git-safe merge-from-master --remote`.
4. Resolve manifest.json conflict (keep 41.3).
5. Push. CI re-runs automatically.

Alternative (if user wants to land #87 BEFORE #90): manually edit
manifest.json on contrib branch to 41.1 (matching main), let GitHub auto-merge,
re-bump version on the merge commit. More fragile, not recommended.

## Branch protection rules (assumed — should verify)

Repo has branch protection on `main`:
- Requires PR (no direct push).
- Requires smoke check to pass.
- Requires principal approval.
- Optional: required for full-qg (Ring 3), sister-gate (Ring 2). When skipped, status is "skipping" not "pending" — this is GitHub's correct handling for `if:` conditions.

If branch protection requires full-qg/sister-gate as REQUIRED checks (not
optional), then "skipping" might block merges. **Action:** verify in repo
settings that the required checks list is `[smoke]` only, and that
full-qg/sister-gate are NOT in the required list. If they are, switch them
to optional — the if-condition makes them context-dependent.

## What's actually missing

Looking at the contribution model docs and the workflow files, two gaps:

1. **No status check verifying QGR receipt presence.** A PR could lack the
   QGR receipt and still pass CI. The `pr-create` tool enforces this locally,
   but a hand-crafted contributor PR (from a fork) could skip it. Could add
   a workflow that verifies QGR exists for the diff.

2. **No status check verifying version bump.** Same gap. `pr-create` enforces;
   raw `gh pr create` does not (and is hookify-blocked locally, but a
   contributor on a fork has no such hook).

Filing as flag #134 + #135.

## Recommendation

- PR #90: merge when ready, no CI gating issue.
- PR #87: defer until PR #90 lands; resolve conflict in the prescribed flow.
- Verify branch protection required-checks list is `[smoke]` only.
- Add receipt + version-bump CI gates as a follow-up release (D41-R7 or later).
