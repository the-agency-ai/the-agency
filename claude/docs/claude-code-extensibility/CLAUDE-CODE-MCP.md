---
title: Claude Code MCP Servers
created: 2026-01-21T12:50:00
author: captain
version: 1.0.0
source: https://code.claude.com/docs/en/mcp
---

# Claude Code MCP Servers

MCP (Model Context Protocol) servers extend Claude's capabilities with external tools and data sources.

## Overview

MCP is an open protocol for connecting AI models to external systems. Claude Code can connect to MCP servers that provide tools, resources, and prompts. This enables integration with databases, APIs, file systems, and custom tooling.

## Key Features

### MCP Server Types

| Type | Purpose | Examples |
|------|---------|----------|
| Tools | Extend Claude's actions | Database queries, API calls |
| Resources | Provide data/context | File contents, documentation |
| Prompts | Inject instructions | Domain-specific guidance |

### Configuration

```json
// .claude/settings.json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/path/to/dir"]
    },
    "postgres": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-postgres"],
      "env": {
        "DATABASE_URL": "postgresql://..."
      }
    }
  }
}
```

### Server Lifecycle

1. Claude Code starts MCP servers on launch
2. Servers register available tools/resources
3. Claude can invoke tools as needed
4. Servers shut down when session ends

## Configuration

### Server Definition

| Field | Description | Required |
|-------|-------------|----------|
| `command` | Executable to run | Yes |
| `args` | Command arguments | No |
| `env` | Environment variables | No |
| `cwd` | Working directory | No |

### Environment Variables

```json
{
  "mcpServers": {
    "api-server": {
      "command": "node",
      "args": ["./mcp-server.js"],
      "env": {
        "API_KEY": "${API_KEY}",
        "API_URL": "https://api.example.com"
      }
    }
  }
}
```

### OAuth Authentication

Some MCP servers support OAuth:

```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@mcp/github-server"],
      "oauth": {
        "provider": "github",
        "scopes": ["repo", "read:user"]
      }
    }
  }
}
```

## Examples

### Filesystem Server

```json
{
  "mcpServers": {
    "project-files": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-filesystem",
        "./src",
        "./docs"
      ]
    }
  }
}
```

### Database Server

```json
{
  "mcpServers": {
    "postgres": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-postgres"],
      "env": {
        "PGHOST": "localhost",
        "PGPORT": "5432",
        "PGDATABASE": "mydb",
        "PGUSER": "user"
      }
    }
  }
}
```

### Browser Automation

```json
{
  "mcpServers": {
    "browser": {
      "command": "npx",
      "args": ["-y", "@anthropic/browser-mcp"]
    }
  }
}
```

### Custom MCP Server

```javascript
// mcp-server.js
import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";

const server = new Server({
  name: "custom-server",
  version: "1.0.0"
}, {
  capabilities: {
    tools: {}
  }
});

server.setRequestHandler("tools/list", async () => ({
  tools: [{
    name: "custom_tool",
    description: "Does something custom",
    inputSchema: {
      type: "object",
      properties: {
        input: { type: "string" }
      }
    }
  }]
}));

server.setRequestHandler("tools/call", async (request) => {
  if (request.params.name === "custom_tool") {
    return { content: [{ type: "text", text: "Result" }] };
  }
});

const transport = new StdioServerTransport();
await server.connect(transport);
```

## Available MCP Servers

### Official Servers

| Server | Package | Purpose |
|--------|---------|---------|
| Filesystem | `@modelcontextprotocol/server-filesystem` | File operations |
| PostgreSQL | `@modelcontextprotocol/server-postgres` | Database queries |
| GitHub | `@mcp/github-server` | GitHub integration |
| Slack | `@mcp/slack-server` | Slack messaging |
| Browser | `@anthropic/browser-mcp` | Browser automation |

### Community Servers

Searchable via `claude mcp search <query>` or MCP Hub.

## Agency Relevance

**Very High** - MCP enables powerful integrations:

| Current Agency | MCP Equivalent |
|----------------|---------------|
| `./tools/gh` wrapper | GitHub MCP server |
| Browser agent | Browser MCP server |
| Custom API calls | Custom MCP server |
| Database operations | Postgres MCP server |

### Benefits
1. **Standard protocol** - Interoperable tools
2. **External tools** - Extend beyond built-in capabilities
3. **OAuth support** - Secure authentication
4. **Custom servers** - Build domain-specific tools

### Implementation Ideas

```json
// Agency-specific MCP servers
{
  "mcpServers": {
    "agency-service": {
      "command": "node",
      "args": ["./mcp/agency-server.js"],
      "env": {
        "AGENCY_PORT": "3141"
      }
    },
    "browser": {
      "command": "npx",
      "args": ["-y", "@anthropic/browser-mcp"]
    }
  }
}
```

### Custom Agency MCP Server

Could expose Agency operations as MCP tools:
- `agency_request_create` - Create new requests
- `agency_request_complete` - Mark requests complete
- `agency_collaborate` - Send collaboration messages
- `agency_news_post` - Post news broadcasts

## Links/Sources

- [MCP Documentation](https://code.claude.com/docs/en/mcp)
- [MCP Specification](https://spec.modelcontextprotocol.io)
- [MCP Hub](https://hub.modelcontextprotocol.io)
- [Building MCP Servers](https://code.claude.com/docs/en/mcp-servers)
