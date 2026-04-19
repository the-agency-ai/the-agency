# Workstream Content Split — Shared vs Personal

> If the artifact is about the workstream, it lives in the workstream.
> If the artifact is about the agent's personal state, it lives in the agent's sandbox.

**Litmus test:** if a second principal joined this workstream tomorrow, would they need to read `usr/{P}/{A}/` to understand the workstream? If yes, those artifacts belong in `claude/workstreams/{W}/`.

## Variables

| Variable | Meaning | Example |
|---|---|---|
| `{P}` | **Principal** — the human | `jordan`, `peter` |
| `{A}` | **Agent** — principal-owned instance | `captain`, `folio`, `of-mobile` |
| `{W}` | **Workstream** — the shared work domain | `folio`, `of-mobile`, `monofolk` |

## Shared Workstream — `agency/workstreams/{W}/`

Visible to every principal's agent working this workstream.

```
agency/workstreams/{W}/
  CLAUDE-{W}.md                          # workstream CLAUDE.md
  KNOWLEDGE.md                           # accumulated patterns + decisions
  pvr-{W}-{slug}-{YYYYMMDD}.md           # current PVR(s) — flat at root
  ad-{W}-{slug}-{YYYYMMDD}.md            # current A&D(s) — flat at root
  plan-{W}-{slug}-{YYYYMMDD}.md          # current plan(s) — flat at root
  seed-{W}-{topic}-{YYYYMMDD}.md         # seed proposals — flat at root
  qgr/                                   # quality gate receipts
  rgr/                                   # release gate receipts
  drafts/{P}-{A}/                        # WIP before ratification
  research/                              # MARFI outputs, investigations
  transcripts/                           # 1B1 records, summaries, verbatim
  history/                               # superseded current versions
  history/flotsam/                       # uncategorized archive
```

Current versions at root, accumulation in subdirs.

## Personal State — `usr/{P}/{A}/`

Only this agent instance's working state.

```
usr/{P}/{A}/
  {A}-handoff.md                         # session handoff
  CLAUDE-{A}.md                          # personal overlay on class doc
  tmp/                                   # scratch (gitignored)
  tools/                                 # personal scripts
  history/                               # personal archive
  history/flotsam/                       # uncategorized personal items
```

Nothing about the workstream's shared knowledge lives here.

## Agent Registrations — `.claude/agents/{P}/{A}.md`

Principal-scoped. Invocation: `claude --agent {P}/{A}` (e.g., `claude --agent jordan/captain`).

Each registration contains:
- `@import` of class doc: `@agency/agents/{class}/agent.md`
- `@import` of workstream CLAUDE: `@agency/workstreams/{W}/CLAUDE-{W}.md`
- `@import` of personal overlay: `@usr/{P}/{A}/CLAUDE-{A}.md`
- Startup steps (handoff read, dispatch check)

## Receipt Naming

`{org}-{principal}-{agent}-{workstream}-{project}-{type}-{boundary}-{YYYYMMDD-HHMM}-{hash_e_short}.md`

Written to `agency/workstreams/{W}/qgr/` or `agency/workstreams/{W}/rgr/`.

## Draft → Ratified Flow

1. Draft at `agency/workstreams/{W}/drafts/{P}-{A}/{type}-draft-{W}-{slug}-{YYYYMMDD}.md`
2. 1B1 review or principal approval
3. Move to workstream root (drops `{P}-{A}` attribution — now shared canon)
4. Superseded versions → `history/`

## Repo-Level Workstream

Every repo has one, owned by captain: `agency/workstreams/{repo-name}/`. Cross-cutting plans, research, transcripts, receipts.

## Frontmatter

Every shared artifact:

```yaml
---
type: pvr
workstream: folio
project: folio-cms
principal: jordan
agent: monofolk/jordan/folio
date: 2026-04-16
---
```

## Related

- Issue #121 — original proposal
- Issue #130 — `git-safe mv` (migration prerequisite)
- `agency/REFERENCE-RECEIPT-INFRASTRUCTURE.md` — five-hash chain details
- `agency/REFERENCE-REPO-STRUCTURE.md` — full directory tree
