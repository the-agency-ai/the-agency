# pr-captain-land Protocol (v2 — local-first)

Full step-by-step execution flow for `/pr-captain-land`, with failure modes and recovery paths. This document is the contract; the script at `scripts/pr-captain-land` implements it.

**Protocol version 2.0.** v1 was PR-first: switch the main checkout to the agent's branch, push, open a PR, let GitHub CI gate. v2 inverts that — integrate and validate locally in a scratch worktree, then publish already-validated work.

---

## The core idea

Everything happens in a **scratch worktree** at `.claude/worktrees/_land-<branch>`, cut from `origin/<agent-branch>`.

```
origin/<default> ──ancestor-of──▶ origin/<agent-branch>
                                        │
                                        │ worktree-create --from
                                        ▼
                         .claude/worktrees/_land-<branch>   ← all work happens here
                                        │
                        validate → bump → sign → push → PR
```

The main checkout stays on the default branch, untouched, for the whole run. **Rollback at any pre-publish failure is `worktree-delete _land-<branch> --force`** — there is no `git reset --hard`, no `merge --abort`, no stash, and nothing that can strand the captain.

Slashes in the agent branch name collapse to dashes in the scratch name (`fix/foo` → `_land-fix-foo`): a worktree directory must not nest under `.claude/worktrees/`, and `_land-fix/foo` as a ref would collide with an existing `_land-fix` ref.

## Preconditions checklist

| # | Check | Failure action |
|---|---|---|
| 1 | `pwd` is the main checkout (first `git worktree list` entry) | exit 1 naming both paths |
| 2 | Current branch is the resolved default branch | exit 1, ask captain to switch |
| 3 | No existing `.claude/worktrees/_land-<branch>` | exit 1 naming the path + the `worktree-delete` fix |
| 4 | `<agent-branch>` exists on origin | exit 1 |
| 5 | Branch name matches `^[a-zA-Z0-9][a-zA-Z0-9/_.-]*$`, no `..`, no leading `-` | exit 2 |
| 6 | `origin/<default>` is an ancestor of `origin/<agent-branch>` | BLOCK — see Step 1 |

