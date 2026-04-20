---
title: Claude Code Hooks System
created: 2026-01-21T13:35:00+08:00
author: research-agent
version: 1.0.0
source: Claude Code Documentation
---

# Claude Code Hooks System

## Overview

Hooks allow you to run custom commands before or after tool executions and lifecycle events. They provide automation, validation, and workflow customization capabilities.

## Key Features

- Execute bash commands or LLM-based evaluation
- Filter by tool name with matcher patterns
- Control tool execution (allow/deny/ask)
- Modify tool inputs before execution
- Inject context into conversations
- Persist environment variables (SessionStart)

## Configuration

Hooks are configured in settings files:

```json
{
  "hooks": {
    "EventName": [
      {
        "matcher": "ToolPattern",
        "hooks": [
          {
            "type": "command",
            "command": "your-command-here",
            "timeout": 60
          }
        ]
      }
    ]
  }
}
```

## Hook Events

| Event | Matcher Input | When It Fires |
|-------|---------------|---------------|
| PreToolUse | Tool name | Before tool execution |
| PostToolUse | Tool name | After tool completion |
| PermissionRequest | Tool name | When permission dialog shown |
| UserPromptSubmit | (none) | When user submits prompt |
| Stop | (none) | When main agent finishes |
| SubagentStop | (none) | When subagent finishes |
| SessionStart | startup/resume/clear/compact | When session starts |
| SessionEnd | (none) | When session ends |
| PreCompact | manual/auto | Before compaction |
| Setup | init/maintenance | With --init or --maintenance |
| Notification | notification_type | When notifications sent |

## Hook Types

### Command Hooks (type: "command")

Execute bash commands with JSON input via stdin:

```json
{
  "type": "command",
  "command": "./scripts/validate.sh",
  "timeout": 60
}
```

### Prompt Hooks (type: "prompt")

Use LLM (Haiku) for intelligent evaluation:

```json
{
  "type": "prompt",
  "prompt": "Evaluate if Claude should stop: $ARGUMENTS",
  "timeout": 30
}
```

## Exit Codes

| Exit Code | Behavior |
|-----------|----------|
| 0 | Success - stdout processed for JSON control |
| 2 | Blocking error - stderr shown to Claude |
| Other | Non-blocking error - continue execution |

## Decision Control

### PreToolUse Decisions

```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "allow|deny|ask",
    "permissionDecisionReason": "Explanation",
    "updatedInput": { "field": "new value" },
    "additionalContext": "Context for Claude"
  }
}
```

### Stop/SubagentStop Decisions

```json
{
  "decision": "block",
  "reason": "Must complete additional tasks"
}
```

## Environment Variables

Hooks receive these environment variables:

- `CLAUDE_PROJECT_DIR` - Absolute path to project root
- `CLAUDE_CODE_REMOTE` - "true" if remote environment
- `CLAUDE_ENV_FILE` - Path for persisting env vars (SessionStart only)

## Example: Bash Command Validation

```python
#!/usr/bin/env python3
import json
import sys

input_data = json.load(sys.stdin)
command = input_data.get("tool_input", {}).get("command", "")

# Block dangerous commands
if "rm -rf" in command:
    print("Blocked: Dangerous command", file=sys.stderr)
    sys.exit(2)

sys.exit(0)
```

## Example: SessionStart Context Loading

```bash
#!/bin/bash
if [ -n "$CLAUDE_ENV_FILE" ]; then
    echo 'export NODE_ENV=development' >> "$CLAUDE_ENV_FILE"
fi

# Add context to Claude
echo "Project initialized at $(date)"
exit 0
```

## Plugin Hooks

Plugins can provide hooks in `hooks/hooks.json`:

```json
{
  "description": "Automatic code formatting",
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/scripts/format.sh"
          }
        ]
      }
    ]
  }
}
```

## Managed Hooks

Enterprise administrators can use `allowManagedHooksOnly: true` in managed settings to:
- Only allow managed and SDK hooks
- Block user, project, and plugin hooks

## Agency Relevance

The Agency framework could leverage hooks for:

1. **SessionStart hooks** - Auto-load agent context at session start
2. **PreToolUse hooks** - Validate commands against project conventions
3. **PostToolUse hooks** - Auto-format code, run linters
4. **Stop hooks** - Ensure work is properly documented before stopping
5. **UserPromptSubmit hooks** - Inject project context based on prompts

## Links/Sources

- [Hooks Reference](https://code.claude.com/docs/en/hooks)
- [Get Started with Hooks](https://code.claude.com/docs/en/hooks-tutorial)
