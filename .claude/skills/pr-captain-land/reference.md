# pr-captain-land Protocol

Full step-by-step execution flow for `/pr-captain-land`, with failure modes and recovery paths. This document is the contract; the script at `scripts/pr-captain-land` implements it.

## Preconditions checklist

Before any mutation, the script must verify ALL of these:

| # | Check | Failure action |
|---|---|---|
| 1 | `pwd` equals main checkout (first `git worktree list` entry) | exit 1, point at /pr-captain-land help |
| 2 | Current branch is `master` or `main` | exit 1, ask captain to switch |
| 3 | `git status --porcelain` empty | exit 1, list dirty files |
| 4 | `<agent-branch>` exists on origin | exit 1, list suggestion |
| 5 | Diff-hash of `<agent-branch>` matches a QGR receipt at `agency/workstreams/**/qgr/*qgr-pr-prep-*-{hash}.md` | exit 1, tell agent to re-prep |

Any failure => zero mutation, clean error message.

## The 9 steps

### Step 1 — Switch to agent branch

```
./agency/tools/git-captain switch-branch <agent-branch>
```

Current working branch becomes the agent's. Main checkout is now sitting on agent's branch.

**Failure:** switch fails (dirty tree, branch doesn't exist locally). Script exits; captain resolves.

### Step 2 — Verify receipt

Compute current diff-hash against `origin/master`. Find receipt matching that hash.

```
./agency/tools/diff-hash --base origin/master --json
# extract hash
find agency/workstreams -name "*qgr-pr-prep-*-{hash}.md"
```

**Failure:** no matching receipt. Branch state doesn't match what /pr-submit claimed. Switch back to master, exit 1. Agent must re-prep.

### Step 3 — Bump `monofolk_version`

Read current version from `agency/config/manifest.json`. Bump minor (e.g., 1.8 → 1.9). Write back with `updated_at` refreshed to current UTC timestamp.

Commit via `git-safe-commit` with message:
```
chore(manifest): bump monofolk_version {old} → {new} for PR landing (captain)
```

Push to origin.

**Failure:** push fails (concurrent captain activity, branch protection edge case). Switch back to master, exit 1.

### Step 4 — Create PR

```
./agency/tools/pr-create --title "{title}" --body "{body}"
```

Title: `--title` flag value, or `<agent-branch>` as fallback. Body: captain-authored fleet-aware description that wraps the agent's scope with:
- "Captain-landed PR via pr-captain-land (the-agency#296 Phase 1 pilot)"
- Branch, receipt path, hash, version bump
- Release v{new} will follow on merge

**Failure:** pr-create blocks on receipt mismatch (race with a concurrent captain coord commit on master). Re-verify hash, retry once; on second failure, exit 1 and ask captain to investigate.

### Step 5 — Switch back to master

```
./agency/tools/git-captain switch-branch master
```

Captain should sit on master for the wait-and-merge phase. Avoids any accidental commit landing on the PR branch.

### Step 6 — Watch CI

Poll `gh pr view {num} --json statusCheckRollup` every 20 seconds. Look at the `lint-and-test` check.

| State | Action |
|---|---|
| SUCCESS | proceed to Step 7 |
| FAILURE | exit 1 — agent must fix + push + resubmit |
| PENDING / IN_PROGRESS | wait 20s, poll again |

Max 30 attempts = 10 minutes. On timeout, exit 1.

**Note on `deploy-preview-backend`**: this check is environmental flake (ordinaryfolk org lookup issue). IGNORED by /pr-captain-land. Only `lint-and-test` is the gate.

### Step 7 — Merge

```
./agency/tools/pr-merge {pr-num} --principal-approved
```

Uses admin merge (principal-approved flag gated). True merge commit — never squash, never rebase per framework discipline.

**Failure:** merge conflicts (agent's branch drifted from master during the CI wait). Exit 1; captain resolves.

### Step 8 — Sync master + create release

```
./agency/tools/git-captain fetch
./agency/tools/git-captain merge-from-origin
./agency/tools/gh-release create v{new-version} --target master --title "..." --notes "..."
```

Release notes: captain-authored, references the PR number and agent.

**Failure (release only):** release creation fails but merge succeeded → warn captain, suggest manual `gh release create`. Skill returns success (merge is the primary outcome).

### Step 9 — Dispatch agent

Dispatch type: `master-updated`
Subject: `PR #{num} landed — v{new} released (pr-captain-land)`
Body: PR URL, release URL, version bump, Phase 1 pilot feedback request

Agent receives on their next /session-resume.

## Recovery flows

### Version-bump landed but CI failed

The version-bump commit is on agent's branch. Two paths:

- **Agent fixes + pushes** — version bump stays, new fixes layer on top. /pr-captain-land can be re-run after agent re-submits via /pr-submit. Version doesn't bump again (current → same).
- **Agent wants fresh state** — captain reverts the version-bump commit on agent's branch (separate cleanup).

Recommend the first path; simpler.

### Receipt invalidated mid-flow (Step 4 retry)

Between /pr-submit and /pr-captain-land, a captain coord commit may land on master, changing origin/master and thus the diff-hash. Agent's receipt no longer matches.

Detected at Step 2 or Step 4 (pr-create). Script exits; agent re-runs /pr-prep (re-signs receipt) + /pr-submit.

### CI green but merge fails

Likely branch-protection edge case. Script exits; captain uses `/pr-captain-merge <num> --principal-approved` manually to resolve.

### Dispatch monitor doesn't pick up /pr-submit

Captain manually runs `/pr-captain-land <branch>`. Dispatch integration is auto-convenience, not required for correctness.

## Concurrency

**One /pr-captain-land at a time.** Running two simultaneously would race on the version bump. No tool-level lock today; captain discipline enforces. Phase 2 adds a lockfile.

Captain can run other non-land work (dispatch reads, flag triage, reviewer agent launches) concurrently with /pr-captain-land. Just not two /pr-captain-land.

## Protocol versioning

v1.0 — this document. Phase 1 pilot.

v1.1 (planned): parse full dispatch payload instead of just branch name; agent's scope text becomes the PR body core.

v2.0 (planned): dispatch-monitor auto-invocation (captain doesn't type /pr-captain-land; monitor picks up /pr-submit dispatch and fires /pr-captain-land).
