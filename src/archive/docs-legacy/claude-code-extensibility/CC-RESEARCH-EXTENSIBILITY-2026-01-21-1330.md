---
title: Claude Code Extensibility Features - Research Overview
created: 2026-01-21T13:30:00+08:00
author: research-agent
version: 1.0.0
source: Claude Code Documentation (https://code.claude.com/docs)
---

# Claude Code Extensibility Features - Research Overview

## Executive Summary

Claude Code provides a comprehensive extensibility framework that allows users, teams, and organizations to customize and extend its capabilities. This research documents all extensibility mechanisms discovered in the official documentation.

## Extensibility Features Overview

| Feature | Purpose | Scope | Complexity |
|---------|---------|-------|------------|
| **Settings/Configuration** | Behavior customization via JSON | Managed/User/Project/Local | Low |
| **CLAUDE.md (Memory)** | Custom instructions and context | Enterprise/User/Project/Local | Low |
| **Skills** | Reusable prompts and workflows | User/Project/Plugin | Medium |
| **Subagents** | Custom AI assistants | User/Project/Plugin | Medium |
| **Hooks** | Lifecycle event automation | Managed/User/Project/Plugin | Medium |
| **MCP Servers** | External tool integrations | Managed/User/Project/Local | Medium-High |
| **Plugins** | Full extension packages | Marketplace/Local | High |
| **Agent SDK** | Programmatic access | API | High |

## Feature Categories

### 1. Configuration System

Claude Code uses a hierarchical configuration system with four scopes (from highest to lowest precedence):

1. **Managed** - Organization-wide, deployed by IT (cannot be overridden)
2. **Local** - Personal overrides for specific project
3. **Project** - Team-shared settings (committed to git)
4. **User** - Personal global settings

**Key Files:**
- `settings.json` - Main configuration
- `CLAUDE.md` - Instructions and context
- `.mcp.json` - MCP server configuration

### 2. Memory System (CLAUDE.md)

Custom instructions loaded into Claude's context at startup:

| Type | Location | Shared With |
|------|----------|-------------|
| Enterprise | System directory | All users in org |
| User | `~/.claude/CLAUDE.md` | Just you (all projects) |
| Project | `./CLAUDE.md` or `./.claude/CLAUDE.md` | Team via git |
| Project Rules | `./.claude/rules/*.md` | Team via git |
| Local | `./CLAUDE.local.md` | Just you (this project) |

**Key Features:**
- Supports `@path/to/file` imports
- Recursive directory lookup
- Path-specific rules with glob patterns
- Modular organization via `.claude/rules/`

### 3. Skills

Extend Claude's capabilities with reusable prompts and instructions.

**Storage Locations:**
- User: `~/.claude/skills/<skill-name>/SKILL.md`
- Project: `.claude/skills/<skill-name>/SKILL.md`
- Plugin: `<plugin>/skills/<skill-name>/SKILL.md`

**Key Features:**
- YAML frontmatter configuration
- Automatic invocation based on description
- Manual invocation via `/skill-name`
- Tool restrictions with `allowed-tools`
- Subagent execution with `context: fork`
- Dynamic context injection with `!command` syntax
- Supporting files (templates, examples, scripts)

### 4. Subagents

Specialized AI assistants that handle specific tasks in isolated contexts.

**Built-in Subagents:**
- **Explore** - Fast, read-only codebase exploration (Haiku)
- **Plan** - Research agent for plan mode
- **general-purpose** - Complex multi-step tasks
- **Bash** - Terminal commands
- **Claude Code Guide** - Questions about Claude Code features

**Custom Subagent Features:**
- Markdown files with YAML frontmatter
- Stored in `.claude/agents/` (project) or `~/.claude/agents/` (user)
- Model selection (sonnet, opus, haiku, inherit)
- Tool restrictions
- Permission modes
- Preloaded skills
- Scoped hooks

### 5. Hooks

Custom commands that run before/after tool executions and lifecycle events.

**Hook Events:**
| Event | When It Fires |
|-------|---------------|
| PreToolUse | Before tool execution |
| PostToolUse | After tool completion |
| PermissionRequest | When permission dialog shown |
| UserPromptSubmit | When user submits prompt |
| Stop | When main agent finishes |
| SubagentStop | When subagent finishes |
| SessionStart | When session starts/resumes |
| SessionEnd | When session ends |
| PreCompact | Before compaction |
| Setup | With --init or --maintenance flags |
| Notification | When notifications sent |

**Hook Types:**
- `type: "command"` - Execute bash commands
- `type: "prompt"` - LLM-based evaluation (Haiku)

**Key Features:**
- Matcher patterns for tool filtering
- Decision control (allow/deny/ask)
- Tool input modification
- Context injection
- Environment variable persistence (SessionStart)

### 6. MCP Servers (Model Context Protocol)

Connect Claude Code to external tools, databases, and APIs.

**Transport Types:**
- HTTP (recommended for remote)
- SSE (Server-Sent Events)
- stdio (local processes)

**Configuration Scopes:**
- Local: `~/.claude.json` (current project only)
- Project: `.mcp.json` (shared via git)
- User: `~/.claude.json` (all projects)
- Managed: `managed-mcp.json` (organization-wide)

**Key Features:**
- 100+ pre-built integrations
- OAuth 2.0 authentication
- Dynamic tool updates
- Environment variable expansion
- Plugin-bundled MCP servers
- MCP Tool Search for large tool sets
- Resource references via `@server:protocol://resource`
- Prompts as `/mcp__servername__promptname` commands

### 7. Plugins

Full extension packages that bundle skills, agents, hooks, and MCP servers.

**Plugin Structure:**
```
my-plugin/
├── .claude-plugin/
│   └── plugin.json        # Manifest (required)
├── commands/              # Legacy slash commands
├── skills/                # Agent skills
├── agents/                # Custom subagents
├── hooks/                 # Event handlers
├── .mcp.json              # MCP servers
└── .lsp.json              # LSP servers
```

**Distribution:**
- Local: `--plugin-dir` flag for testing
- Project: Committed to repository
- Marketplace: Shared via GitHub, git, npm, or URL

**Key Features:**
- Plugin namespacing (`/plugin-name:skill`)
- Marketplace management
- Managed restrictions (`strictKnownMarketplaces`)
- LSP server bundling for code intelligence

### 8. Agent SDK

Programmatic access to Claude Code capabilities for building custom agents.

**Available In:**
- Python: `@anthropic-ai/claude-agent-sdk`
- TypeScript: `@anthropic-ai/claude-agent-sdk`

**Key Features:**
- Built-in tools (Read, Write, Edit, Bash, Glob, Grep, WebSearch, WebFetch)
- Hooks support
- Subagent support
- MCP integration
- Permission control
- Session management

**Authentication Options:**
- `ANTHROPIC_API_KEY` (primary)
- Amazon Bedrock (`CLAUDE_CODE_USE_BEDROCK=1`)
- Google Vertex AI (`CLAUDE_CODE_USE_VERTEX=1`)
- Microsoft Foundry (`CLAUDE_CODE_USE_FOUNDRY=1`)

## Configuration Hierarchy Summary

```
┌─────────────────────────────────────────────────────────────┐
│                    MANAGED (Highest)                        │
│  /Library/Application Support/ClaudeCode/ (macOS)           │
│  /etc/claude-code/ (Linux)                                  │
│  Cannot be overridden by users                              │
├─────────────────────────────────────────────────────────────┤
│                    COMMAND LINE                             │
│  Temporary session overrides                                │
├─────────────────────────────────────────────────────────────┤
│                    LOCAL                                    │
│  .claude/settings.local.json                                │
│  CLAUDE.local.md                                            │
│  Personal, project-specific (gitignored)                    │
├─────────────────────────────────────────────────────────────┤
│                    PROJECT                                  │
│  .claude/settings.json                                      │
│  CLAUDE.md, .claude/CLAUDE.md                               │
│  .mcp.json                                                  │
│  .claude/skills/, .claude/agents/                           │
│  Team-shared (committed to git)                             │
├─────────────────────────────────────────────────────────────┤
│                    USER (Lowest)                            │
│  ~/.claude/settings.json                                    │
│  ~/.claude/CLAUDE.md                                        │
│  ~/.claude.json (MCP servers)                               │
│  ~/.claude/skills/, ~/.claude/agents/                       │
│  Personal global settings                                   │
└─────────────────────────────────────────────────────────────┘
```

## Key Documentation URLs

- Overview: https://code.claude.com/docs
- Settings: https://code.claude.com/docs/en/settings
- Memory: https://code.claude.com/docs/en/memory
- Skills: https://code.claude.com/docs/en/skills
- Subagents: https://code.claude.com/docs/en/subagents
- Hooks: https://code.claude.com/docs/en/hooks
- MCP: https://code.claude.com/docs/en/mcp
- Plugins: https://code.claude.com/docs/en/plugins
- Agent SDK: https://platform.claude.com/docs/en/agent-sdk/overview

## Detailed Feature Documents

For deep-dives into each feature area, see:
- `CC-RESEARCH-SETTINGS.md` - Configuration system details
- `CC-RESEARCH-MEMORY.md` - CLAUDE.md and memory system
- `CC-RESEARCH-SKILLS.md` - Skills system details
- `CC-RESEARCH-SUBAGENTS.md` - Subagent configuration
- `CC-RESEARCH-HOOKS.md` - Hook events and configuration
- `CC-RESEARCH-MCP.md` - MCP server integration
- `CC-RESEARCH-PLUGINS.md` - Plugin development
- `CC-RESEARCH-SDK.md` - Agent SDK usage
- `CC-RESEARCH-RECOMMENDATIONS.md` - Agency-specific recommendations
