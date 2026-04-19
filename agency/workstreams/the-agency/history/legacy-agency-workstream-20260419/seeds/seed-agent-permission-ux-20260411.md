---
type: seed
workstream: agency
date: 2026-04-11
captured_by: the-agency/jordan/captain
principal: jordan
status: draft-pending-filing
report: usr/jordan/reports/report-feedback-agent-permission-ux-20260411.md
source: usr/jordan/captain/anthropic-issues-to-file-20260406.md (items 2 + extension)
---

# Seed: Agent permission model needs "trusted framework paths" for autonomous agents

## What this is

A feature request / UX report to file with Anthropic about Claude Code's permission system as it applies to **autonomous agents running inside a framework** — the use case we're building with `the-agency`.

Claude Code's permission model is designed around interactive human-in-the-loop sessions: when an unfamiliar command or path appears, the user sees a prompt and decides whether to allow it. That works for a human developer at a terminal. It breaks for autonomous agents that run operationally: polling queues, reading handoffs, checking flags, running framework tools. Most of these operations are read-only and touch a small, predictable set of framework paths — and yet each unseen agent hits permission prompts that it cannot answer.

This report folds in the previously-tracked separate issue about **brace expansion triggering permission prompts** (originally item 2 of `anthropic-issues-to-file-20260406.md`) because it's the same root cause: the permission model parser doesn't have enough context to distinguish "this is a trusted framework operation" from "this is an unfamiliar command."

## The gap (short version)

For autonomous agents operating inside a framework:

- **No concept of "trusted framework paths"** — we can't say "any read operation on `~/.agency/` is auto-approved."
- **Permission grammar is command-oriented, not path-oriented** — hard to express "read is OK on this path, regardless of which command performs the read."
- **Permission changes require session restart** — an autonomous agent can't restart itself in place, losing conversation context.
- **Permission prompts are invisible to autonomous agents** — they go to a terminal buffer the agent can't read, so the agent appears to hang with no visible signal.
- **Parser surprises** — brace expansion (`mkdir -p {a,b,c}`) triggers compound-command handling even when `mkdir` is individually allowed. Compound command patterns (`cmd1 && cmd2`) also trip extra prompts.

Adding entries to `settings.json` helps somewhat, but it doesn't scale to the autonomous-agent use case because:
1. The `settings.json` grammar is command-level, not path-level
2. Changes don't take effect without a restart
3. Every new edge case adds entries and the list grows unbounded
4. The parser has surprises that can't be predicted in advance

## Related Agency work

