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
    - the-agency/jordan/devex (dispatch #86 → #91, delivered via direct prompt due to identity bug)
    - the-agency/jordan/mdpal-cli (dispatch #87 → committed to mdpal branch, merged to main)
    - the-agency/jordan/mdpal-app (dispatch #88 → committed to mdpal branch, merged to main)
    - monofolk/jordan/captain (collaboration-monofolk PR #7 → responded)
paired-to: valueflow-ad-20260406.md (post-round-1 revision, commit 9e6a84d)
---

# MAR Round 2: Valueflow A&D

**ALL 9 REVIEWERS RESPONDED.** 4 research subagents + 5 agents. Three verdicts of "ready for planning" (ISCP, monofolk, mdpal-app). No structural concerns from any reviewer. DevEx, mdpal-cli, mdpal-app delivered via workarounds (direct prompt delivery, commit-to-branch) due to dispatch identity bugs.

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

## Agent Reviewer: DevEx (#91, delivered via direct prompt) — 10 findings

| ID | Finding | Disposition | Reasoning/Action |
|----|---------|-------------|-----------------|
| R2-DX1 | T1 scoping needs default for unmapped files — warn and proceed? | **Autonomous** | Valid. No mapping = warn and proceed. Manifest closes gaps over time. Will state default explicitly. |
| R2-DX2 | Enforcement ladder needs concrete example — one capability through all 5 levels | **Autonomous** | Good pedagogical point. Will add git-commit as the worked example (currently at level 5). |
| R2-DX3 | Test hermiticity misses 25 un-isolated files + filesystem pollution | **Autonomous** | Acknowledged. DevEx Phase 1 scope. A&D §6 references the requirement; DevEx PVR/A&D fills the rollout plan. |
| R2-DX4 | Permission model still missing — no design section despite V2 deliverable | **Autonomous** | Valid gap. DevEx owns this in their PVR/A&D. Valueflow A&D can reference it rather than duplicate. |
| R2-DX5 | Symlinks need reconstruction on fresh clone — not mentioned | **Autonomous** | Valid. Dispatch tool needs to rebuild symlinks from DB on init (scan active dispatches, recreate symlinks from payload_path). Will add. |
| R2-DX6 | PostCompact — just always inject full, keep handoffs tight | **Autonomous** | Aligns with principal decision. Always inject full handoff. Keep handoffs under 100 lines. Problem solved. |
| R2-DX7 | V2 deliverables need sequencing — 25 items with implicit dependencies | **Autonomous** | Valid. Implementation plan will include dependency graph. Not A&D scope — plan scope. |
| R2-DX8 | Dispatch authority: review-response should be "any agent in reply to review" not "artifact author" | **Autonomous** | Valid — same finding as mdpal-app R2-MA8. Clarify: any agent receiving a review dispatch can send review-response. |
| R2-DX9 | Day counting measurement mechanism unspecified | **Autonomous** | Simple: `git log --format="%ad" --date=short | sort -u | wc -l`. Can be a tool. Low priority. |
| R2-DX10 | Captain loop cadence — interactive vs polling mode transition | **Autonomous** | Same as practitioner R2-PR1. `/loop 5m dispatch check` fires during idle. Captain prioritizes principal conversation. |

**DevEx verdict:** "Most gaps are DevEx territory. Ready to fill them in my own PVR/A&D."

## Agent Reviewer: mdpal-cli (committed to mdpal branch, merged) — 9 findings

Note: mdpal-cli submitted this as their round 1 review (dispatch system was broken). Content covers the same A&D version — these are their first findings on the document.

| ID | Finding | Disposition | Reasoning/Action |
|----|---------|-------------|-----------------|
| R2-CL1 | Gate tiers assume language-specific tooling (Swift has no linter) | **Autonomous** | Already addressed in round 2 revision: T1 baseline is "stage-hash + compile." Format/lint optional per language. |
| R2-CL2 | Changed-file test scoping needs package-level default | **Autonomous** | Already addressed: "run all tests in affected package" as fallback. |
| R2-CL3 | Dispatch payload migration risky — fix read path instead | **Disagree** | Superseded by symlink design (principal decision, ISCP implemented). Symlinks keep git as source of truth AND provide branch-transparent access. |
| R2-CL4 | Captain should explicitly be session-scoped for V2 | **Autonomous** | Already addressed in collaborative resolution C4: "always-on by design, first up last down. V2 mechanism is sessions. V3 adds daemon." |
| R2-CL5 | MARFI boundary fuzzy — need decision rule | **Autonomous** | Already addressed: "MARFI = questions answerable with web search + docs. Domain research = questions requiring project context." |
| R2-CL6 | effort: levels undefined | **Autonomous** | Already addressed in collaborative resolution C5: "Anthropic's abstraction over token budget. Set dial per skill. Don't define internals." |
| R2-CL7 | Circuit breaker should be time-based not attempt-based | **Autonomous** | Already addressed: changed to "no progress in N hours." Agent self-reports stuck vs making progress. |
| R2-CL8 | Context budget linter must ship with decomposition | **Autonomous** | Already captured: "linter and decomposition must ship together or neither ships." |
| R2-CL9 | Captain loop cadence — close the question | **Autonomous** | Already closed: fixed interval V2 (`/loop 5m dispatch check`), event-driven V3. |

**mdpal-cli verdict:** "The A&D is solid and grounded. No structural issues."

## Agent Reviewer: mdpal-app (committed to mdpal branch, merged) — 12 findings

| ID | Finding | Disposition | Reasoning/Action |
|----|---------|-------------|-----------------|
| R2-MA1 | MARFI as sub-protocol reframing is good | **Agree** | Positive. Matches their experience. |
| R2-MA2 | Autonomous stage transition protocol is well-scoped | **Agree** | Positive. Informational dispatch model confirmed. |
| R2-MA3 | Three handoff classes are practical — who writes bootstrap? | **Autonomous** | Valid question. Captain writes the bootstrap handoff content. Will make explicit in §7. |
| R2-MA4 | Intra-session handoffs as insurance — yes | **Agree** | Positive confirmation of existing practice. |
| R2-MA5 | Transcript injection underspecified — how to select relevant transcripts, token budget? | **Autonomous** | Valid. Handoff should summarize transcripts, not inject raw. Add: "summarize relevant context from transcripts, don't inject raw transcript files." Token budget for transcript summaries within the handoff's 100-line target. |
| R2-MA6 | Changed-file test scoping — package-level fallback is practical | **Agree** | Positive confirmation. |
| R2-MA7 | Stage-hash delta tolerance — clean rule | **Agree** | Positive confirmation. |
| R2-MA8 | Dispatch authority: review-response gating too strict — any reviewer should respond, not just author | **Autonomous** | Valid — same as DevEx R2-DX8. Clarify: "any agent receiving a review dispatch can send review-response." |
| R2-MA9 | Dispatch retention 30-day is reasonable | **Agree** | Positive. |
| R2-MA10 | Context budget linter + decomposition must ship together | **Agree** | Enforcement triangle confirmed. |
| R2-MA11 | Day counting — useful velocity signal | **Agree** | Positive. Example: 4 commit-days over 4 calendar days = healthy. |
| R2-MA12 | PostCompact scope confirmed — CLAUDE.md survives, handoff only | **Agree** | Positive confirmation from agent experience. |

**mdpal-app verdict:** "No structural concerns. Remaining findings are minor refinements."

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

## Final Summary — All 9 Reviewers

| Category | Count |
|----------|-------|
| Disagree | 4 (WorktreeCreate is PVR detail, MAR-always is pair programming, dispatch paths serve different purposes, payload migration superseded by symlinks) |
| Autonomous | 46 |
| Agree (positive) | 11 |
| Collaborative (resolved with principal) | 3 |

## Verdicts

| Reviewer | Verdict |
|----------|---------|
| Methodology critic | Refinements, no blockers |
| Practitioner | Captain mode-switching gap, no blockers |
| Adopter advocate | Needs "start here" (added), no blockers |
| Lean analyst | MAR-always justified, improvement loop needs closing metric |
| ISCP | **Ready for planning** |
| monofolk/captain | **Ready for planning** |
| DevEx | "Most gaps are DevEx territory" — ready to fill in own PVR/A&D |
| mdpal-cli | "Solid and grounded, no structural issues" |
| mdpal-app | **"No structural concerns"** |

## Delivery Notes

Local agents (DevEx, mdpal-cli, mdpal-app) were blocked by dispatch identity bugs — could not send dispatches through normal ISCP channels. Workarounds:
- DevEx: review delivered via direct prompt from principal, dispatched manually
- mdpal-cli + mdpal-app: reviews committed to mdpal branch, merged to main by captain
- monofolk/captain: delivered via collaboration-monofolk repo (no identity bug — different infra)

The dispatch identity bugs are fixed (ISCP commit 6647c43) but agents need restart to pick up fixes.

## Status

**MAR round 2: COMPLETE. 9 of 9 reviewers. A&D is ready for implementation planning.**

Three independent verdicts of "ready for planning" (ISCP, monofolk, mdpal-app). No structural concerns from any reviewer. Remaining findings are refinements — most are already addressed in the revision or are DevEx territory for their own PVR/A&D.

Session transcript: `usr/jordan/captain/transcripts/session20-continued-20260406-0730.md`
