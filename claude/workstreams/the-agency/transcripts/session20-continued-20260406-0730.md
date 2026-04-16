---
type: transcript
date: 2026-04-06T07:30
source: captain-session-20
topic: valueflow MAR, dispatch architecture, transcripts strategy, handoffs evolution
participants: jordan, captain
status: active
---

## Context

Continuation of session 20. Previous transcript: valueflow-design-session-20260406-0400.md. This picks up from MAR round 2, through dispatch payload architecture, DevEx findings, and Jordan's Granola drops on transcripts and handoffs.

## PVR MAR Round 2

### Agent Reviews Received
- **mdpal-app (#59):** 9 findings. Three-bucket clarification praised. NFR8 "under 2 hours" needs qualifying. FR6 gate scope mechanism unspecified (A&D territory). FR12 rework rate as companion metric. Captain catch-up protocol needed. OQ4 answer: checklist + MAR + principal sign-off.
- **ISCP (#60):** Deep technical. Enforcement ladder ordering: tools before warn (you build the tool, THEN warn about bypassing). Gate scope mechanism options. Stage-hash delta tolerance. Captain batching needs topological ordering. Permission model missing as FR. Dispatch authority enforcement. Error recovery absent.
- **mdpal-cli (#61):** Empty template again — dispatch payload bug.
- **DevEx (#64):** 9 raw findings. FR6 gate scope undefined. Permission model invisible. NFR8 measures wrong thing. C3 causing pain. Test hermiticity missing. Captain recovery undefined. OQ4 should be answered now. FR12 data source underspecified. MARFI should trigger at any stage.
- **monofolk/captain:** Round 1 feedback resolved. New: three-bucket clarification important, FR6 needs specificity, FR9 decomposition by concern, NFR4 multi-part handoffs (ceiling not floor), NFR8 "under 2 hours" ambitious. Missing: compaction strategy, error recovery. Ready for A&D.

### Key Decisions from MAR Triage
- DevEx review misattributed as principal review initially — corrected
- MAR framing fix: reviewers kept self-sorting into buckets despite instructions. Need mechanical enforcement in MAR skill.
- DevEx ignored corrected framing twice — principal had to intervene directly

## ISCP Fixes Merged

Both escalations resolved and merged to main:
- **Escalation #53 (empty templates):** dispatch create now requires --body or --template (opt-in). 163 → 169 tests.
- **Escalation #63 (PR branch identity):** agent-identity resolves captain/* branches as captain. .agency-agent file precedence.
- `.agency-agent` file created on main checkout for captain identity.

## Dispatch Payload Architecture — Design Decision

### The Discussion
Three classes of bugs with payloads in git:
1. Branch transparency — payloads invisible across branches
2. Template confusion — dispatch create wrote templates agents didn't edit
3. Path derivation — PR branches created garbage directories

Captain proposed payloads outside git → principal said NO: actual artifact must be in git.

Principal's key insight: "If the payload is a PVR in the repo, running through valueflow, then it is in git. But we need it accessible."

### The Solution: Symlinks
`~/.agency/{repo}/dispatches/` holds symlinks to actual git artifacts on disk:
- Symlink to main checkout file → works (real directory)
- Symlink to worktree file → works (real directory)
- OS resolves symlinks — no git commands needed for reading
- Artifacts stay in git (C3 holds)
- Branch-transparent by default

Dispatched to ISCP (#71) for design and implementation.

## Valueflow A&D Authored

Full A&D drafted covering 12 sections:
1. Flow stage architecture (inputs, outputs, gates, autonomy per stage)
2. Three-bucket disposition protocol (mechanism, dispatch format)
3. Multi-agent groups (MARFI, MAR, MAP — protocols, composition, V2 vs V3)
4. Enforcement ladder (revised: doc → skill → tool → warn → block)
5. Captain architecture (always-on loop, interactive, catch-up protocol)
6. Quality gate tiers (T1-T4 by boundary type)
7. Context resilience (multi-part handoffs, PostCompact, stage-aware resume)
8. Dispatch payload architecture (symlinks)
9. CLAUDE-THEAGENCY.md decomposition (by concern, context budget)
10. Continual learning (three channels, improvement loop)
11. Error recovery (failure modes, circuit breaker, escalation)
12. V2/V3 boundary

Embedded questions for ISCP and DevEx throughout. Dispatched for MAR (#65-68, collaboration-monofolk PR #5).

## FR13: Continual Learning and Improvement

Added to PVR. Three input channels:
1. Transcript mining — patterns from session transcripts
2. Flag mechanism — categorized: `flag --friction`, `flag --idea`, `flag --bug`
3. Telemetry — _log-helper data, ISCP timestamps, dispatch patterns

The methodology observes its own performance and tightens.

## Content: AI Augmented Development Framing

Jordan's framing: "AI Augmented Development is about building, not coding. In the past humans coded and built. Now it's about building — the coding is handled by agents."

Captured as content seed for X/LinkedIn articles. Plus: four MARFI research papers → short and long articles.

## DevEx PVR Findings — 1B1 (in progress)

9 findings from DevEx. Triaging:
- Finding 1 (FR6 gate scope): A&D answers this — convention-based with manifest fallback
- Finding 2 (permission model): Adding FR14
- Finding 3 (NFR8 measure full stream): In discussion
- Findings 4-9: Autonomous incorporation

## Granola Drops: Transcripts Strategy

### Transcript Types
- **Principal-agent dialogue** — back-and-forth brainstorming, problem-solving
- **Monologue/dictation** — like Granola sessions, generating artifacts on a topic

### Architecture
- Always-on transcripts: continuous capture of agent ↔ user exchanges
- Agent drops block summaries periodically
- Transcripts stored in git; index stored outside git (avoid conflicts)
- Index entries: summary + timestamp covering the time period

### Injection Design
- Transcript injection into handoffs — pull last X transcripts into new sessions
- Enables more frequent compaction without losing context
- Agent-written summaries now; Anthropic API could automate later
- Session resumes become slimmer when transcripts carry the context

## Granola Drops: Handoff Evolution

### Three Handoff Classes
1. **Session handoff** — between sessions (existing)
2. **Agent bootstrap handoff** — captain creates agent on workstream, handoff bootstraps them
3. **Agent project bootstrap handoff** — captain assigns project to existing agent. A "sit rep": everything they need to succeed. Links to transcripts, documents, context.

### Strategic Direction
- Richer bootstrap handoffs → slimmer session resumes
- Handoffs remain core primitive, predating session resume

## PR #40 Created
25 commits packaged: [the-agency-ai/the-agency#40](https://github.com/the-agency-ai/the-agency/pull/40). Full session 20 output.

## Process Notes Captured
- MARFI: principal must review research questions before agents spin up
- MAR: reviewers give raw findings, do NOT self-sort into buckets. Need mechanical enforcement.
- 15-minute dispatch check loop in agent startup sequence
- DevEx is new, hasn't internalized the process — needs documentation + enforcement
