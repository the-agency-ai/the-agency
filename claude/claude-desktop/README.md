# Claude Desktop Integration

This directory contains configuration and tools for integrating The Agency with Claude Desktop via MCP (Model Context Protocol).

## Current State (January 2026)

### What Works

| Capability | Claude Code | Claude Desktop | Via API |
|------------|-------------|----------------|---------|
| MCP servers (add tools) | ✅ | ✅ | ✅ |
| Files API (upload/reference) | ✅ | ✅ | ✅ |
| Messages API (conversations) | ✅ | ✅ | ✅ |
| Computer Use | ✅ | ❌ | ✅ |

### What Doesn't Work (No API)

| Capability | Status | Notes |
|------------|--------|-------|
| Create projects | ❌ | Web UI only |
| Add project knowledge | ❌ | Web UI only |
| Manage project instructions | ❌ | Web UI only |
| Create/manage artifacts | ❌ | Generated in-chat only |
| Trigger Code from Desktop | ❌ | No automation hook |
| Trigger Desktop from Code | ❌ | No automation hook |

**Bottom line:** Projects and Artifacts are Claude.ai web features with no programmatic API. The bidirectional triggering we want doesn't exist yet.

## Known Limitations

### Cannot Do (Yet)

From Claude Code, we cannot:
- Create a Claude Desktop project
- Add knowledge to a Desktop project
- Create chats in Desktop
- Upload files as artifacts
- Convert artifacts to project knowledge
- Download artifacts to Claude Code

From Claude Desktop, we cannot:
- Trigger Claude Code agents
- Pass context to running Code sessions
- Receive handoffs from Code

### Why This Matters

The Agency vision includes seamless handoffs between:
- Claude Desktop (planning, research, high-level design)
- Claude Code (implementation, testing, deployment)

Without APIs, these remain manual copy-paste operations.

## Workarounds

### 1. Files API Sync

Both environments can access files uploaded via the Files API:

```bash
# Upload a file (from code)
curl https://api.anthropic.com/v1/files \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -F "file=@knowledge.md"

# Reference in conversations
"See the context in file_id: file_abc123"
```

### 2. MCP Shared State Server

Build an Agency MCP server that both environments connect to:

```
┌─────────────────┐     ┌─────────────────┐
│  Claude Desktop │     │   Claude Code   │
│                 │     │                 │
│  ┌───────────┐  │     │  ┌───────────┐  │
│  │ MCP Client│  │     │  │ MCP Client│  │
│  └─────┬─────┘  │     │  └─────┬─────┘  │
└────────┼────────┘     └────────┼────────┘
         │                       │
         └───────────┬───────────┘
                     │
              ┌──────┴──────┐
              │ Agency MCP  │
              │   Server    │
              │             │
              │ - Context   │
              │ - Handoffs  │
              │ - Status    │
              └─────────────┘
```

This gives both environments access to:
- Shared context store
- Handoff queue
- Agent status
- Coordination primitives

### 3. Filesystem Sync (Fragile)

Claude Desktop may store project data locally. If we find the location:
- macOS: `~/Library/Application Support/Claude/` (unconfirmed)
- Could sync knowledge files
- Risk: format changes break everything

### 4. Computer Use (Meta/Experimental)

Claude has Computer Use capability - it can control a desktop. Theoretically:
- Claude Code spawns a Claude instance with Computer Use
- That instance clicks through Claude Desktop UI
- Creates projects, adds knowledge, etc.

This is fragile and slow, but technically possible for one-time setup operations.

## Feature Request to Anthropic

**We need:**

1. **Projects API** - Create, read, update, delete projects programmatically
2. **Knowledge API** - Add/remove project knowledge files
3. **Instructions API** - Set/get project custom instructions
4. **Artifacts API** - List, export, convert artifacts to knowledge
5. **Triggering hooks** - Webhook or MCP-based triggers between Desktop ↔ Code

**Use case:** Multi-agent development workflows where Claude Desktop handles high-level planning and Claude Code handles implementation, with seamless handoffs.

**Who to contact:** developer-feedback@anthropic.com or via the Anthropic Discord

## Directory Structure

```
claude-desktop/
  README.md              # This file
  mcp-config.json        # MCP server configuration template
  agency-server/         # Custom Agency MCP server (when built)
    index.ts
    handlers/
  FEATURE_REQUEST.md     # Detailed feature request for Anthropic
```

## MCP Server Setup

### Project-level (`.mcp.json` in project root)

```json
{
  "mcpServers": {
    "agency": {
      "type": "stdio",
      "command": "npx",
      "args": ["tsx", "claude/claude-desktop/agency-server/index.ts"],
      "env": {
        "PROJECT_ROOT": "${workspaceFolder}"
      }
    }
  }
}
```

### Claude Desktop Global

Add to `~/Library/Application Support/Claude/claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "agency": {
      "command": "npx",
      "args": ["tsx", "/path/to/project/claude/claude-desktop/agency-server/index.ts"]
    }
  }
}
```

## Roadmap

### Phase 1: MCP Shared State (Now)
- [ ] Build agency-server with context sharing
- [ ] Document manual handoff workflow
- [ ] Test with Desktop + Code simultaneously

### Phase 2: Files API Integration
- [ ] Upload shared knowledge via Files API
- [ ] Reference in both environments
- [ ] Sync mechanism for updates

### Phase 3: Automation (When APIs Exist)
- [ ] Projects API integration
- [ ] Knowledge sync automation
- [ ] Artifact export/import
- [ ] Bidirectional triggers

## Resources

- [MCP Documentation](https://modelcontextprotocol.io/)
- [Claude Code MCP Guide](https://docs.anthropic.com/en/docs/claude-code)
- [Claude Developer Platform](https://claude.com/platform/api)
- [Files API](https://docs.anthropic.com/en/api/files)
- [Computer Use](https://docs.anthropic.com/en/docs/build-with-claude/computer-use)

---

*Last updated: 2026-01-01*
