---
report_type: feedback
target: Anthropic Claude Code
filing_agent: the-agency/jordan/captain
filed_by: jordan
date_filed: 2026-04-11
status: draft
category: bug
severity: moderate
subject: --agent / --name flag does not set CLAUDE_AGENT_NAME environment variable
source: usr/jordan/captain/anthropic-issues-to-file-20260406.md (item 1)
---

## [Bug Report]: --agent/--name flag does not expose agent name as an environment variable

**From:** Jordan Dea-Mattson
**GitHub:** @jordandm (the-agency-ai), @jordan-of (OrdinaryFolk)
**Email:** jordandm@users.noreply.github.com, jordan-of@users.noreply.github.com
**Related:** Framework multi-agent workflow patterns; agent identity in `the-agency`

## Problem

When launching Claude Code with `claude --agent devex` or `claude --name devex`, the spawned process does not expose the agent name to its shell environment. There is no `CLAUDE_AGENT_NAME`, `CLAUDE_NAME`, or equivalent variable that downstream tooling can read.

This is a hard blocker for any workflow that runs **multiple agents concurrently** and needs to tell them apart from outside the Claude Code process — terminal tab titles, shell prompts, status lines, tmux pane labels, telemetry tagging, per-agent log routing, and so on.

## Steps to Reproduce

1. Launch multiple Claude Code sessions with different agent names:
   ```bash
   claude --agent captain
   claude --agent devex
   claude --agent iscp
   ```
2. Inside each session, inspect the environment:
   ```bash
   env | grep -i agent
   env | grep -i claude
   ```
3. Inspect the terminal tab/title bar.

**Observed:** No environment variable references the agent name. All terminal tabs display a generic "agent" label. `$CLAUDE_AGENT_NAME` is unset.

**Expected:** An environment variable — `CLAUDE_AGENT_NAME`, or similar — is set in the child process, containing the name passed to `--agent` / `--name`. Terminal integration features would use this to populate the tab title automatically.

## Diagnostic Evidence

We maintain agent identity via a custom `agent-identity` tool that reads a project-local `.agency-agent` file, because we cannot read the name Claude Code is using internally. This is a workaround for a gap that should not exist.

## Requested Behavior

**Minimal change:** Set `CLAUDE_AGENT_NAME` (or a namespace-qualified variant like `CLAUDE_CODE_AGENT_NAME`) in the spawned process's environment when `--agent` / `--name` is passed. The variable should be readable from shell, from tools invoked via `Bash`, and from hooks.

**Nice to have:**
- Also set `CLAUDE_SESSION_ID` so concurrent sessions can be distinguished programmatically
- Document the full set of environment variables Claude Code exposes to child processes in the public docs
- Consider a structured session metadata file (e.g., `$XDG_RUNTIME_DIR/claude-code/{session-id}.json`) for richer integration

## Why This Matters

- **Multi-agent development is the use case Claude Code is being used for.** Many teams (including ours) run captain + multiple worktree agents simultaneously. Differentiating them outside the Claude Code process is currently impossible.
- **Terminal ergonomics matter.** Humans looking at a row of terminal tabs need to see which one is doing what. Generic "agent" labels everywhere is a paper cut that becomes painful fast.
- **Tool integration matters.** Shell prompts, tmux status lines, monitoring tools, and IDE integrations all want to know "which agent is this?" and there's no answer.
- **Programmatic agent-aware scripting is blocked.** Shell scripts that want to behave differently per agent (e.g., "if this is captain, use the admin path; otherwise, use the worktree path") have no reliable way to detect the agent context.

## Workaround

We maintain a project-local `.agency-agent` file that records the expected agent name per worktree, and our `agent-identity` tool reads this file to produce a fallback identity. This works for us because we control the worktree directory layout, but it's not a general solution — any user without our framework scaffolding is stuck.

## Related context

- Filed by: Jordan Dea-Mattson, building the-agency framework (multi-agent AI development framework)
- Internal flag: captured 2026-04-06 during ISCP workstream buildout
- Workaround in use: project-local `.agency-agent` file + custom `agent-identity` tool

---

*Draft — awaiting principal review before send.*
