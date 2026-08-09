# Plan — Re-orient `pr-captain-land` to local-first + converge default-branch primitive

**Author:** captain · **Date:** 2026-08-09 · **Status:** v2 — POST-MAR (revised design below supersedes the original flow)

---

## v2 — Post-MAR revised design (SUPERSEDES the flow further down)

Four MAR reviewers converged on one root fix and several must-fixes. Key change: **the land never touches local `main`.**

### The root fix: integrate + validate on a scratch worktree cut from `origin/<default>`, not on local `main`

Local `main` carries unpushed captain coord commits (currently 2 ahead) and `captain-sync-all` merges other worktrees' work into it without pushing. So cutting the publish branch at local-main's tip pollutes the PR and there's a data-loss/concurrency hazard if a land mutates `main`. Instead:

- The whole land runs in a **dedicated scratch worktree** (`worktree-create _land-<branch>` off `origin/<default>`). Local `main` and the main checkout are never touched.
- **Rollback at any pre-publish failure = delete the scratch worktree.** No `git reset --hard`, no new unsafe primitive, no `captain-sync-all` double-integration, no interrupt-strands-main. This dissolves ~half the MAR findings at once.
- "Local-first" is preserved and *strengthened*: we validate the branch integrated against **pristine `origin/<default>`**, not captain's coord-polluted local main.

### Revised flow — `pr-captain-land <agent-branch>`

| Step | Action |
|---|---|
| 0 | Preflight: captain in main checkout; `git-captain fetch` (origin refs current); resolve default branch via new primitive. **Does not read/write local main.** |
| 1 | Verify agent branch on origin; verify QGR receipt matches `origin/<agent-branch>` diff vs `origin/<default>` (if main moved under it → BLOCK with "merge main + re-run /pr-prep", not a bare hash error). |
| 2 | `worktree-create _land-<branch>` at `origin/<agent-branch>` (which, per the step-1 receipt gate, already contains `origin/<default>`). This scratch IS the local integration. |
| 3 | **Validate locally** in the scratch: build + tests + commit-precheck on the integrated tree. **On failure → delete scratch, abort, dispatch agent.** |
| 4 | Bump `agency_version` in the scratch; commit. |
| 5 | **Sign a captain LANDING receipt** binding the scratch's diff vs `origin/<default>` (`hash_a` = agent receipt's `hash_e`, `hash_d` auto). This is what lets `pr-create` pass — do NOT weaken `pr-create`. |
| 6 | Publish from the scratch: `git-push _land-<branch>` → `pr-create` (receipt matches, version bumped) → PR (`_land-<branch>` → default). |
| 7 | **CI wait on the aggregate `statusCheckRollup`** (all required contexts green; fail-fast on FAILURE; "no required checks found" = distinct error). NOT hardcoded `lint-and-test`. |
| 8 | `pr-merge` (true merge) → `gh-release` (or verify Fix D). |
| 9 | Cleanup: delete `_land-<branch>` (scratch worktree + local + remote branch); dispatch `master-updated` to agent; `post-merge-state clear`. Reconcile local main separately/idempotently via `merge-from-origin` (local main FFs to the server merge). |

### Must-fixes folded in (from MAR)

