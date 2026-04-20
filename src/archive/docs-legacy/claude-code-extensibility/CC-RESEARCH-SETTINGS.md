---
title: Claude Code Settings and Configuration
created: 2026-01-21T13:40:00+08:00
author: research-agent
version: 1.0.0
source: Claude Code Documentation
---

# Claude Code Settings and Configuration

## Overview

Claude Code uses a hierarchical configuration system with JSON settings files at multiple scopes. Higher scopes take precedence over lower scopes.

## Configuration Scopes

| Scope | Location | Who it affects | Shared? |
|-------|----------|----------------|---------|
| Managed | System directory | All users on machine | Yes (IT deployed) |
| User | `~/.claude/` | You, across all projects | No |
| Project | `.claude/` in repo | All collaborators | Yes (git) |
| Local | `.claude/*.local.*` | You, in this repo only | No (gitignored) |

## Settings File Locations

| Scope | Settings File |
|-------|---------------|
| Managed (macOS) | `/Library/Application Support/ClaudeCode/managed-settings.json` |
| Managed (Linux) | `/etc/claude-code/managed-settings.json` |
| Managed (Windows) | `C:\Program Files\ClaudeCode\managed-settings.json` |
| User | `~/.claude/settings.json` |
| Project | `.claude/settings.json` |
| Local | `.claude/settings.local.json` |

## Settings Precedence

From highest to lowest:
1. Managed settings (cannot be overridden)
2. Command line arguments
3. Local project settings
4. Shared project settings
5. User settings

## Example settings.json

```json
{
  "permissions": {
    "allow": [
      "Bash(npm run lint)",
      "Bash(npm run test:*)",
      "Read(~/.zshrc)"
    ],
    "deny": [
      "Bash(curl:*)",
      "Read(./.env)",
      "Read(./secrets/**)"
    ]
  },
  "env": {
    "CLAUDE_CODE_ENABLE_TELEMETRY": "1"
  },
  "hooks": {
    "PostToolUse": [{
      "matcher": "Write|Edit",
      "hooks": [{
        "type": "command",
        "command": "npm run lint:fix"
      }]
    }]
  },
  "model": "claude-sonnet-4-5-20250929"
}
```

## Key Settings

### Permission Settings

| Key | Description |
|-----|-------------|
| `permissions.allow` | Array of permission rules to allow |
| `permissions.deny` | Array of permission rules to deny |
| `permissions.ask` | Array of rules requiring confirmation |
| `permissions.additionalDirectories` | Extra directories Claude can access |
| `permissions.defaultMode` | Default permission mode |
| `permissions.disableBypassPermissionsMode` | Disable `--dangerously-skip-permissions` |

### Permission Rule Syntax

```
Tool                    # Match all uses
Tool(specifier)         # Match specific use
Bash(npm run:*)         # Prefix matching (word boundary)
Bash(ls*)               # Glob matching
Read(./.env)            # File path
Read(./secrets/**)      # Glob pattern
```

### Environment Settings

| Key | Description |
|-----|-------------|
| `env` | Environment variables for all sessions |
| `apiKeyHelper` | Custom script for auth value |
| `awsAuthRefresh` | AWS credential refresh script |
| `awsCredentialExport` | AWS credential export script |

### Model Settings

| Key | Description |
|-----|-------------|
| `model` | Override default model |
| `alwaysThinkingEnabled` | Enable extended thinking |

### Behavior Settings

| Key | Description | Default |
|-----|-------------|---------|
| `cleanupPeriodDays` | Session cleanup period | 30 |
| `showTurnDuration` | Show turn duration messages | true |
| `language` | Response language | (system) |
| `autoUpdatesChannel` | "stable" or "latest" | "latest" |
| `spinnerTipsEnabled` | Show spinner tips | true |

### Attribution Settings

```json
{
  "attribution": {
    "commit": "Generated with AI\n\nCo-Authored-By: AI <ai@example.com>",
    "pr": ""
  }
}
```

### Sandbox Settings

```json
{
  "sandbox": {
    "enabled": true,
    "autoAllowBashIfSandboxed": true,
    "excludedCommands": ["git", "docker"],
    "network": {
      "allowUnixSockets": ["/var/run/docker.sock"],
      "allowLocalBinding": true
    }
  }
}
```

### MCP Server Settings

| Key | Description |
|-----|-------------|
| `enableAllProjectMcpServers` | Auto-approve project MCP servers |
| `enabledMcpjsonServers` | List of approved servers |
| `disabledMcpjsonServers` | List of rejected servers |
| `allowedMcpServers` | Managed allowlist |
| `deniedMcpServers` | Managed denylist |

### Plugin Settings

```json
{
  "enabledPlugins": {
    "formatter@acme-tools": true,
    "analyzer@security-plugins": false
  },
  "extraKnownMarketplaces": {
    "acme-tools": {
      "source": {
        "source": "github",
        "repo": "acme-corp/plugins"
      }
    }
  }
}
```

## Environment Variables

Key environment variables (can also be set in `env` field):

| Variable | Purpose |
|----------|---------|
| `ANTHROPIC_API_KEY` | API key for Claude SDK |
| `ANTHROPIC_MODEL` | Model to use |
| `CLAUDE_CODE_USE_BEDROCK` | Use AWS Bedrock |
| `CLAUDE_CODE_USE_VERTEX` | Use Google Vertex AI |
| `CLAUDE_CODE_USE_FOUNDRY` | Use Microsoft Foundry |
| `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` | Auto-compaction threshold |
| `MAX_THINKING_TOKENS` | Extended thinking budget |
| `MCP_TIMEOUT` | MCP server startup timeout |
| `DISABLE_TELEMETRY` | Opt out of telemetry |
| `DISABLE_AUTOUPDATER` | Disable auto-updates |

## Managed Settings (Enterprise)

Managed settings for organization-wide control:

```json
{
  "disableBypassPermissionsMode": "disable",
  "allowManagedHooksOnly": true,
  "strictKnownMarketplaces": [
    { "source": "github", "repo": "company/approved-plugins" }
  ],
  "allowedMcpServers": [
    { "serverName": "github" }
  ],
  "deniedMcpServers": [
    { "serverName": "dangerous-server" }
  ]
}
```

## The /config Command

Run `/config` in Claude Code to open interactive settings interface.

## Agency Relevance

Configuration system could benefit The Agency:

1. **Project Settings** - Share agent configurations via `.claude/settings.json`
2. **Permission Rules** - Pre-approve common tool patterns
3. **Hook Configuration** - Team-wide automation
4. **MCP Server Config** - Standardize tool integrations
5. **Environment Variables** - Share development environment setup

## Links/Sources

- [Settings Documentation](https://code.claude.com/docs/en/settings)
- [Tool Permission Rules](https://code.claude.com/docs/en/tool-permissions)
