---
type: mar
project: valueflow
artifact: valueflow-ad-20260406.md
round: 1
date: 2026-04-06
author: the-agency/jordan/captain
reviewers:
  - the-agency/jordan/mdpal-app (dispatch #68 → #70)
  - the-agency/jordan/iscp (dispatch #65 → #72)
  - monofolk/jordan/captain (collaboration-monofolk)
  - the-agency/jordan/mdpal-cli (dispatch #67 → #73)
  - the-agency/jordan/devex (dispatch #66 → not received)
---

# MAR Round 1: Valueflow A&D

50 findings from 4 reviewers + 4 embedded Q&A responses. DevEx did not deliver.

## Embedded Questions — Answers Received

| Q | Section | Answered by | Response | Disposition |
|---|---------|-------------|----------|-------------|
| MAR triage: schema or free-form? | §2 | ISCP | Free-form V2, structured schema V3. Add YAML frontmatter for metrics. | **Accept** — right call, enough structure for FR12 without constraining |
| MARFI: dispatches or subagents? | §3 | ISCP | Subagents V2, dispatches V3. Write output to seeds/ for durability. | **Accept** — simpler, cheaper, durable via file output |
| Commit dispatch carry stage-hash? | §5 | ISCP | Yes. Structured YAML: commit_hash, stage_hash, branch, phase, iteration, files_changed. | **Accept** — machine-consumed by captain merge, structured from day one |
| Dispatch payload migration? | §8 | ISCP | Superseded by symlink directive #71. Implemented in 1e610fd. | **Done** — symlinks implemented, 173 tests passing |
| Changed-file test mapping? | §6 | monofolk | Convention-based (option 1). Already implicit. | **Accept** — zero-config default |
| Stage-hash semantic diff? | §6 | monofolk | Linter's changed-file detection. Only .md → skip. Any code → re-run. | **Accept** — simpler heuristic |
| Context budget linter? | §9 | monofolk | Yes, build it. DevEx tool. Warn at 4000 tokens. | **Accept** — V2 deliverable |
| Enforcement registry? | §4 | monofolk | YAML manifest + audit tool. | **Accept** |
| Captain loop cadence? | §5 | monofolk + mdpal-cli | Fixed interval V2 (/loop 5m dispatch check). Event-driven V3. | **Accept** — close OQ7 |
| Compaction strategy? | §7 | monofolk | Auto at 80% context. PreCompact writes handoff. | **Accept** — if we have control; handle gracefully if not |

## Bucket 1: Disagree (4 items)

| ID | Source | Finding | Reasoning |
|----|--------|---------|-----------|
| D1 | ISCP §10 | Flag categories at triage not capture — don't burden capture moment | **Disagree.** `--friction` costs 1 word at capture and routes instantly. Deferring to triage means undifferentiated pile. Capture IS routing. |
| D2 | mdpal-cli #3 | Dispatch payload migration risky, fix read path instead of moving storage | **Disagree — superseded.** Principal decided symlinks. ISCP implemented (#74, commit 1e610fd). The read path IS fixed — via symlinks. |
| D3 | monofolk OQ1 | Schema-validated MAR because health metrics need structured data | **Disagree.** Agree with ISCP: free-form V2 with YAML frontmatter is enough for metrics. Full schema is premature — we don't have enough triage cycles to know the right schema. |
| D4 | monofolk #17 | V2 includes platform-dependent features (conditional `if:` on hooks, PermissionDenied) — should be V3 | **Disagree.** These are Claude Code features that exist NOW in the current release. `if:` is documented in hooks spec. `PermissionDenied` hook is in the events list. Not hypothetical. |

## Bucket 2: Autonomous — Incorporating (28 items)

| ID | Source | Finding | Action |
|----|--------|---------|--------|
| A1 | mdpal-app #2 | No timeout for unanswered cross-workstream RFI | Add to §3: 24h auto-proceed with available input + flag missing responders |
| A2 | mdpal-app #5 | Schema for triage response, free-form for review input | Specify in §2: review input = free-form markdown, triage response = structured tables + YAML frontmatter |
| A3 | mdpal-app #8 | PostCompact context budget unmeasured at hook time | Note in §7: minimal injection by default, full if budget allows. DevEx builds measurement. |
| A4 | mdpal-app #9 | 2000-token budget per doc is too aggressive | Change in §9: budget per skill injection (4000 total), not per document. Doc can be 3000 if skill adds 1000. |
| A5 | mdpal-app #11 | MAR dispatches should specify reviewer focus | Add to §3 MAR protocol: dispatch includes "review from perspective of: {focus area}" |
| A6 | ISCP #1 | Dispatch payloads in artifact taxonomy say "TBD (see §8)" | Update §1 artifact table: dispatch payloads at `~/.agency/{repo}/dispatches/` (symlinks to git artifacts) |
| A7 | ISCP #2 | Enforcement registry drifts without audit tool | Note in §4: audit tool is load-bearing dependency. DevEx must build alongside registry. No registry without auditor. |
| A8 | ISCP #6 | Stage-hash delta: single markdown file → allow with warning, simpler than "non-code" | Adopt in §6: if delta is single .md file → allow with warning. Any other change → re-run. Simpler, less ambiguous. |
| A9 | ISCP #7 | PostCompact should also inject agent's scoped CLAUDE.md | Add to §7 PostCompact injection: Identity + State + Next Action + scoped CLAUDE.md (agent registration's @ imports) |
| A10 | ISCP #10 | V2 list should include symlink implementation (not V3) | Update §12: move "dispatch payloads symlinks" from V3 to V2 as delivered |
| A11 | ISCP #11 | No DB schema versioning strategy | Add to §8: version column in ISCP DB, checked on every init. Migration tool handles version transitions. |
| A12 | ISCP #12 | Dispatch authority not tied to enforcement ladder level | Add to §8: dispatch authority at enforcement ladder level 3 (tool enforcement) from day one. Dispatch tool rejects unauthorized types. |
| A13 | ISCP #13 | No dispatch TTL/cleanup policy | Add to §8: retention policy — archive resolved dispatches after 30 days. Symlinks cleaned when payload archived. |
| A14 | monofolk #2 | Naming convention should allow sub-project qualifiers | Update §1 artifact table: `{project}[-{subproject}]-pvr-{YYYYMMDD}.md` |
| A15 | monofolk #4 | MAR "N agents" should be "N relevant agents" with selection criteria | Update §3 MAR protocol: explicit selection criteria, not broadcast. Captain selects relevant agents per artifact scope. |
| A16 | monofolk #5 | MAR deadlines for dormant agents: 24h auto-proceed | Add to §3 MAR protocol: 24h timeout, proceed with available reviews, flag missing reviewers for information. |
| A17 | monofolk #10 | Convention-based test mapping confirmed for multi-framework repos | Confirm in §6: convention-based as default, "all tests in affected package" as package-level fallback |
| A18 | monofolk #13 | Local vs cross-repo dispatch distinction needed | Add to §8: local dispatches = DB + symlinks. Cross-repo dispatches = git-only via collaboration repos. Different mechanisms, same addressing. |
| A19 | monofolk #15 | Transcript mining needs token budget limit | Add to §10: budget cap per mining run, prioritize recent sessions, limit to last N days |
| A20 | monofolk #16 | Circuit breaker N should be configurable per workstream, default 5 | Update §11: configurable per workstream. Research/design may have long iterations. |
| A21 | mdpal-cli #1 | Gate tiers assume language-specific tooling (Swift has no standard linter) | Generalize §6 T1: "stage-hash match + compile/build" as universal baseline. Format/lint optional per language toolchain. |
| A22 | mdpal-cli #2 | Changed-file scoping needs simpler default for non-mirrored layouts | Add to §6: package-level fallback — "anything in `apps/mdpal/Sources/` changed → run tests in `apps/mdpal/`" |
| A23 | mdpal-cli #5 | MARFI boundary fuzzy — need concrete decision rule | Add to §3: "MARFI = questions answerable with web search + reading docs. Domain research = questions requiring project context and design decisions." |
| A24 | mdpal-cli #7 | Circuit breaker should be time-based not attempt-based | Change §11: "no progress in N hours" not "N failed attempts." Agent self-reports: stuck vs making progress on distinct findings. |
| A25 | mdpal-cli #8 | Context budget linter must ship with decomposition | Move from question to §12 V2 deliverables: linter ships alongside CLAUDE-THEAGENCY.md decomposition |
| A26 | mdpal-cli #9 | Captain loop cadence is not an open question | Close OQ7: fixed interval V2 (`/loop 5m dispatch check`), event-driven V3 |
| A27 | ISCP Q&A | MARFI subagents persist output to seeds/ for durability | Add to §3 MARFI protocol: subagents write output to `claude/workstreams/{ws}/seeds/marfi-{agent}-{date}.md` before returning |
| A28 | ISCP Q&A | Commit dispatch structured YAML frontmatter | Add to §5: commit dispatch payload format — YAML with commit_hash, stage_hash, branch, phase, iteration, files_changed |

## Bucket 3: Collaborative — Need Principal Input (8 items)

| ID | Source | Finding | Question for Principal |
|----|--------|---------|----------------------|
| C1 | mdpal-app #3 | T1 should include fast unit tests, not just lint | **RESOLVED:** T1 = stage-hash + build/compile + format + relevant fast tests, **60 second budget**. Format runs on save AND at T1 (belt and suspenders). 60s is generous for iteration complete — agents don't get impatient. If tests exceed 60s, test scoping needs improvement. |
| C2 | monofolk #3 | Autonomous stages + principal review in §2 contradict | **RESOLVED:** Autonomous stages: agent triages MAR feedback and acts without presenting to principal. Sends informational dispatch with bucket disposition — "here's what came in, here's what I did." Principal sees it on next check-in (MDPal panel). Scope-definition stages (PVR, A&D, master plan): full present-and-discuss flow. |
| C3 | monofolk #9 | Commit processing: additive to /phase-complete or replacement? | **RESOLVED:** Additive, not replacement. Defense in depth. Dispatch-on-commit fires on every iteration commit (captain notified, merges, syncs). /phase-complete handles phase boundary (squash merge, deep QG, PR). Two mechanisms for two boundaries. Multiple layers catch what individual layers miss. |
| C4 | mdpal-cli #4 | Captain explicitly session-scoped for V2 — conflicts with "always-on" | **RESOLVED:** Captain is always-on by design — first up, last down. If any agent is running, captain is running. Principal brings captain up first, puts captain to bed last, then principal goes to bed. V2 mechanism is interactive sessions. V3 adds headless daemon (`--bare -p`). Between sessions dispatches queue — no work lost. Not session-scoped — always-on in intent, session-based in V2 mechanism. |
| C5 | mdpal-cli #6 | `effort:` levels — what do they actually control? | **RESOLVED:** Effort is Anthropic's abstraction over token budget — it tunes model behavior, context usage, depth of reasoning behind the scenes. We don't control the levers individually, we set the dial per skill. Low = fast and cheap. High = deep and thorough. `/dispatch-read` = low, `/quality-gate` = high. Don't define internals — Anthropic manages that. |
| C6 | ISCP #3 | Per-workstream enforcement transition: who decides level changes? | **RESOLVED:** Principal decides. DRI is the principal. Audit tool informs, agents recommend, captain presents — but the principal makes the call. For TheAgency framework itself, Jordan is the DRI. Other principals decide for their own repos. No automatic transitions. |
| C7 | monofolk OQ8 | Compaction at 80%: auto or manual? | **RESOLVED:** We don't control compaction timing — Claude Code fires it around 80% context used (20% remaining). We control recovery. PostCompact hook re-injects handoff. Transcripts provide depth. Multi-part handoffs provide structure. Intra-session handoffs are insurance checkpoints. The better the handoff, the less compaction matters. |
| C8 | ISCP #7 + mdpal-app #8 | PostCompact injection scope: minimal or full? | **RESOLVED:** PostCompact injects the handoff only. CLAUDE.md survives compaction — it's system-level context that Claude Code preserves. The handoff provides session-specific context that was compressed. Keep handoffs tight, CLAUDE.md light. The decomposition of CLAUDE-THEAGENCY.md into composable chunks saves context budget for handoff injection and actual work. |

## Reviewer Summary

| Reviewer | Findings | Agree (positive) | Disagree (by me) | Autonomous | Collaborative → Resolved |
|----------|----------|-------------------|-------------------|------------|--------------------------|
| mdpal-app | 11 | 6 | 0 | 5 (A1-A5) | 1 (C1) → resolved |
| ISCP | 12 + 4 Q&A | 1 | 1 (D1) | 11 (A6-A13, A27-A28) | 2 (C6, C8) → resolved |
| monofolk | 18 + 8 OQ answers | 5 | 2 (D3, D4) | 7 (A14-A20) | 3 (C2, C3, C7) → resolved |
| mdpal-cli | 9 | 4 | 1 (D2) | 5 (A21-A26) | 2 (C4, C5) → resolved |
| DevEx | — | — | — | — | NOT RECEIVED |
| **Totals** | **50 + 12** | **16** | **4** | **28** | **8 → all resolved** |

## Collaborative Resolution Transcript

Decisions made via 1B1 with principal (Jordan) during captain session 20 (Day 30).
Full transcript: `usr/jordan/captain/transcripts/session20-continued-20260406-0730.md`

## Additional Design Decisions from Session (post-MAR)

These emerged during the 1B1 triage and are captured here for completeness:

| Decision | Context |
|----------|---------|
| **Day counting convention** | Count days with commits per repo and per workstream. Day 30 for the-agency. "Day 12 of valueflow for mdpal." Proposed as Agency model. |
| **Dispatch check loop: 5 minutes** | All agents set `/loop 5m dispatch check` on startup. `dispatch check` (not `dispatch list`) — silent when empty. |
| **ISCP tip: `dispatch check`** | Use for silent polling, `dispatch list` for interactive inspection. From ISCP dispatch #75. |
| **Captain order: first up, last down** | Principal wakes → captain up → agents up → work → agents down → captain down → principal sleeps. |
| **CLAUDE.md three-level hierarchy** | CLAUDE-THEAGENCY.md (methodology) → CLAUDE-{WORKSTREAM}.md (workstream) → CLAUDE-{APP}.md (application/service). V3: fragment registry + autonomous generation tooling. |
| **Dispatch payload symlinks** | `~/.agency/{repo}/dispatches/` holds symlinks to git artifacts. ISCP implemented in 1e610fd (dispatch #74). Merge pending. |
| **AI Augmented Development framing** | "About building, not coding." Content seed for X/LinkedIn articles. Four MARFI papers → short + long articles. |
| **Format on save AND at T1** | Belt and suspenders. Format on write prevents dirty diffs, T1 confirms at commit. Both cheap. |
| **Defense in depth** | Multiple layers of gates (iteration, phase, PR). Each catches what the previous missed. Additive, not replacement. Reference: Jordan's 2007 lightning talk at Google Quality Conference, London. |

## Resolution Dispatches Sent

| Agent | Dispatch ID | Status |
|-------|-------------|--------|
| ISCP | #82 | Sent |
| mdpal-app | #83 | Sent |
| mdpal-cli | #84 | Sent |
| monofolk/captain | collaboration-monofolk PR #6 | Pending merge |

## Not Received

DevEx (dispatch #66, nudged #80) — no A&D review delivered. Will incorporate when/if received. Not blocking revision.

## Status

**MAR round 1: COMPLETE.** All findings dispositioned. All collaborative items resolved. A&D revision pending (action 2). Will be followed by MAR round 2 with both research subagents and agent dispatches.
