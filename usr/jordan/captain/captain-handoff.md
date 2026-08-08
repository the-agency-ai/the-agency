---
type: session
agent: the-agency/jordan/captain
date: 2026-08-07T20:50
trigger: fleet-rebuild-complete
branch: main
mode: continuation
next-action: |
  Session will /compact then continue. After compact, run /compact-resume.
  Then move things forward — principal's call between: (a) land the rebuilt
  app-work branches via PR (mdslidepal-mac 912797c, mdpal-app 06ade7a),
  (b) tackle the 3 remaining rotting PRs (#443, #435, #426), (c) start the
  199-flag mountain triage (/flag-triage). Original triage Task #3 (flag
  mountain) is still open. Dispatch monitor task b1id5zl1d running.
---

# Captain handoff — fleet rebuild-on-main COMPLETE

## Session summary (2026-08-07)

Resumed from a ~3-month-stale handoff (this-happened hackathon, next-action
already done). Discovered the entire worktree fleet was **parked behind the
Great Rename** and drove a full **rebuild-on-main campaign** to unstick it.

## What was done this session

### 1. Landed PR #444 (delivery-stream win)
- `feat: port block-raw-tools.sh from monofolk` — merged via `pr-merge --principal-approved` (admin override; contrib branch, no GH review).
- Fix D auto-release cut **v46.26**. Post-merge state cleared. Main reconciled with origin (merge `8a7b9f6d`).

### 2. Fleet rebuild-on-main (the big work) — 7/7 worktrees
**Root cause:** every worktree was pre-Great-Rename (`claude/` paths); main is post-rename + wave-3/4 (`agency/` + `src/`). Naive `worktree-sync` reproduced dispatch #869's 618-conflict wall. great-rename-migrate v1.2 only reduced it (618→502) — residual = shared framework content main archived/deleted.

**Key insight (from principal):** main already owns the framework authoritatively; **`src/` is the installable source-of-truth** (the-agency is self-bootstrapping — root `agency/`/`apps/`/`tests/` is this running instance dogfooding; `src/` is what `agency init` installs). So: don't reconcile history — rebuild each worktree fresh from main, graft ONLY genuine unmerged product work.

**Mechanic (proven, sanctioned):** tag old tip `retired/<wt>-20260807` → `worktree-delete --force` → `git-captain branch-delete --force` → `worktree-create` (fresh from main) → graft product files via `git-safe show <tag>:<oldpath>` redirected into new worktree (NO cross-worktree cp, NO raw git) → `git-safe add` → `git-safe-commit`.

| Worktree | Outcome | New commit |
|---|---|---|
| mdslidepal-web | Retired — zero unmerged work | 24b5a1a (main base) |
| mdpal-cli | Retired — zero unmerged work | 24b5a1a (main base) |
| mdslidepal-mac | Phase 5.1/5.2 grafted (7 files) | `912797c` |
| mdpal-app | Phase 2.1–2.6 grafted (16 files) | `06ade7a` |
| iscp | dispatch-hub service (38 files → `src/services/dispatch-hub/`) | `35b2e09` |
| devex | test-monitor WIP preserved (`--no-verify`, red BATS) | `f204bd2` |
| designex | design-system pipeline preserved (`--no-verify`, 2 red/13 skip) | `81df836` |

All 7 `retired/*-20260807` recovery tags exist. Main clean at `8e27e33`.

### 3. Coordination artifacts committed
- `8e27e33` — 3 deferred dispatches + 5 commit-announce receipts (coord-commit).

## Key decisions / learnings (do not re-litigate)

1. **`src/` = source-of-truth installable payload; root = running instance.** the-agency is self-bootstrapping. The dual `agency/` + `src/agency/` tracking is BY DESIGN, not a bug. Framework tools live at BOTH `agency/tools/` (running) + `src/agency/tools/` (source); skills at `.claude/skills/` + `src/claude/skills/`; tests at `src/tests/` only; services tracked at `src/services/` (root `/services/` is gitignored — .gitignore:97).
2. **App-dir grafts are always safe** (main only gets app code via merges from the worktree → worktree strictly ahead). **Framework-tool grafts are NOT** — main is the active dev locus, so blind-graft regresses main. Those need 3-way merges → deferred to owning agents.
3. **Graft faithfully to the paths the agent had** — don't invent src/ copies; the framework's own src-split process propagates them.
4. **zsh gotcha:** `"$TAG:claude/..."` / `"$TAG:tests/..."` triggers zsh param modifiers (`:c`, `:t`). Always put the path in a variable: `"$TAG:$path"`.
5. **`--no-verify` skips the pre-commit hook that runs commit-precheck scoped tests** — used ONLY for explicit WIP-preservation (devex/designex red tests), honestly labeled.

## Deferred work — dispatched to owning agents (HIGH priority)

Each rebuilt framework worktree has a deferred 3-way merge captured as a dispatch (agent picks up on resume). Feature work safe in recovery tags:
- **iscp** (dispatch #): dispatch-tool feature merge (remote-poll/status-mirror/cross-agency ×373 lines) vs main's landed bug fixes #167/#201/#247/#251/#388. + dispatch-monitor (~50 lines).
- **devex** (dispatch #): git-safe-commit 3-way merge (111 lines, resolve_repo_root/BATS-regex) + FINISH Iter 1 (test-monitor BATS red).
- **designex** (dispatch #): figma-extract tool merge + relevance-check on agent-bootstrap/changelog-monitor/ci-monitor/enforcement-audit (main may have SUPERSEDED via changelog-watch/monitor-ci/agent-create).

## Open items (carry forward)

1. **Rebuilt branches not yet pushed/PR'd.** App work (mdslidepal-mac `912797c`, mdpal-app `06ade7a`) is committed on fresh branches, ready to land via PR. devex/designex wait on agents finishing deferred pieces first.
2. **3 rotting PRs** (never got to): #443 (port SKILL.md — CI red), #435 (worktree-sync stale-stash — CONFLICTING), #426 (agency-captain-release-notes — CI red, oldest Apr 23).
3. **Flag mountain: 199 flags** (Apr 5 → May 9) — untouched. Original triage Task #3. Needs strategy (dedicated /flag-triage vs pre-May bankruptcy sweep). #199 already stale.
4. **Local main carries unpushed captain coord commits** (4b35db38 + merges + 8e27e33) — normal captain-on-main pattern, sync later.

## What's NOT in scope / parked
- this-happened hackathon bootstrap (the old stale next-action — was already done; project at ~/code/this-happened/)
- Old flags #216 (dispatch-monitor py3.13 — worked around by invoking /opt/homebrew/bin/python3.13 directly this session), #217, #218, #220

## On resume (post-compact)
1. `/compact-resume` — verify tree clean, monitors alive, dispatch drift
2. Re-launch dispatch monitor if dead (was task b1id5zl1d, uses `/opt/homebrew/bin/python3.13 ./agency/tools/dispatch-monitor --include-collab`)
3. Move forward per principal's direction (land branches / PRs / flag mountain)

— captain, fleet rebuild complete.

*OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*
