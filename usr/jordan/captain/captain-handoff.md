---
type: session
agent: the-agency/jordan/captain
workstream: housekeeping
date: 2026-04-18
trigger: pre-principal-wake
---

## On principal wake — Morning 1B1 agenda

Open in this order. 0 is time-sensitive; the rest can run in any order but the sequence
below is what the D44 end-of-day briefing committed us to.

0. **Review + merge PR #213** (Python 3.13 floor). QGR receipt signed, QG clean, 4 BATS tests pass. Then `/post-merge` (creates v45.1 release). Then authorize fleet broadcast (drafts at `usr/jordan/captain/dispatches/drafts/d45-r1-python-3.13-broadcast-draft.md` + `-body.md`).
1. **1B1 Close Issues** (7 themes, 73 flags). Briefing at `usr/jordan/captain/briefings/close-issues-briefing-20260418.md`.
2. **Ratify flag→issue rule** — rewrite `/flag-triage` skill so outcomes are `close` / `do now` / `file issue`. No "defer" state.
3. **Install-vs-repo boundary discussion** (flag #146 / #165). Open question — needs a decision on where the line between `agency init` install surface and dev-repo-only surface lives. Candidate outcome: new GH issue captures scope; maybe a CONTRIBUTING.md + INSTALLED-SURFACE.md split.
4. **HIP Sprint FIFO** (epic #215, children #216–#228). Lead item #222 (git-safe-commit receipt glob) first.
5. **Release notes mechanism** — start `/define` (PVR) on issue #214 after HIP work is in flight.

## 0300 autonomous setup — what was executed

Executed per runbook `usr/jordan/captain/briefings/0300-runbook-20260418.md` (commit `237245ed`). All 9 workstreams A–I landed. Setup only — no PR merges, no broadcasts.

| WS | Output | State on wake |
|---|---|---|
| A | D45-R1 PR #213 (Python 3.13 floor) | **OPEN**, QGR signed, unmerged. Awaits review. |
| B | Shebang briefing written | `usr/jordan/captain/briefings/python-shebang-investigation-20260418.md` (B2 shipped, B3 deferred per briefing). |
| C | Release notes mechanism GH issue | **#214** filed, labeled `enhancement`. |
| D | HIP Sprint epic + 13 children | Epic **#215**; children **#216–#228**. Comment on #215 lists children. |
| E | ~40 defer→issue filings | **#229–#269** (41 issues across Pass 1 + Pass 2). See "Workstream E issues" below for groupings. |
| F | Close Issues briefing | `usr/jordan/captain/briefings/close-issues-briefing-20260418.md`. |
| G | Fleet broadcast drafts | `usr/jordan/captain/dispatches/drafts/d45-r1-python-3.13-broadcast-draft.md` + `-body.md`. **HOLD — do NOT send without principal authorization.** |
| H | Dispatch monitor | Running since session resume. Task `b2szksh2h` (persistent, python3.13 shim workaround). |
| I | Handoff refresh | This file. |

**Cron:** task `ac8b0716` — fired on schedule, now consumed.

## PR #213 — review checklist for principal

- **Branch:** `release/python-3.13-floor`
- **Commits:** `9245a4fa` (fix + migration) → `a31ca6dd` (QGR receipt) → `b941041f` (close-issues briefing + broadcast draft)
- **QGR:** `claude/workstreams/the-agency/qgr/the-agency-jordan-captain-the-agency-python-3.13-floor-qgr-pr-prep-20260418-0509-d406320.md`
- **Reviewers:** 4 parallel (code/security/design/test) + haiku scorer + own review. 8 findings scored; 6 passed ≥50 threshold. 3 accepted + fixed in-PR (agency-dependencies brew formula, stale `__future__` import, runtime-guard test coverage). 3 tracked as follow-ups (below).
- **Tests:** `bats tests/tools/python-floor-guard.bats` = 4/4 pass. Regression `bats tests/tools/dispatch.bats` = 48/48 pass. `commit-precheck` clean.
- **Smoke:** `/opt/homebrew/bin/python3.13 ./claude/tools/dispatch-monitor --help` runs; `/usr/bin/python3 ./claude/tools/dispatch-monitor --help` exits 1 with guard message.
- **Files:** 10 (7 modified + 3 new). See PR body for full list.

After merge: `/post-merge` (creates v45.1 GH release), then authorize broadcast send. The Monitor shim (`/opt/homebrew/bin/python3.13 ...`) can be retired once the new shebang is on main.

## Follow-up issues from the QG (NOT blocking D45-R1 merge)

These were accepted as follow-up during triage. File them as new GH issues when convenient:
- Propagate runtime guard to `.claude/hooks/stop-check.py`, `.claude/hooks/plan-capture.py`, `tests/schemas/validate-schema.py`, `usr/jordan/captain/tools/strip-skill-allowed-tools`.
- `agency-health`: add `python3 >= 3.13` check. See **#209** — that issue already exists but says "< 3.12"; needs an update comment bumping to 3.13.
- `_agency-deps`: teach it to consume `min_version` + `version_cmd` from `dependencies.yaml`. Pre-existing gap.

## Workstream E issues — grouped

**Pass 1 (defer→issue, infrastructure + gaps):**
- **Agent identity + naming:** #229 (ident cross-contamination watch), #230 (naming convention enforcement)
- **Dispatch features:** #231 (SMS-style dispatches), #251 (dispatch body validation)
- **Captain process:** #232 (captains log formalize), #233 (friction→toolification pattern)
- **Services / infra:** #234 (agent mail service)
- **Docs:** #235 (telemetry-driven tool discovery), #253 (REFERENCE-RECEIPT-INFRA §6 fix), #239 (Over/Over-and-out protocol)
- **Tooling bugs:** #236 (commit-precheck end events), #254 (diff-hash fail-loud), #258 (git-commit worktree wipe), #267 (worktree-sync hardcoded master — BLOCKING), #268 (detect_main_branch unreachable)
- **Skills:** #237 (/why-did-this-fail), #240 (/make-slides), #269 (/feedback-submit sibling to #170)
- **mdslidepal:** #241 (smart quotes), #242 (Fixture 08 count)
- **Enforcement:** #243 (full git-op audit + Triangle), #244 (dispatch service), #245 (RG on QGR), #249 (CRITICAL — hookify block doesn't stop), #252 (skill-vs-tool gap)
- **Naming + receipts:** #246 (universal artifact naming), #248 (pr-create boundary-specific receipt), #255 (gh-safe / captain-gh)
- **Friction / permissions:** #247 (Edit on .claude/skills/), #250 (git-safe switch subcommand), #257 (git-safe unstage)
- **Process:** #238 (D-counter correction), #256 (Claude Code Routines adoption)

**Pass 2 (was-seed, discuss/research):**
- #259 (agency-gtm vouch model), #260 (MAR raw findings), #261 (MAR skill blunt instruction), #262 (day counting convention), #263 (adopter permission scoping), #264 (Docker daemon self-heal), #265 (cross-repo evolution articles), #266 (pre-history articles)

**Skipped as dupes / noise:**
- #126 → dupe of #206 (sync-main)
- #118, #124, #125 → dupe of #210 (commit-dispatch loop)
- #107 → dupe of HIP #227 (receipt chain-verify)
- #47 → already dispatched to designex
- #43, #44, #45, #48, #80 → Close-Issues Theme 6 (test noise)
- #5, #32 → in HIP (#225, #226)
- #62 → fixed (coord-commit allowed-tools)
- #33 → folded into #229 (identity)

## Repo state

- **Branch:** `main` (clean tree, before this handoff commit).
- **Release branch `release/python-3.13-floor`:** pushed, PR #213 OPEN.
- **Local main commits ahead of origin/main:** 4 (coord commits from D44 end + runbook + two handoffs). Do NOT push. These will land via a separate captain push after principal authorizes — or be rebased past if we go through PR #213 first.
- **Branch-topology note:** release/python-3.13-floor is branched FROM main at commit `e4f666c5` (pre-session-end handoff). When PR merges, main gains the release branch contents including this morning's close-issues briefing + broadcast draft.

## Dispatches & flags at handoff

- **Dispatches:** queue clean. Monitor running (`b2szksh2h`).
- **Flags:** 1 unread at 0300 start — #170 from principal last session ("Review the agency commands and clean up"). Queued for 1B1 as a standalone agenda item beyond the 5 above.
- **Cross-repo collab:** stale `dispatch-patch-incoming-issue-111-principal-scope-20260415.md: needs merge` — 3 days old, dedup'd by Monitor.

## Fleet status

Unchanged from D44 end-of-day. Fleet sync deferred to `/session-resume` on individual agent wake.

| Agent | Branch | Ahead | Behind | Dirty |
|---|---|---|---|---|
| designex | designex | varied | ~136 | some |
| devex | devex (merged) | 10 | 0 | 1 |
| iscp | iscp | 24 | 0 | 7 |
| mdpal-app | mdpal-app | 1 | many | 3 |
| mdpal-cli | mdpal-cli | 13 | 71 | 31 |
| mdslidepal-mac | | 9 | 338 | 6 |
| mdslidepal-web | | 4 | 163 | 1 |
| mock-and-mark | (empty) | — | — | — |

## Release summary carryover

D44 (fifteen releases): v44.1–v44.4, v44.pr183, v44.pr185–pr193, v44.6, v44.7 (3.12 floor — **superseded by pending v45.1**).

D45 (pending): v45.1 — Python 3.13 floor (PR #213).

## Model + session state

- **Model:** `opus-4-6` (successfully switched after last /exit+/resume). 1M context.
- **Session alive** through 0300 cron fire. Monitor persistent (`b2szksh2h`). Cron `ac8b0716` one-shot fired successfully.
- **No new cron needed** — 0300 work complete; next scheduled action is principal-driven on wake.

## Principal action items (short list)

1. Review PR #213; merge when satisfied (or request changes — feedback welcome on the shebang decision specifically).
2. Authorize broadcast send after merge (or not — fleet can pick up on `/session-resume` organically; broadcast is a belt+suspenders).
3. Work through the morning 1B1 agenda (5 items + flag #170).
4. Optionally: batch-update #209's comment with the 3.13 bump note so we don't fork the B3 follow-up story.

---

*OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*
