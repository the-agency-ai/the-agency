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
| 1 | `pwd` is the main checkout (first `git worktree list --porcelain` entry) | exit 1 naming both paths |
| 2 | No existing `.claude/worktrees/_land-<branch>` | exit 1 naming the path + the cleanup commands |
| 3 | No existing `refs/heads/_land-<branch>` | exit 1 — a crash between `worktree add -b` and `worktree remove` leaves only the branch, and `worktree-create` then refuses on every retry with no visible reason |
| 4 | `post-merge-state check` is clean (C#372 Fix B) | exit 1 — finish the prior release first |
| 5 | `git-captain fetch` succeeds | exit 1 — **fatal, not best-effort** |
| 6 | `<agent-branch>` exists on origin | exit 1 |
| 7 | Branch name matches `^[a-zA-Z0-9][a-zA-Z0-9/_.-]*$`, no `..`, no leading `-` | exit 2 |
| 8 | `origin/<default>` is an ancestor of `origin/<agent-branch>` | BLOCK — see Step 1 |

**A dirty main checkout is NOT a precondition failure (#393).** The land never reads, commits to, or moves local main. The script notes the dirt and continues. The Step-9 reconcile does need a clean tree, so on a dirty checkout that last fast-forward is skipped with a note and `/captain-sync-all` picks it up.

**Which branch the main checkout is on is also not a precondition.** v1 required the default branch; v2 does not read it, so requiring it only blocked lands while the captain was mid-`/captain-release` on a `captain-*` branch.

The default branch is resolved by `agency/tools/resolve-default-branch` — one shared primitive, never a hardcode. Its probe order is **remote-authoritative**: `origin/HEAD` → `refs/remotes/origin/{main,master}` → local `refs/heads/{main,master}`. Local branches are the offline fallback only. Probing them first (git-captain's historical order) reintroduces issue #107 — a stale local `main` in a `master`-default clone would make every consumer build `origin/main`, a ref that does not exist.

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

The slug collapses **both** slashes and dots (`fix/v1.2` → `_land-fix-v1-2`): `worktree-create` validates against `^[a-zA-Z_][a-zA-Z0-9_-]*$`, while the branch-name gate deliberately permits dots. Slugging only slashes made every dotted branch unlandable.

`worktree-create`'s stderr is **not** discarded on the failure path. Swallowing it turned every distinct cause — invalid name, existing branch, disk full — into one opaque "could not create scratch worktree".

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

The package manager is resolved by `agency/tools/pkg-manager` — `packageManager` field, else lockfile, else npm — and it fails rather than substituting npm for a declared-but-uninstalled manager. Skills never name a package manager inline; adopter repos differ.

**`commit-precheck` is deliberately not in this ladder.** It gates on *staged* files and the scratch tree is clean here, so it exits 0 having inspected nothing — while still counting as a step. That inflated the step count, suppressed the no-validation abort below, and wrote "N local validation step(s) passed" into a signed receipt on the strength of a no-op. It still runs where it means something: `git-safe-commit` invokes it on the Step-4 and Step-5 commits.

Each step runs with the captain's credentials removed from the environment (`GH_TOKEN`, `GITHUB_TOKEN`, `GH_ENTERPRISE_TOKEN`, `GIT_ASKPASS`, `SSH_AUTH_SOCK`; `GIT_TERMINAL_PROMPT=0`). The command comes from the branch under review, and on failure its output is tailed to stderr — i.e. into the session transcript. Defence in depth, not a sandbox: validating a branch locally means executing its code as the captain's user, which is inherent to the design.

Every step's output is appended to a validation log (mode 0600, removed by the EXIT trap); the log's SHA-256 becomes `hash_b` of the landing receipt, so the receipt binds to *what was actually run*.

| Outcome | Action |
|---|---|
| All steps pass | proceed |
| Any step fails | tail the log, **dispatch the agent** naming the failing step, delete the scratch, exit 1 |
| No step resolved | **ABORT.** Signing a five-hash receipt for a gate that never ran would make the receipt a lie. `--allow-unvalidated` overrides, and is recorded verbatim in the receipt summary. |

`--rehearse` and `--dry-run` stop here, delete the scratch, and exit 0.

### Step 4 — Bump `agency_version` in the scratch

Read `agency/config/manifest.json`, bump the minor component, refresh `updated_at`, `git-safe add`, `git-safe-commit`.

The bump policy itself lives in `agency/tools/agency-version-next` (`46.25 → 46.26`; three-component semver is refused, not guessed). Inline, it was `NEW_VER=$(python3 -c '... sys.exit(1)')`, which under `set -euo pipefail` killed the *caller* before its own error could run — so the friendly "could not bump version" message was unreachable for exactly the input it was written for, and the scratch worktree was stranded.

**Security:** the manifest write uses Python **env-var** substitution, never f-string interpolation into python source (MAR F-SEC-1 / CRITICAL-3). Prevents code injection if the manifest were ever attacker-controllable. It also writes a trailing newline (`json.dump` does not), so a land no longer adds a spurious "\ No newline at end of file" hunk, and refreshes both the nested and top-level `updated_at`.

### Step 5 — Sign the captain LANDING receipt

`pr-create` is not bypassed and not weakened. The captain signs a receipt for the state it validated:

```
receipt-sign --type qgr --boundary pr-captain-land \
  --agent captain --workstream agency --project <branch-slug> \
  --hash-a <agent receipt hash_e> \
  --hash-b <sha256 of the validation log> \
  --hash-c <= B>  --hash-d <= C>  \
  --hash-d-source <"auto-approved — no principal 1B1" | the --principal-approved attestation> \
  --hash-e <diff hash of the bumped tree vs origin/<default>> \
  --diff-base origin/<default>
```

A = what was reviewed (chains to the agent's receipt). B = what was validated. C = B (nothing to triage — validation was green). D = C, with `hash_d_source` recording whether a principal actually approved — the receipt must not attest to an approval that did not happen. E = what is being published.

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

Classification is **not** inline. It lives in `agency/tools/ci-rollup-verdict`, a pure function of (rollup JSON, required contexts) that prints one verdict token — table-tested in `src/tests/tools/ci-rollup-verdict.bats`. Inline it was a python heredoc inside a command substitution inside the polling loop, which no test could reach: every guard written for it was a `grep` for a string, and all of them still passed with the PASS and FAIL state sets swapped.

Where branch protection exposes `/repos/{org}/{repo}/branches/{default}/protection/required_status_checks/contexts`, the rollup is narrowed to those contexts. Anything that is not a non-empty JSON array (the endpoint returns an error *object* on unprotected repos and without admin scope) means no narrowing.

State normalization handles both node shapes: `CheckRun` (`status` + `conclusion` — the conclusion is meaningless until the status is COMPLETED) and `StatusContext` (`state`).

| Verdict | Action |
|---|---|
| every gated check terminal in {SUCCESS, NEUTRAL, SKIPPED} | proceed |
| any check in {FAILURE, ERROR, TIMED_OUT, CANCELLED, ACTION_REQUIRED, STARTUP_FAILURE, STALE} | exit 1 immediately, naming the checks |
| any gated check pending | wait 20s, poll again |
| a **required** context absent from the rollup | PENDING, not absent |
| rollup empty, past the 3-minute grace window | exit 1 with a **distinct** error |
| gh output unreadable | treat as transient, retry |

Max 45 attempts × 20s = 15 minutes.

**Why a required context that has not reported is PENDING:** narrowing to "required contexts that happen to be present" means 1-of-3 required checks reporting green reads as PASSED, and the PR merges on partial evidence.

**Why the empty-rollup case has a grace window:** GitHub has usually registered no check runs in the first seconds after a PR opens. Treating that as immediately fatal would abort nearly every real land. Past the window it is a hard error — "no checks configured" and "all checks green" must never be indistinguishable.

**Name-mismatch caveat:** branch-protection contexts are often `"workflow / job"` while check runs are named just `job`. When they do not match, the gate reports PENDING and eventually times out rather than merging — the safe direction, but worth knowing when a green PR appears to hang.

**Why the hardcode was wrong:** v1 gated on a check literally named `lint-and-test`. This repo's checks are `bash 3.2 probe`, `manifest version`, and `smoke`. The loop could only ever time out — and a genuinely failing check could never fail fast. `src/tests/skills/pr-captain-land-localfirst.bats` asserts that literal never comes back.

### Step 8 — Merge + release

```
./agency/tools/pr-merge <num> [--principal-approved] --delete-branch
./agency/tools/gh-release create v<new> --target <default> --title ... --notes ...
```

True merge commit — never squash, never rebase.

`--principal-approved` is forwarded **only** when the captain passed it to `/pr-captain-land`. `pr-merge` treats that flag as the captain's attestation that the principal verbally approved, and it is the only route to `gh pr merge --admin`; asserting it unconditionally in a non-interactive script would make branch-protection bypass the fleet's default merge mode. Default behaviour is to defer to GitHub's gates, and the failure message says to re-run with the flag if protection is the blocker.

Both calls capture their output and print the tail on failure. Silencing them at the two most consequential steps left "pr-merge failed — check manually" with nothing to check.

### Step 9 — Cleanup, notify, reconcile

1. `worktree-delete _land-<branch> --force` + `git-captain branch-delete _land-<branch> --force`. (The remote copy was deleted by `pr-merge --delete-branch`; this is *not* retried with `git-push`, which has no delete mode and would re-push the branch.)
2. `dispatch create --type master-updated` to the agent. The recipient is resolved against the agent registry, not guessed from the branch prefix — `pr-lifecycle-v2` would otherwise yield `pr`, and the dispatch (best-effort by design) would vanish. An unresolvable name routes to captain with a note.
3. `post-merge-state clear <num>` — **only if a release was actually cut.** Clearing it after `--no-release` or a failed `gh-release` discards exactly the "merged but release not cut" signal the guard exists to carry.
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
