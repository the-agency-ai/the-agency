---
type: mar
project: valueflow
artifact: valueflow-ad-20260406.md (post-round-1 revision)
round: 2
date: 2026-04-06
author: the-agency/jordan/captain
reviewers:
  research:
    - methodology-critic (sonnet subagent)
    - practitioner (sonnet subagent)
    - adopter-advocate (sonnet subagent)
    - lean-process-analyst (sonnet subagent)
  agents:
    - the-agency/jordan/iscp (dispatch #85 → #89)
    - the-agency/jordan/devex (dispatch #86 → not received)
    - the-agency/jordan/mdpal-cli (dispatch #87 → not received)
    - the-agency/jordan/mdpal-app (dispatch #88 → not received)
    - monofolk/jordan/captain (collaboration-monofolk PR #7 → not received)
paired-to: valueflow-ad-20260406.md (post-round-1 revision, commit 9e6a84d)
---

# MAR Round 2: Valueflow A&D

5 of 9 reviewers responded (4 research subagents + ISCP). 4 agent reviews outstanding (DevEx, mdpal-cli, mdpal-app, monofolk). Not blocking — ISCP (most technically critical) says "ready for planning."

## Research Reviewer: Methodology Critic — 8 findings

| ID | Finding | Disposition | Reasoning/Action |
|----|---------|-------------|-----------------|
| R2-MC1 | MARFI is inconsistently a stage vs sub-protocol — stage table includes it but text says "triggers at any stage" | **Autonomous** | Fixed in revision — removed MARFI row from stage table, clarified as sub-protocol |
| R2-MC2 | Value stage has no V2 output path — if V3, say so in §12 | **Autonomous** | Fixed — Value row now says "V3 — feedback loop not in V2 scope" |
| R2-MC3 | Captain commit processing numbering misleading — iteration steps 1-7 then "step 8" for phase | **Autonomous** | Fixed — separated into two clearly labeled paths (coordination vs quality+shipping) |
| R2-MC4 | Circuit breaker "5 iterations worth of time" is unresolvable — iterations have no defined duration | **Autonomous** | Valid — will change to explicit hour-based default (configurable per workstream) during implementation planning |
| R2-MC5 | §9 "thin wrapper" vs current 650+ line CLAUDE-THEAGENCY.md — no migration plan | **Autonomous** | Migration is a V2 deliverable. The decomposition + linter ship together. Implementation plan will detail the migration steps. |
| R2-MC6 | MAP protocol underspecified for V2 — who receives RFIs if agents are session-based? | **Autonomous** | Captain dispatches to agents who will see it on next startup. Dispatches queue in ISCP DB. Same as all cross-session dispatch. |
| R2-MC7 | WorktreeCreate hook in V2 deliverables but not described in doc | **Disagree** | It's a Claude Code platform feature detailed in the PVR MARFI findings. The A&D references the PVR. Not every V2 deliverable needs a full A&D section. |
| R2-MC8 | Handoff type in §1 artifact table incomplete — defined in §7 but not §1 | **Autonomous** | Valid inconsistency — handoff IS in the §1 artifact table. Will verify both tables are consistent. |

## Research Reviewer: Practitioner — 6 findings

| ID | Finding | Disposition | Reasoning/Action |
|----|---------|-------------|-----------------|
| R2-PR1 | Captain loop underspecified for session reality — no protocol for transition between interactive and polling mode | **Autonomous** | Valid gap. In practice: captain runs the `/loop 5m dispatch check` and it fires during idle time. When principal is actively talking, loop still fires but captain prioritizes the conversation. Will add clarification. |
| R2-PR2 | 24-hour timeout wrong for subagents — they finish in seconds or error immediately | **Autonomous** | Already fixed in round 2 revision — §3 MAR protocol now distinguishes subagent timeouts (seconds) from dispatched agent timeouts (24h). |
| R2-PR3 | Three-bucket triage needs disagree criteria | **Autonomous** | Already fixed in round 2 revision — §2 now includes explicit criteria for when to reject a finding. |
| R2-PR4 | Dispatch authority at level 3 creates build-before-enforce gap — partially enforced system confusing without audit tool | **Autonomous** | Valid concern. The audit tool is flagged as "no registry without auditor" (§4). DevEx builds this. Until then, the enforcement is documented but not mechanically verified. Acceptable for V2 ramp-up. |
| R2-PR5 | Agent bootstrap handoff has no trigger condition | **Autonomous** | Already fixed in round 2 revision — §7 now specifies trigger: "via /workstream-create or /worktree-create, WorktreeCreate hook auto-triggers." |
| R2-PR6 | Stage-hash delta "single markdown file" edge case — commit with plan update + tool comment fix | **Autonomous** | Already fixed in round 2 revision — changed to "exclusively markdown files." If any non-.md file in delta, re-run. |

## Research Reviewer: Adopter Advocate — 5 findings

| ID | Finding | Disposition | Reasoning/Action |
|----|---------|-------------|-----------------|
| R2-AA1 | MARFI/MAR/MAP distinction unclear on first read — needs comparison table | **Autonomous** | Already fixed in round 2 revision — comparison table added at top of §3. |
| R2-AA2 | No "start here" minimum viable subset for adopters | **Autonomous** | Already fixed in round 2 revision — added to §9. |
| R2-AA3 | "Gleam" undefined on first use | **Autonomous** | Already fixed in round 2 revision — defined in stage table Seed row. |
| R2-AA4 | Context budget linter is non-trivial V2 deliverable — risk if it slips | **Autonomous** | Already flagged in round 2 revision — "linter and decomposition must ship together or neither ships." |
| R2-AA5 | V2/V3 boundary is credible and honest | **Agree** | Positive finding. No action needed. |

## Research Reviewer: Lean Analyst — 4 findings

| ID | Finding | Disposition | Reasoning/Action |
|----|---------|-------------|-----------------|
| R2-LA1 | MAR-always risks ceremony for trivial artifacts | **Disagree** | MAR is pair programming at machine speed (Linus's Law). Cost is seconds, not hours. Captain scales reviewer group to artifact significance. A trivial revision gets 1-2 subagents in seconds. Never skipped. Principal decision. |
| R2-LA2 | T3 Docker: if not running, blocks or degrades silently | **Autonomous** | Already fixed in round 2 revision — T3 falls back to in-process with isolation helpers. Warn, don't block. |
| R2-LA3 | Improvement loop doesn't fully close — no before/after metric comparison | **Autonomous** | Valid. The loop produces seeds but doesn't confirm they delivered value. Will add: "flag rate for category X before and after improvement Y" as the closing metric. Implementation detail for the telemetry system. |
| R2-LA4 | Dispatch-on-commit + /phase-complete is duplication not defense in depth | **Disagree** | They serve different purposes: dispatch-on-commit = coordination (captain merges, syncs). /phase-complete = quality + shipping (deep QG, PR). Both check stage-hash but for different reasons at different scopes. The design is sound — the framing has been clarified in the revision. Principal confirmed: "100% correct." |

## Agent Reviewer: ISCP (#89) — 4 findings

| ID | Finding | Disposition | Reasoning/Action |
|----|---------|-------------|-----------------|
| R2-ISCP1 | DB schema versioning is one sentence for a non-trivial problem | **Autonomous** | Defer detailed design to ISCP workstream. A&D references the requirement; ISCP owns the implementation design. |
| R2-ISCP2 | Dispatch retention (30-day) needs mechanism — where do archived dispatches go? | **Autonomous** | Defer to ISCP implementation. A&D states the policy; ISCP designs the mechanism (status change, symlink cleanup, git payload handling). |
| R2-ISCP3 | Flag categories should be optional enrichment, not required — bare `flag "msg"` must remain default | **Autonomous** | Valid. Will clarify: bare `flag "message"` is the default zero-thought path. `--friction`, `--idea`, `--bug` are optional enrichment for routing. Categories don't replace the default. |
| R2-ISCP4 | Captain batching needs merge conflict handling — queue conflicting commit, continue non-conflicting | **Autonomous** | Valid operational detail. Will add to captain loop: "if merge conflict, queue for manual resolution, continue processing non-conflicting commits." |

**ISCP verdict: "This A&D is ready for planning."**

## Agent Reviewers: Not Received

| Agent | Dispatch | Status |
|-------|----------|--------|
| DevEx | #86 | Not received — missed round 1 entirely, nudged twice |
| mdpal-cli | #87 | Not received |
| mdpal-app | #88 | Not received |
| monofolk/captain | collaboration-monofolk PR #7 | Merged, not yet responded |

Not blocking. Will incorporate when/if received.

## Summary

| Category | Count |
|----------|-------|
| Disagree | 3 (WorktreeCreate is PVR detail, MAR-always is pair programming, dispatch paths serve different purposes) |
| Autonomous | 22 (12 already fixed in revision, 10 to incorporate) |
| Agree (positive) | 2 |
| Not received | 4 agent reviews |

## Collaborative Items Resolved with Principal (from round 2 triage)

| Item | Resolution |
|------|-----------|
| WorktreeCreate hook not described in A&D | It's a Claude Code feature detailed in the PVR MARFI findings. A&D references PVR. |
| MAR-always ceremony for trivial artifacts | MAR = pair programming. Many eyes, all bugs are shallow. Cost is seconds. Captain scales reviewer group. Never skipped. |
| Dispatch-on-commit + /phase-complete duplication | Different mechanisms, different boundaries, different purposes. Coordination vs quality. Principal confirmed: "100% correct." Defense in depth is the right framing. |

## Additional Context from Principal

- "It is akin to pair programming where someone is looking at things with me. We can do that, so we do it."
- "With many eyes, all bugs are shallow." (Linus's Law)
- "Think of it as analogous to pair programming" — on why MAR is never skipped
- "100% correct" — on dispatch-on-commit + /phase-complete serving different purposes

Session transcript: `usr/jordan/captain/transcripts/session20-continued-20260406-0730.md`

## Agent Reviewer: monofolk/captain (collaboration-monofolk) — 3 findings

| ID | Finding | Disposition | Reasoning/Action |
|----|---------|-------------|-----------------|
| R2-MF1 | Enforcement registry needs bootstrap story — what starting state for new adopters? | **Autonomous** | Valid. Add: audit current state, declare honest levels, start at level 1 for everything, tighten from there. |
| R2-MF2 | Context budget linter is critical path — must ship with decomposition | **Autonomous** | Already captured in revision: "linter and decomposition must ship together or neither ships." |
| R2-MF3 | Dispatch retention — git payloads should remain indefinitely, only clean up symlinks and DB | **Autonomous** | Valid refinement. 30-day archive = DB records + symlinks. Git payloads stay forever (they're in git history regardless). |

**monofolk verdict: "The A&D is ready for planning."**

**Notable observation from monofolk:** Cross-repo review (monofolk/captain) returned faster than local agents (DevEx, mdpal-cli, mdpal-app) because monofolk doesn't have the permission friction blocking dispatch creation. Local agents are stuck asking for permission to send their reviews. This is the #1 proof point for why the permission model overhaul is urgent.

## Agent Reviewers: Still Not Received

| Agent | Dispatch | Status | Likely cause |
|-------|----------|--------|-------------|
| DevEx | #86 | Not received | Permission friction — can't send dispatch |
| mdpal-cli | #87 | Not received | Permission friction — can't send dispatch |
| mdpal-app | #88 | Not received | Permission friction — can't send dispatch |

## Updated Summary

| Category | Count |
|----------|-------|
| Disagree | 3 |
| Autonomous | 25 (12 pre-fixed + 10 ISCP/research + 3 monofolk) |
| Agree (positive) | 2 |
| Not received | 3 agent reviews (permission friction) |

## Status

**MAR round 2: COMPLETE (research + ISCP + monofolk).** 6 of 9 reviewers responded. 3 local agents blocked by permission friction. Two independent verdicts of "ready for planning" (ISCP, monofolk). Research reviewers: no blockers. A&D is ready for implementation planning.
