---
type: session
agent: the-agency/jordan/captain
workstream: housekeeping
date: 2026-04-17
trigger: pre-session-end-model-switch
---

## On resume — IMMEDIATE ACTIONS (in order)

**Principal is doing /exit + /resume to switch models. Session state must be rebuilt.**

### 1. Reinstall the 0300 cron (CRITICAL — time-sensitive)

The cron is session-only and died on /exit. Reinstall immediately via CronCreate:

- Target time: **03:03 SGT 2026-04-18**
- Cron expression: `3 3 18 4 *`
- recurring: `false` (one-shot)
- durable: `true` (will still report session-only — keep session alive)
- Prompt:
  ```
  It is 0300 SGT 2026-04-18 — morning autonomous setup (captain, the-agency repo, /Users/jdm/code/the-agency).

  Execute the 0300 runbook: `/Users/jdm/code/the-agency/usr/jordan/captain/briefings/0300-runbook-20260418.md`

  Read it first, then execute each workstream in order. The runbook is the source of truth — follow it verbatim. Setup only — no PR merges, no fleet broadcasts. Principal reviews on wake.

  Pre-flight reminder: you are on `main`, tree should be clean. Read handoff first: `./claude/tools/handoff read`.
  ```

### 2. Restart the dispatch-monitor (via Monitor tool)

The Monitor task also died on /exit. Restart with the python3.13 shim (until 3.13 floor PR ships):

- Description: `dispatches + cross-repo collab (python3.13 workaround until floor PR ships)`
- Command: `/opt/homebrew/bin/python3.13 ./claude/tools/dispatch-monitor --include-collab`
- persistent: `true`
- timeout_ms: `3600000`

**Why the explicit path?** Shebang on `dispatch-monitor` is `#!/usr/bin/env python3.12` (from D44-R6, now stale) and `python3.12` is not installed on this machine. The explicit `/opt/homebrew/bin/python3.13` bypasses the shebang. Once the D45-R1 PR ships (at 0300 + principal merge), the shebang becomes `python3` + guard and the shim is no longer needed.

### 3. Confirm state to principal

Report: cron reinstalled (task id), monitor running (task id), runbook still committed (`237245ed`), standing by for 0300.

---

## Session context — D44 late-evening revisions (what changed tonight)

### Python 3.13 SUPERSEDES 3.12

Principal flipped the floor decision tonight:

- **D44-R6 (earlier today):** Python 3.12 ratified as floor — PR #208 merged as v44.7, fleet dispatches #649-656 broadcast, iscp #614 ack'd via #657.
- **D45 decision (tonight):** Flip to **3.13**. Rationale: brew default is 3.13 (adopters get the floor for free); 3.13 adds nothing we must turn on (JIT + no-GIL are opt-in); 3.12 was never even installed on this dev machine — which is how we discovered the gap: Monitor exited 127 tonight because `python3.12` not on PATH. `python3.13` already present via brew.
- **To be implemented at 0300:** D45-R1 PR (branch `release/python-3.13-floor`) — built autonomously per runbook, PR left `OPEN` for principal review, unmerged.

### Runbook committed

`usr/jordan/captain/briefings/0300-runbook-20260418.md` (commit `237245ed`) — full 0300 autonomous execution plan across 9 workstreams (A–I). The cron prompt just tells the 0300 agent to read and execute this file. **Runbook is the source of truth — do not improvise at 0300.**

### Workstreams queued for 0300 autonomous execution

