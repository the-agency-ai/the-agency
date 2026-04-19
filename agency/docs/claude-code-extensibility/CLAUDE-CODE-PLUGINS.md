---
title: Claude Code Plugins
created: 2026-01-21T12:50:00
author: captain
version: 1.0.0
source: https://code.claude.com/docs/en/plugins
---

# Claude Code Plugins

Plugins bundle skills, agents, hooks, and configuration into shareable packages.

## Overview

Plugins extend Claude Code with additional capabilities that can be distributed and shared. A plugin can include skills, subagents, hooks, MCP servers, and settings in a single package.

## Key Features

### Plugin Structure

```
my-plugin/
├── .claude-plugin/
│   └── plugin.json       # Plugin manifest
├── skills/
│   └── my-skill/
│       └── SKILL.md
├── agents/
│   └── my-agent.md
├── hooks/
│   └── hooks.json
└── README.md
```

### Plugin Manifest

```json
// .claude-plugin/plugin.json
{
  "name": "my-plugin",
  "version": "1.0.0",
  "description": "Plugin description",
  "author": "Author Name",
  "skills": ["skills/*"],
  "agents": ["agents/*"],
  "hooks": "hooks/hooks.json",
  "mcpServers": {
    "plugin-server": {
      "command": "node",
      "args": ["./server.js"]
    }
  }
}
```

### Plugin Locations

| Location | Path | Discovery |
|----------|------|-----------|
| Local | `.claude/plugins/<name>/` | Automatic |
| User | `~/.claude/plugins/<name>/` | Automatic |
| NPM | `@scope/claude-plugin-*` | Via install |
| Marketplace | Claude Code Marketplace | Via install |

### Namespacing

Plugin resources are namespaced to avoid conflicts:

```bash
# Skill from plugin
/my-plugin:skill-name

# Agent from plugin
Task subagent_type=my-plugin:agent-name
```

## Configuration

### Installing Plugins

```bash
# From npm
claude plugin install @company/claude-plugin-react

# From local path
claude plugin install ./path/to/plugin

# From marketplace
claude plugin install react-patterns
```

### Plugin Settings

```json
// .claude/settings.json
{
  "plugins": {
    "my-plugin": {
      "enabled": true,
      "config": {
        "option1": "value1"
      }
    }
  }
}
```

### Plugin Hooks

Plugins can define hooks that integrate with Claude's lifecycle:

```json
// hooks/hooks.json
{
  "hooks": {
    "PostToolUse": [{
      "matcher": "Edit|Write",
      "hooks": [{
        "type": "command",
        "command": "./scripts/plugin-lint.sh"
      }]
    }]
  }
}
```

## Examples

### React Development Plugin

```json
{
  "name": "react-patterns",
  "version": "1.0.0",
  "description": "React development patterns and tools",
  "skills": ["skills/*"],
  "agents": ["agents/*"]
}
```

With skills:
```
skills/
├── component-generator/
│   └── SKILL.md
├── hook-patterns/
│   └── SKILL.md
└── testing-patterns/
    └── SKILL.md
```

### Database Plugin

```json
{
  "name": "db-tools",
  "version": "1.0.0",
  "description": "Database development tools",
  "mcpServers": {
    "postgres": {
      "command": "npx",
      "args": ["-y", "@mcp/postgres-server"]
    }
  },
  "agents": ["agents/db-analyst.md"]
}
```

### LSP Server Plugin

```json
{
  "name": "typescript-enhanced",
  "version": "1.0.0",
  "description": "Enhanced TypeScript support",
  "lspServers": {
    "typescript": {
      "command": "typescript-language-server",
      "args": ["--stdio"]
    }
  }
}
```

## Agency Relevance

**High** - Plugin model could package Agency components:

| Current Agency | Plugin Equivalent |
|----------------|------------------|
| `agency/agents/` | Plugin agents/ directory |
| `tools/` scripts | Plugin skills/ directory |
| Agent KNOWLEDGE.md | Plugin skills with context |
| MCP servers | Plugin mcpServers config |

### Benefits
1. **Distribution** - Share Agency patterns as plugins
2. **Namespacing** - Avoid conflicts with user customizations
3. **Versioning** - Plugin versions for compatibility
4. **Marketplace** - Discover community plugins

### Implementation Ideas

The Agency could become a plugin:

```json
// .claude-plugin/plugin.json
{
  "name": "the-agency",
  "version": "1.0.0",
  "description": "Multi-agent development framework",
  "skills": [
    "skills/commit",
    "skills/collaborate",
    "skills/review-spawn"
  ],
  "agents": [
    "agents/captain",
    "agents/research"
  ],
  "hooks": "hooks/agency-hooks.json"
}
```

### Distribution Options
1. **NPM package** - `@the-agency/claude-plugin`
2. **Marketplace** - List on Claude Code Marketplace
3. **GitHub** - Direct installation from repo

## Links/Sources

- [Plugins Documentation](https://code.claude.com/docs/en/plugins)
- [Creating Plugins](https://code.claude.com/docs/en/creating-plugins)
- [Plugin Marketplace](https://marketplace.claude.com)
