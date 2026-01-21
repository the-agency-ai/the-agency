---
title: Claude Code MCP Server Integration
created: 2026-01-21T13:35:00+08:00
author: research-agent
version: 1.0.0
source: Claude Code Documentation
---

# Claude Code MCP Server Integration

## Overview

MCP (Model Context Protocol) enables Claude Code to connect to external tools, databases, and APIs through a standardized protocol. It's an open source standard for AI-tool integrations.

## Key Features

- Connect to 100+ pre-built integrations
- Three transport types (HTTP, SSE, stdio)
- OAuth 2.0 authentication support
- Dynamic tool discovery
- Resource references via @ mentions
- Prompts as slash commands

## Transport Types

### HTTP (Recommended for Remote)

```bash
claude mcp add --transport http <name> <url>

# Example: Connect to Notion
claude mcp add --transport http notion https://mcp.notion.com/mcp
```

### SSE (Deprecated)

```bash
claude mcp add --transport sse <name> <url>
```

### stdio (Local Processes)

```bash
claude mcp add --transport stdio <name> -- <command> [args...]

# Example: Add Airtable server
claude mcp add --transport stdio --env AIRTABLE_API_KEY=KEY airtable \
  -- npx -y airtable-mcp-server
```

## Configuration Scopes

| Scope | Location | Shared |
|-------|----------|--------|
| Local | `~/.claude.json` (project path) | No |
| Project | `.mcp.json` | Yes (via git) |
| User | `~/.claude.json` | No |
| Managed | `managed-mcp.json` | Yes (org-wide) |

## .mcp.json Format

```json
{
  "mcpServers": {
    "server-name": {
      "type": "http",
      "url": "https://api.example.com/mcp",
      "headers": {
        "Authorization": "Bearer ${API_KEY}"
      }
    }
  }
}
```

## Environment Variable Expansion

Supported syntax in `.mcp.json`:
- `${VAR}` - Expands to variable value
- `${VAR:-default}` - Uses default if not set

Expansion locations: `command`, `args`, `env`, `url`, `headers`

## MCP Commands

```bash
# List servers
claude mcp list

# Get server details
claude mcp get <name>

# Remove server
claude mcp remove <name>

# Import from Claude Desktop
claude mcp add-from-claude-desktop

# Add from JSON
claude mcp add-json <name> '<json>'
```

## MCP Tool Search

For large tool sets, Claude Code supports dynamic tool loading:

```bash
# Enable at 5% context threshold
ENABLE_TOOL_SEARCH=auto:5 claude

# Always enabled
ENABLE_TOOL_SEARCH=true claude

# Disabled
ENABLE_TOOL_SEARCH=false claude
```

## MCP Resources

Reference MCP resources via @ mentions:

```
Can you analyze @github:issue://123?
Review the docs at @docs:file://api/authentication
```

## MCP Prompts

Execute MCP prompts as commands:

```
/mcp__github__list_prs
/mcp__github__pr_review 456
```

## Popular Integrations

| Service | Command |
|---------|---------|
| GitHub | `claude mcp add --transport http github https://api.githubcopilot.com/mcp/` |
| Sentry | `claude mcp add --transport http sentry https://mcp.sentry.dev/mcp` |
| Linear | `claude mcp add --transport http linear https://mcp.linear.app/mcp` |
| Notion | `claude mcp add --transport http notion https://mcp.notion.com/mcp` |
| Figma | `claude mcp add --transport http figma https://mcp.figma.com/mcp` |
| Slack | Custom URL required |
| Jira | `claude mcp add --transport sse atlassian https://mcp.atlassian.com/v1/mcp` |

## Managed MCP Configuration

For organizations:

### Option 1: Exclusive Control

Deploy `managed-mcp.json` to system directory:
- macOS: `/Library/Application Support/ClaudeCode/managed-mcp.json`
- Linux: `/etc/claude-code/managed-mcp.json`

### Option 2: Policy-Based Control

Use allowlists/denylists in managed settings:

```json
{
  "allowedMcpServers": [
    { "serverName": "github" },
    { "serverUrl": "https://mcp.company.com/*" }
  ],
  "deniedMcpServers": [
    { "serverName": "dangerous-server" }
  ]
}
```

## Plugin-Provided MCP Servers

Plugins can bundle MCP servers in `.mcp.json`:

```json
{
  "database-tools": {
    "command": "${CLAUDE_PLUGIN_ROOT}/servers/db-server",
    "args": ["--config", "${CLAUDE_PLUGIN_ROOT}/config.json"]
  }
}
```

## Claude Code as MCP Server

Use Claude Code as an MCP server for other applications:

```bash
claude mcp serve
```

Claude Desktop configuration:
```json
{
  "mcpServers": {
    "claude-code": {
      "type": "stdio",
      "command": "claude",
      "args": ["mcp", "serve"]
    }
  }
}
```

## Agency Relevance

MCP servers could enhance The Agency with:

1. **GitHub Integration** - Direct PR/issue management
2. **Jira/Linear** - Issue tracking integration
3. **Database Access** - Query project databases
4. **Custom Tools** - Build agency-specific MCP servers
5. **Slack/Teams** - Communication integration

## Links/Sources

- [MCP Documentation](https://code.claude.com/docs/en/mcp)
- [MCP Specification](https://modelcontextprotocol.io/)
