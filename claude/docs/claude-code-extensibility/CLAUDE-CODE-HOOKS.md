---
title: Claude Code Hooks
created: 2026-01-21T12:50:00
author: captain
version: 1.0.0
source: https://code.claude.com/docs/en/hooks
---

# Claude Code Hooks

Hooks are event handlers that run custom logic at specific lifecycle points in Claude Code.

## Overview

Hooks allow you to automate workflows by executing commands, evaluating prompts with an LLM, or running full agents at key moments like before/after tool use, session start/end, and when Claude stops.

## Key Features

### Hook Events

| Event | Matcher Input | When It Fires |
|-------|---------------|---------------|
| `PreToolUse` | Tool name | Before tool execution |
| `PostToolUse` | Tool name | After tool succeeds |
| `PostToolUseFailure` | Tool name | After tool fails |
| `PermissionRequest` | Tool name | Permission dialog shown |
| `UserPromptSubmit` | (none) | User submits prompt |
| `SessionStart` | Source | Session begins |
| `SessionEnd` | (none) | Session ends |
| `Stop` | (none) | Claude attempts to stop |
| `SubagentStart` | Agent name | Subagent begins |
| `SubagentStop` | Agent name | Subagent stops |
| `Setup` | Trigger | `--init` or `--maintenance` |
| `PreCompact` | Trigger | Before compaction |
| `Notification` | Type | Notification sent |

### Hook Types

| Type | Description | Use Case |
|------|-------------|----------|
| `command` | Execute shell script | Validation, formatting, logging |
| `prompt` | LLM evaluates decision | Intelligent stop decisions |
| `agent` | Full agent with tools | Complex verification tasks |

### SessionStart Matchers
- `startup` - New session
- `resume` - From `--resume`, `--continue`, `/resume`
- `clear` - From `/clear`
- `compact` - From auto or manual compact

### Notification Matchers
- `permission_prompt` - Permission requests
- `idle_prompt` - Waiting for user (60+ seconds)
- `auth_success` - Authentication success
- `elicitation_dialog` - MCP tool input needed

## Configuration

### Settings File Structure
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

### Hook Locations
- `~/.claude/settings.json` - User settings
- `.claude/settings.json` - Project settings
- `.claude/settings.local.json` - Local (not committed)
- `hooks/hooks.json` - Plugin hooks
- Skill/Agent frontmatter - Scoped to component

### Environment Variables
- `CLAUDE_PROJECT_DIR` - Absolute path to project root
- `CLAUDE_ENV_FILE` - Path to persist env vars (SessionStart only)
- `CLAUDE_PLUGIN_ROOT` - Plugin directory (plugin hooks)

## Examples

### Command Hook - Auto-format After Edits
```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "npm run lint:fix"
          }
        ]
      }
    ]
  }
}
```

### Prompt Hook - Intelligent Stop Decision
```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "prompt",
            "prompt": "Evaluate if Claude should stop. Context: $ARGUMENTS\n\nCheck if:\n1. All tasks are complete\n2. No errors need addressing\n3. No follow-up needed\n\nRespond: {\"ok\": true} to stop, or {\"ok\": false, \"reason\": \"explanation\"} to continue.",
            "timeout": 30
          }
        ]
      }
    ]
  }
}
```

### SessionStart - Load Context
```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup",
        "hooks": [
          {
            "type": "command",
            "command": "./tools/welcomeback"
          }
        ]
      }
    ]
  }
}
```

### SessionStart - Persist Environment
```bash
#!/bin/bash
# Hook script with CLAUDE_ENV_FILE
if [ -n "$CLAUDE_ENV_FILE" ]; then
    echo 'export NODE_ENV=production' >> "$CLAUDE_ENV_FILE"
    echo 'export API_KEY=your-api-key' >> "$CLAUDE_ENV_FILE"
fi
exit 0
```

### PreToolUse - Block Dangerous Commands
```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "./scripts/validate-command.sh"
          }
        ]
      }
    ]
  }
}
```

### Skill-Scoped Hook (One-Time)
```yaml
---
name: setup-env
description: Set up development environment
hooks:
  PostToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "./scripts/verify-setup.sh"
          once: true  # Only runs once per session
---
```

## Hook Input/Output

### Input (JSON via stdin)
```json
{
  "session_id": "abc123",
  "transcript_path": "/path/to/transcript.jsonl",
  "cwd": "/current/directory",
  "permission_mode": "default",
  "hook_event_name": "PreToolUse",
  "tool_name": "Bash",
  "tool_input": {
    "command": "npm run test"
  },
  "tool_use_id": "toolu_01ABC..."
}
```

### Exit Codes
| Code | Behavior |
|------|----------|
| 0 | Success, continue |
| 2 | Blocking error, stderr shown to Claude |
| Other | Non-blocking error, logged |

### JSON Output (Exit 0)
```json
{
  "decision": "block",
  "reason": "Explanation for Claude",
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "allow|deny|ask",
    "permissionDecisionReason": "Why",
    "updatedInput": { "command": "modified" },
    "additionalContext": "Extra info for Claude"
  }
}
```

## Agency Relevance

**High** - Enhances our current hook usage:

| Current Agency | Enhanced Capability |
|----------------|-------------------|
| SessionStart welcomeback | Add `CLAUDE_ENV_FILE` for env persistence |
| Manual tool checks | `PreToolUse` with validation scripts |
| Manual reviews | `Stop` with prompt-based completion check |
| Post-edit linting | `PostToolUse` auto-formatting |

### New Capabilities
1. **Prompt-based hooks** - LLM evaluates decisions
2. **Agent hooks** - Full agent verification
3. **Skill-scoped hooks** - Isolated to skill execution
4. **`once: true`** - One-time execution per session
5. **`updatedInput`** - Modify tool parameters
6. **`additionalContext`** - Inject context for Claude

### Implementation Ideas
```json
{
  "hooks": {
    "Stop": [{
      "hooks": [{
        "type": "prompt",
        "prompt": "Check if all TODO items in the todo list are complete and tests pass before stopping."
      }]
    }],
    "PostToolUse": [{
      "matcher": "Edit|Write",
      "hooks": [{
        "type": "command",
        "command": "./tools/test-run --changed-only"
      }]
    }]
  }
}
```

## Links/Sources

- [Hooks Reference](https://code.claude.com/docs/en/hooks)
- [Get Started with Hooks](https://code.claude.com/docs/en/hooks-tutorial)
