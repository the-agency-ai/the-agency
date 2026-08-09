# Seed — Family-1/2 delivery-tooling consolidation

**Filed:** 2026-08-09 · **By:** captain · **Priority:** medium · **Status:** deferred (queued)
**Origin:** deferred scope from the local-first `pr-captain-land` re-orientation (plan `usr/jordan/captain/plans/plan-pr-captain-land-localfirst-20260809.md`) + MAR findings.

## Problem

The captain's git/PR tooling has two families that overlap heavily but re-implement shared operations independently — so the same bug lands in many places and is fixed piecemeal. This session alone paid for it repeatedly (the `origin/master` hardcode, the `head`/pipefail abort, and **seven** copies of default-branch resolution).

- **Family 1 — local integration (no publish):** `captain-sync-all`, `git-captain merge-to-master`, `worktree-sync`/`merge-from-master`.
- **Family 2 — PR delivery (publish to origin):** `pr-create`, `pr-captain-merge`, `pr-captain-post-merge`, `pr-captain-land`, `captain-release`.

They share a **front-half**: `fetch → reconcile local main → merge/integrate → validate`. Only the back-half (publish/release) is Family-2-only.

## Goal

Do NOT collapse the two families (distinct concerns — agreed with principal). DO extract the shared front-half into **one tested primitive per operation** that both families compose, then thin the orchestrators down to sequences of those primitives.

## Scope (this deferred workstream)

1. **Finish the default-branch convergence.** The local-first `pr-captain-land` pass converged 4 of 7 (`git-captain`, `pr-create`, `pr-submit`, `_sync-main-ref`) onto `agency/tools/resolve-default-branch`. Remaining 3: `agency/tools/dispatch` (~line 203), `agency/tools/pr-build` (its own `detect_main_branch`), `agency/tools/worktree-sync` (~line 125). Plus their `src/` mirrors.
2. **Extract an `integrate-branch` primitive** — the shared "cut a clean base from origin, merge a branch onto it, validate" step. `captain-sync-all` (batched, no publish) and `pr-captain-land` (single-branch, then publish) both compose it.
3. **Thin the orchestrators**: `captain-sync-all` and the `pr-captain-*` skills become thin sequences of primitives; remove the piecemeal re-implementations.
4. **Audit `agency/tools/lib/_path-resolve`** — devex flagged (flag #225) that line ~178 unconditionally reassigns `AGENCY_PROJECT_ROOT` on source, making the documented override dead code fleet-wide. Fix under the same lib-hygiene banner.

## Constraints

- Touches load-bearing delivery tooling — do incrementally, test-backed, primitive-by-primitive. Do NOT big-bang rewrite while PRs are in flight.
- Self-bootstrapping: every `agency/` change mirrors to `src/`.
- Merge-not-rebase; never push master; safe-tools only.

## Related
- Plan: `usr/jordan/captain/plans/plan-pr-captain-land-localfirst-20260809.md`
- MAR reviewers flagged: 7 resolvers, `_sync-main-ref` hardcode, `_path-resolve` override dead-code (flag #225), CI-check-name hardcode.
