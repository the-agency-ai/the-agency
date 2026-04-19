---
title: Claude Code Subagents
created: 2026-01-21T12:50:00
author: captain
version: 1.0.0
source: https://code.claude.com/docs/en/subagents
---

# Claude Code Subagents

Subagents are specialized AI assistants that handle specific types of tasks with custom prompts, tool access, and independent permissions.

## Overview

Each subagent runs in its own context window with a custom system prompt, specific tool access, and independent permissions. When Claude encounters a task that matches a subagent's description, it delegates to that subagent.

## Key Features

### Built-in Subagents

| Agent | Model | Tools | Purpose |
|-------|-------|-------|---------|
| `Explore` | Haiku | Read-only | Codebase exploration |
| `Plan` | Inherit | Read-only | Planning research |
| `general-purpose` | Inherit | All | Complex tasks |
| `Bash` | Inherit | Bash | Terminal commands |
| `statusline-setup` | Sonnet | Limited | /statusline config |
| `Claude Code Guide` | Haiku | Limited | Help questions |

### Subagent File Format
```yaml
---
name: code-reviewer
description: Reviews code for quality and best practices
tools: Read, Glob, Grep
disallowedTools: Write, Edit
model: sonnet
permissionMode: default
skills:
  - api-conventions
  - error-handling-patterns
hooks:
  PostToolUse:
    - matcher: "Edit|Write"
      hooks:
        - type: command
          command: "./scripts/run-linter.sh"
---
You are a code reviewer. When invoked, analyze the code and provide
specific, actionable feedback on quality, security, and best practices.
```

### Frontmatter Fields

| Field | Description | Default |
|-------|-------------|---------|
| `name` | Unique identifier (kebab-case) | Required |
| `description` | When Claude should delegate | Required |
| `tools` | Allowed tools (allowlist) | Inherit all |
| `disallowedTools` | Denied tools (denylist) | None |
| `model` | `sonnet`, `opus`, `haiku`, `inherit` | inherit |
| `permissionMode` | Permission behavior | default |
| `skills` | Skills to preload | None |
| `hooks` | Lifecycle hooks | None |

### Permission Modes

| Mode | Behavior |
|------|----------|
| `default` | Standard permission checking |
| `acceptEdits` | Auto-accept file edits |
| `dontAsk` | Auto-deny permission prompts |
| `bypassPermissions` | Skip all permission checks |
| `plan` | Plan mode (read-only) |

## Configuration

### Subagent Locations

| Scope | Location | Priority |
|-------|----------|----------|
| CLI flag | `--agents` JSON | 1 (highest) |
| Project | `.claude/agents/*.md` | 2 |
| User | `~/.claude/agents/*.md` | 3 |
| Plugin | `<plugin>/agents/*.md` | 4 (lowest) |

### CLI-Defined Subagents
```bash
claude --agents '{
  "code-reviewer": {
    "description": "Expert code reviewer",
    "prompt": "You are a senior code reviewer...",
    "tools": ["Read", "Grep", "Glob"],
    "model": "sonnet"
  }
}'
```

### Preloading Skills
```yaml
---
name: api-developer
description: Implement API endpoints following team conventions
skills:
  - api-conventions
  - error-handling-patterns
---
```

Skills are fully injected into subagent context at startup, not just made available for invocation.

## Examples

### Read-Only Code Reviewer
```yaml
---
name: code-reviewer
description: Reviews code for quality and best practices. Use proactively after code changes.
tools: Read, Glob, Grep, Bash
model: sonnet
---
You are a senior code reviewer ensuring high standards.

Review checklist:
- Code is clear and readable
- No duplicated code
- Proper error handling
- No exposed secrets
- Good test coverage

Provide feedback by priority:
- Critical issues (must fix)
- Warnings (should fix)
- Suggestions (consider)
```

### Database Query Validator
```yaml
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
```

### Debugger with Edit Access
```yaml
---
name: debugger
description: Debugging specialist for errors and test failures
tools: Read, Edit, Bash, Grep, Glob
---
You are an expert debugger specializing in root cause analysis.

Process:
1. Capture error message and stack trace
2. Identify reproduction steps
3. Isolate the failure location
4. Implement minimal fix
5. Verify solution works
```

## Advanced Patterns

### Resume Subagents
Subagents can be resumed with their agent ID:
```
Continue that code review and now analyze the authorization logic
```
Claude resumes the subagent with full context from previous conversation.

### Parallel Research
```
Research the authentication, database, and API modules in parallel using separate subagents
```

### Chained Subagents
```
Use the code-reviewer subagent to find performance issues, then use the optimizer subagent to fix them
```

### Foreground vs Background
- **Foreground**: Blocking, permission prompts passed through
- **Background**: Concurrent, auto-deny unpermitted actions
- Press `Ctrl+B` to background a running task

## Agency Relevance

**Very High** - Direct mapping to our agent model:

| Agency Concept | Native Subagent Equivalent |
|----------------|---------------------------|
| `claude/agents/captain/agent.md` | `.claude/agents/captain.md` |
| Agent KNOWLEDGE.md | `skills:` field to preload |
| `./tools/myclaude` | Native subagent invocation |
| Agent permissions | `tools`, `disallowedTools`, `permissionMode` |

### Benefits
- Native Claude Code integration
- Model selection per agent
- Tool restrictions built-in
- Resume capability with agent ID
- Foreground/background execution
- Skill preloading

### Migration Path
1. Convert `claude/agents/*/agent.md` to `.claude/agents/*.md`
2. Use frontmatter for tool/model configuration
3. Move KNOWLEDGE.md content to skills
4. Use `skills:` field to preload context

## Links/Sources

- [Subagents Documentation](https://code.claude.com/docs/en/subagents)
- [/agents Command Reference](https://code.claude.com/docs/en/interactive#agents)
