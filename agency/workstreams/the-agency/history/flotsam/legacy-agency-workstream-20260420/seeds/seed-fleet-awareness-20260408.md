---
type: seed
workstream: agency (possibly split to new "fleet" workstream — decision in /define)
date: 2026-04-08
captured_by: the-agency/jordan/captain
principal: jordan
status: seed
---

# Seed: Fleet Awareness

## The Idea

Captain needs to know, at any moment: who is alive, what are they working on, what's blocking them, what's next. Today, captain guesses — reads the last handoff, assumes worktree agents are where they said they'd be, and waits for dispatches to arrive. That works until it doesn't: agents crash silently, sessions end without handoffs, work-in-flight becomes invisible, and standups don't exist.

This is **fleet awareness** — a first-class protocol for liveness, startup, heartbeat, and status reporting across every agent in the agency.

## Three Parts, One Feature

### 1. Liveness DB (protocol substrate)

External SQLite database at `~/.agency/{repo}/fleet.db`, outside git. Same neighborhood as `iscp.db`.

**Schema sketch (draft — for discussion):**

```
agent_sessions
  id               INTEGER PRIMARY KEY
  agent_address    TEXT NOT NULL            -- fully qualified: repo/principal/agent
  session_id       TEXT NOT NULL            -- Claude Code session ID if available, else UUID
  came_online_at   TIMESTAMP NOT NULL
  last_heartbeat   TIMESTAMP NOT NULL
  went_offline_at  TIMESTAMP                -- NULL while alive; set on clean exit
  startup_state    TEXT (JSON)              -- checklist: handoff_read, loops_armed, iscp_checked, collab_checked, captain_pinged
  metadata         TEXT (JSON)              -- worktree path, branch, plan phase, anything else
  UNIQUE(agent_address, session_id)
```

**Staleness rule (draft):** `last_heartbeat > 15min ago AND went_offline_at IS NULL` → presumed offline (session crashed without clean exit). Configurable.

**Query primitives (draft):**
- `fleet alive` — list currently-alive agents
- `fleet status <agent>` — detailed state for one agent
- `fleet history <agent>` — session history
- `fleet cleanup` — sweep stale sessions

### 2. `/startup` skill (canonical entry for every agent)

Covers all three entry paths:
- **Cold start** — first time in a fresh install/clone
- **Bootstrap** — first time for a newly-created agent
- **Resume** — continuing work across session boundary

Single skill, same sequence, different branches based on state detection.

**Sequence (draft):**

1. Resolve identity (`agent-identity`) — who am I
2. Detect entry mode (cold / bootstrap / resume) from handoff presence + fleet.db history
3. Read handoff (`handoff read`) — or write initial if cold/bootstrap
4. Check local ISCP (`dispatch list`, `flag list`)
5. Check cross-repo (`collaboration check`) — all agents, not captain-only (per peer-to-peer decision)
6. Arm the two dispatch loops (5m silent + 30m nag)
7. **Arm the heartbeat loop** (10m, see below)
8. **Register liveness** — write row to fleet.db with startup_state checklist
9. **Ping captain** — send a `status` dispatch: "alive, online, entry mode: {cold|bootstrap|resume}, handoff summary"
10. Follow "Next Action" from handoff

**Result:** every agent's startup becomes a single command. The CLAUDE-{AGENT}.md startup section collapses to: **"Run `/startup` on session start."**

### 3. Heartbeat

Periodic ping from every agent (including captain) to fleet.db. Updates `last_heartbeat`.

**Draft design:**
- New tool: `claude/tools/fleet-heartbeat` — updates current session's heartbeat, idempotent
- Scheduled loop: `/loop 10m fleet-heartbeat` armed by `/startup`
- Silent operation — no terminal noise
- Stale threshold tuneable (default 15m → presumed offline)
- On clean exit: `/session-end` writes `went_offline_at`

### 4. `/captains-report` skill (standup)

Depends on the liveness DB. Captain fans out a standup-style dispatch to currently-alive fleet, collects responses, compiles a report.

**Sequence (draft):**

1. Args: `--since "<time>"` (e.g., `"last standup"`, `"yesterday"`, `"1h ago"`)
2. Query fleet.db: who's alive right now?
3. For each alive agent, dispatch a `standup` (or `directive` with structured subject) asking:
   - What did you do since {time}?
   - What's next?
   - Any blockers?
4. Wait for responses (timeout, e.g., 10m configurable)
5. Aggregate into a report — table + per-agent narrative
6. Output:
   - Print to captain's terminal
   - Write to `usr/jordan/captain/logs/captains-report-{YYYYMMDD-HHMM}.md`
7. Agents who didn't respond: listed as "no response"
8. Agents marked offline in fleet.db: listed as "offline since {time}"

## Why Now

