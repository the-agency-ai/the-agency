# pr-captain-land — examples (v2, local-first)

All output below is illustrative but shaped like the real thing. The one habit
worth forming: **rehearse first.**

---

## Rehearse before you land

`--rehearse` runs steps 0-3 — fetch, verify the branch and its base, cut the
scratch worktree, validate locally — then deletes the scratch. Nothing is
pushed. No PR, no version bump, no receipt, no release, no dispatch.

```
/pr-captain-land jordan-devex-d12-r3 --rehearse
```

```
→ Fetching origin...
→ Branch origin/jordan-devex-d12-r3 is current with origin/main
→ Creating scratch worktree _land-jordan-devex-d12-r3 at origin/jordan-devex-d12-r3...
→ Agent receipt verified: agency/workstreams/devex/qgr/…-8b4c2e1.md (hash: 8b4c2e1)
→ Validating locally in _land-jordan-devex-d12-r3 (this is the gate)...
  · tests (<pm> run bats:all)
  · commit-precheck
→ Local validation: PASSED (2 local validation step(s) passed against origin/main)

pr-captain-land: rehearsal complete — integrated + validated, nothing published.
```

`--dry-run` is the same run plus a printout of what would be published:

```
/pr-captain-land jordan-devex-d12-r3 --dry-run
```

```
…
[DRY-RUN] Would publish:
    PR title:    jordan-devex-d12-r3
    Head branch: _land-jordan-devex-d12-r3 (pushed from the scratch worktree)
    Base branch: main
    Agent to notify: devex
    Release:     yes, v<bumped version>
```

---

## Happy path — full land

Captain on `main` in the main checkout. Agent dispatched `/pr-submit` for
`jordan-devex-d12-r3`.

```
/pr-captain-land jordan-devex-d12-r3
```

```
→ Fetching origin...
→ Branch origin/jordan-devex-d12-r3 is current with origin/main
→ Creating scratch worktree _land-jordan-devex-d12-r3 at origin/jordan-devex-d12-r3...
→ Agent receipt verified: agency/workstreams/devex/qgr/…-8b4c2e1.md (hash: 8b4c2e1)
→ Validating locally in _land-jordan-devex-d12-r3 (this is the gate)...
  · tests (<pm> run bats:all)
  · commit-precheck
→ Local validation: PASSED (2 local validation step(s) passed against origin/main)
→ Bumping agency_version 46.25 → 46.26 (in scratch)
→ Signing captain landing receipt (hash_e: 3f19ad0)...
→ Pushing _land-jordan-devex-d12-r3...
→ Creating PR...
→ PR created: https://github.com/the-agency-ai/the-agency/pull/470 (#470)
→ Waiting for CI on PR #470 (aggregate status check rollup)...
→ CI green: bash 3.2 probe,manifest version,smoke
→ Merging PR #470 (true merge commit)...
→ Creating release v46.26...
→ Cleaning up scratch worktree and land branch...
→ Dispatching devex with merge outcome...
→ Reconciling local main with origin...

pr-captain-land: complete
  Branch:  jordan-devex-d12-r3 (via _land-jordan-devex-d12-r3)
  PR:      https://github.com/the-agency-ai/the-agency/pull/470
  Release: v46.26
  Gate:    local (2 local validation step(s) passed against origin/main), CI confirmed
```

Note what did **not** happen: the main checkout never switched branches, the
agent's branch was never modified, and local `main` moved only at the very end,
by a plain fast-forward from origin.

### Custom title

```
/pr-captain-land jordan-devex-d12-r3 --title "[devex] Fix worktree-sync for all fleet agents"
```

### Explicit agent to notify

The dispatch target defaults to the branch-name prefix, which is a guess. Override it:

```
/pr-captain-land fix/pr-submit-org-resolution --agent devex
```

The default is the branch-name prefix, checked against the agent registry. For
`fix/pr-submit-org-resolution` that guess is `fix`, which is not a registered
agent — the script says so and routes to captain instead. Pass `--agent` and
the author actually hears that their work landed.

(That branch lands via scratch worktree `_land-fix-pr-submit-org-resolution` —
slashes *and dots* collapse to dashes, so `captain-grm-v1.2` becomes
`_land-captain-grm-v1-2`.)

### Land without cutting a release

```
/pr-captain-land jordan-captain-d41-r22-doc-fix --no-release
```

Steps 0-8 run; the release is skipped; the agent dispatch omits the release URL.

---

## Failure modes

### Stale base — the most common block

```
/pr-captain-land jordan-mdpal-app-phase3
```

```
→ Fetching origin...

BLOCKED: 'jordan-mdpal-app-phase3' does not contain origin/main (4 commit(s) behind).

  Its QGR receipt was signed against an older base, so it can never
  verify against the current one. This is not a receipt bug.

  Agent action: merge main into jordan-mdpal-app-phase3, re-run /pr-prep,
                push, then re-run /pr-submit.
```

Nothing was created. This is the message you want instead of a bare hash
mismatch — it names the cause and the fix.

### Local validation fails — the whole point of v2

