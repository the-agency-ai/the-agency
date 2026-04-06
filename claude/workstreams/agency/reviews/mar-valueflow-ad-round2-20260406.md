---
type: mar
project: valueflow
artifact: valueflow-ad-20260406.md (post-round-1 revision)
round: 2
date: 2026-04-06
author: the-agency/jordan/captain
paired-to: valueflow-ad-20260406.md (commit 9e6a84d)
reviewers:
  research:
    - methodology-critic (sonnet subagent)
    - practitioner (sonnet subagent)
    - adopter-advocate (sonnet subagent)
    - lean-process-analyst (sonnet subagent)
  agents:
    - the-agency/jordan/iscp (dispatch #85 → #89)
    - the-agency/jordan/devex (dispatch #86 → #91, delivered via direct prompt)
    - the-agency/jordan/mdpal-cli (dispatch #87 → committed to mdpal branch)
    - the-agency/jordan/mdpal-app (dispatch #88 → committed to mdpal branch)
    - monofolk/jordan/captain (collaboration-monofolk PR #7 → responded)
---

# MAR Round 2: Valueflow A&D — Complete Disposition

**ALL 9 REVIEWERS RESPONDED.** Three verdicts of "ready for planning" (ISCP, monofolk, mdpal-app). No structural concerns from any reviewer.

---

## Complete Finding Table

| ID | Reviewer | Version | Finding | Disposition | Reasoning/Action |
|----|----------|---------|---------|-------------|-----------------|
| R2-MC1 | Methodology Critic | R1-revised | MARFI inconsistently a stage vs sub-protocol | **Autonomous** | Fixed — removed from stage table, clarified as sub-protocol |
| R2-MC2 | Methodology Critic | R1-revised | Value stage has no V2 output path | **Autonomous** | Fixed — Value row says "V3 — feedback loop not in V2 scope" |
| R2-MC3 | Methodology Critic | R1-revised | Captain commit processing numbering misleading | **Autonomous** | Fixed — separated into two labeled paths (coordination vs quality+shipping) |
| R2-MC4 | Methodology Critic | R1-revised | Circuit breaker "5 iterations worth of time" unresolvable | **Autonomous** | Change to explicit hour-based default during implementation planning |
| R2-MC5 | Methodology Critic | R1-revised | "Thin wrapper" vs current 650+ line CLAUDE-THEAGENCY.md — no migration plan | **Autonomous** | Migration is V2 deliverable. Decomposition + linter ship together. Plan details steps. |
| R2-MC6 | Methodology Critic | R1-revised | MAP underspecified — who receives RFIs if agents are session-based? | **Autonomous** | Dispatches queue in ISCP DB. Agents see on next startup. Same as all cross-session dispatch. |
| R2-MC7 | Methodology Critic | R1-revised | WorktreeCreate hook in V2 deliverables but not described | **Disagree** | Claude Code platform feature detailed in PVR MARFI. A&D references PVR. Not every deliverable needs A&D section. |
| R2-MC8 | Methodology Critic | R1-revised | Handoff in §1 artifact table inconsistent with §7 | **Autonomous** | Verify both tables consistent |
| R2-PR1 | Practitioner | R1-revised | Captain loop — no protocol for interactive vs polling transition | **Autonomous** | `/loop 5m dispatch check` fires during idle. Captain prioritizes principal conversation. Will clarify. |
| R2-PR2 | Practitioner | R1-revised | 24h timeout wrong for subagents | **Autonomous** | Already fixed — §3 distinguishes subagent (seconds) from dispatched agent (24h) timeouts |
| R2-PR3 | Practitioner | R1-revised | Three-bucket triage needs disagree criteria | **Autonomous** | Already fixed — §2 includes explicit criteria |
| R2-PR4 | Practitioner | R1-revised | Dispatch authority at level 3 creates build-before-enforce gap | **Autonomous** | Audit tool is load-bearing. DevEx builds. Acceptable partial enforcement during V2 ramp-up. |
| R2-PR5 | Practitioner | R1-revised | Bootstrap handoff has no trigger condition | **Autonomous** | Already fixed — §7 specifies WorktreeCreate hook trigger |
| R2-PR6 | Practitioner | R1-revised | Stage-hash delta: commit with markdown + code | **Autonomous** | Already fixed — "exclusively markdown files" rule |
| R2-AA1 | Adopter Advocate | R1-revised | MARFI/MAR/MAP unclear — needs comparison table | **Autonomous** | Already fixed — comparison table at top of §3 |
| R2-AA2 | Adopter Advocate | R1-revised | No "start here" minimum viable subset | **Autonomous** | Already fixed — added to §9 |
| R2-AA3 | Adopter Advocate | R1-revised | "Gleam" undefined on first use | **Autonomous** | Already fixed — defined in stage table Seed row |
| R2-AA4 | Adopter Advocate | R1-revised | Context budget linter risk if slips | **Autonomous** | Already flagged — "linter and decomposition must ship together or neither ships" |
| R2-AA5 | Adopter Advocate | R1-revised | V2/V3 boundary is credible | **Agree** | Positive |
| R2-LA1 | Lean Analyst | R1-revised | MAR-always risks ceremony for trivial artifacts | **Disagree** | MAR = pair programming (Linus's Law). Cost is seconds. Captain scales. Never skipped. Principal decision. |
| R2-LA2 | Lean Analyst | R1-revised | T3 Docker not running — blocks or degrades silently | **Autonomous** | Already fixed — T3 falls back to in-process with isolation. Warn, don't block. |
| R2-LA3 | Lean Analyst | R1-revised | Improvement loop doesn't close — no before/after comparison | **Autonomous** | Add "flag rate for category X before and after improvement Y" as closing metric |
| R2-LA4 | Lean Analyst | R1-revised | Dispatch-on-commit + /phase-complete is duplication | **Disagree** | Different purposes: coordination vs quality. Both check stage-hash at different scopes. Principal: "100% correct." |
| R2-ISCP1 | ISCP | R1-revised | DB schema versioning is one sentence for non-trivial problem | **Autonomous** | Defer to ISCP workstream. A&D references requirement; ISCP owns implementation. |
| R2-ISCP2 | ISCP | R1-revised | Dispatch retention 30-day needs mechanism | **Autonomous** | Defer to ISCP. A&D states policy; ISCP designs mechanism. |
| R2-ISCP3 | ISCP | R1-revised | Flag categories should be optional enrichment, bare flag default | **Autonomous** | Clarify: bare `flag "msg"` is default. `--friction`/`--idea`/`--bug` are optional. |
| R2-ISCP4 | ISCP | R1-revised | Captain batching needs merge conflict handling | **Autonomous** | Add: queue conflicting commit for manual resolution, continue non-conflicting. |
| R2-MF1 | monofolk | R1-revised | Enforcement registry needs bootstrap story for new adopters | **Autonomous** | Add: audit current state, declare honest levels, start at level 1, tighten from there. |
| R2-MF2 | monofolk | R1-revised | Context budget linter critical path — must ship with decomposition | **Autonomous** | Already captured in revision |
| R2-MF3 | monofolk | R1-revised | Dispatch retention — git payloads stay forever, only clean symlinks + DB | **Autonomous** | Valid refinement. 30-day = DB + symlinks. Git payloads stay. |
| R2-DX1 | DevEx | R1-revised | T1 scoping needs default for unmapped files | **Autonomous** | No mapping = warn and proceed. Manifest closes gaps over time. State explicitly. |
| R2-DX2 | DevEx | R1-revised | Enforcement ladder needs concrete example through all 5 levels | **Autonomous** | Add git-commit as worked example (currently at level 5) |
| R2-DX3 | DevEx | R1-revised | Test hermiticity misses 25 un-isolated files + filesystem pollution | **Autonomous** | DevEx Phase 1 scope. A&D references requirement; DevEx PVR/A&D owns rollout. |
| R2-DX4 | DevEx | R1-revised | Permission model still missing — no design section | **Autonomous** | DevEx owns in their PVR/A&D. Valueflow A&D references, doesn't duplicate. |
| R2-DX5 | DevEx | R1-revised | Symlinks need reconstruction on fresh clone | **Autonomous** | Add: dispatch tool rebuilds symlinks from DB on init. |
| R2-DX6 | DevEx | R1-revised | PostCompact — always inject full, keep handoffs tight | **Autonomous** | Aligns with principal decision. Always full. Under 100 lines. |
| R2-DX7 | DevEx | R1-revised | V2 deliverables need sequencing — 25 items with dependencies | **Autonomous** | Implementation plan scope, not A&D. Plan will include dependency graph. |
| R2-DX8 | DevEx | R1-revised | Dispatch authority: review-response = any reviewer, not artifact author | **Autonomous** | Valid. Clarify: any agent receiving review dispatch can respond. |
| R2-DX9 | DevEx | R1-revised | Day counting measurement mechanism unspecified | **Autonomous** | `git log --format="%ad" --date=short | sort -u | wc -l`. Can be a tool. |
| R2-DX10 | DevEx | R1-revised | Captain interactive vs polling mode transition | **Autonomous** | Same as R2-PR1. Loop fires during idle. |
| R2-CL1 | mdpal-cli | **original** | Gate tiers assume language-specific tooling | **Autonomous** | Already addressed in R1-revised — T1 baseline universal: stage-hash + compile. Format/lint optional. |
| R2-CL2 | mdpal-cli | **original** | Changed-file scoping needs package-level default | **Autonomous** | Already addressed in R1-revised — package-level fallback. |
| R2-CL3 | mdpal-cli | **original** | Dispatch payload migration risky | **Disagree** | Superseded by symlink design (principal decision, ISCP implemented). |
| R2-CL4 | mdpal-cli | **original** | Captain should explicitly be session-scoped for V2 | **Autonomous** | Already addressed in R1-revised — C4: always-on by design, V2 = sessions, V3 = daemon. |
| R2-CL5 | mdpal-cli | **original** | MARFI boundary fuzzy | **Autonomous** | Already addressed in R1-revised — decision rule added. |
| R2-CL6 | mdpal-cli | **original** | effort: levels undefined | **Autonomous** | Already addressed — C5: Anthropic's abstraction. Set dial per skill. |
| R2-CL7 | mdpal-cli | **original** | Circuit breaker should be time-based | **Autonomous** | Already addressed in R1-revised — changed to "no progress in N hours." |
| R2-CL8 | mdpal-cli | **original** | Context budget linter must ship with decomposition | **Autonomous** | Already captured. |
| R2-CL9 | mdpal-cli | **original** | Captain loop cadence — close the question | **Autonomous** | Already closed — fixed interval V2, event-driven V3. |
| R2-MA1 | mdpal-app | R1-revised | MARFI sub-protocol reframing is good | **Agree** | Positive |
| R2-MA2 | mdpal-app | R1-revised | Autonomous stage transition well-scoped | **Agree** | Positive |
| R2-MA3 | mdpal-app | R1-revised | Three handoff classes — who writes bootstrap? | **Autonomous** | Captain writes bootstrap content. Make explicit in §7. |
| R2-MA4 | mdpal-app | R1-revised | Intra-session handoffs as insurance — yes | **Agree** | Positive |
| R2-MA5 | mdpal-app | R1-revised | Transcript injection underspecified — selection, budget | **Autonomous** | Handoff summarizes transcripts, doesn't inject raw. Within 100-line target. |
| R2-MA6 | mdpal-app | R1-revised | Package-level test fallback is practical | **Agree** | Positive |
| R2-MA7 | mdpal-app | R1-revised | Stage-hash delta tolerance — clean rule | **Agree** | Positive |
| R2-MA8 | mdpal-app | R1-revised | Dispatch authority: review-response too strict | **Autonomous** | Same as R2-DX8. Any agent receiving review can respond. |
| R2-MA9 | mdpal-app | R1-revised | 30-day retention reasonable | **Agree** | Positive |
| R2-MA10 | mdpal-app | R1-revised | Context budget linter + decomposition = enforcement triangle | **Agree** | Positive |
| R2-MA11 | mdpal-app | R1-revised | Day counting — useful velocity signal | **Agree** | Positive |
| R2-MA12 | mdpal-app | R1-revised | PostCompact scope confirmed | **Agree** | Positive |

---

## Totals

| Disposition | Count |
|-------------|-------|
| **Disagree** | 4 |
| **Autonomous** | 46 |
| **Agree (positive)** | 11 |
| **Collaborative (resolved with principal)** | 3 |
| **Total findings** | 64 |

---

## Collaborative Items Resolved with Principal

| Item | Resolution |
|------|-----------|
| WorktreeCreate hook not described in A&D | It's a Claude Code feature detailed in the PVR MARFI findings. A&D references PVR. |
| MAR-always ceremony for trivial artifacts | MAR = pair programming. Many eyes, all bugs are shallow (Linus's Law). Cost is seconds. Captain scales reviewer group. Never skipped. |
| Dispatch-on-commit + /phase-complete duplication | Different mechanisms, different boundaries, different purposes. Coordination vs quality. Defense in depth. Principal: "100% correct." |

## Principal Quotes

- "It is akin to pair programming where someone is looking at things with me. We can do that, so we do it."
- "With many eyes, all bugs are shallow." (Linus's Law)
- "100% correct." — on dispatch-on-commit + /phase-complete serving different purposes
- "No, it isn't [ceremony]. We can knock this out in under 2 hours." — on the full valueflow being lightweight
- "And it doesn't take 10 minutes." — on MAR being seconds, not minutes

## Reviewer Verdicts

| Reviewer | Verdict |
|----------|---------|
| Methodology Critic | Refinements, no blockers |
| Practitioner | Captain mode-switching gap, no blockers |
| Adopter Advocate | Needs "start here" (added), no blockers |
| Lean Analyst | MAR-always justified, improvement loop needs closing metric |
| ISCP | **"This A&D is ready for planning"** |
| monofolk/captain | **"The A&D is ready for planning"** |
| DevEx | "Most gaps are DevEx territory" — ready to fill in own PVR/A&D |
| mdpal-cli | "Solid and grounded, no structural issues" |
| mdpal-app | **"No structural concerns"** |

## Delivery Notes

Local agents (DevEx, mdpal-cli, mdpal-app) were blocked by dispatch identity bugs (agent-identity resolves wrong when agents `cd` to main checkout). ISCP fixed in commit 6647c43 — agents need restart to pick up fix. Workarounds for this round:
- DevEx: review delivered via direct prompt from principal
- mdpal-cli + mdpal-app: reviews committed to mdpal branch, merged to main by captain
- monofolk/captain: collaboration-monofolk repo (no identity bug)

Additional design decisions captured during triage:
- **One agent, one worktree** — many agents per workstream, but each in own worktree
- **Worktree naming: agent name = worktree name** — workstream encoded as prefix (mdpal-cli → mdpal workstream)
- **5-minute dispatch check loop** on all agent startups (`/loop 5m dispatch check`)

## Status

**MAR round 2: COMPLETE. 9 of 9. 64 findings. A&D is ready for implementation planning.**

Session transcript: `usr/jordan/captain/transcripts/session20-continued-20260406-0730.md`
