# pr-captain-land — examples

## Happy-path examples

### Captain lands agent's PR end-to-end

Captain is on master, main checkout, tree clean. Agent dispatched `/pr-submit` for branch `jordan-devex-d12-r3`:

```
/pr-captain-land jordan-devex-d12-r3
```

Expected flow:

```
[pr-captain-land] Preflight OK: main-checkout=ok, branch=master, tree=clean, remote-branch=exists, receipt=found
[pr-captain-land] Switched to jordan-devex-d12-r3
[pr-captain-land] Receipt verified: hash 8b4c2e1 matches qgr-pr-prep-20260419-1430-8b4c2e1.md
[pr-captain-land] Bumping monofolk_version 1.9 → 1.10
[pr-captain-land] Pushed chore(manifest) commit to origin/jordan-devex-d12-r3
[pr-captain-land] Created PR #118: "devex: fix worktree-sync MAIN_BRANCH resolution"
[pr-captain-land] Switched back to master
[pr-captain-land] CI check (lint-and-test): PENDING... SUCCESS (attempt 4 of 30, 80s)
[pr-captain-land] Merging PR #118 via pr-merge --principal-approved
[pr-captain-land] Merged. Syncing master... fetched + merged origin/master
[pr-captain-land] Released v1.10 on GitHub
[pr-captain-land] Dispatched monofolk/jordan/devex: "PR #118 landed — v1.10 released"
✓ Land complete. Size: M, ~3-10 minutes (CI wait dominates).
```

### Dry-run to preview

Captain wants to see the PR body before committing:

```
/pr-captain-land jordan-devex-d12-r3 --dry-run
```

Expected: walks Steps 1-4 (precondition check + receipt verify + version-bump preview + PR body compose) and stops before mutation. Prints the proposed PR title, body, and version bump target. Exit 0.

### Custom title override

```
/pr-captain-land jordan-devex-d12-r3 --title "[devex] Critical: fix worktree-sync for all fleet agents"
```

Uses the override instead of the agent's scope.

### Land without release

Rare — a PR that shouldn't cut a release (e.g., a doc-only amendment to a prior release):

```
/pr-captain-land jordan-captain-d41-r22-doc-fix --no-release
```

Steps 1–7 run; Step 8 skips release creation; Step 9 dispatches agent without a release URL.

## Failure-mode examples

### Not in main checkout

Captain accidentally invokes from a worktree:

```
/pr-captain-land jordan-devex-d12-r3
```

```
[pr-captain-land] ERROR: Preflight failed — not in main checkout.
  Current: /Users/jordan_of/code/monofolk/.claude/worktrees/devex
  Expected: main checkout (first entry of `git worktree list`)
  Fix: cd to main checkout and re-run, OR use /pr-submit if you're an agent.
```

Exit 1. Zero mutation. (Runtime precondition — Layer 4 of the captain-only defense.)

### Agent branch name fails validation

Rare — adversarial branch name or typo:

```
/pr-captain-land "evil; rm -rf /"
```

```
[pr-captain-land] ERROR: Invalid branch name.
  Provided: "evil; rm -rf /"
  Required: regex ^[a-zA-Z0-9][a-zA-Z0-9/_.-]*$, no '..', no leading '-'
```

Exit 1. (Branch-name validation from ccf054ad / MAR finding F-SEC-2.)

### Receipt mismatch (most common legit failure)

Captain's coord commits landed on master between agent's `/pr-prep` and captain's `/pr-captain-land`. Agent's receipt hash no longer matches:

```
[pr-captain-land] Preflight OK
[pr-captain-land] Switched to jordan-devex-d12-r3
[pr-captain-land] ERROR: No receipt matches current diff-hash (c1d2e3f).
  Searched: agency/workstreams/**/qgr/*qgr-pr-prep-*-c1d2e3f.md (0 matches)
  The agent's receipt was signed against an older origin/master baseline.
[pr-captain-land] Switching back to master.
[pr-captain-land] Dispatching agent: "Receipt stale — re-run /pr-prep + /pr-submit."
```

Exit 1. Captain is back on master, agent is notified, no partial state.

### CI failure

```
[pr-captain-land] ... (steps 1-6 succeed)
[pr-captain-land] CI check (lint-and-test): PENDING... FAILURE (attempt 2 of 30, 40s)
[pr-captain-land] Switching back to master.
[pr-captain-land] Dispatching agent: "CI failed — fix and re-submit. Version bump commit (abc1234) stays on your branch."
```

Exit 1. Version-bump commit is on the agent's branch; they can push more fixes on top. On re-submit, `pr-captain-land` detects current version == target and skips re-bump.

### CI timeout

10-minute wait elapsed with no resolution:

```
[pr-captain-land] CI check (lint-and-test): still PENDING after 30 attempts (10min)
[pr-captain-land] Switching back to master.
[pr-captain-land] Timeout — captain investigate manually. PR #118 open at https://github.com/...
```

Exit 1. Captain uses `gh pr checks 118` + whatever manual resolution.

### Merge fails after green CI

Unusual — likely branch-protection edge:

```
[pr-captain-land] CI green. Merging via pr-merge --principal-approved.
[pr-captain-land] ERROR: pr-merge exit 3 (branch protection blocked).
  Fallback: run /pr-captain-merge 118 --principal-approved manually.
```

Exit 1. Release is skipped. Captain resolves via the companion skill.

### Release creation fails but merge succeeded

Most common: GitHub release API hiccup:

```
[pr-captain-land] Merged PR #118 successfully.
[pr-captain-land] gh-release create v1.10 FAILED: ...
[pr-captain-land] WARN: merge is the primary outcome (success). Release creation deferred.
  Captain: run `gh release create v1.10 --target master --notes-file ...` manually.
[pr-captain-land] Dispatched agent with merge confirmation (no release URL).
```

Exit 0 because merge is authoritative. (MAR follow-up H13 proposes stricter semantics — track there.)

### Dispatch emission fails at the end

```
[pr-captain-land] Merged + released successfully.
[pr-captain-land] WARN: dispatch emission failed (ISCP tool error).
  Agent will see the PR landed on next /sync, even without the dispatch.
```

Exit 0. Merge + release are the authoritative record.

## Four-layer defense in action

Each of the four defense layers has caught a different incident in development:

1. **`disable-model-invocation: true`** — prevented an auto-tool-use accidentally firing during a multi-turn coord dialog
2. **`paths: []`** — prevented the skill from auto-surfacing when captain opened a file under `.claude/worktrees/*/` (which is where this skill definitely should not fire)
3. **`captain-` name qualifier** — a new agent browsing the skill list asked "wait, is this captain-only?" → answered by the name before even reading SKILL.md
4. **Runtime precondition** — caught a case where the first three layers were all bypassed (captain copied the script to a worktree sandbox to test) and the script refused to run because `pwd` wasn't the main checkout

Defense in depth works.

## Concurrency note

**Never run two `/pr-captain-land` simultaneously.** Phase 1 pilot enforces this by captain discipline (one captain, one sequential skill). Phase 2 adds a lockfile at `$HOME/.agency/monofolk/pr-captain-land.lock`.

Captain CAN run other non-land work concurrently (dispatch reads, flag triage, reviewer-agent launches). Just not two lands.
