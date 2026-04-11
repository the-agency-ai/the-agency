---
report_type: feedback
target: Anthropic Claude Code
filing_agent: the-agency/jordan/captain
filed_by: jordan
date_filed: 2026-04-11
status: draft
category: feature-request
severity: moderate
subject: Agent permission model needs a "trusted framework paths" mode for autonomous agents
---

## [Feature Request]: Agent permission model — trusted framework paths for autonomous agents

**From:** Jordan Dea-Mattson
**GitHub:** @jordandm (the-agency-ai), @jordan-of (OrdinaryFolk)
**Email:** jordandm@users.noreply.github.com, jordan-of@users.noreply.github.com
**Related:** Folds in brace-expansion-triggers-permission-prompts (previously tracked separately in anthropic-issues-to-file-20260406.md item 2)

## Problem

Claude Code's permission system is designed around interactive human-in-the-loop sessions: when an unfamiliar command or path appears, the user sees a prompt and decides whether to allow it. That model works well for a human developer sitting at a terminal.

It works poorly for **autonomous agents operating inside a framework** — the use case I'm building with `the-agency`. Our agents are designed to run operationally: they read their own handoffs, poll dispatch queues, check flags, run framework tools, and respond to events. Most of these operations are **read-only** and touch **a small, predictable set of paths** (`claude/`, `~/.agency/`, `.claude/`, `usr/`). They are not commands a human should be asked about — they are the framework's own internal plumbing.

What happens in practice:

- An autonomous worktree agent hits a permission prompt on `ls ~/.agency/`, `git show HEAD -- claude/config/agency.yaml`, or `sqlite3 ~/.agency/the-agency/iscp.db "SELECT ..."`.
- The agent is running unattended. There is no human at the terminal to approve the prompt.
- The agent blocks. Or worse — the prompt goes to a buffer the agent can't see, and the agent appears to hang for no reason with no visible signal.
- By the time the principal notices, minutes or hours have passed.

Adding entries to `settings.json` helps somewhat, but:
- Permission changes require a session restart to take effect — an autonomous agent can't restart itself in-place.
- The `settings.json` permission grammar is command-oriented, not path-oriented. It's hard to say "any read operation on `~/.agency/`" without enumerating every verb (ls, cat, git, sqlite3, find, stat, ...).
- Compound commands and brace expansions surprise the parser — see related bug report on brace expansion.

## Steps to Reproduce

1. Build an autonomous agent that polls a queue on a schedule (we use `dispatch-monitor` under the Claude Code `Monitor` tool).
2. The agent is configured to run in the background, with no human present to approve prompts.
3. The agent attempts any of:
   - `git -C /path/to/worktree show HEAD -- some-file.md`
   - `sqlite3 ~/.agency/the-agency/iscp.db "SELECT * FROM dispatches"`
   - `ls ~/.agency/`
   - `cat some-framework-file.md` (when `cat` isn't in allowed list)
4. Observe: Claude Code raises a permission prompt that the agent cannot see, acknowledge, or act on.

## Diagnostic Evidence

From our flag queue during the ISCP agent buildout:

> "ISCP agent hitting permission prompts for basic operations (ls, git show, sqlite3). Permissions added to settings.json but agents need restart to pick them up. The permission UX is a friction point — agents shouldn't need approval for read-only operations on framework paths."

> "ISCP agent blocked on ~/.agency/ access too. Need to add Read/Bash permissions for ~/.agency/ path. The compound command pattern (cmd1 && cmd2) triggers extra prompts even when both commands are allowed individually."

> "ISCP agent blocked on cd+git show compound command in worktree. Claude Code treats cd+git as bare repo attack vector."

The captain's own workflow hits this regularly. We've gradually accumulated a large `settings.json` allowlist specifically to stop interrupting autonomous agent operations, and still hit edge cases weekly.

## Requested Behavior

I'd love to see **one or more** of the following:

### Option 1: Trusted framework paths concept (our preferred shape)

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

### Option 2: Agent mode (a session-level trust level)

A CLI flag or session setting that marks a session as "autonomous agent mode," where:

- Read operations on any path under the project root are auto-approved
- Write operations still require approval (or are allowlisted)
- Permission prompts are disabled entirely and replaced with structured errors the agent can handle

```bash
claude --agent-mode --agent-identity the-agency/jordan/captain
```

The agent's identity would be logged alongside every operation for audit.

### Option 3: Hot-reload permissions

Allow `settings.json` changes to take effect without a session restart. Current workflow:
1. Agent hits permission prompt
2. Principal (eventually) sees it
3. Principal edits `settings.json`
4. Principal kills agent session
5. Principal restarts agent session — **losing all conversation context**
6. Agent resumes from handoff (if one was written in time)

A hot-reload signal (e.g., `SIGHUP` to the Claude Code process, or a `/reload-permissions` slash command) would eliminate the restart penalty.

### Option 4: Better prompt visibility for autonomous agents

If prompts must remain, expose them via a programmatic channel the agent can see. For example, a status-line API or a special prompt-pending tool call the agent can query. The current model where prompts go to a terminal buffer the agent can't read is the worst case.

## Why This Matters

**For the framework-building use case:**
- `the-agency` is an open-core framework for AI-augmented development. The whole premise is that agents operate with increasing autonomy inside a well-defined framework scope.
- Every permission friction is a moment where the framework breaks its own promise. "The captain handles this for you" becomes "the captain is frozen on a permission prompt you can't see."
- We've had to build elaborate workarounds: `dispatch-monitor`, `block-raw-tools`, agent-identity resolution, complex `settings.json` grammar — much of which exists to route *around* the permission model rather than work *with* it.

**For the autonomous agent trend broadly:**
- Claude Code's developer audience is increasingly using it for agent-backed workflows (background jobs, scheduled runs, autonomous research agents, long-running monitors).
- The permission model is optimized for interactive use. Without an evolution toward agent-friendly modes, the ergonomics will push developers to either disable the model entirely (bad) or work around it with elaborate wrappers (our current state).
- Anthropic has been ahead of the industry on AI safety. An opinionated, principled answer to "how should autonomous agents handle permissions?" is a natural extension.

**For our team's productivity:**
- We lose multiple sessions per week to permission-prompt deadlocks.
- We've built tooling to detect when an agent is stuck on a prompt and alert the principal — this is a hack for a gap Claude Code should close.
- The settings.json we ship to new users is complex specifically because we're papering over this gap.

## Related context

- Filed by: Jordan Dea-Mattson, building `the-agency-ai/the-agency` framework
- Internal flags: #1, #2, #3, #10 — all documenting permission friction for autonomous agents
- Workaround currently in use: ever-growing `settings.json` allowlist + `block-raw-tools` hook + `dispatch-monitor` for silent polling
- Related bug: brace expansion triggering compound-command permission prompts (separate feedback report)

## Proposed next step

Happy to share our `settings.json` allowlist, our `block-raw-tools` hook, and our `dispatch-monitor` implementation as concrete examples of the workarounds we've built. These might be useful input into a design for trusted framework paths or agent mode.

---

*Draft — awaiting principal review before send.*