```
→ Validating locally in _land-jordan-devex-d12-r3 (this is the gate)...
  · tests (<pm> run bats:all)

── local validation output (tail) ──
not ok 41 worktree-sync: resolves MAIN_BRANCH from origin/HEAD
…
────────────────────────────────────

pr-captain-land: local validation failed at step 'tests' — see output above.
  Rolled back: scratch worktree _land-jordan-devex-d12-r3 deleted. Nothing was published.
```

No PR was opened. No version was bumped. No release exists. The agent gets a
dispatch naming the failing step and re-preps. In v1 this failure would have
surfaced on GitHub *after* a version bump had already been pushed to the
agent's branch.

### Receipt does not match the branch

```
pr-captain-land: no QGR receipt matching hash 8b4c2e1 on branch jordan-devex-d12-r3.
  The branch content and the newest receipt disagree.
  Agent action: re-run /pr-prep, push, re-run /pr-submit.
```

Scratch deleted. Nothing published.

### Leftover scratch from a crashed run

```
pr-captain-land: scratch worktree _land-jordan-devex-d12-r3 already exists at
  /Users/jdm/code/the-agency/.claude/worktrees/_land-jordan-devex-d12-r3
  A previous land is still running, or crashed. Inspect it, then:
    ./agency/tools/worktree-delete _land-jordan-devex-d12-r3 --force
```

The script never auto-deletes a pre-existing scratch — it could be another land
in flight.

### CI red after a green local gate

```
pr-captain-land: CI FAILED on PR #470 — failing checks: smoke
  The local gate passed but the server disagreed. Investigate before re-landing.
  Agent must fix, push, and re-submit via /pr-submit.
```

Worth reading carefully: local and server disagreeing is a signal about the
validation ladder, not just about the branch.

### No status checks at all

```
pr-captain-land: no status checks found on PR #470.
  This is NOT a pass. Either CI is not configured for this repo,
  or the required-contexts filter matched nothing.
  Merge manually with /pr-captain-merge if that is expected.
```

An empty rollup is never treated as green.

### No local validation command resolved — this ABORTS

```
pr-captain-land: no local validation command resolved for this repo — refusing to land.
  The local gate is the whole point of this flow; signing a landing receipt
  for a validation that did not happen would make the receipt a lie.

  Fix one of these:
    - declare a build/test script in package.json, or
    - set PR_LAND_VALIDATE_CMD='<your gate>', or
    - pass --allow-unvalidated to land anyway (recorded in the receipt).
  Rolled back: scratch worktree _land-some-branch deleted. Nothing was published.
```

Fix it for the repo:

```
PR_LAND_VALIDATE_CMD='make ci' /pr-captain-land some-branch --rehearse
```

Or, knowingly, land without a gate — the receipt records
`NO LOCAL VALIDATION RAN (--allow-unvalidated)` so the audit trail is honest:

```
/pr-captain-land some-branch --allow-unvalidated
```

### Branch protection blocks the merge

```
pr-captain-land: pr-merge failed on PR #470:
  BLOCKED: branch protection requires 1 approving review

  If branch protection is the blocker and the principal approved,
  re-run with --principal-approved, or merge via /pr-captain-merge.
```

`--principal-approved` is never asserted on your behalf. It is the captain's
attestation that the principal actually said yes, and the only route to
`gh pr merge --admin`.

### A previous land crashed and left a scratch behind

```
pr-captain-land: land branch _land-devex-x already exists (no worktree).
  A previous land crashed mid-cleanup. Inspect it, then:
    ./agency/tools/git-captain branch-delete _land-devex-x --force
```

Both the directory and the branch are checked, because a crash between
`worktree add -b` and `worktree remove` leaves only the branch — and
`worktree-create` then refuses on every retry.

### A prior merge never got its release

```
pr-captain-land: a previous PR merge has no release yet.
  {"pr": 468, "base": "main"}
  Run /pr-captain-post-merge <that-PR> first, then re-run this land.
```

### Running from the wrong place

```
pr-captain-land: must run from main checkout (you're in a worktree).
  Main checkout: /Users/jdm/code/the-agency
  Current:       /Users/jdm/code/the-agency/.claude/worktrees/devex
```

### A dirty main checkout is fine now

```
note: main checkout is dirty — harmless here (the land runs in a scratch worktree).
→ Fetching origin...
```

In v1 this was a hard stop (#393). The land no longer touches local main, so
uncommitted captain work is simply irrelevant to it. One caveat: the Step-9
reconcile is a `merge-from-origin`, which does need a clean tree — on a dirty
checkout it is skipped with a note and `/captain-sync-all` picks it up.

Same for the branch the checkout happens to be on:

```
note: main checkout is on 'captain-coord-20260810', not 'main' — harmless
      (the land runs in a scratch worktree).
```

### Cannot reach origin

```
pr-captain-land: could not fetch origin.
  The land validates against origin/<default>; stale refs would make
  every downstream check meaningless. Fix connectivity/auth and retry.
```

The fetch is fatal, not best-effort — validating against stale refs and then
publishing is the failure this whole flow exists to prevent.
