---
title: Claude Code Subagents System
created: 2026-01-21T13:35:00+08:00
author: research-agent
version: 1.0.0
source: Claude Code Documentation
---

# Claude Code Subagents System

## Overview

Subagents are specialized AI assistants that handle specific tasks in isolated contexts. Each subagent runs with its own context window, custom system prompt, tool access, and permissions.

## Key Features

- Independent context windows
- Custom system prompts
- Tool restrictions
- Model selection
- Permission modes
- Preloaded skills
- Scoped hooks
- Foreground or background execution

## Built-in Subagents

| Agent | Model | Tools | Purpose |
|-------|-------|-------|---------|
| Explore | Haiku | Read-only | Fast codebase exploration |
| Plan | Inherit | Read-only | Research for plan mode |
| general-purpose | Inherit | All | Complex multi-step tasks |
| Bash | Inherit | Bash | Terminal commands |
| Claude Code Guide | Haiku | Limited | Questions about Claude Code |

## Subagent Locations

| Location | Scope | Priority |
|----------|-------|----------|
| `--agents` CLI flag | Session | 1 (highest) |
| `.claude/agents/` | Project | 2 |
| `~/.claude/agents/` | User | 3 |
| Plugin `agents/` | Plugin | 4 (lowest) |

## Subagent File Structure

```markdown
---
name: code-reviewer
description: Reviews code for quality and best practices
tools: Read, Glob, Grep
model: sonnet
---

You are a code reviewer. When invoked, analyze the code and provide
specific, actionable feedback on quality, security, and best practices.
```

## Frontmatter Fields

| Field | Required | Description |
|-------|----------|-------------|
| name | Yes | Unique identifier (lowercase, hyphens) |
| description | Yes | When Claude should delegate |
| tools | No | Allowed tools (inherits all if omitted) |
| disallowedTools | No | Tools to deny |
| model | No | sonnet, opus, haiku, or inherit |
| permissionMode | No | default, acceptEdits, dontAsk, bypassPermissions, plan |
| skills | No | Skills to preload |
| hooks | No | Lifecycle hooks |

## Model Selection

```yaml
model: sonnet    # Use Claude Sonnet
model: opus      # Use Claude Opus
model: haiku     # Use Claude Haiku (fast, cheap)
model: inherit   # Use same as main conversation (default)
```

## Permission Modes

| Mode | Behavior |
|------|----------|
| default | Standard permission checking |
| acceptEdits | Auto-accept file edits |
| dontAsk | Auto-deny prompts (allowed tools still work) |
| bypassPermissions | Skip all permission checks |
| plan | Read-only exploration |

## Tool Restrictions

```yaml
# Allow specific tools
tools: Read, Grep, Glob, Bash

# Or deny specific tools
disallowedTools: Write, Edit
```

## Preloaded Skills

Inject skill content at startup:

```yaml
---
name: api-developer
description: Implement API endpoints
skills:
  - api-conventions
  - error-handling-patterns
---
```

## Subagent Hooks

```yaml
---
name: code-reviewer
description: Review code changes
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "./scripts/validate-command.sh"
  PostToolUse:
    - matcher: "Edit|Write"
      hooks:
        - type: command
          command: "./scripts/run-linter.sh"
---
```

## CLI-Defined Subagents

```bash
claude --agents '{
  "code-reviewer": {
    "description": "Expert code reviewer",
    "prompt": "You are a senior code reviewer...",
    "tools": ["Read", "Grep", "Glob", "Bash"],
    "model": "sonnet"
  }
}'
```

## Foreground vs Background

- **Foreground**: Blocks main conversation, permission prompts passed through
- **Background**: Runs concurrently, auto-deny unpermitted actions

Control execution:
- Ask Claude to "run this in the background"
- Press `Ctrl+B` to background a running task
- Set `CLAUDE_CODE_DISABLE_BACKGROUND_TASKS=1` to disable

## Example: Read-Only Code Reviewer

```markdown
---
name: code-reviewer
description: Reviews code for quality and best practices. Use proactively after code changes.
tools: Read, Grep, Glob, Bash
model: inherit
---

You are a senior code reviewer ensuring high standards.

When invoked:
1. Run git diff to see recent changes
2. Focus on modified files
3. Begin review immediately

Review checklist:
- Code clarity and readability
- Proper error handling
- No exposed secrets
- Good test coverage

Provide feedback organized by priority:
- Critical issues (must fix)
- Warnings (should fix)
- Suggestions (consider improving)
```

## Example: Database Query Validator

```markdown
---
name: db-reader
description: Execute read-only database queries
tools: Bash
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "./scripts/validate-readonly-query.sh"
---

You are a database analyst with read-only access.
Execute SELECT queries to answer questions about the data.

You cannot modify data. If asked to INSERT, UPDATE, DELETE,
explain that you only have read access.
```

## Disabling Subagents

In settings.json:
```json
{
  "permissions": {
    "deny": ["Task(Explore)", "Task(my-custom-agent)"]
  }
}
```

Or via CLI:
```bash
claude --disallowedTools "Task(Explore)"
```

## Subagent Transcripts

Transcripts stored at:
`~/.claude/projects/{project}/{sessionId}/subagents/agent-{agentId}.jsonl`

Resume a subagent by asking Claude to continue previous work.

## Agency Relevance

Subagents could enhance The Agency with:

1. **Specialized Agents** - Code reviewer, test runner, documentation writer
2. **Task Isolation** - Keep verbose output out of main context
3. **Parallel Research** - Multiple agents exploring independently
4. **Cost Control** - Use Haiku for simple tasks
5. **Permission Control** - Restrict dangerous operations

## Links/Sources

- [Subagents Documentation](https://code.claude.com/docs/en/subagents)