- **ISCP workstream buildout** — the original flags (`#1`, `#2`, `#3` in the captain's queue) all came from trying to run the ISCP agent autonomously. The agent blocked on `ls ~/.agency/`, `git -C worktree show HEAD -- file`, and `sqlite3 ~/.agency/iscp.db "SELECT ..."` — all routine framework operations.
- **Brace expansion bug** — originally tracked separately in `anthropic-issues-to-file-20260406.md` item 2. Same root cause family. Folding into this filing.
- **`block-raw-tools` hookify rule** — we built a PreToolUse hook that blocks raw `cat`, `grep`, `find`, etc., forcing agents to use framework tools instead. This is a *workaround* for the permission model, not a replacement.
- **`dispatch-monitor` tool** — we built a silent-polling tool running under the Claude Code `Monitor` tool specifically so agents could poll dispatch queues without triggering permission prompts every 10 seconds. Another workaround.
- **`agent-identity` tool** — reads a project-local `.agency-agent` file to resolve agent identity, because `$CLAUDE_AGENT_NAME` doesn't exist (see separate `seed-agent-name-env-var-20260411.md`).

We have a **growing pile of workarounds** that exist specifically to route around the permission model. Each workaround adds complexity. Each gap we close with tooling leaves the underlying model un-improved.

## Our observations

From captain's flag queue captured during ISCP workstream buildout:

> *"ISCP agent hitting permission prompts for basic operations (ls, git show, sqlite3). Permissions added to settings.json but agents need restart to pick them up. The permission UX is a friction point — agents shouldn't need approval for read-only operations on framework paths."*

> *"ISCP agent blocked on ~/.agency/ access too. Need to add Read/Bash permissions for ~/.agency/ path. The compound command pattern (cmd1 && cmd2) triggers extra prompts even when both commands are allowed individually."*

> *"ISCP agent blocked on cd+git show compound command in worktree. Claude Code treats cd+git as bare repo attack vector. The dispatch tool uses `git -C` instead of cd+git show — but agent is running raw bash, not the tool."*

From the `anthropic-issues-to-file-20260406.md` tracking file (brace expansion issue, previously tracked separately):

> *"Bash commands containing brace expansion (e.g., `mkdir -p {a,b,c}`) trigger Claude Code's permission system as though they are compound or multiple commands. This forces tools to avoid standard shell idioms and use verbose alternatives. ... Tools like `agency-init` that scaffold directory trees must avoid brace expansion entirely, resulting in verbose repetitive code."*

Captain's own workflow hits this weekly. We've gradually accumulated a large `settings.json` allowlist and still hit edge cases.

## What we've tried

1. **Ever-expanding `settings.json` allowlist** — works for known operations, fails for new edge cases, requires session restart to pick up new entries.
2. **`dispatch-monitor` tool running under Monitor** — silent polling without triggering prompts, but required building a new tool because the permission model couldn't accommodate what we needed.
3. **`block-raw-tools` PreToolUse hook** — forces agents to use framework tools rather than raw `cat`, `grep`, etc. Reduces permission prompts because the framework tools are pre-approved. Workaround, not a fix.
4. **`run-in` tool** — wraps cross-directory commands to avoid triggering `cd &&` compound command detection. Another workaround.
5. **Avoiding brace expansion** — replacing `mkdir -p {a,b,c}` with three separate `mkdir -p` calls in every tool that scaffolds directories. Tax on every tool that creates multiple paths.
6. **Project-local `.agency-agent` file** — because there's no programmatic way to know "which agent is this session supposed to be." Another workaround.

We have invested significant engineering specifically to route around the permission model. That engineering would be better spent on framework features.

## Use case for the feedback

**Multi-agent framework.** We are building [the-agency](https://github.com/the-agency-ai/the-agency), an open-core framework for AI-augmented development. Each agent in the framework runs as its own Claude Code session. Agents coordinate via a SQLite-backed inter-session communication protocol (ISCP). A typical operational day for an autonomous worktree agent involves:

- Reading handoff files at SessionStart
- Polling the dispatch queue every few seconds
- Reading framework config from `~/.agency/{repo}/`
- Executing framework tools (`./agency/tools/*`)
- Writing dispatches, flags, handoffs, and telemetry

**Every one of these is a read or a framework-tool invocation that should be pre-approved.** None of them are unfamiliar. None of them need human-in-the-loop judgment. And yet every one of them has tripped a permission prompt at some point during development — prompts that the autonomous agent cannot see, acknowledge, or act on.

**Downstream ecosystem.** As more teams adopt Claude Code for autonomous agent workflows (and the feature set is clearly pointing that way — Monitor, CronCreate, async hooks, background Bash, SubAgent APIs, etc.), this gap will affect more users. The current state is the Claude Code team has built *the primitives* for autonomous agents but the *permission model is still built for interactive users*. The mismatch is the bug.

## Requested behavior

### Option 1 (preferred): Trusted framework paths

A new section in `settings.json` that marks specific filesystem paths as "trusted framework paths," where any read-only operation (`read`, `ls`, `cat`, `git show/log/diff`, `sqlite3 SELECT`, etc.) is auto-approved without prompting:

```json
{
  "permissions": {
    "trustedFrameworkPaths": [
      "~/.agency/",
      "./claude/",
      "./.claude/",
      "./usr/{principal}/"
    ]
  }
}
```

Write operations on these paths still go through the normal permission gate. This narrowly expands read-trust without opening write-trust.

### Option 2: Agent mode (session-level trust)

A CLI flag or session setting that marks a session as "autonomous agent mode":
- Read operations on any path under the project root are auto-approved
- Write operations still require approval (or are allowlisted)
- Permission prompts are disabled and replaced with structured errors the agent can handle programmatically

```bash
claude --agent-mode --agent-identity the-agency/jordan/captain
```

The agent's identity is logged alongside every operation for audit.

### Option 3: Hot-reload permissions

Allow `settings.json` changes to take effect without a session restart. Current workflow:
1. Agent hits permission prompt
2. Principal (eventually) sees it
3. Principal edits `settings.json`
4. Principal kills agent session
5. Principal restarts agent session — **losing all conversation context**
6. Agent resumes from handoff (if one was written in time)

A hot-reload signal (`SIGHUP`, `/reload-permissions` slash command, or file-watcher on `settings.json`) would eliminate the restart penalty.

### Option 4: Better prompt visibility for autonomous agents

If prompts must remain, expose them via a programmatic channel the agent can see. For example, a status-line API or a special prompt-pending tool call the agent can query. The current model where prompts go to a terminal buffer the agent can't read is the worst case.

### Option 5 (narrower but independently valuable): Fix brace expansion parsing

Brace expansion (`mkdir -p {a,b,c}`) is a single command — the shell expands it before execution. The permission parser should recognize this and match against the `mkdir` allowlist normally instead of treating it as multiple commands.

Same for compound command patterns (`cmd1 && cmd2`) where both commands are individually allowed — the parser should allow the compound if each component is allowed.

## Why it matters

**For the framework-building use case:**
- `the-agency` is an open-core framework whose whole premise is that agents operate with increasing autonomy inside a well-defined framework scope.
- Every permission friction is a moment where the framework breaks its own promise. "The captain handles this for you" becomes "the captain is frozen on a permission prompt you can't see."
- We've built elaborate workarounds: `dispatch-monitor`, `block-raw-tools`, agent-identity resolution, `run-in`, complex `settings.json` grammar — all of which exist to route around the permission model rather than work with it.

**For the autonomous agent trend broadly:**
- Claude Code's developer audience is increasingly using it for agent-backed workflows (background jobs, scheduled runs, monitors, long-running research agents).
- The permission model is optimized for interactive use. Without an evolution toward agent-friendly modes, developers will either disable permissions entirely (bad) or wrap Claude Code in elaborate automation layers that defeat the purpose.
- Anthropic has been ahead of the industry on AI safety. An opinionated, principled answer to *"how should autonomous agents handle permissions?"* is a natural extension of that posture.

**For productivity:**
- We lose multiple sessions per week to permission-prompt deadlocks.
- We've built tooling to detect when an agent is stuck on a prompt and alert the principal — this is a hack for a gap Claude Code should close.
- The settings.json we ship to new users is complex specifically because we're papering over this gap.

## Mechanical notes for submission

**Role split:**
- **Captain authors** the seed and draft text.
- **Principal files** via `/feedback` and cross-files to GitHub via `gh issue create`.
- Captain updates the report tracker with both IDs.

**Reporter identity (pre-filled from `agency.yaml`):**
- Jordan Dea-Mattson, @jordandm (the-agency-ai), @jordan-of (OrdinaryFolk)
- jordandm@users.noreply.github.com, jordan-of@users.noreply.github.com
- Framework: https://github.com/the-agency-ai/the-agency
- Claude Code version: `claude --version` at filing time

## Draft feedback text (ready for principal to file via `/feedback` + `gh issue create`)

*Captain authors this section. Principal reviews, edits if needed, then files.*

---

# Agent permission model needs a "trusted framework paths" concept for autonomous agents

## Problem

Claude Code's permission system is designed around interactive human-in-the-loop sessions: when an unfamiliar command or path appears, the user sees a prompt and decides whether to allow it. That model works well for a human developer sitting at a terminal.

It works poorly for **autonomous agents operating inside a framework**. I'm building `the-agency`, a multi-agent framework where agents run unattended: polling queues, reading handoffs, running framework tools, responding to events. Most of these operations are **read-only** and touch **a small, predictable set of paths** (`claude/`, `~/.agency/`, `.claude/`, `usr/`). They are not commands a human should be asked about — they are the framework's own internal plumbing.

What happens in practice:

- An autonomous worktree agent hits a permission prompt on `ls ~/.agency/`, `git show HEAD -- agency/config/agency.yaml`, or `sqlite3 ~/.agency/iscp.db "SELECT ..."`.
- The agent is running unattended. There is no human at the terminal to approve the prompt.
- The agent blocks, or the prompt goes to a buffer the agent can't read, and the agent appears to hang for no reason with no visible signal.
- By the time the principal notices, minutes or hours have passed.

Adding entries to `settings.json` helps somewhat, but:
- Permission changes require a session restart to take effect — an autonomous agent can't restart itself in-place.
- The `settings.json` permission grammar is command-oriented, not path-oriented. It's hard to say "any read operation on `~/.agency/`" without enumerating every verb (`ls`, `cat`, `git`, `sqlite3`, `find`, `stat`, ...).
- Brace expansion (`mkdir -p {a,b,c}`) is treated as a compound command even though the shell expands it to a single `mkdir` call. Same with `cmd1 && cmd2` where both commands are individually allowed.

## Steps to reproduce

1. Build an autonomous agent that polls a queue on a schedule (I use `dispatch-monitor` under the Claude Code `Monitor` tool).
2. The agent is configured to run in the background, with no human present to approve prompts.
3. The agent attempts any of:
   - `git -C /path/to/worktree show HEAD -- some-file.md`
   - `sqlite3 ~/.agency/the-agency/iscp.db "SELECT * FROM dispatches"`
   - `ls ~/.agency/`
   - `mkdir -p some-project/{docs,src,tests}` (brace expansion)
4. Observe: Claude Code raises a permission prompt that the agent cannot see, acknowledge, or act on.

## Expected behavior

One of the following options (listed in preference order):

### Option 1: Trusted framework paths

```json
{
  "permissions": {
    "trustedFrameworkPaths": [
      "~/.agency/",
      "./claude/",
      "./.claude/"
    ]
  }
}
```

Any read-only operation on these paths is auto-approved. Writes still gated. This narrowly expands read-trust without opening write-trust.

### Option 2: Agent mode

A session-level flag `--agent-mode` that marks a session as autonomous. Read operations on any path under the project root are auto-approved. Write operations still gated. Permission prompts replaced with structured errors the agent can handle.

### Option 3: Hot-reload permissions

Allow `settings.json` changes to take effect without a session restart. Current workflow forces autonomous agents to lose conversation context on every permission update.

### Option 4: Better prompt visibility

If prompts must remain, expose them via a programmatic channel the agent can see (status-line API, pending-prompt tool call). The current model where prompts go to a terminal buffer the agent can't read is the worst case.

### Option 5 (narrower but independently valuable): Fix brace expansion parsing

Brace expansion is a single command — the shell expands it before execution. The permission parser should recognize this and match against the `mkdir` allowlist normally instead of treating it as multiple commands. Same for compound command patterns where both components are individually allowed.

## Why this matters

**For the framework-building use case:**
- `the-agency` is an open-core framework whose premise is that agents operate with increasing autonomy inside a well-defined framework scope.
- Every permission friction breaks the framework's promise. "The captain handles this for you" becomes "the captain is frozen on a permission prompt you can't see."
- We've built elaborate workarounds: `dispatch-monitor`, `block-raw-tools` hook, `run-in` tool, complex `settings.json` grammar — all of which exist to route around the permission model.

**For the autonomous agent trend broadly:**
- Claude Code's developer audience is increasingly using it for agent-backed workflows.
- The permission model is optimized for interactive use. Without evolution toward agent-friendly modes, developers will either disable permissions entirely (bad) or wrap Claude Code in elaborate automation layers that defeat the purpose.
- Anthropic has been thoughtful about AI safety — an opinionated answer to "how should autonomous agents handle permissions?" is a natural extension.

**For productivity:**
- We lose multiple sessions per week to permission-prompt deadlocks.
- We've built tooling specifically to detect when an agent is stuck on a prompt and alert the principal — a hack for a gap Claude Code should close.

## Workaround

We maintain an ever-growing `settings.json` allowlist and a `block-raw-tools` hook that forces agents to use framework tools (pre-approved) instead of raw `cat`/`grep`/`find`. We use `dispatch-monitor` under the `Monitor` tool for silent polling. We avoid brace expansion. We use `git -C` instead of `cd && git`. These workarounds are fragile and don't generalize outside our framework.

## Reporter

- **Name:** Jordan Dea-Mattson
- **GitHub:** @jordandm (the-agency-ai), @jordan-of (OrdinaryFolk)
- **Email:** jordandm@users.noreply.github.com, jordan-of@users.noreply.github.com
- **Framework:** https://github.com/the-agency-ai/the-agency
- **Claude Code version:** (fill at submission — `claude --version`)

## Related

- This feedback folds in a previously-tracked issue about brace expansion (`{a,b,c}`) triggering permission prompts as compound commands. They are the same underlying root cause: the permission parser lacks enough context to distinguish legitimate patterns from unfamiliar commands.
- Companion filings in the same 2026-04-11 batch:
  - Comms gap about `/feedback` ([#46531](https://github.com/anthropics/claude-code/issues/46531))
  - `/feedback` silent failure (technical bug)
  - Content filter opacity
  - `--agent` / `--name` environment variable missing
  - macOS permissions break on every Claude Code update
- Previous successful filing: [#45017](https://github.com/anthropics/claude-code/issues/45017) — silent periodic tool calls

---

## Revisit triggers

File as part of today's batch.

## Conversation source

Captured during ISCP workstream buildout (early April 2026) as flags #1, #2, #3 in captain's queue. Previously tracked in `usr/jordan/captain/anthropic-issues-to-file-20260406.md` as item 2 (brace expansion) and via ad-hoc flags for the broader permission UX issues. Restructured into this seed during the Day 36-37 captain session on 2026-04-11 as part of clearing the feedback backlog.
