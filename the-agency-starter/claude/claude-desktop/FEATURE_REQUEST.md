# Feature Request: Claude Desktop/Code Integration APIs

**From:** The Agency Project
**Date:** 2026-01-01
**To:** Anthropic Developer Relations

## Summary

We're building "The Agency" - an open-source multi-agent development framework for Claude Code. We've hit a significant limitation: **there's no programmatic way to integrate Claude Desktop with Claude Code**.

## The Vision

A seamless workflow where:
1. **Claude Desktop** handles planning, research, high-level design
2. **Claude Code** handles implementation, testing, deployment
3. **Handoffs** between them are automated, not copy-paste

## What We Need

### 1. Projects API

```
POST   /v1/projects              # Create project
GET    /v1/projects              # List projects
GET    /v1/projects/:id          # Get project
PATCH  /v1/projects/:id          # Update project
DELETE /v1/projects/:id          # Delete project
```

### 2. Project Knowledge API

```
POST   /v1/projects/:id/knowledge           # Add knowledge
GET    /v1/projects/:id/knowledge           # List knowledge
DELETE /v1/projects/:id/knowledge/:kid      # Remove knowledge
```

Ideally, knowledge could be:
- Files (uploaded via Files API)
- Text content
- URLs (fetched and indexed)

### 3. Project Instructions API

```
GET    /v1/projects/:id/instructions        # Get custom instructions
PUT    /v1/projects/:id/instructions        # Set custom instructions
```

### 4. Artifacts API

```
GET    /v1/conversations/:id/artifacts      # List artifacts from conversation
GET    /v1/artifacts/:id                    # Get artifact content
POST   /v1/artifacts/:id/to-knowledge       # Convert to project knowledge
GET    /v1/artifacts/:id/download           # Download artifact
```

### 5. Cross-Environment Triggers

Either webhooks or MCP-based:

```
# Webhook approach
POST /v1/projects/:id/webhooks
{
  "event": "artifact_created",
  "url": "https://my-server.com/hook"
}

# Or MCP-based
{
  "mcpServers": {
    "triggers": {
      "type": "http",
      "url": "https://api.anthropic.com/v1/mcp/triggers"
    }
  }
}
```

Events we'd want:
- `artifact_created`
- `knowledge_added`
- `conversation_started`
- `project_updated`

## Use Cases

### Multi-Agent Development

```
┌─────────────────────────────────────────────────────────┐
│                    THE AGENCY                            │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  Claude Desktop                    Claude Code           │
│  ┌────────────────┐               ┌────────────────┐    │
│  │ Planning       │──────────────▶│ Implementation │    │
│  │ Research       │   Handoff     │ Testing        │    │
│  │ Architecture   │◀──────────────│ Deployment     │    │
│  └────────────────┘   Results     └────────────────┘    │
│                                                          │
│  Projects API + Triggers enable automated handoffs      │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

### Knowledge Synchronization

1. Claude Code generates documentation
2. Automatically syncs to Desktop project knowledge
3. Desktop sessions have full context
4. Desktop creates artifacts (diagrams, specs)
5. Automatically available in Code

### Team Workflows

1. PM uses Desktop to create requirements (artifacts)
2. Triggers webhook → creates Claude Code instruction
3. Developer agents implement
4. Results sync back to Desktop project
5. PM reviews in familiar environment

## Why This Matters

Claude Code and Claude Desktop serve different needs:
- **Desktop**: Better for exploration, research, visual artifacts
- **Code**: Better for implementation, file operations, git

Forcing developers to choose one or manually bridge them limits what's possible.

## Current Workarounds (All Suboptimal)

1. **Manual copy-paste** - Breaks flow, loses context
2. **Files API** - Works for documents, not projects/artifacts
3. **MCP shared state** - Adds complexity, doesn't solve triggering
4. **Computer Use** - Fragile, slow, meta

## Impact

The Agency is open-source and aims to establish patterns for multi-agent Claude development. With these APIs, we could:

- Ship with Desktop ↔ Code integration out of the box
- Enable new workflow patterns the community builds on
- Demonstrate Claude's full potential for software development

## We're Happy To

- Test beta APIs
- Provide feedback on design
- Document patterns for the community
- Build reference implementations

## Contact

- GitHub: [the-agency-starter](https://github.com/your-org/the-agency-starter)
- Email: [your contact]

---

*The Agency - Multi-agent development, done right.*
