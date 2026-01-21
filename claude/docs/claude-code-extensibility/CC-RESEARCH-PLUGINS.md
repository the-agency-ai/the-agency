---
title: Claude Code Plugin System
created: 2026-01-21T13:40:00+08:00
author: research-agent
version: 1.0.0
source: Claude Code Documentation
---

# Claude Code Plugin System

## Overview

Plugins extend Claude Code with bundled skills, agents, hooks, MCP servers, and LSP servers. They can be shared via marketplaces and managed at user, project, or organization levels.

## Key Features

- Bundle multiple extension types
- Namespace isolation (`/plugin-name:skill`)
- Marketplace distribution
- Managed restrictions for enterprise
- LSP server support for code intelligence

## Plugin Structure

```
my-plugin/
├── .claude-plugin/
│   └── plugin.json        # Manifest (required)
├── commands/              # Legacy slash commands
├── skills/                # Agent skills
├── agents/                # Custom subagents
├── hooks/
│   └── hooks.json         # Event handlers
├── .mcp.json              # MCP server config
└── .lsp.json              # LSP server config
```

## Plugin Manifest (plugin.json)

```json
{
  "name": "my-plugin",
  "description": "Plugin description",
  "version": "1.0.0",
  "author": {
    "name": "Your Name"
  },
  "homepage": "https://github.com/...",
  "repository": "https://github.com/...",
  "license": "MIT"
}
```

## Plugin Components

### Skills

Located in `skills/<skill-name>/SKILL.md`:

```markdown
---
description: What this skill does
---

Your skill instructions here...
```

Invoked as `/plugin-name:skill-name`.

### Agents

Located in `agents/<agent-name>.md`:

```markdown
---
name: my-agent
description: When to use this agent
tools: Read, Grep, Glob
---

Agent system prompt here...
```

### Hooks

Located in `hooks/hooks.json`:

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
            "command": "${CLAUDE_PLUGIN_ROOT}/scripts/format.sh",
            "timeout": 30
          }
        ]
      }
    ]
  }
}
```

### MCP Servers

Located in `.mcp.json`:

```json
{
  "database-tools": {
    "command": "${CLAUDE_PLUGIN_ROOT}/servers/db-server",
    "args": ["--config", "${CLAUDE_PLUGIN_ROOT}/config.json"],
    "env": {
      "DB_URL": "${DB_URL}"
    }
  }
}
```

### LSP Servers

Located in `.lsp.json`:

```json
{
  "go": {
    "command": "gopls",
    "args": ["serve"],
    "extensionToLanguage": {
      ".go": "go"
    }
  }
}
```

## Plugin Environment Variables

| Variable | Description |
|----------|-------------|
| `${CLAUDE_PLUGIN_ROOT}` | Absolute path to plugin directory |
| `${CLAUDE_PROJECT_DIR}` | Project root directory |

## Testing Plugins

```bash
# Load plugin locally
claude --plugin-dir ./my-plugin

# Load multiple plugins
claude --plugin-dir ./plugin-one --plugin-dir ./plugin-two
```

## Plugin Management

```
/plugin                    # Interactive management
/plugin install <source>   # Install from marketplace
/plugin list               # List installed plugins
/plugin enable <name>      # Enable plugin
/plugin disable <name>     # Disable plugin
```

## Plugin Settings

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

## Marketplace Sources

| Type | Example |
|------|---------|
| GitHub | `{ "source": "github", "repo": "owner/repo" }` |
| Git | `{ "source": "git", "url": "https://..." }` |
| URL | `{ "source": "url", "url": "https://..." }` |
| NPM | `{ "source": "npm", "package": "@scope/pkg" }` |
| File | `{ "source": "file", "path": "/path/to/file" }` |
| Directory | `{ "source": "directory", "path": "/path/to/dir" }` |

## Managed Plugin Restrictions

Enterprise admins can use `strictKnownMarketplaces`:

```json
{
  "strictKnownMarketplaces": [
    { "source": "github", "repo": "company/approved-plugins" },
    { "source": "url", "url": "https://plugins.company.com/..." }
  ]
}
```

- `undefined`: No restrictions
- `[]`: Complete lockdown
- List: Only approved sources allowed

## Converting Standalone to Plugin

1. Create plugin directory with `.claude-plugin/plugin.json`
2. Copy commands from `.claude/commands/`
3. Copy agents from `.claude/agents/`
4. Copy skills from `.claude/skills/`
5. Migrate hooks to `hooks/hooks.json`
6. Test with `--plugin-dir`

## Distribution

1. Add README.md with installation instructions
2. Use semantic versioning
3. Publish to marketplace (GitHub, npm, etc.)
4. Add `extraKnownMarketplaces` for team projects

## Agency Relevance

The plugin system could benefit The Agency:

1. **Agency Plugin** - Package agency tools as a plugin
2. **Workstream Plugins** - Plugin per workstream type
3. **Tool Plugins** - Distribute agency-specific tools
4. **Team Marketplaces** - Private plugin distribution
5. **Managed Control** - Restrict plugins for security

## Links/Sources

- [Create Plugins](https://code.claude.com/docs/en/plugins)
- [Discover Plugins](https://code.claude.com/docs/en/plugins-install)
- [Plugin Reference](https://code.claude.com/docs/en/plugins-reference)
