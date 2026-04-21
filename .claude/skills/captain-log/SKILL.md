---
name: captain-log
description: Append to or read the captain's narrative log — decisions, friction, learning, milestones, observations, builds.
agency-skill-version: 2
when_to_use: "Capturing the narrative thread of a session as work happens — decisions made, friction hit, things learned, milestones reached, tools built — or reading back the day's entries. Anti-triggers: do NOT use for session pickup context (use /handoff — handoffs are authoritative state, logs are narrative); do NOT use for ephemeral observations that need routing (use /flag — flags are a queue, logs are append-only history); do NOT use as a transcript (use /transcript — transcripts are full dialogue, logs are curated narrative)."
argument-hint: "[entry text | -c <category> <text> | read [YYYYMMDD] | list | path]"
paths: []
required_reading:
  - agency/REFERENCE-AGENT-DISCIPLINE.md
---

<!--
  Flag #62/#63: allowed-tools removed. Inherits Bash(*) from
  .claude/settings.json. Restricting to specific subcommand patterns at the
  skill level silently blocks agents on permission prompts the agent cannot
  see — see dispatch #171 for the devex incident that surfaced this trap.
-->

# Captain's Log

The captain's log is the **narrative thread** of a session. Distinct from handoffs (authoritative current state), transcripts (full dialogue), and flags (ephemeral observation queue) — the log captures *what we discovered, what we built, what we decided* as a rolling daily record. Append-only. Mined later for friction patterns and continual improvement.

## Why this exists

Sessions lose their "why" the moment context compacts or the agent ends. Handoffs carry state; transcripts carry dialogue; flags carry open items. None of them carry the **narrative** — the decisions made, the friction hit, the things built, the things learned — in a form that accumulates across sessions and can be mined for patterns.

The log fills that gap:

- A **decision** entry lets future sessions see not just *what* was decided but that it was decided (and when).
- A **friction** entry is a seed for the next toolification cycle — friction is the raw material for framework evolution.
- A **build** entry pairs the "what" (a tool, skill, or rule shipped) with the "why" — rescuing intent that would otherwise evaporate.
- A **learning** entry captures surprises about the codebase, methodology, or principal's preferences for later sessions.
- A **milestone** entry marks significant progress — phase complete, plan complete, release shipped.

The richer the log, the more useful the mining. Log proactively; don't batch.

## Required reading

Before running, Read the files listed in `required_reading:` frontmatter.

- `agency/REFERENCE-AGENT-DISCIPLINE.md` — Two Priorities + Over/Over-and-out. The log is a working-session practice; it sits inside the agent-discipline frame.

## Usage

```
/captain-log <free text>                       # appended as observation (default)
/captain-log -c <category> <text>              # appended with category
/captain-log --category <category> <text>      # long form
/captain-log read                              # read today's log
/captain-log read YYYYMMDD                     # read a specific day
/captain-log list                              # list all log files
/captain-log path                              # print today's log file path
```

Categories: `decision`, `friction`, `learning`, `milestone`, `observation` (default), `build`.

Examples:

```bash
./agency/tools/captain-log "noticed agents kept cd-ing to main checkout"
./agency/tools/captain-log -c friction "permission prompt for chmod blocked agent boot"
./agency/tools/captain-log -c decision "QGRs go in workstream/quality-gate-reports/, not usr/"
./agency/tools/captain-log -c build "shipped /collaborate skill + tool + hookify warn"
./agency/tools/captain-log read
./agency/tools/captain-log read 20260406
```

## Preconditions

1. You are in a git repository with the agency tooling installed.
2. Your principal sandbox exists at `usr/{principal}/captain/` — the tool writes daily log files beneath it.
3. For a write, you know which category best fits the entry (default is `observation` if unsure).
4. For a read (`read [YYYYMMDD]`), the target day's file must exist — otherwise the tool reports "no log for that day."

The skill is **append-only** on writes and read-only on reads. Writes never rewrite earlier entries; running twice produces two entries.

## Flow / Steps

### Step 1: Decide write vs read

- If you just made a decision, hit friction, built something, learned something, reached a milestone, or want to capture a general observation — proceed as a **write**.
- If you want to review the narrative of the current day or a past day, or enumerate the corpus — proceed as a **read** (`read`, `read YYYYMMDD`, `list`, or `path`).

### Step 2a: Write an entry

Invoke the tool with the entry text. Choose the category deliberately — the category is what makes the log mineable later:

```
./agency/tools/captain-log -c <category> "<entry text>"
```

- Use `-c observation` (or omit `-c`) for general notes that don't fit another bucket.
- Use `-c decision` when the entry is "we chose X over Y because Z" — future sessions read this to understand why the codebase looks the way it does.
- Use `-c friction` when something got in the way — this is a toolification seed.
- Use `-c learning` when you learned something non-obvious — about the codebase, methodology, or principal preferences.
- Use `-c milestone` for significant progress — phase complete, plan delivered, release shipped.
- Use `-c build` when you shipped a tool, skill, hookify rule, or process change — pair "what" with "why."

The tool appends to today's file at `usr/{principal}/captain/logs/captains-log-{YYYYMMDD}.md` with an `HH:MM:SS — category` heading plus the entry body.

### Step 2b: Read entries

- `read` — read today's log.
- `read YYYYMMDD` — read a specific day's log.
- `list` — enumerate all log files.
- `path` — print today's log file path (for scripting or piping into another tool).

### Step 3: Proceed with work

The log is a **side-channel** practice — it never blocks the work. Capture the entry, keep moving. The mining step happens later, at week-end or when friction patterns are being reviewed.

## Failure modes

- **Principal sandbox missing**: tool errors with a path-not-found on `usr/{principal}/captain/logs/`. Run `/sandbox-init` or create the directory.
- **Read for a day with no entries**: tool reports "no log for that day" and exits non-zero. Confirm the date or use `list` to see what exists.
- **Entry text contains shell metacharacters**: quote the argument so the shell passes it intact. Unquoted entries with `&`, `|`, `;`, or `*` will lose content.
- **Wrong category**: log is append-only — there is no edit-in-place. File a new entry with a correction note, or leave it and move on (the mining step handles noise).
- **Tool output suggests a bug**: do not fix it here — report it via `/flag` or `/agency-issue` per `agency/REFERENCE-AGENT-DISCIPLINE.md`.

## What this does NOT do

- **Does not replace handoffs.** Handoffs carry authoritative pickup state; logs carry narrative. A fresh session reads the handoff first, the log for color.
- **Does not replace transcripts.** Transcripts capture the full dialogue of a conversation; the log is curated narrative, not verbatim.
- **Does not replace flags.** Flags are a queue for open items; log entries are closed observations about work that already happened.
- **Does not commit the log.** The tool writes files; commit them via `/coord-commit` or the session-lifecycle skills like any other coord artifact.
- **Does not dispatch, QG, or push.** All three are out of scope — this is a single-agent journaling practice.
- **Does not mine the log.** Mining (extracting friction patterns, building toolification seeds) is a separate, later step — the log is the raw material, not the analysis.

## Status

`active` (v2 migrated from v1 in monofolk V1→V2 migration). Stable surface; the underlying tool at `agency/tools/captain-log` has the same CLI it did pre-migration.

## Related

- `/handoff` — authoritative session pickup state; reads first, log reads for color.
- `/flag` — ephemeral observation queue; route to discussion, log if the observation is closed.
- `/transcript` — full dialogue capture; log is curated narrative, not verbatim.
- `/dispatch` — cross-agent coordination; log captures local narrative, dispatches carry cross-agent findings.
- `agency/tools/captain-log` — the underlying tool this skill invokes.

*OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*
