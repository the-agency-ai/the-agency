---
type: transcript
date: 2026-04-06T04:00
source: captain-session-20
topic: valueflow design session — methodology, enforcement, project structure
participants: jordan, captain
status: active
---

## Context

Captain session 20. Started with ISCP rollout completion, legacy flag triage (62 flags → 3 buckets), then evolved into valueflow methodology design. Jordan provided two Granola transcript drops (flag triage workflow, seed-to-delivery lifecycle) which became the foundation for the valueflow seed.

## Key Decisions

### Valueflow naming and framing
- **Valueflow** — the path from a gleam in someone's eye to value customers are using
- Rooted in Lean thinking: everything before delivery is waste
- A seed is as little as a gleam — called "seed" because from it everything grows
- Considered "gleam" as a name for seeds but seed is better — it's what grows

### 5-Stage Enforcement Ladder
Progressive tightening for every capability:
1. **Document** — CLAUDE-THEAGENCY.md + README-THEAGENCY.md. Dispatch to all. "This is the standard."
2. **Skills** — working from docs, no hard enforcement. Skills reference the docs.
3. **Hookify warn** — kittens warnings. Sprinkle these where we don't yet have tooling.
4. **Tools + refined skills** — build and improve. Tighten mechanics.
5. **Hookify block** — hard enforcement. Can't bypass.

Strip kittens warnings when sufficient tooling + enforcement exists. Iterate through the ladder.

### CLAUDE-THEAGENCY.md Decomposition
- Break into composable chunks: `claude/docs/VALUEFLOW.md`, `claude/docs/MAR.md`, etc.
- CLAUDE-THEAGENCY.md `@` imports them all (agents get everything on startup)
- Skills `@` import only what they need (one source of truth, multiple composition points)
- Agent registrations `@` import their relevant pieces
- This decomposition is part of the valueflow project plan

### Multi-Agent Group Types (MARFI/MAR/MAP)
Three distinct multi-agent group types identified:
- **MARFI** (Multi-Agent Request for Information) — research/input group. Feeds material to driving agent before they write. Competitors, implementation approaches, prior art.
- **MAR** (Multi-Agent Review) — review group. Three-bucket feedback (disagree, autonomous, collaborative). Different profiles per artifact type (PBR review ≠ code review ≠ A&D review).
- **MAP** (Multi-Agent Plan) — planning input group. Feeds the plan seed.

Different forms of MARs for different artifact types — each has different flow, different reviewer profiles, different dimensions.

### Three-Bucket Pattern
Recurs everywhere in valueflow:
1. Disagree / Resolved — agent decides, principal reviews
2. Autonomous — agent acts, principal informed
3. Collaborative — requires 1B1 discussion

Appears in: MAR disposition, flag triage, dispatch handling, plan review.

### Project-within-Workstream Convention
- A workstream is long-lived, projects come and go within it
- Valueflow is a project within the agency workstream
- Namespace by convention for now: `valueflow-pvr-20260406.md`
- Formalize `/project-create` later — note taken, to be built and enforced

### What/How/Why Headers (WHW)
- Renamed from "provenance headers"
- Warn level (not block) for now
- Applies to ALL source code, new files AND modifications
- Audit compliance 2026-04-13 — dial up if adoption is low
- Backfill organically: every touch adds/updates the header

### Captain Loop
- Captain on a cadence: fetch origin, scan dispatches, process commits, build PRs
- Batch commits: process all before syncing to worktrees
- Currently running as hourly check in session — formalize as part of captain's role

### `/seed` Skill
- Gap identified: we keep doing seed synthesis manually
- `/seed` gathers all seed files, transcripts, flags, dispatches for a topic
- Synthesizes into a seed brief — themes, scope, gaps
- Identifies what needs MARFI
- Flow becomes: `/seed` → (optional MARFI) → `/define` → MAR → `/design` → MAR → plan → implement

### Granola Transcript Convention
- Capture both summary + raw transcript in `transcripts/`
- Named with date+time stamp
- If revisiting a topic, add another transcript
- Summaries are ~85-90% sufficient for seed creation
- Transcripts needed for: reasoning depth, exact phrasing, vision/intent, ambiguity resolution
- Both go into content pipeline for articles/book

## Items Mapped to Pending Work

| Item | Disposition | Agent |
|------|-------------|-------|
| Development Workflow seed | Merge into valueflow seed | Captain |
| MAR formalization | Document first, then enforcement ladder | Captain |
| `git-pr` tool | Document first, then enforcement ladder | Captain + DevEx |
| Captain loop | Document, formalize in registration | Captain |
| Flag triage skill | Dispatched to ISCP (#33), acknowledged (#35) | ISCP |
| QGR stage-hash enforcement | Part of valueflow commit flow | Captain + DevEx |

## Open Items

- When do projects get their own home? (Jordan: "when we get to projects, they will have their own home and all materials captured there")
- MARFI design — what agents compose the research group, how invoked
- MAR reviewer profiles per artifact type
- `/seed` skill design
- `/project-create` tool (deferred — convention for now)
- CLAUDE-THEAGENCY.md decomposition plan

## Resolved During Session

- Legacy 62 flags triaged (22 resolved, 16 autonomous, 18 collaborative)
- Handoff cross-contamination bug fixed (agent-identity in handoff tool)
- ISCP v1.1 merged (payload transparency, test isolation, Docker runner)
- DevEx workstream created and spun up
- Monofolk ISCP adoption acknowledged
- Settings-template permissions fixed
- WHW hookify warn rule created
- Anthropic issues list written (4 bugs)
- Valueflow seed written
- Agency GTM seed written
- Flag triage seed written and dispatched to ISCP
