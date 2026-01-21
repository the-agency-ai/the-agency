---
title: Claude Code Permissions
created: 2026-01-21T12:50:00
author: captain
version: 1.0.0
source: https://code.claude.com/docs/en/permissions
---

# Claude Code Permissions

Permissions control what actions Claude can take, with granular patterns for tool access.

## Overview

Claude Code uses a permission system that controls tool access through allow/deny patterns. Permissions can be configured at enterprise, user, project, and local levels.

## Key Features

### Permission Modes

| Mode | Behavior |
|------|----------|
| `default` | Standard permission checking with prompts |
| `acceptEdits` | Auto-accept file edits (Write, Edit) |
| `dontAsk` | Auto-deny unpermitted actions |
| `bypassPermissions` | Skip all permission checks |
| `plan` | Read-only planning mode |

### Permission Patterns

Permissions use glob-like patterns:

```
Tool(command:argument)
```

| Pattern | Matches |
|---------|---------|
| `Bash(git:*)` | Any git command |
| `Bash(npm run:*)` | Any npm run script |
| `Bash(npm install:*)` | npm install with any package |
| `Read` | All file reads |
| `Edit(src/**/*.ts)` | Edit TypeScript in src/ |
| `Write(*.md)` | Write markdown files |

### Allow vs Deny

```json
{
  "permissions": {
    "allow": [
      "Bash(git:*)",
      "Bash(npm:*)",
      "Read",
      "Edit",
      "Write"
    ],
    "deny": [
      "Bash(rm -rf:*)",
      "Bash(sudo:*)",
      "Bash(curl|wget:*)"
    ]
  }
}
```

Deny rules take precedence over allow rules.

## Configuration

### Project Permissions

```json
// .claude/settings.json
{
  "permissions": {
    "allow": [
      "Bash(git:*)",
      "Bash(npm test:*)",
      "Bash(npm run lint:*)",
      "Read",
      "Glob",
      "Grep"
    ]
  }
}
```

### Local Overrides

```json
// .claude/settings.local.json (gitignored)
{
  "permissions": {
    "allow": [
      "Bash(npm run dev:*)",
      "Bash(docker:*)"
    ]
  }
}
```

### Enterprise Restrictions

Enterprise settings can lock permissions:

```json
{
  "permissions": {
    "deny": [
      "Bash(curl|wget:*)",
      "Bash(ssh:*)"
    ],
    "locked": true
  }
}
```

When `locked: true`, lower scopes cannot override.

## Examples

### Read-Only Agent

```json
{
  "permissions": {
    "allow": [
      "Read",
      "Glob",
      "Grep",
      "Bash(git status:*)",
      "Bash(git log:*)"
    ],
    "deny": [
      "Write",
      "Edit",
      "Bash(git commit:*)",
      "Bash(git push:*)"
    ]
  }
}
```

### Full Development Access

```json
{
  "permissions": {
    "allow": [
      "Bash(git:*)",
      "Bash(npm:*)",
      "Bash(node:*)",
      "Bash(python:*)",
      "Read",
      "Edit",
      "Write",
      "Glob",
      "Grep"
    ],
    "deny": [
      "Bash(rm -rf:*)",
      "Bash(sudo:*)"
    ]
  }
}
```

### Database Read-Only

```json
{
  "permissions": {
    "allow": [
      "Bash(psql -c \"SELECT:*)",
      "Read"
    ],
    "deny": [
      "Bash(psql -c \"INSERT|UPDATE|DELETE:*)"
    ]
  }
}
```

## Agency Relevance

**Very High** - Directly maps to our permission model:

| Current Agency | Native Permission Equivalent |
|----------------|----------------------------|
| `claude/docs/PERMISSIONS.md` | Native permission system |
| `.claude/settings.json` | Same file, same patterns |
| `.claude/settings.local.json` | Same pattern for overrides |
| Agent tool restrictions | Subagent `tools`/`disallowedTools` |

### Benefits
1. **Pattern-based** - Granular control over commands
2. **Layered** - Project, local, enterprise scopes
3. **Deny priority** - Safety first approach
4. **Path patterns** - File operation scoping

### Current Implementation
We already use this permission model. Our `PERMISSIONS.md` documentation describes the same layered approach that Claude Code supports natively.

### Enhancement Ideas
1. Use permission modes in subagents (`acceptEdits`, `dontAsk`)
2. Add more granular deny patterns for dangerous commands
3. Consider enterprise-level restrictions for sensitive operations

## Links/Sources

- [Permissions Documentation](https://code.claude.com/docs/en/permissions)
- [Security Best Practices](https://code.claude.com/docs/en/security)
