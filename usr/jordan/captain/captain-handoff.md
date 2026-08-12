---
type: session
agent: the-agency/jordan/captain
date: 2026-08-12T09:00
trigger: delivery-path-hardening-ready
branch: main
mode: continuation
next-action: |
  Session will /compact then continue. After compact, run /compact-resume, then:
  (1) BOOTSTRAP-LAND the delivery-path-hardening branch `devex-publish-path-repo-root`
      @ 2a07f80a (worktree .claude/worktrees/devex-landfix, receipt d60f4bd) via
      PRIMITIVES (the new pr-captain-land still can't land itself): in that worktree
      bump 46.28→46.29, re-sign receipt (keep A/B/C/D, new E), push, pr-create,
      wait CI, pr-merge <N> --principal-approved, gh-release, then post-merge sync
      main + delete worktree/branch. This carries BOTH the publish-path repo-root
      fix AND the git-sync main-guard fix.
  (2) THEN land the two app PRs with the NOW-COMPLETE local-first pr-captain-land
      (see "Landing the apps" below). Each land moves main → the other app re-preps
      first. That closes original task (a).
  Dispatch monitors bigfr7taj + b1id5zl1d running.
---

# Captain handoff — delivery-path hardening ready to land (post-compact)

## The arc of this (epic) session

Resumed a 3-month-stale session; drove a fleet rebuild; then discovered and fixed
the **entire PR-lifecycle**, which was structurally broken on this `main`-default
repo. Two big framework PRs LANDED, a third READY to land, and the two app PRs
are prepped behind it.

## LANDED this session
- **#444** — block-raw-tools port (v46.26). Closed **#443/#435** (superseded).
- **#463** — PR-lifecycle made **main-aware** (v46.26→...): `pr-submit`,
  `pr-captain-land`, `diff-hash` (handoff-exclusion / receipt-churn fix), `pr-create`
  (head/pipefail SIGPIPE guard) + new shared `resolve-default-branch`. This unstuck
  landing entirely — it was the parking brake.
- **#464** — **local-first `pr-captain-land` v2** (v46.28). Plan → MAR (4 reviewers)
  → build → QG (32 defects) → bootstrap-land. The land now integrates + validates in
  a **scratch worktree cut from origin/main**, never touches local main, rollback =
  delete the scratch. Plus new primitives: `ci-rollup-verdict`, `agency-version-next`,
  `pkg-manager`. **Rehearse (steps 0-3) PROVEN LIVE** — a real Swift build validated
  in a scratch, cleaned up, nothing published.

## READY TO LAND NOW — do this first, post-compact

### (1) Delivery-path-hardening branch `devex-publish-path-repo-root`
- **Worktree:** `.claude/worktrees/devex-landfix` · **Head:** `2a07f80a` · **Receipt:** `d60f4bd` (verifies vs origin/main=`ceb09231`).
- **Why it exists:** the FIRST real (publish) land of the v2 tool failed — `receipt-sign`, `pr-create`, `dispatch` resolved REPO_ROOT from their INSTALL dir (main checkout), not the scratch, so step-5 wrote the landing receipt to the wrong tree → clean rollback. (Steps 4-9 were never integration-tested; rehearse stops at 3.)
- **Fix A (publish-path):** `-C <repo-root>` targeting on receipt-sign/pr-create/dispatch (default unchanged, zero regression); pr-captain-land passes `-C "$SCRATCH_DIR"`. + 2 more bugs devex found (pr-create graded receipts against cwd hash by luck; dispatch derived ISCP DB from branch-supplied agency.yaml). + coverage of steps 4-9 (two-repo tests).
- **Fix B (git-sync, flag #229):** `git-sync` did `pull --rebase` + `push` with NO main-guard → something ran it on main and **rebased + pushed main** (both 20,000-volt offenses). Now guards main/master/resolved-default + merge-not-rebase + real agent in push-log. devex found 3 MORE git-sync bugs (detached-HEAD → `push origin ""`, conflicted-merge swallowed, push-log self-corruption). All fixed, mutation-verified.
- **Land it via PRIMITIVES** (NOT the new tool — it can't land itself yet): bump 46.28→46.29, re-sign (A/B/C/D from d60f4bd's chain, new E), push, `pr-create`, CI, `pr-merge --principal-approved`, `gh-release`, post-merge sync. Same dance as #463/#464 (see their history in git log).

### (2) The two app PRs (original task a)
- **mdslidepal-mac** @ `d7bc5da0`, receipt `ac1475f` (base ceb09231).
- **mdpal-app** @ `1e8b1b57`, receipt `ca897af` (base ceb09231).
- Both re-prepped clean, app-only-ish (carry 3 captain coord files from the worktree-sync bug — harmless, reach origin as legit coord).
- **Land with the COMPLETED local-first pr-captain-land** (after fix #1 lands):
  - Native (Swift) workstreams need `PR_LAND_VALIDATE_CMD` — the ladder is JS-only.
  - **mdslidepal-mac cmd** (agent-confirmed): `export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer; cd src/apps/mdslidepal-mac && swift build && swift run MdSlidepalTests` (NOT `swift test` — custom runner; cold build ~1-2 min).
  - mdpal-app cmd: ask the mdpal-app agent (executable test target `swift run MarkdownPalAppTests`).
  - **`--rehearse` first** (non-destructive), then the real land with `--principal-approved`.
  - Each land moves main → the OTHER app's receipt goes stale → dispatch it to re-`/pr-prep`+`/pr-submit` before landing. (Inherent single-writer cost; agents handle it fast.)

## Known bugs / debt surfaced (for follow-up, NOT blocking the above)
1. **flag #229 — git-sync** — being fixed in the branch above. SECONDARY: trace WHAT invoked git-sync on main (no daemon running; likely a skill path).
2. **worktree-sync merges LOCAL main** (not origin/main) → captain's unpushed commits ride into every synced agent branch. Should merge origin/main / expose `--remote`. (This is why the app PRs carry 3 extra captain files.)
3. **Python 3.13 floor vs machine's 3.9 `python3`** — bitten twice (dispatch-monitor, ci-rollup-verdict guards at 3.8). Policy decision: relax to "guard at actual need" or fix the machine default.
4. **issue #465 (devex-filed)** — 19 BATS fixtures still `mkdir claude/config` post-rename → abort in setup; + iscp-migrate copies a nonexistent tool; agent-identity 2 real branch-detection failures. devex fixed 5/19.
5. **`handoff write` silent no-op** — targets `usr/jordan/{agent}/` but file lives at `usr/jordan/{workstream}/`; reports ✓, writes nothing. mdslidepal-mac still has no handoff. HIGH.
6. **PAT in `.git/config`** — never pushed (verified: 0 tracked files, 0 commits, local-only). Principal to rotate: `git remote set-url origin https://github.com/the-agency-ai/the-agency.git` + revoke `ghp_…`.
7. New bats suites **don't run in CI** (smoke.yml placeholder, bash32-probe fixed list).
8. Local-first tool's **validation ladder is JS-only** — native workstreams need PR_LAND_VALIDATE_CMD or a declared per-workstream gate (design enhancement).
9. **Family-1/2 consolidation** seed: `agency/workstreams/agency/seeds/seed-family-1-2-consolidation-20260809.md` (converge remaining 3 default-branch resolvers: dispatch/pr-build/worktree-sync; extract shared integrate-branch primitive).
10. Second unread captain flag exists ("2 unread" when #229 filed) — read on resume.

## Original a / b / c
- **(a) apps** — READY; land after fix #1 (imminent).
- **(b) #426** (agency-captain-release-notes) — blocked on `worktree-create` remote-branch DWIM fix. devex delivered v2.2.0 earlier but it's on the `devex` branch mixed with RED test-monitor WIP (`f204bd2e`) — needs the 3 worktree-create commits (b9a4f89b/521a0f01/d9c00a39) ISOLATED onto a clean branch before landing. Then revive #426.
- **(c) 199-flag mountain** — untouched (now ~201 with #229 + one other). Original triage Task #3. Needs strategy (dedicated /flag-triage vs pre-May bankruptcy sweep).

## State
- **main == origin/main == `ceb09231`** (v46.28). Clean tree.
- Worktrees: `devex-landfix` (the land-ready fix), `mdslidepal-mac`, `mdpal-app` (apps prepped), plus fleet worktrees. `pr-lifecycle-v2` torn down.
- Dispatch monitors: `bigfr7taj`, `b1id5zl1d` (both running; use `/opt/homebrew/bin/python3.13 ./agency/tools/dispatch-monitor --include-collab`).
- Plan doc: `usr/jordan/captain/plans/plan-pr-captain-land-localfirst-20260809.md` (v2 post-MAR).

## On resume (post-compact)
1. `/compact-resume` — verify tree clean, monitors, dispatch drift. Read the 2 unread flags.
2. Execute next-action (1) then (2) above.

— captain. Delivery path hardened; one bootstrap-land + two app lands from done on (a).

*OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*
