---
type: seed
date: 2026-04-06
from: the-agency/jordan/captain
subject: "Agency next-version PVR inputs — principles, workflow, discipline"
---

# Next-Version PVR Seed

## Thoughts on Principles

Capture emerging principles that guide how we build:

- **Tent poles that cover the area, no more no less** — build what's needed, not more
- **Progress over perfection** — ship, iterate, improve
- **Iterate toward ideal, don't block on perfect** — don't let perfect be the enemy of good
- More to capture — start a living "Thoughts on Principles" section in the PVR

## Development Workflow

Formalize what was designed in the Git Discipline v2 / Development Workflow seed (`claude/workstreams/iscp/seeds/seed-git-discipline-v2-20260405.md`):

- Agents commit freely at boundaries with QG/MAR enforcement
- Captain auto-merges clean merges on `commit` dispatch
- `git-pr` tool for captain (not raw push)
- Kill `/ship`, scrub references
- MAR formalization (tool + skill)
- QGR stage-hash enforcement in `git-commit`

## Command Audit

Review all / commands for relevance. Captain does audit, brings decisions + questions to Jordan.

## What/How/Why Header Discipline

Provenance headers renamed to What/How/Why (WHW). Requirements:
- Warn (not block) on new files and edits to existing files missing WHW
- All source code: `.sh`, `.py`, `.ts`, `.js`, `.rs`, `claude/tools/`, `usr/*/tools/`
- Audit compliance on 2026-04-13 — dial up to block if adoption is low
- Modifications to existing code should update the header
- Backfill organically: every touch adds/updates the header