| Workstream | Output | State on principal wake |
|---|---|---|
| A | D45-R1 PR: Python 3.13 floor | `OPEN`, QGR signed, unmerged |
| B | Shebang investigation briefing | Written, recommends B3 hybrid (`python3` + `sys.version_info` guard + agency-health check) |
| C | GH issue: "Release notes mechanism accessible to Principals and Agents" | Filed, labeled `discuss` |
| D | HIP Sprint epic + 13 child issues | Filed |
| E | ~40 defer→issue filings (dedup'd) | Filed |
| F | Close Issues themes briefing | Written at `usr/jordan/captain/briefings/close-issues-briefing-20260418.md` |
| G | Fleet broadcast drafts | Saved, NOT sent — awaits principal authorization |
| H | Dispatch monitor | Restarted (shebang-appropriate) |
| I | Handoff refresh | Written with `--trigger pre-principal-wake` |

### New principal directive — release notes mechanism

"We need to have a release notes mechanism that is accessible to Principals and Agents. Let's do this."

- Captured as Workstream C (GH issue filing at 0300).
- Shape TBD. Candidates: `agency release-notes` tool / hookified session-resume hint / per-agent dispatch on main-updated / machine-readable log at `claude/releases/NOTES.jsonl`.
- Enters Valueflow as /define (PVR) → /design (A&D) → /plan after HIP Sprint items land.

### Shebang decision — captured in runbook Workstream B

- Original D44 convention: `#!/usr/bin/env python3.12` — fails on any machine without that exact binary on PATH. Tonight's Monitor 127 proved the fragility.
- Options analyzed:
  - **B1:** Switch to `#!/usr/bin/env python3.13` — same fragility, different number.
  - **B2:** `#!/usr/bin/env python3` + runtime `sys.version_info` guard — flexible.
  - **B3:** B2 + `agency-health` check that warns if `python3` resolves to <3.13 — install-time visibility.
- Runbook recommends **B3**. Workstream A implements whatever B produces.

## Morning 1B1 agenda on principal wake (unchanged, with D45 items prepended)

0. **Review + merge D45-R1 PR** (Python 3.13 floor) → /post-merge → authorize fleet broadcast
1. 1B1 Close Issues (7 themes, 73 flags)
2. Ratify flag→issue rule (rewrite `/flag-triage` skill)
3. Install-vs-repo boundary discussion (flags #146/#165)
4. HIP Sprint FIFO (13 items)
5. Release notes mechanism — start /define (PVR) after HIP items land

---

## Fleet status at handoff (unchanged from D44 end-of-day)

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

Fleet sync deferred to `/session-resume` on individual agent wake.

## Dispatches & flags at handoff

- Dispatches: all 21 routine commit notifications batch-resolved silently. Queue clean at this snapshot. Fresh routine commits may have accumulated since — resolve silently on resume via batch loop.
- Flags: 0.
- Cross-repo collab: 1 stale marker (`dispatch-patch-incoming-issue-111-principal-scope-20260415.md: needs merge`) — two days old, non-actionable, dedup'd by Monitor within a session.

## Release summary carryover — D44

Fifteen releases shipped D44:
- v44.1 (#162), v44.2 (#175), v44.3 (#179), v44.4 (#182)
- v44.pr183 (#183 mdpal-app Phase 1B)
- v44.pr185–pr193 (#185–193 monofolk contributions)
- v44.6 (#203 devex triple)
- v44.7 (#208 Python 3.12 floor — SUPERSEDED by pending D45-R1)

## Repo state at this handoff

- **Branch:** main
- **Last commit:** `237245ed misc: 0300 runbook — D45-R1 Python 3.13 floor PR prep + HIP/issues setup`
- **Clean after commit of this handoff** (run /coord-commit on resume if this handoff is untracked).
- **Ahead of origin:** 3 local commits. Do NOT push.

## Context for fresh session

- Tonight's scoreboard: Python floor **re-ratified from 3.12 to 3.13**, runbook committed, release notes mechanism added as morning Valueflow input.
- Tomorrow's priorities: 0300 runbook → review PR + merge → authorize broadcast → 1B1 Close Issues → flag→issue rule → install-vs-repo → HIP Sprint FIFO → /define release-notes-mechanism.
- **Session must stay alive through 0300** (cron is session-only, `durable: true` is ignored by the scheduler).

## Model note (from principal tonight)

Principal tried `/model 4.6[1M]` / `Opus 4.6` / `Opus 4.6 (1M contect)` — **Opus 4.6 is not available via /model.** Current model is Opus 4.7 (1M context). Session restart is happening to retry the model switch — outcome may still land on 4.7.
