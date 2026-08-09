---
name: pr-captain-land
description: Captain-only. Land an agent's prepared branch LOCAL-FIRST — integrate and validate in a scratch worktree cut from origin/<default>, then bump agency_version, sign a landing receipt, open the PR, confirm CI, merge, release, notify. The single-writer serialization point for agency_version and PR creation. Companion to /pr-submit. The `captain-` qualifier in the name signals scope at a glance (complements `paths: []` scoping and the Step-0 runtime precondition).
agency-skill-version: 2
when_to_use: Captain on master in main checkout, after a /pr-submit dispatch from an agent. NEVER from a worktree. Intended for explicit captain invocation — the Step-0 runtime precondition refuses from wrong context.
argument-hint: "<agent-branch> [--rehearse] [--dry-run] [--title \"...\"] [--agent <name>] [--no-release] [--principal-approved] [--allow-unvalidated]"
paths: []
required_reading:
  - agency/REFERENCE-CODE-REVIEW-LIFECYCLE.md
  - agency/REFERENCE-RECEIPT-INFRASTRUCTURE.md
  - agency/REFERENCE-GIT-MERGE-NOT-REBASE.md
  - agency/REFERENCE-SAFE-TOOLS.md
---

<!--
  allowed-tools intentionally omitted — inherits Bash(*) from
  .claude/settings.json. Subcommand-level restriction silently blocked
  fleet agents (flag #62/#63; devex dispatch #171). This skill composes
  git-safe, git-captain, git-push, git-safe-commit, worktree-create,
  worktree-delete, pr-create, pr-merge, gh-release, dispatch, diff-hash,
  receipt-sign, receipt-verify, resolve-default-branch, and gh — tool-level
  narrow restriction would work but needs maintenance. Inherit Bash(*).
  Defense in depth is layered via paths: [] + captain- name + runtime
  precondition (see "Captain-only — three-layer defense" below).
-->

# pr-captain-land

Captain-side skill that lands an agent's prepared branch as a merged PR + GitHub release + fleet notification. Companion to `/pr-submit`. The single-writer serialization point for `agency_version` and PR creation.

**v2 is LOCAL-FIRST.** The work is integrated and validated locally *before* a PR exists. GitHub is the publish step for already-validated work, not the reviewer.

## The inversion

The v1 flow was PR-first: switch the main checkout to the agent's branch, bump, push, open a PR, and let GitHub CI decide. Three structural problems:

1. **Worktree collision.** Switching the main checkout to a branch the agent still has checked out in its own worktree fails outright. And switching at all makes the captain's checkout a moving target mid-land.
2. **The wrong gate.** CI was the first thing that could say no. TheAgency's model is local review and validation.
3. **No clean abort.** Any mid-flight failure left the main checkout parked on someone else's branch.

v2 does not fix the rollback — it removes the thing that needed rolling back:

> **The entire landing happens in a dedicated scratch worktree cut from `origin/<agent-branch>`. Local `main` is never read for content, never merged into, never reset, and never pushed. Rollback at any pre-publish failure is one action: delete the scratch worktree.**

Validating against pristine `origin/<default>` is also strictly more correct than validating on the captain's local main, which routinely carries unpushed coordination commits and other worktrees' merges — none of which belong in the PR under test.

### Invariants

| Invariant | Why |
|---|---|
| The agent's branch is **never checked out** in the main checkout | Kills the worktree-collision bug by construction |
| **`main`/`master` is never pushed** | All changes reach the default branch through a PR |
| Local `main` is only ever moved by the final, idempotent `merge-from-origin` | No data-loss hazard, no double-integration with `/captain-sync-all` |
| The agent's receipt is verified **before** the version bump | The bump edits `manifest.json`, which is inside the hashed file set (the #463 churn trap) |
| `pr-create` is **not** weakened | Captain signs its own landing receipt instead |

## Why this exists

Per the-agency#296 — one captain, one writer, one serialization point. Pre-v2 distributed PR ownership produced version-bump races (two agents bump `agency_version` concurrently), receipt-hash races (a captain coord commit lands between an agent's `/pr-prep` and its `/pr-create`), and one-line PR bodies that fleet reviewers could not triage.

## Required reading

Before running, Read the files listed in `required_reading:` frontmatter.

- `REFERENCE-CODE-REVIEW-LIFECYCLE.md` — end-to-end PR flow
- `REFERENCE-RECEIPT-INFRASTRUCTURE.md` — five-hash chain, landing-receipt semantics
- `REFERENCE-GIT-MERGE-NOT-REBASE.md` — merge discipline
- `REFERENCE-SAFE-TOOLS.md` — the safe-tool family this skill composes

`reference.md` is the step-by-step protocol with failure-mode recovery. `examples.md` has worked runs.

## Usage

```
/pr-captain-land <agent-branch>
/pr-captain-land <agent-branch> --rehearse
/pr-captain-land <agent-branch> --dry-run
/pr-captain-land <agent-branch> --title "Custom PR title"
/pr-captain-land <agent-branch> --agent devex
/pr-captain-land <agent-branch> --no-release
```

- `<agent-branch>`: **required.** The branch `/pr-submit` identified.
- `--rehearse`: run **steps 0-3 only** — integrate + validate, then delete the scratch. Nothing pushed, no PR, no bump, no receipt. **Rehearse first on any branch you have not landed before.**
- `--dry-run`: `--rehearse` plus a printout of exactly what would be published.
- `--title`: override the PR title (defaults to the branch name).
- `--agent`: who to dispatch (defaults to the branch-name prefix).
- `--no-release`: skip the GitHub release after merge (rare).
- `--principal-approved`: forward `--admin` to `pr-merge`, bypassing branch protection. **Pass only when the principal actually said so.** Without it the merge defers to GitHub's own gates. It is also recorded in the landing receipt's `hash_d_source`.
- `--allow-unvalidated`: land even when no local validation command resolves. Without it that case **aborts** (see Step 3). Recorded verbatim in the receipt.

Environment:

- `PR_LAND_VALIDATE_CMD` — replace the local validation ladder wholesale, for repos whose gate is not a package build/test script. Run with `bash -c` inside the scratch worktree.

## Preconditions

Enforced before any mutation; failure exits non-zero with no state change.

1. Running in the **main checkout** (first entry of `git worktree list`).
2. No leftover scratch worktree **or branch** named `_land-<branch>` (a previous land crashed — inspect, then `worktree-delete` + `git-captain branch-delete`).
3. No pending post-merge state (C#372 Fix B) — a prior merge whose release was never cut must be finished first.
4. `git-captain fetch` succeeds. **This is fatal, not best-effort**: every guarantee below assumes origin refs are current.
5. `<agent-branch>` exists on origin.
6. `<agent-branch>` passes safe-name validation: `^[a-zA-Z0-9][a-zA-Z0-9/_.-]*$`, no `..`, no leading `-`.
7. `origin/<default>` is an **ancestor** of `origin/<agent-branch>` — the base is current.

**A dirty main checkout no longer blocks a land (#393).** The landing never touches local main, so uncommitted captain work is irrelevant. The script notes it and continues. (One caveat: the Step-9 reconcile is a `merge-from-origin`, which does require a clean tree — a dirty checkout means that last step is skipped with a note, and `/captain-sync-all` picks it up later.)

**Which branch the main checkout is on is also not load-bearing** — that was v1 coupling. The script notes it and continues.

## Flow / Steps

Script: `scripts/pr-captain-land`.

### Step 0 — Preflight

Main-checkout check, leftover-scratch check (directory **and** branch), pending-post-merge check, and a **fatal** `git-captain fetch`. The default branch is resolved via the shared `agency/tools/resolve-default-branch` primitive, which probes `origin/HEAD` first — a stale local `main` must never outvote the remote's own answer, because every consumer turns the result into `origin/<name>`. **Local main is not read or written.**

### Step 1 — Verify the branch and its base

Branch must exist on origin. Then:

```
git merge-base --is-ancestor origin/<default> origin/<agent-branch>
```

If the base has moved, the agent's receipt was signed against an older base and *can never* verify. That is BLOCKED with the real cause and the real fix — "merge `<default>` into your branch, re-run `/pr-prep`, push, re-run `/pr-submit`" — never a bare hash-mismatch error.

### Step 2 — Cut the scratch worktree

```
./agency/tools/worktree-create _land-<branch> --from origin/<agent-branch>
```

This **is** the local integration: step 1 proved `origin/<default>` is an ancestor, so the scratch tree already represents the agent's work on top of the default branch. Slashes in the branch name collapse to dashes in the scratch name.

### Step 2b — Verify the agent's QGR receipt

`diff-hash --base origin/<default>` inside the scratch, find `agency/workstreams/**/qgr/*qgr-pr-prep-*-{hash}.md`, and `receipt-verify --file` it. **Before any mutation** — verifying after the bump would churn the receipt (#463).

Failure → delete the scratch, tell the agent to re-run `/pr-prep`.

### Step 3 — VALIDATE LOCALLY. This is the gate.

In the scratch, in order: build script, then the widest declared test script (`bats:all`, else `test`). The package manager comes from `agency/tools/pkg-manager`. `PR_LAND_VALIDATE_CMD` replaces all of it.

Each step runs with the captain's credentials scrubbed from the environment (`GH_TOKEN`, `GITHUB_TOKEN`, `SSH_AUTH_SOCK`, …). The command comes from the branch under review and its output is tailed to stderr on failure, so a `build` script of `gh auth token` must not be able to put the PAT into the transcript. This is defence in depth, not a sandbox — validating a branch locally means running its code.

- **Failure → delete the scratch, dispatch the agent naming the failing step, exit 1.** Nothing was published.
- **No resolvable validation command → ABORT.** A landing with no local gate is the old PR-first flow with extra steps, and it would sign a five-hash receipt attesting to a gate that never ran. Override with `--allow-unvalidated`, which is recorded in the receipt.

`commit-precheck` is deliberately **not** in this ladder: it gates on staged files and the scratch tree is clean here, so it would exit 0 having inspected nothing while still counting as a step. It runs where it means something — `git-safe-commit` invokes it on the Step-4 and Step-5 commits.

`--rehearse` / `--dry-run` stop here and delete the scratch.

### Step 4 — Bump `agency_version` in the scratch

Read `agency/config/manifest.json`, bump minor, refresh `updated_at`, commit via `git-safe-commit`.

**Security note:** the bump uses Python env-var substitution (`MANIFEST=... NEW_VER=... python3 -c '...os.environ[...]...'`), never f-string interpolation. Blocks code injection via adversarial branch names (MAR F-SEC-1 / CRITICAL-3, landed `ccf054ad`).

### Step 5 — Sign the captain LANDING receipt

`pr-create` is not bypassed or weakened. Instead the captain signs a receipt for the state it actually validated, extending the agent's chain:

| Hash | Value |
|---|---|
| A | the agent receipt's `hash_e` (what was reviewed) |
| B | hash of the local validation log |
| C | B — nothing to triage, validation was green |
| D | C. `hash_d_source` records the truth: `auto-approved — no principal 1B1`, or the `--principal-approved` attestation when that flag was passed |
| E | diff hash of the bumped tree vs `origin/<default>` |

Written to `agency/workstreams/agency/qgr/` with boundary `pr-captain-land`, then committed. Receipts are excluded from `diff-hash`, so committing one does not invalidate the hash it carries.

### Step 6 — Publish

Push `_land-<branch>` from the scratch, then `pr-create --base <default>`. The landing receipt is the newest receipt, so `pr-create`'s receipt gate and version-bump gate both pass on their own terms.

**This is the first irreversible action.** Past here, failures report and leave the scratch in place for inspection rather than rolling back.

### Step 7 — CI confirmation on the aggregate rollup

Poll `gh pr view <num> --json statusCheckRollup` every 20s, up to 15 minutes. Classification is `agency/tools/ci-rollup-verdict` — a pure function of (rollup, required contexts), table-tested in `src/tests/tools/ci-rollup-verdict.bats`.

| Rollup state | Action |
|---|---|
| every gated check terminal and SUCCESS / NEUTRAL / SKIPPED | proceed |
| any terminal failure (FAILURE, ERROR, TIMED_OUT, CANCELLED, …) | exit 1, fail fast, name the checks |
| any gated check still pending | wait 20s, poll again |
| a **required** context that has not reported at all | PENDING — 1-of-3 required checks green must not read as green |
| **rollup empty**, past a 3-minute grace window | exit 1 with a **distinct** error — "no checks configured" must never look like "all green" |

The grace window matters: GitHub has usually registered no check runs in the first seconds after a PR opens, so treating an empty rollup as immediately fatal would abort nearly every real land.

v1 hardcoded a check named `lint-and-test` that does not exist in this repo, so the loop could only ever time out. The gate is now name-agnostic, and a regression test asserts that literal never returns.

### Step 8 — Merge + release

```
./agency/tools/pr-merge <num> [--principal-approved] --delete-branch
./agency/tools/gh-release create v<new> --target <default> ...
```

True merge commit — never squash, never rebase. `--principal-approved` is forwarded **only** when the captain passed it; by default the merge defers to branch protection. Both the merge and the release capture their output and print it on failure.

If no release was cut (`--no-release`, or `gh-release` failed), the pending post-merge state is deliberately **left set** — that guard exists precisely for "merged but release not cut".

### Step 9 — Cleanup, notify, reconcile

Delete the scratch worktree and the local land branch; dispatch `master-updated` to the agent; `post-merge-state clear`; then reconcile local main with `git-captain merge-from-origin`.

The reconciliation is a **separate, idempotent** step on purpose: it is the same fast-forward `/captain-sync-all` performs, so running either afterwards is a no-op rather than a double-integration.

## Failure modes

| Where | What happens |
|---|---|
| Preflight (0) | Exit 1, zero mutation. |
| Fetch fails (0) | Exit 1. Stale origin refs would make every downstream check meaningless. |
| Pending post-merge (0) | Exit 1. Finish the prior release with `/pr-captain-post-merge` first. |
| Leftover scratch or land branch (0) | Exit 1 naming the path and the cleanup commands. Never auto-deletes someone else's in-flight land — cleanup only touches a scratch this run created. |
| No local gate resolves (3) | **Abort**, unless `--allow-unvalidated`. |
| Any `set -e` abort before publish | An EXIT trap deletes the scratch, so an unhandled error cannot strand it and wedge the next land. |
| Stale base (1) | BLOCK naming the real cause; agent merges default + re-preps. |
| Receipt missing/invalid (2b) | Scratch deleted; agent re-runs `/pr-prep`. |
| Local validation fails (3) | Scratch deleted, agent dispatched with the failing step. **Nothing published.** |
| Bump or receipt-sign fails (4-5) | Scratch deleted. Nothing published. |
| `pr-create` returns no URL (6) | Scratch **kept** for inspection; the land branch is pushed and must be cleaned up manually if abandoned. |
| CI fails (7) | Exit 1. The local gate passed and the server disagreed — investigate before re-landing. |
| CI timeout (7) | Exit 1 with the last verdict; check manually. |
| Empty rollup (7) | Exit 1, distinct message. Merge via `/pr-captain-merge` if that is genuinely expected. |
| Merge fails (8) | Fall back to `/pr-captain-merge <num> --principal-approved`. |
| Release fails (8) | Warn — check whether auto-release already cut the tag. Merge is the primary outcome. |
| Dispatch fails (9) | Warn only. Merge + release are the authoritative record. |

## What this does NOT do

- **Does not write code.** The agent's branch is the substance.
- **Does not modify the agent's branch.** The version bump and landing receipt go on the `_land-` branch; `<agent-branch>` is never checked out or pushed.
- **Does not squash or rebase.**
- **Does not touch local `main`** until the final reconcile.
- **Does not auto-retry.**
- **Does not fire from an agent context.**

## Captain-only — three-layer defense

1. **`paths: []`** — no file-path auto-activation. (Contrast `pr-submit`, which has `paths: [.claude/worktrees/**]`.)
2. **Name contains `captain-`** — scope visible in the skill list.
3. **Runtime precondition** — Step 0 refuses unless in the main checkout on the default branch.

(Historically `disable-model-invocation: true` was a fourth layer, removed 2026-04-20: the captain session IS the principal's session, and DMI blocked the captain from invoking captain-* skills. See `REFERENCE-SKILL-CONVENTIONS.md` §1.)

## Status

`active` — v2 local-first, per `usr/{principal}/captain/plans/plan-pr-captain-land-localfirst-20260809.md` (MAR-reviewed). Invariants pinned by `src/tests/skills/pr-captain-land-localfirst.bats`; the v1 master-hardcode guards remain in `src/tests/skills/pr-captain-land-helpers.bats`.

**Rehearse before the first land of any branch.** `--rehearse` exercises steps 0-3 with zero side effects.

## Related

- `/pr-submit` — agent-side companion; this skill consumes its dispatch
- `/pr-captain-merge` — the merge primitive used at Step 8
- `/pr-prep` — the QG that signs the receipt verified at Step 2b
- `/pr-captain-post-merge` — post-merge tasks when a landing was done manually
- `/captain-sync-all` — the daily integration rhythm; idempotent with Step 9
- `agency/tools/resolve-default-branch` — the shared default-branch primitive (v2)
- `agency/tools/pkg-manager` — resolves the package manager for the validation ladder (v2)
- `agency/tools/ci-rollup-verdict` — the CI gate's classification, extracted and table-tested (v2)
- `agency/tools/agency-version-next` — the `agency_version` bump policy (v2)
- `agency/tools/worktree-create --from <ref>` — how the scratch is cut (v2)
- `agency/tools/pr-create`, `pr-merge`, `gh-release`, `dispatch`, `diff-hash`, `receipt-sign`, `receipt-verify`
- `reference.md` — full protocol + recovery flows
- `examples.md` — happy path, rehearsal, and failure-mode runs
- the-agency#296 — PR lifecycle ownership design
- the-agency#393 — session-end dirty handoff (largely mooted by scratch isolation)
- the-agency#463 — receipt churn from verifying after the bump

*OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*