- Captain is currently flying blind on fleet state — guesses from handoffs and dispatch timing
- Silent agent crashes are invisible — no way to know a session died mid-work
- No standup protocol — captain cannot ask "what's everyone doing right now?"
- Growing fleet: today it's captain + 4 worktree agents; will scale with more workstreams
- Cross-repo collaboration is becoming peer-to-peer (iscp #165) — liveness awareness becomes more valuable as more agents coordinate directly

## Open Questions (for /define 1B1)

1. ~~**Workstream ownership.**~~ **RESOLVED by principal during seed capture:** *"You are the fleet. The fleet is you."* Captain owns the fleet workstream. Fleet is captain's domain — coordination, liveness, standup, presence, scheduling. A new `fleet` workstream is created under captain's ownership. Other agents (iscp, devex) contribute via dispatches but captain drives the work.

2. **Protocol split across agents.** Fleet workstream is captain-owned, but implementation still touches iscp (schema patterns, DB conventions) and devex (skills, tool scaffolding). The plan should assign specific iterations to the right implementer while captain orchestrates. Open: does captain implement directly, or dispatch every iteration?

3. **Session ID source.** Claude Code provides session IDs in hooks but not always in user-initiated commands. Fallback to UUID? Persist the session ID in a file?

4. **Dispatch type for standup.** New `standup` type, or reuse `directive` with a structured subject format? New types bump the ISCP schema; reuse has less protocol churn.

5. **Heartbeat interval.** 10m default sensible? Too frequent wastes cycles, too sparse makes staleness detection slow.

6. **Staleness threshold.** 15m default sensible? Needs to be > heartbeat interval + jitter + expected-pause.

7. **Startup checklist granularity.** Which steps count? What does "startup complete" mean? Does a failed step block the agent from being counted as "alive"?

8. **Principal liveness.** Is the principal represented in the fleet DB? They're not an agent per se but their presence/absence affects captain's behavior.

9. **Multi-principal.** How does this scale when multiple principals share the same repo (future)?

10. **Cross-repo fleet visibility.** Does captain see monofolk's fleet too? Separate DBs or aggregated view?

11. **Offline history retention.** How long do we keep went-offline rows? Forever (audit trail) or rolling window?

12. **Privacy / isolation.** Sandbox agents writing to a shared DB — any isolation needed?

13. **`/captains-report` scope.** Captain-only skill, or can any agent request a report? (A tech lead running their own standup for their sub-team, for instance.)

14. **Report format.** Markdown table? Narrative? Both? Include plan phase progress from the handoff?

15. **Timeout behavior for standup.** If an agent is alive but doesn't respond to the standup dispatch within timeout, what does captain do? Note in report, re-ask, escalate?

16. **Symmetric `/suspend` (or `/shutdown`).** Principal raised this during seed capture: *"does handoff become part of suspend or some such skill?"* If `/startup` arms the session, a symmetric skill should cleanly close it:
    - Write handoff (via existing `/handoff` tool)
    - Mark `went_offline_at` in fleet.db
    - Emit a final heartbeat with state = "suspended"
    - Cancel any armed loops cleanly
    - Send a `status` dispatch to captain: "going offline, handoff at {path}"
    - Archive anything that should be archived
    - Return a "safe to exit" confirmation
    - Name candidates: `/suspend`, `/shutdown`, `/session-end` (existing), `/offline`
    - Open: is this a new skill, or does it absorb/replace `/session-end` and `/handoff`?

## Related Work

- **Priority Order** (shipped) — captain reads dispatches first, principal communications override
- **Dispatch loops** (shipped) — 5m silent + 30m nag pattern, now canonical for every agent
- **Peer-to-peer collaboration** (iscp #165 queued) — cross-repo dispatches become peer-to-peer with captain auto-CC
- **Captain's log** (shipped Day 32) — narrative thread alongside handoffs; may cross-reference standup reports
- **ISCP schema versioning** (Phase 2.0 shipped) — fleet.db schema can use the same PRAGMA user_version pattern
- **Per-agent inboxes** (iscp Plan #121 approved) — another substrate extension

## Conversation Source

This seed was captured from a principal/captain conversation on 2026-04-08 during Day 33. Key quotes:

> "I want to have a skill captains report, which you use to send a dispatch out to the fleet asking them for current status and what is pending and any blockers."

> "I want to have a skill 'resume' which guides them through the resume process. What to read, what to do (setup loops), send a dispatch to captain that they are alive, send input for captains report, etc."

> "Do we want to add to a database outside the repo a mechanism that let's us see who is live, when came online or went offline, and that if they have a session, confirmation that they did all of their startup activities in our 'resume' or startup skill?"

> "Maybe this /resume skill is actually /startup? Because it might be a resume, a cold-start, or a bootstrap?"

> "We also need a heartbeat."

> "You are the fleet. The fleet is you." — resolving workstream ownership: fleet is captain's domain.

> "And does handoff become part of suspend or some such skill?" — proposing a symmetric shutdown skill paired with `/startup`.

Full chat transcript available in the current session record.

## Next Steps

1. Principal + captain 1B1 through `/define` — resolve open questions, produce Fleet Awareness PVR
2. `/design` — produce A&D document with schema, tool contracts, skill specifications
3. Plan — phases and iterations, workstream assignment, cross-agent coordination
4. Implement — iscp owns DB and protocol, devex owns skills and tooling (or whoever the plan assigns)
5. Ship — gradual rollout: captain first, then worktree agents one at a time

*Captured during Day 33 R1 work.*
