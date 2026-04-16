# Claude Code Agent Startup Behavior

**Created:** 2026-01-15
**Context:** REQUEST-0053 Phase A parallel agent work
**Related Issues:** AGENTNIT-0001, AGENTNIT-0002

---

## The Problem

We want agents to proactively check for pending collaborations and messages on startup, without requiring user input first.

## Key Finding

**SessionStart hooks cannot make the agent send the first message automatically.** They can only inject context or log output - you still need either an initial CLI prompt, a slash command, or a custom wrapper script.

---

## What SessionStart Can Do

- Fires when Claude Code starts a new session or resumes an existing one
- Primarily meant for loading extra context (e.g., issues, recent changes) before the first user turn
- Can output JSON with `additionalContext` string injected into Claude's internal context
- Hook scripts can print to stdout (visible with `claude --verbose`), but this is diagnostic output, not a conversational reply

## What SessionStart Cannot Do

- Cannot produce a visible assistant message in the chat UI
- Cannot trigger autonomous assistant turns
- There is an open feature request (GitHub #4318) asking for this capability

---

## Workarounds

### 1. Headless + Initial Prompt
```bash
claude -p "Read CLAUDE.md and tell me the next task"
```
Makes the "first turn" automatic, though it's still a user-supplied prompt from CLI's perspective.

### 2. Wrapper Script Around Interactive Mode
- Start Claude Code with `claude` from a script
- Use SessionStart hooks to precompute context
- Have wrapper immediately send a canned user message like "Use the preloaded context to summarize where we are and suggest next steps"
- Requires expect/pty tools

### 3. Agent SDK / External Client
When using the Claude agent SDK instead of the CLI, you can:
- React to the system init message that carries the session id
- Programmatically send your own first user message
- Produces immediate assistant turn driven by client logic rather than SessionStart hook

---

## Our Current Approach

We added news and collaboration checking to the SessionStart hook:
```bash
# .claude/hooks/session-start.sh
NEWS_OUTPUT=$("$REPO_ROOT/tools/news-read" --quiet 2>/dev/null)
COLLAB_OUTPUT=$("$REPO_ROOT/tools/collaboration-pending" 2>/dev/null)
```

This **displays** the information to the user, who then needs to tell the agent to act on it.

---

## Future Options

1. **Wrapper script for myclaude** - After launching claude, automatically send initial prompt
2. **Modified myclaude** - Use `-p` flag to send startup prompt
3. **Wait for Claude Code feature** - GitHub #4318 requests this capability
4. **Agent SDK approach** - Build custom launcher using SDK

---

## References

- https://code.claude.com/docs/en/hooks
- https://github.com/anthropics/claude-code/issues/4318 (feature request)
- https://github.com/anthropics/claude-code/issues/10808
- https://stevekinney.com/courses/ai-development/claude-code-session-management
- https://www.anthropic.com/engineering/claude-code-best-practices

---

## Implications for The Agency

For multi-agent choreography, we need to consider:
1. User must prompt agents to check collaborations (current workaround)
2. Or use wrapper/SDK approach for truly autonomous agent activation
3. This is a known limitation of Claude Code as of 2025