- **Shared primitive = superset with `--strict`.** The 3 resolvers encode *different* policies: `git-captain` checks local refs first and `die`s if unresolved; `pr-create` fails loud; `pr-submit` falls back silently. The new `resolve-default-branch` must be the **union** (local refs → origin/HEAD → origin/{main,master}) with a `--strict` mode (nonzero on unresolved) so `git-captain`/`pr-create` keep fail-closed. Default mode keeps a `main` fallback (deliberate, tested).
- **Scope the resolver convergence honestly.** There are **7** copies (also `_sync-main-ref` [hardcodes origin/main], `dispatch`, `pr-build`, `worktree-sync`). This pass converges **git-captain, pr-create, pr-submit, _sync-main-ref**; the other three are explicitly deferred to the consolidation workstream (noted, not silently left).
- **Receipt integrity kept.** No `pr-create` bypass; captain signs a landing receipt (step 5). Five-hash chain intact; verify strictly BEFORE the bump (avoids the #463 churn — confirmed by MAR).
- **The two pending app PRs will need ANOTHER re-prep** after this lands (main moves → their receipts go stale). Execution step 7 must dispatch both agents to re-sync + re-`/pr-prep` + re-`/pr-submit` before landing them. Budget the bounce.
- **`--rehearse` mode**: runs steps 0–3 (integrate + validate, no publish) so the first real use is de-risked; rehearse on one app branch first.
- **src/ mirror parity** for every touched pair: new tool, git-captain, pr-create, pr-submit, _sync-main-ref, pr-captain-land script + docs, all tests. QG diffs live-vs-src.
- **Docs migration** beyond pr-captain-land's 3 files: `REFERENCE-CODE-REVIEW-LIFECYCLE.md` + sibling skills (`pr-captain-merge`, `pr-captain-post-merge`, `captain-release`, `captain-sync-all`) that reference the old PR-first switch-checkout behavior.
- **Tests add:** rollback-deletes-scratch, no-master-push, no-checkout-of-agent-branch, local-validation-gate, CI-gate-not-hardcoded, resolver `--strict`/fallback matrix, receipt-invalidation-rejection message.
- **#393 (session-end dirty handoff)** is largely mooted (land never touches main), but note it; scratch-worktree isolation means main-checkout dirtiness no longer blocks a land.

### MAR verdict
Core inversion (validate locally, publish already-validated work) is sound; worktree-collision fix is real. The scratch-worktree redesign + landing-receipt + aggregate-CI-gate + superset-resolver are the required changes before build. Proceeding on the v2 design.

---

## (original pre-MAR draft — retained for provenance)

**Principal directive:** "TheAgency model is about local review and validation. It needs to be oriented to local first."

## Goal

Re-orient `pr-captain-land` from **PR-first** (trust GitHub CI, merge on origin, sync local down) to **local-first** (integrate + validate on local main, *then* publish), and converge the duplicated default-branch resolution into **one shared primitive** — without collapsing Family 1 (integrate) / Family 2 (deliver), and without breaking the delivery path while app PRs are pending.

## Principles (agreed with principal)

1. **Don't collapse the two families** — integrate (local reconciliation) and deliver (publish to origin) are distinct concerns. Keep two thin orchestrators.
2. **Share the plumbing** — one tested primitive per operation; a bug fixed once is fixed everywhere. The duplicated default-branch resolver (3 copies) is the poster child.
3. **Phased** — converge the obvious duplication *now* as part of this re-orientation; defer the full Family-1/2 orchestrator consolidation to its own workstream (don't rewrite delivery under load).

## The shared seam

```
front-half (shared):  fetch → fast-forward local main → merge branch(es) → validate locally
Family 1 (captain-sync-all):  front-half only, batched, then push to worktrees. Never publishes.
Family 2 (pr-captain-land):   front-half (one branch) → publish (PR) → release → notify.
```

Only the back-half (publish/release) is Family-2-only.

---

## Scope — THIS pass

### 1. New shared primitive: `agency/tools/resolve-default-branch`
- Standalone zero-pip bash tool that **echoes** the repo's default branch name.
- Logic (canonical, from #463's `resolve_default_branch`): `git symbolic-ref --short refs/remotes/origin/HEAD` → else loop `origin/main`, `origin/master` → else fallback `main` (NOTE: change the fallback from `master` to `main` — flagged in #463 QG; `main` is the modern default and safer).
- Replaces the THREE current copies:
  - `git-captain` `detect_main_branch()` → call the tool (or keep a thin wrapper that delegates).
  - `pr-create` inline default-branch block → call the tool.
  - `pr-submit` `resolve_default_branch()` lib fn → delegate to the tool (keep the fn name as a thin wrapper so pr-submit's sourced-lib consumers, incl. pr-captain-land, still work; the fn shells to the tool).
- Tests: `src/tests/tools/resolve-default-branch.bats` — origin/HEAD present, absent-with-main, absent-with-master, neither (fallback), slash-bearing names.
- `src/` mirror kept identical.

### 2. Re-orient `pr-captain-land` to local-first

New flow (`pr-captain-land <agent-branch>`):

| Step | Action | Notes |
|---|---|---|
| 0 | **Preflight + sync** | captain on default branch in main checkout; clean tree; `git-captain fetch`; fast-forward local main to `origin/<default>` (via `_sync-main-ref` / `merge-from-origin`). Validate against latest. |
| 1 | **Verify branch + receipt** | agent branch exists on origin; QGR receipt matches branch diff vs `origin/<default>` (now current). |
| 2 | **Integrate locally** | `git-captain merge-to-master <branch>` (`--no-ff`). **No checkout of the branch** → the worktree-collision bug is gone by construction. |
| 3 | **Validate locally** | Run the pre-PR gate on the **integrated** main: `commit-precheck` / scoped tests / build. **On failure: `git reset --hard <pre-merge-sha>` (roll back the merge), abort, dispatch the agent to fix.** This is the local gate — the agency model. |
| 4 | **Bump version** | Bump `agency_version` on integrated main; commit. |
| 5 | **Publish** | Create `release/<branch>` at the validated main tip; push it; open PR (`release/<branch>` → default); merge server-side. origin fast-forwards to match local main. **No receipt re-gate at publish** — local validation (step 3) already gated; the publish is mechanical. CI on the publish PR is a final server-side confirmation. |
| 6 | **Release + notify + cleanup** | Cut `v<version>` (or verify Fix D auto-release); dispatch `master-updated` to the agent; delete `release/<branch>`; `post-merge-state clear`. |

Key inversions vs. today:
- Validation is **local, on the integrated tree** — GitHub becomes the publish step for already-validated work.
- The branch is **merged into main, never checked out** in the main checkout → no worktree collision.
- **No push of `master`** — publish rides a short-lived `release/<branch>` PR (fast-forward reconcile).

### 3. Reuse existing primitives (do NOT add new copies)
`merge-to-master` (exists), `_sync-main-ref` / `merge-from-origin` (exists), `sync-all` (exists), `gh-release` (exists), `receipt-verify` (exists), `diff-hash` (exists), `post-merge-state` (exists).

### 4. Docs + tests
- Rewrite `pr-captain-land` SKILL.md / reference.md / examples.md for the local-first flow.
- `src/tests/skills/pr-captain-land-*.bats` — extend guards: asserts merge-not-checkout, asserts local-validation-gate present, asserts rollback-on-failure, no-master-push.
- `src/` mirrors identical.

---

## OUT of scope — deferred workstream (file as seed/issue)

Full Family-1/2 consolidation: thin `captain-sync-all` + all `pr-captain-*` skills down to the shared `integrate → validate` front-half primitive; extract a single `integrate-branch` primitive both families compose. Real value, but touches load-bearing delivery tooling — its own planned pass, not bundled here.

---

## Open questions for MAR

1. **Receipt semantics at publish.** Local validation (step 3) is the real gate. Is skipping `pr-create`'s receipt re-verify at publish (step 5) correct, or must the publish PR still carry a matching receipt for audit? If the latter, captain re-signs a landing receipt binding the integrated+bumped state (adds churn). **Proposed: local gate is authoritative; publish PR is mechanical; keep the agent's receipt in history as the review evidence.**
2. **Rollback fidelity.** On step-3 failure, `git reset --hard <pre-merge-sha>` on local main — is that safe (main checkout tree is captain's; no agent WIP there), or should it be `merge --abort` before the merge commit is finalized? **Proposed: capture `PRE_MERGE_SHA` before step 2; hard-reset to it on failure.**
3. **`merge-to-master` semantics** — does the existing `git-captain merge-to-master` merge the branch INTO main (correct direction), refuse on conflict, and leave a recoverable state? Verify before reuse.
4. **Bootstrap.** The re-oriented `pr-captain-land` can't land its own PR. Land the re-orientation PR via the proven #463 primitive-bootstrap; subsequent lands (the two pending app PRs) use the new tool. Confirm no chicken-and-egg beyond that.
5. **CI gate name.** Today's checks are `bash 3.2 probe` / `manifest version` / `smoke` — not `lint-and-test`. The publish-PR CI wait must gate on the right check(s) for THIS repo (resolve, don't hardcode).
6. **Interaction with `captain-sync-all`.** After a local-first land, local main already has the work; the next `captain-sync-all` must not double-merge or conflict. Verify idempotence.

---

## Execution order (post-MAR)

1. Worktree `pr-captain-land-localfirst` off current main.
2. Build `resolve-default-branch` + tests; re-point the 3 consumers.
3. Re-orient `pr-captain-land` script + docs + tests.
4. Sync `src/` mirrors.
5. QG (full gate).
6. Bootstrap-land the re-orientation PR via primitives.
7. **Then** land the two pending app PRs (`mdslidepal-mac` `433cfd1`, `mdpal-app` `ee439a0`) with the new local-first tool — first real use.
8. File the deferred Family-1/2 consolidation workstream.