**A dirty main checkout is NOT a precondition failure (#393).** The land never reads, commits to, or moves local main. The script notes the dirt and continues.

The default branch is resolved by `agency/tools/resolve-default-branch` — one shared primitive, never a hardcode.

---

## The 10 steps

### Step 0 — Preflight

Precondition checks 1-3, then `git-captain fetch`. No read or write of local main's content.

### Step 1 — Verify the branch and its base

```
git show-ref --verify refs/remotes/origin/<agent-branch>
git merge-base --is-ancestor origin/<default> origin/<agent-branch>
```

**Stale base is the important case.** If `origin/<default>` moved after the agent branched, the agent's QGR receipt was signed against an older base and can *never* verify. Reporting that as a hash mismatch sends the captain hunting the wrong problem. The script BLOCKS with the count of commits behind and the actual fix:

> merge `<default>` into `<agent-branch>`, re-run `/pr-prep`, push, re-run `/pr-submit`

### Step 2 — Cut the scratch worktree

```
./agency/tools/worktree-create _land-<branch> --from origin/<agent-branch>
```

This **is** the local integration. Step 1 proved `origin/<default>` is an ancestor, so the scratch tree already represents the agent's work on top of the default branch — no merge needed, no merge conflict possible.

`--from` was added to `worktree-create` for this (v2.2.0), along with allowing a leading underscore in worktree names so machine-created scratch worktrees are visually distinct from agent worktrees.

**Note:** `git-captain merge-to-master` is deliberately NOT used. It requires a *local* branch ref and merges into local main — both of which v2 avoids by construction.

### Step 2b — Verify the agent's QGR receipt

```
(cd _land-<branch> && diff-hash --base origin/<default> --json)
find agency/workstreams -name "*qgr-pr-prep-*-{hash}.md"
receipt-verify --file <receipt>
```

**Ordering is load-bearing.** The version bump in Step 4 edits `agency/config/manifest.json`, which is inside `diff-hash`'s file set. Verifying *after* the bump would invalidate the very receipt being checked and ask the agent to re-prep for a change the captain made — the #463 trap.

The receipt's `hash_e` is captured here; it becomes `hash_a` of the landing receipt.

**Failure:** delete the scratch, exit 1, tell the agent to re-run `/pr-prep`.

### Step 3 — VALIDATE LOCALLY

This is the gate. GitHub is not the gate.

Resolution ladder, all run inside the scratch:

1. `PR_LAND_VALIDATE_CMD` if set — replaces everything below.
2. `<pm> run build`, if `package.json` declares a `build` script.
3. `<pm> run bats:all`, else `<pm> run test` — the widest declared suite.
4. `agency/tools/commit-precheck`.

The package manager is resolved by `agency/tools/pkg-manager`, which picks one from the lockfile and only returns it if that manager is installed. Skills never name a package manager inline — adopter repos differ.

Every step's output is appended to a validation log; the log's SHA-256 becomes `hash_b` of the landing receipt, so the receipt binds to *what was actually run*.

| Outcome | Action |
|---|---|
| All steps pass | proceed |
| Any step fails | tail the log, **dispatch the agent** naming the failing step, delete the scratch, exit 1 |
| No step resolved | loud WARNING, recorded in the receipt summary — never a silent pass |

`--rehearse` and `--dry-run` stop here, delete the scratch, and exit 0.

### Step 4 — Bump `agency_version` in the scratch

Read `agency/config/manifest.json`, bump the minor component, refresh `updated_at`, `git-safe add`, `git-safe-commit`.

**Security:** the bump uses Python **env-var** substitution, never f-string interpolation into python source (MAR F-SEC-1 / CRITICAL-3). Prevents code injection if the manifest were ever attacker-controllable.

### Step 5 — Sign the captain LANDING receipt

`pr-create` is not bypassed and not weakened. The captain signs a receipt for the state it validated:

```
receipt-sign --type qgr --boundary pr-captain-land \
  --agent captain --workstream agency --project <branch-slug> \
  --hash-a <agent receipt hash_e> \
  --hash-b <sha256 of the validation log> \
  --hash-c <= B>  --hash-d <= C>  \
  --hash-e <diff hash of the bumped tree vs origin/<default>> \
  --diff-base origin/<default>
```

A = what was reviewed (chains to the agent's receipt). B = what was validated. C = B (nothing to triage — validation was green). D = C (auto-approved, no principal 1B1). E = what is being published.

The receipt is then committed. Receipts are excluded from `diff-hash`, so committing one does not invalidate the hash it carries.

### Step 6 — Publish

```
(cd _land-<branch> && git-push _land-<branch>)
(cd _land-<branch> && pr-create --title ... --body ... --base <default>)
```

`pr-create` re-derives the newest receipt (the landing receipt) and re-verifies it, and independently confirms `manifest.json` differs from `origin/<default>`. Both gates pass on their own terms.

**This is the first irreversible action.** Past this point `abort_land` is no longer correct — work exists on origin. Failures report, name the pushed branch, and leave the scratch in place for inspection.

### Step 7 — CI confirmation on the aggregate rollup

```
gh pr view <num> --json statusCheckRollup
```

Where branch protection exposes `/repos/{org}/{repo}/branches/{default}/protection/required_status_checks/contexts`, the rollup is narrowed to those contexts. Otherwise every check in the rollup is treated as required.

State normalization handles both node shapes: `CheckRun` (`status` + `conclusion`) and `StatusContext` (`state`).

| Verdict | Action |
|---|---|
| every check terminal in {SUCCESS, NEUTRAL, SKIPPED} | proceed |
| any check in {FAILURE, ERROR, TIMED_OUT, CANCELLED, ACTION_REQUIRED, STARTUP_FAILURE, STALE} | exit 1 immediately, naming the checks |
| any check pending | wait 20s, poll again |
| rollup empty after filtering | exit 1 with a **distinct** error |
| gh output unreadable | treat as transient, retry |

Max 45 attempts × 20s = 15 minutes.

**Why the empty-rollup case is its own error:** "no checks configured" and "all checks green" must never be indistinguishable. A rollup gate that silently passes an unchecked PR is worse than the hardcode it replaced.

**Why the hardcode was wrong:** v1 gated on a check literally named `lint-and-test`. This repo's checks are `bash 3.2 probe`, `manifest version`, and `smoke`. The loop could only ever time out — and a genuinely failing check could never fail fast. `src/tests/skills/pr-captain-land-localfirst.bats` asserts that literal never comes back.

### Step 8 — Merge + release

```
./agency/tools/pr-merge <num> --principal-approved --delete-branch
./agency/tools/gh-release create v<new> --target <default> --title ... --notes ...
```

True merge commit — never squash, never rebase.

### Step 9 — Cleanup, notify, reconcile

1. `worktree-delete _land-<branch> --force` + `git-captain branch-delete _land-<branch> --force`. (The remote copy was deleted by `pr-merge --delete-branch`; this is *not* retried with `git-push`, which has no delete mode and would re-push the branch.)
2. `dispatch create --type master-updated` to the agent.
3. `post-merge-state clear <num>`.
4. `git-captain merge-from-origin` — reconcile local main with the server merge.

Step 4 is deliberately separate and idempotent: it is exactly what `/captain-sync-all` does, so running either afterwards is a no-op rather than a double-integration.

---

## Recovery flows

### Local validation failed

Nothing was published. The scratch is gone. The agent has a dispatch naming the failing step. Agent fixes, re-preps, pushes, re-submits. The captain does nothing else.

This replaces v1's "version-bump landed but CI failed" recovery entirely — there is no orphan bump commit on the agent's branch to clean up, because the bump never touched the agent's branch.

### Receipt invalidated between `/pr-submit` and `/pr-captain-land`

A captain coord commit lands on the default branch, moving `origin/<default>`. Detected at **Step 1** as a stale base — with the correct message — rather than surfacing later as a bare hash mismatch. Agent merges the default branch, re-runs `/pr-prep`, re-submits.

### Leftover `_land-` worktree from a crashed run

Step 0 refuses to start and names the path. Inspect it (it may contain a useful validation log or an unpushed bump), then:

```
./agency/tools/worktree-delete _land-<branch> --force
./agency/tools/git-captain branch-delete _land-<branch> --force
```

The script never auto-deletes a pre-existing scratch — that could be another land in flight.

### `pr-create` returned no URL

The land branch **is** pushed. The scratch is kept. Either finish manually (`pr-create` from the scratch, then `/pr-captain-merge`), or abandon: delete the remote branch, then the scratch.

### CI red after a green local gate

Genuinely interesting — the local gate and the server disagree. Do not re-land until you know why. Usual causes: a check that only exists on the server (secrets, permissions, matrix OS), or a local validation ladder that resolved nothing (check for the WARNING in the run output and in the landing receipt summary).

### Merge fails after green CI

Branch-protection edge case. `/pr-captain-merge <num> --principal-approved`.

## Rehearsal

```
/pr-captain-land <agent-branch> --rehearse
```

Runs steps 0-3 and deletes the scratch. No push, no PR, no bump, no receipt, no release, no dispatch. This is the cheap way to answer "would this branch actually land?" and the recommended first action on any branch class you have not landed before.

`--dry-run` is `--rehearse` plus a printout of what would have been published.

## Concurrency

**One `/pr-captain-land` at a time.** Two concurrent runs would race on the version bump. Two runs *for the same branch* are now blocked mechanically by the leftover-scratch precondition; two runs for *different* branches are still captain discipline. No lockfile yet.

Concurrency against the captain's own work is much safer than in v1: the land no longer requires a clean main checkout and never moves local main, so captain coord work can proceed alongside it.

## Protocol versioning

- **v1.0** — Phase 1 pilot (the-agency#296). PR-first; switch-checkout; hardcoded `lint-and-test` CI gate.
- **v2.0** — local-first. Scratch-worktree integration, local validation gate, captain landing receipt, aggregate CI rollup gate, `--rehearse`, shared `resolve-default-branch` primitive. Per `usr/{principal}/captain/plans/plan-pr-captain-land-localfirst-20260809.md`, MAR-reviewed.
- **v2.1 (planned)** — parse the full `/pr-submit` dispatch payload so the agent's scope text becomes the PR body core.
- **v2.2 (planned)** — dispatch-monitor auto-invocation.
