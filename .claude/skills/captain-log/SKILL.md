---
description: Append to or read the captain's narrative log — decisions, friction, learning, milestones
---

<!--
  Flag #62/#63: allowed-tools removed. Inherits Bash(*) from
  .claude/settings.json. Restricting to specific subcommand patterns at the
  skill level silently blocks agents on permission prompts the agent cannot
  see — see dispatch #171 for the devex incident that surfaced this trap.
-->

# Captain's Log

The captain's log is the **narrative thread** of a session. Different from handoffs (current state), transcripts (full conversation), and flags (quick observations) — the log captures *what we discovered, what we built, what we decided* as a rolling daily record.

## Arguments

- `$ARGUMENTS`: One of:
  - Free text — appended as an `observation` entry
  - `-c <category> <text>` or `--category <category> <text>` — appended with that category
  - `read [YYYYMMDD]` — read today's log or a specific day
  - `list` — list all log files
  - `path` — print the current day's log file path

## Categories

- `decision` — a decision was made (with reasoning)
- `friction` — friction encountered during work
- `learning` — something learned about the framework, codebase, or process
- `milestone` — significant progress, completion, or shipping
- `observation` — general note (default)
- `build` — built a tool, skill, hookify rule, or process

## When to Log

Log proactively as you work:

- **When a decision is made** that future sessions need to know about
- **When friction is hit** — it's a candidate for the next toolification cycle
- **When you build something** — capture the "why" alongside the "what"
- **At milestones** — phase complete, plan complete, release shipped
- **When you learn something** — about the codebase, the methodology, or the principal's preferences

The log is mined later for patterns, friction analysis, and continual improvement. The richer the log, the more useful the mining.

## Examples

```bash
# Quick observation (default category)
./agency/tools/captain-log "noticed agents kept cd-ing to main checkout"

# Friction with category
./agency/tools/captain-log -c friction "permission prompt for chmod blocked agent boot"

# Decision
./agency/tools/captain-log -c decision "QGRs go in workstream/quality-gate-reports/, not usr/"

# Build
./agency/tools/captain-log -c build "shipped /collaborate skill + collaboration tool + hookify warn"

# Read today's log
./agency/tools/captain-log read

# Read a specific day
./agency/tools/captain-log read 20260406
```

## Storage

Daily files at `usr/{principal}/captain/logs/captains-log-{YYYYMMDD}.md`. Append-only with timestamps. Format:

```markdown
---
type: captains-log
date: 2026-04-07
agent: jordan/captain
---

# Captain's Log — Tuesday, April 7, 2026

## 13:28:28 — milestone

Captain's log tool shipped — formalizing the narrative thread pattern.

## 13:42:11 — friction

permission prompt for chmod blocked agent boot
```

## Workflow

1. **As work happens:** call `captain-log` with the observation
2. **At session end:** review the day's log via `captain-log read`
3. **At week end:** mine the logs for patterns (friction → seeds for tooling)
4. **Across sessions:** read previous days' logs as context for the current session

The log is the narrative the framework writes about itself.

*OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*
