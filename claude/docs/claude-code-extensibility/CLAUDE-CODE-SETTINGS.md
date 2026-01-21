---
title: Claude Code Settings
created: 2026-01-21T12:50:00
author: captain
version: 1.0.0
source: https://code.claude.com/docs/en/settings
---

# Claude Code Settings

Settings control Claude Code behavior through JSON configuration files at multiple scopes.

## Overview

Claude Code uses a layered settings system where project, user, and enterprise settings merge together. Settings control permissions, tool access, model preferences, and behavioral options.

## Key Features

### Settings Hierarchy

| Scope | Location | Purpose |
|-------|----------|---------|
| Enterprise | Managed deployment | Organization policies |
| User | `~/.claude/settings.json` | Personal preferences |
| Project | `.claude/settings.json` | Team-shared settings |
| Local | `.claude/settings.local.json` | Personal (gitignored) |

Lower scopes can override higher scopes unless enterprise policy restricts it.

### Core Settings

| Setting | Type | Description |
|---------|------|-------------|
| `model` | string | Default model (sonnet, opus, haiku) |
| `statusLine` | object | Terminal status line configuration |
| `fileSuggestion` | boolean | Enable file path autocomplete |
| `sandbox` | object | Sandbox mode configuration |
| `allowedTools` | array | Tools Claude can use |
| `disallowedTools` | array | Tools Claude cannot use |
| `permissions` | object | Granular permission rules |

### Status Line Configuration

```json
{
  "statusLine": {
    "enabled": true,
    "position": "bottom",
    "showModel": true,
    "showTokens": true,
    "showCost": false
  }
}
```

### Sandbox Configuration

```json
{
  "sandbox": {
    "enabled": true,
    "allowNetworkAccess": false,
    "allowFileWrites": true,
    "restrictedPaths": ["/etc", "/var"]
  }
}
```

## Configuration

### Full Settings Example

```json
{
  "model": "sonnet",
  "statusLine": {
    "enabled": true,
    "position": "bottom"
  },
  "fileSuggestion": true,
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
      "Bash(sudo:*)"
    ]
  },
  "hooks": {
    "SessionStart": [{
      "hooks": [{
        "type": "command",
        "command": "./tools/welcomeback"
      }]
    }]
  },
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem"]
    }
  }
}
```

### Environment Variables

| Variable | Description |
|----------|-------------|
| `CLAUDE_MODEL` | Override default model |
| `CLAUDE_PROJECT_DIR` | Project root path |
| `CLAUDE_ENV_FILE` | Path for persistent env vars |
| `CLAUDE_SESSION_ID` | Current session identifier |

## Examples

### Minimal Project Settings

```json
{
  "permissions": {
    "allow": ["Bash(npm:*)"]
  }
}
```

### Development vs Production

```json
// .claude/settings.json (committed)
{
  "permissions": {
    "allow": ["Bash(npm test:*)"]
  }
}

// .claude/settings.local.json (gitignored)
{
  "permissions": {
    "allow": ["Bash(npm run dev:*)"]
  }
}
```

## Agency Relevance

**High** - Our settings approach aligns well:

| Current Agency | Native Settings Equivalent |
|----------------|---------------------------|
| `.claude/settings.json` | Same location, same purpose |
| `.claude/settings.local.json` | Same pattern for local overrides |
| Tool permissions | `permissions.allow` / `permissions.deny` |
| Hooks configuration | Native `hooks` key in settings |

### Benefits
1. **Native integration** - Settings file format is standard
2. **Layered overrides** - Local settings don't get committed
3. **Permission patterns** - Tool access control built-in
4. **MCP servers** - External tools configured in settings

### Implementation Ideas
Our existing settings structure is already compatible. We could:
1. Add more granular permission patterns
2. Use statusLine for agent identification
3. Configure sandbox for safer agent execution

## Links/Sources

- [Settings Reference](https://code.claude.com/docs/en/settings)
- [Configuration Guide](https://code.claude.com/docs/en/configuration)
