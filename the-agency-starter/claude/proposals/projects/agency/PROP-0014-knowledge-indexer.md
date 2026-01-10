# PROP-0014: Knowledge Indexer

**Status:** draft
**Priority:** high
**Created:** 2026-01-06
**Author:** jordan + housekeeping
**Project:** agency

## Problem

The Agency accumulates knowledge in various directories:
- `claude/knowledge/` - Curated knowledge bases
- `claude/docs/` - Guides and documentation
- `claude/agents/*/KNOWLEDGE.md` - Agent-specific knowledge
- `claude/workstreams/*/KNOWLEDGE.md` - Workstream knowledge

Finding specific information requires scanning through files. Agents waste tokens exploring when they could just ask "where do I find X?"

## Proposal

Create a **Knowledge Indexer** that:
1. Builds a searchable index of all knowledge directories
2. Integrates with TheCaptain for natural language queries
3. Provides a `./tools/where` command for quick lookups

### Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     KNOWLEDGE INDEXER                            │
│                                                                  │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐       │
│  │   Scanner    │ →  │   Indexer    │ →  │    Index     │       │
│  │              │    │              │    │   (JSON)     │       │
│  │  Walks dirs  │    │  Extracts:   │    │              │       │
│  │  Reads .md   │    │  - Titles    │    │  - Topics    │       │
│  │  Parses      │    │  - Headings  │    │  - Locations │       │
│  │              │    │  - Keywords  │    │  - Summaries │       │
│  └──────────────┘    └──────────────┘    └──────────────┘       │
│                                                                  │
│                              ▲                                   │
│                              │                                   │
│  ┌──────────────┐    ┌──────┴───────┐    ┌──────────────┐       │
│  │ ./tools/where│ →  │  TheCaptain  │ ←  │ Agent Query  │       │
│  │              │    │  Integration │    │              │       │
│  │ "where do I  │    │              │    │ "In this KB, │       │
│  │  find..."    │    │  Uses index  │    │  where..."   │       │
│  └──────────────┘    └──────────────┘    └──────────────┘       │
└─────────────────────────────────────────────────────────────────┘
```

### Usage

#### CLI Tool

```bash
# Quick lookup
./tools/where "deployment"
→ Found in:
  - claude/knowledge/claude-code/07-advanced.md (Deployment Options section)
  - claude/docs/guides/architecture-development-guide-v3.0.md (CI/CD section)

# Specific knowledge base
./tools/where --kb claude-code "checkpoints"
→ Found in:
  - claude/knowledge/claude-code/07-advanced.md#checkpoints

# Rebuild index
./tools/index-knowledge
```

#### Natural Language (via TheCaptain)

```
> Where do I find information about MCP servers?

TheCaptain: Based on the knowledge index, MCP server documentation is in:
- claude/knowledge/claude-code/07-advanced.md#mcp
- See also: claude/knowledge/claude-code/05-configuration.md
```

### Index Format

```json
{
  "version": "1.0.0",
  "generated": "2026-01-06T10:00:00+08:00",
  "sources": [
    {
      "path": "claude/knowledge/claude-code/07-advanced.md",
      "title": "Claude Code Advanced Features",
      "headings": [
        {"level": 2, "text": "Checkpoints", "line": 10},
        {"level": 2, "text": "Subagents", "line": 45},
        {"level": 2, "text": "MCP", "line": 80}
      ],
      "keywords": ["checkpoint", "rewind", "subagent", "hook", "mcp"],
      "summary": "Advanced Claude Code features including checkpoints, subagents, hooks, and MCP integration."
    }
  ],
  "topics": {
    "checkpoints": ["claude/knowledge/claude-code/07-advanced.md#checkpoints"],
    "mcp": ["claude/knowledge/claude-code/07-advanced.md#mcp"],
    "deployment": ["claude/docs/guides/architecture-development-guide-v3.0.md"]
  }
}
```

### Knowledge Sources

| Directory | Type | Indexed |
|-----------|------|---------|
| `claude/knowledge/*/` | Curated knowledge bases | All .md files |
| `claude/docs/guides/` | Developer guides | All .md files |
| `claude/agents/*/KNOWLEDGE.md` | Agent knowledge | KNOWLEDGE.md only |
| `claude/workstreams/*/KNOWLEDGE.md` | Workstream knowledge | KNOWLEDGE.md only |
| `.claude/` | Project config | CLAUDE.md only |

### TheCaptain Integration

TheCaptain's skill file includes:

```markdown
---
name: knowledge-lookup
description: Find information in the knowledge base
allowed-tools: Read
---

When asked "where do I find" or similar:

1. Read the knowledge index at `claude/knowledge/INDEX.json`
2. Search for matching topics, keywords, or headings
3. Return specific file paths with section anchors
4. Suggest related topics if exact match not found
```

### Index Update Strategy

| Trigger | Action |
|---------|--------|
| `./tools/index-knowledge` | Full rebuild |
| Post-commit hook | Incremental update for changed .md files |
| Session start | Check if index is stale (>24h) |

## Implementation Phases

### Phase 1: Basic Index (MVP)

- Scanner walks directories
- Extracts titles and headings
- Generates INDEX.json
- `./tools/where` does grep-like search

### Phase 2: TheCaptain Integration

- TheCaptain reads index
- Natural language queries
- Topic mapping

### Phase 3: Smart Indexing

- Keyword extraction
- Summary generation (LLM-powered)
- Cross-reference detection

## Open Questions

- [ ] Should index include line numbers for deep linking?
- [ ] Full-text search or just metadata?
- [ ] LLM-generated summaries for each file?
- [ ] Version the index file?

## Dependencies

- TheCaptain (for natural language queries)
- `jq` (for JSON manipulation in bash)

## When Approved

- Becomes: INSTR-XXXX
- Assigned to: housekeeping
- Target: v0.2.0

---

## Discussion Log

### 2026-01-06 - Created

Jordan: "A tool that you point at a directory of knowledge and it builds an index that is tied to TheCaptain and I can ask questions like 'In this knowledge base, where do I find?' Or just a general 'where do I find.'"

This solves the problem of agents spending tokens exploring when they could just look up the answer.
