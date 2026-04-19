---
type: break-glass
date: 2026-04-06
agent: the-agency/jordan/captain
access: principal-approved only
---

# Getting to Day 31 — How We Got Here

**DO NOT READ unless your bootstrap handoff is insufficient AND principal has approved.**

Session resume is the final backup if this isn't enough.

---

## Day 30 Summary (2026-04-06)

Captain session 20. Started ~midnight, ran ~20 hours. The session that defined the methodology.

### What Happened (chronological)

1. **ISCP rollout completion** — merged ISCP v1.1 (payload transparency, test isolation, Docker runner). Pushed via PR #37. Monofolk confirmed ISCP adoption via collaboration-monofolk.

2. **Legacy flag triage** — 62 pre-ISCP flags from `flag-queue.jsonl` migrated and triaged. 22 resolved, 16 autonomous (captain works), 18 collaborative (1B1 with Jordan). Three buckets pattern first used here.

3. **Bug fixes** — handoff tool cross-contamination (agent-identity fix), `.git/config` bare=true corruption (BATS tests, happened 4+ times), empty dispatch templates (--body requirement), PR branch identity resolution, worktree identity resolution (CLAUDE_PROJECT_DIR).

4. **DevEx workstream created** — seed written, agent registered, worktree created, dispatched kickoff.

5. **Valueflow defined** — Jordan's Granola transcripts (flag triage workflow, seed-to-delivery lifecycle) became seeds. Ran the full valueflow process on itself:
   - MARFI: 4 research agents (Lean/SAFe/ShapeUp/DORA, AI multi-agent, enforcement ladders, Claude Code features)
   - `/define`: 9-item PVR completeness checklist, 1B1 with Jordan
   - PVR MAR: 2 rounds, 9 reviewers total (4 research + ISCP + DevEx + mdpal-cli + mdpal-app + monofolk)
   - A&D authored: 12 sections covering full methodology
   - A&D MAR: 2 rounds, 9 reviewers, 64 findings, all dispositioned
   - Three "ready for planning" verdicts (ISCP, monofolk, mdpal-app)

6. **Key design decisions** (all with Jordan):
   - Valueflow = TheAgency's AIADLC, rooted in Lean
   - Three-bucket: reviewers review, authors triage (NOT reviewers self-sorting)
   - MAR = pair programming (Linus's Law). Never skipped. Seconds, not hours.
   - Enforcement ladder: document → skill → tool → warn → block. Principal decides transitions.
   - Captain: always-on, first up, last down. V2 = sessions, V3 = daemon.
   - Dispatch payloads: symlinks in `~/.agency/` pointing to git artifacts
   - One agent, one worktree. Workstream name is agent name prefix.
   - Day counting: Day N = Nth day with commits. Day 30 = today.
   - T1 gate: 60s budget (stage-hash + compile + format + fast tests)
   - Dispatch-on-commit additive to /phase-complete (defense in depth)
   - PostCompact: handoff only (CLAUDE.md survives compaction)
   - Effort levels: Anthropic's abstraction, set dial per skill
   - Flag categories: --friction, --idea, --bug (optional enrichment)
   - 5-minute dispatch check loop on all agent startups
   - MARFI: cross-cutting only. Domain research is agent's normal work.
   - MAP: complex cross-workstream only. Single-workstream plans skip MAP.
   - Format on save AND at T1 (belt and suspenders)

7. **Dispatch infrastructure pain** — identity bugs meant local agents couldn't see their own mail. Monofolk responded faster than local agents. Three escalations to ISCP, all fixed. The burning evidence for why DevEx + permission model matters.

8. **Reboot planned and executed** — worktrees split (mdpal → mdpal-cli + mdpal-app), identities fixed, stale dispatches reviewed, registrations updated, handoffs curated.

### Artifacts Produced

| Artifact | Path |
|----------|------|
| Valueflow PVR | `agency/workstreams/agency/valueflow-pvr-20260406.md` |
| Valueflow A&D | `agency/workstreams/agency/valueflow-ad-20260406.md` |
| MAR R1 disposition | `agency/workstreams/agency/reviews/mar-valueflow-ad-round1-20260406.md` |
| MAR R2 disposition | `agency/workstreams/agency/reviews/mar-valueflow-ad-round2-20260406.md` |
| PVR MAR R1 disposition | `agency/workstreams/agency/reviews/mar-valueflow-pvr-round1-20260406.md` |
| MARFI brief | `agency/workstreams/agency/seeds/marfi-valueflow-20260406.md` |
| Valueflow seed | `agency/workstreams/agency/seeds/seed-valueflow-20260406.md` |
| Agency GTM seed | `agency/workstreams/agency/seeds/seed-agency-gtm-20260406.md` |
| Next-version PVR seed | `agency/workstreams/agency/seeds/seed-next-version-pvr-20260406.md` |
| Agency audit seed | `agency/workstreams/agency/seeds/seed-agency-audit-update-20260406.md` |
| Flag triage seed | `agency/workstreams/iscp/seeds/seed-flag-triage-workflow-20260406.md` |
| DevEx kickoff seed | `agency/workstreams/devex/seeds/seed-devex-kickoff-20260406.md` |
| Handoff spec | `claude/docs/HANDOFF-SPEC.md` |
| Friction points | `usr/jordan/captain/friction-points-20260405.md` |
| Legacy flags migrated | `usr/jordan/captain/legacy-flags-migrated-20260406.md` |
| Anthropic issues | `usr/jordan/captain/anthropic-issues-to-file-20260406.md` |
| Reboot plan | `docs/plans/20260406-plan-day-31-reboot-valueflow-v2-planning.md` |

### Transcripts

| Transcript | Path |
|-----------|------|
| Valueflow design session | `usr/jordan/captain/transcripts/valueflow-design-session-20260406-0400.md` |
| Session 20 continued | `usr/jordan/captain/transcripts/session20-continued-20260406-0730.md` |
| Granola: flag triage workflow | `usr/jordan/captain/transcripts/flag-triage-workflow-20260406-0322.md` |
| Granola: valueflow seed-to-delivery | `usr/jordan/captain/transcripts/valueflow-seed-to-delivery-20260406-0322.md` |
| Granola: transcripts strategy | `usr/jordan/captain/transcripts/transcripts-strategy-20260406-0730.md` |
| Granola: handoffs evolution | `usr/jordan/captain/transcripts/handoffs-evolution-20260406-0730.md` |
| AI augmented dev framing | `usr/jordan/captain/transcripts/ai-augmented-dev-framing-20260406-0700.md` |

### PRs Created Day 30

#36, #37, #38, #39, #40, #41, #42 — all merged to main.

### Collaboration-monofolk dispatches

PRs #1-#7 — ISCP adoption ack, valueflow PVR + A&D reviews (rounds 1+2), MAR dispositions.

### ISCP DB State

93 dispatches total, 8 unread (legitimate — agents will see on reboot), rest resolved. All flags processed.
