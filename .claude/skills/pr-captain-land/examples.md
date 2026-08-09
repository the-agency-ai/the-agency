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
    Agent to notify: jordan
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

(That branch would land via scratch worktree `_land-fix-pr-submit-org-resolution` —
slashes collapse to dashes.)

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

### No local validation command resolved

```
WARNING: no local validation command resolved for this repo.
  Set PR_LAND_VALIDATE_CMD, or declare a build/test script.
  Landing continues, but local-first validation did NOT happen.
```

The landing proceeds, but the warning is also written into the landing
receipt's summary so the audit trail records that the local gate was empty.

Fix it for the repo:

```
PR_LAND_VALIDATE_CMD='make ci' /pr-captain-land some-branch --rehearse
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
uncommitted captain work is simply irrelevant to it.
