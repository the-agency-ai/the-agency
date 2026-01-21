---
title: Claude Code Extensibility Features - Overview
created: 2026-01-21T12:50:00
author: captain
version: 1.0.0
source: Claude Code Documentation (https://code.claude.com/docs)
research_method: Browser automation via Claude in Chrome
---

# Claude Code Extensibility Features

Comprehensive overview of all extension and customization mechanisms available in Claude Code.

## Executive Summary

Claude Code provides a rich extensibility ecosystem that enables customization at multiple levels:

- **Configuration** - Settings, permissions, and environment
- **Instructions** - Memory, rules, and output styles
- **Automation** - Hooks, skills, and subagents
- **Integration** - Plugins, MCP servers, and SDK access
- **Deployment** - IDE integrations and CI/CD via GitHub Actions

This document provides an overview with links to detailed documentation for each feature area.

---

## Feature Categories

### Core Automation Features

| Feature | Description | Detail Document |
|---------|-------------|-----------------|
| [Skills](#skills) | Reusable prompts and workflows | [CLAUDE-CODE-SKILLS.md](./CLAUDE-CODE-SKILLS.md) |
| [Subagents](#subagents) | Specialized task handlers | [CLAUDE-CODE-SUBAGENTS.md](./CLAUDE-CODE-SUBAGENTS.md) |
| [Hooks](#hooks) | Lifecycle event automation | [CLAUDE-CODE-HOOKS.md](./CLAUDE-CODE-HOOKS.md) |

### Configuration & Instructions

| Feature | Description | Detail Document |
|---------|-------------|-----------------|
| [Memory](#memory) | Project instructions and rules | [CLAUDE-CODE-MEMORY.md](./CLAUDE-CODE-MEMORY.md) |
| [Settings](#settings) | Configuration options | [CLAUDE-CODE-SETTINGS.md](./CLAUDE-CODE-SETTINGS.md) |
| [Permissions](#permissions) | Tool access control | [CLAUDE-CODE-PERMISSIONS.md](./CLAUDE-CODE-PERMISSIONS.md) |
| [Output Styles](#output-styles) | Response formatting | [CLAUDE-CODE-OUTPUT-STYLES.md](./CLAUDE-CODE-OUTPUT-STYLES.md) |

### Extensibility & Integration

| Feature | Description | Detail Document |
|---------|-------------|-----------------|
| [Plugins](#plugins) | Distributable packages | [CLAUDE-CODE-PLUGINS.md](./CLAUDE-CODE-PLUGINS.md) |
| [MCP Servers](#mcp-servers) | External tool integration | [CLAUDE-CODE-MCP.md](./CLAUDE-CODE-MCP.md) |
| [Agent SDK](#agent-sdk) | Programmatic access | [CLAUDE-CODE-AGENT-SDK.md](./CLAUDE-CODE-AGENT-SDK.md) |

### Deployment & Workflow

| Feature | Description | Detail Document |
|---------|-------------|-----------------|
| [IDE Integration](#ide-integration) | VS Code, JetBrains | [CLAUDE-CODE-IDE.md](./CLAUDE-CODE-IDE.md) |
| [GitHub Actions](#github-actions) | CI/CD automation | [CLAUDE-CODE-GITHUB-ACTIONS.md](./CLAUDE-CODE-GITHUB-ACTIONS.md) |

---

## Feature Summaries

### Skills

**Location**: `.claude/skills/*/SKILL.md` or `~/.claude/skills/*/SKILL.md`

Skills are reusable instruction packages that extend Claude's capabilities. They can be invoked via `/skill-name` or loaded automatically when relevant.

**Key Features**:
- YAML frontmatter for configuration
- `context: fork` for isolated subagent execution
- Dynamic context injection with `!`command`` syntax
- `$ARGUMENTS` and `${CLAUDE_SESSION_ID}` substitutions
- Skill-scoped hooks with `once: true` option
- Supporting files (templates, scripts, examples)

**Agency Relevance**: High - Could replace our `./tools/` scripts with native skills.

→ [Full Documentation](./CLAUDE-CODE-SKILLS.md)

---

### Subagents

**Location**: `.claude/agents/*.md` or `~/.claude/agents/*.md`

Specialized AI assistants that handle specific types of tasks with custom prompts, tool access, and permissions.

**Key Features**:
- Markdown files with YAML frontmatter
- Model selection (`sonnet`, `opus`, `haiku`, `inherit`)
- Tool restrictions via `tools` and `disallowedTools`
- Permission modes (`default`, `acceptEdits`, `dontAsk`, `bypassPermissions`, `plan`)
- Skill preloading via `skills:` field
- Resume capability with agent ID
- Foreground/background execution

**Built-in Subagents**:
- `Explore` (Haiku, read-only) - Codebase exploration
- `Plan` (inherit, read-only) - Planning research
- `general-purpose` (inherit, all tools) - Complex tasks

**Agency Relevance**: Very High - Direct mapping to our agent model.

→ [Full Documentation](./CLAUDE-CODE-SUBAGENTS.md)

---

### Hooks

**Location**: `settings.json` or skill/agent frontmatter

Event handlers that run custom logic at specific lifecycle points.

**Hook Events**:
- `PreToolUse` / `PostToolUse` / `PostToolUseFailure` - Tool lifecycle
- `PermissionRequest` - Permission dialogs
- `UserPromptSubmit` - Before prompt processing
- `SessionStart` / `SessionEnd` - Session lifecycle
- `Stop` / `SubagentStop` - Completion decisions
- `SubagentStart` - Subagent initialization
- `Setup` - One-time initialization (`--init`, `--maintenance`)
- `PreCompact` - Before context compaction
- `Notification` - System notifications

**Hook Types**:
1. `command` - Execute shell commands
2. `prompt` - LLM evaluates decision
3. `agent` - Full agent with tools for verification

**Key Features**:
- `CLAUDE_ENV_FILE` for persisting environment variables (SessionStart)
- `additionalContext` injection
- `updatedInput` for modifying tool parameters
- Skill-scoped hooks with `once: true`

**Agency Relevance**: High - Enhances our current hook usage.

→ [Full Documentation](./CLAUDE-CODE-HOOKS.md)

---

### Memory

**Location**: `CLAUDE.md`, `.claude/CLAUDE.md`, `.claude/rules/*.md`, `~/.claude/CLAUDE.md`

Project instructions and context that Claude loads at startup.

**Memory Hierarchy** (highest to lowest precedence):
1. Enterprise policy (`/Library/Application Support/ClaudeCode/CLAUDE.md`)
2. Project memory (`./CLAUDE.md` or `./.claude/CLAUDE.md`)
3. Project rules (`./.claude/rules/*.md`)
4. User memory (`~/.claude/CLAUDE.md`)
5. Project local (`./CLAUDE.local.md`)

**Key Features**:
- **Imports**: `@path/to/file` syntax for modular composition
- **Path-specific rules**: YAML frontmatter with `paths:` glob patterns
- **Symlinks**: Supported for shared rules across projects
- **Recursive discovery**: Nested `.claude/rules/` in subdirectories

**Agency Relevance**: High - Could modularize our KNOWLEDGE.md files.

→ [Full Documentation](./CLAUDE-CODE-MEMORY.md)

---

### Settings

**Location**: `~/.claude/settings.json`, `.claude/settings.json`, `.claude/settings.local.json`

Configuration options for Claude Code behavior.

**Scope Precedence** (highest to lowest):
1. Managed (`managed-settings.json`)
2. Command line arguments
3. Local (`.claude/settings.local.json`)
4. Project (`.claude/settings.json`)
5. User (`~/.claude/settings.json`)

**Notable Settings**:
- `outputStyle` - Custom response formatting
- `statusLine` - Custom status display (command-based)
- `fileSuggestion` - Custom @ file autocomplete
- `plansDirectory` - Plan file location
- `language` - Response language preference
- `attribution` - Git commit attribution
- `sandbox` - Bash sandboxing configuration

**Agency Relevance**: Medium - Several settings we could leverage.

→ [Full Documentation](./CLAUDE-CODE-SETTINGS.md)

---

### Permissions

**Location**: `settings.json` under `permissions` key

Tool access control with allow/ask/deny rules.

**Key Features**:
- Pattern matching: `Tool`, `Tool(specifier)`, `Tool(prefix:*)`
- Glob patterns for file paths
- Tool-specific rules (Bash, Read, Edit, WebFetch, MCP, Task)
- `additionalDirectories` for expanded access
- `defaultMode` and `disableBypassPermissionsMode`

**Agency Relevance**: Medium - Already use permissions, could expand.

→ [Full Documentation](./CLAUDE-CODE-PERMISSIONS.md)

---

### Output Styles

**Location**: `.claude/output-styles/*.md` or `~/.claude/output-styles/*.md`

Modify Claude's response formatting by altering the system prompt.

**Built-in Styles**:
- `Default` - Standard coding assistant
- `Explanatory` - Educational insights while coding
- `Learning` - Collaborative with `TODO(human)` markers

**Custom Style Frontmatter**:
- `name` - Style name
- `description` - UI display text
- `keep-coding-instructions` - Retain coding system prompt (default: false)

**Agency Relevance**: Medium - Could enforce response conventions.

→ [Full Documentation](./CLAUDE-CODE-OUTPUT-STYLES.md)

---

### Plugins

**Location**: `.claude-plugin/plugin.json` at plugin root

Distributable packages containing skills, agents, hooks, and MCP servers.

**Plugin Components**:
- `.claude-plugin/plugin.json` - Manifest (required)
- `commands/` - Slash commands
- `skills/` - Agent Skills
- `agents/` - Subagent definitions
- `hooks/hooks.json` - Event handlers
- `.mcp.json` - MCP server configurations
- `.lsp.json` - LSP server configurations

**Key Features**:
- Namespaced skills (`/plugin-name:skill`)
- Plugin marketplaces for distribution
- `--plugin-dir` for local development
- CLI management (`claude plugin install/enable/disable`)

**Agency Relevance**: Medium - Could package The Agency as a plugin.

→ [Full Documentation](./CLAUDE-CODE-PLUGINS.md)

---

### MCP Servers

**Location**: `.mcp.json` or `~/.claude.json`

Model Context Protocol servers for external tool integration.

**Transport Types**:
- HTTP (recommended for remote)
- SSE (deprecated)
- stdio (local processes)

**Scopes**:
- Local (default) - Project-specific, private
- Project - Shared via `.mcp.json`
- User - Cross-project

**Key Features**:
- OAuth 2.0 authentication
- Tool Search for dynamic loading (when many tools)
- MCP resources via @ mentions
- MCP prompts as /commands
- Plugin-bundled MCP servers

**Agency Relevance**: Medium - Could expose Agency service as MCP.

→ [Full Documentation](./CLAUDE-CODE-MCP.md)

---

### Agent SDK

**Location**: Python/TypeScript libraries

Programmatic access to Claude Code capabilities.

**Key Features**:
- Built-in tools: Read, Write, Edit, Bash, Glob, Grep, WebSearch, WebFetch, AskUserQuestion
- Supports Claude Code filesystem configuration
- `setting_sources=["project"]` to enable project config
- Hooks, subagents, MCP, permissions, sessions

**Agency Relevance**: Medium - Could use for programmatic agent launching.

→ [Full Documentation](./CLAUDE-CODE-AGENT-SDK.md)

---

### IDE Integration

**Supported IDEs**: VS Code, JetBrains (IntelliJ, PyCharm, WebStorm, GoLand, PhpStorm)

**JetBrains Features**:
- Quick launch: `Cmd+Esc` / `Ctrl+Esc`
- Diff viewing in IDE
- Selection context sharing
- File reference shortcuts
- Diagnostic sharing

**Agency Relevance**: Low - Standard IDE integration.

→ [Full Documentation](./CLAUDE-CODE-IDE.md)

---

### GitHub Actions

**Location**: `.github/workflows/*.yml`

CI/CD automation via `anthropics/claude-code-action@v1`.

**Key Features**:
- @claude mentions trigger automation
- Skills support in prompts (e.g., `/review`)
- CLI passthrough via `claude_args`
- AWS Bedrock / Google Vertex AI support
- CLAUDE.md respected for guidelines

**Example Triggers**:
- `@claude implement this feature`
- `@claude fix the TypeError`
- Scheduled daily reports
- PR open triggers

**Agency Relevance**: Medium - Could integrate agents into CI.

→ [Full Documentation](./CLAUDE-CODE-GITHUB-ACTIONS.md)

---

## Quick Reference

### File Locations

| Item | User Level | Project Level | Local |
|------|------------|---------------|-------|
| Settings | `~/.claude/settings.json` | `.claude/settings.json` | `.claude/settings.local.json` |
| Subagents | `~/.claude/agents/*.md` | `.claude/agents/*.md` | - |
| Skills | `~/.claude/skills/*/SKILL.md` | `.claude/skills/*/SKILL.md` | - |
| Memory | `~/.claude/CLAUDE.md` | `CLAUDE.md`, `.claude/CLAUDE.md` | `CLAUDE.local.md` |
| Rules | `~/.claude/rules/*.md` | `.claude/rules/*.md` | - |
| Output Styles | `~/.claude/output-styles/*.md` | `.claude/output-styles/*.md` | - |
| MCP Servers | `~/.claude.json` | `.mcp.json` | - |

### Environment Variables

| Variable | Purpose |
|----------|---------|
| `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` | Auto-compaction threshold (1-100) |
| `CLAUDE_CODE_SUBAGENT_MODEL` | Default model for subagents |
| `MAX_THINKING_TOKENS` | Extended thinking budget (0 to disable) |
| `ENABLE_TOOL_SEARCH` | MCP tool search (auto, auto:N, true, false) |
| `CLAUDE_CODE_EXIT_AFTER_STOP_DELAY` | Auto-exit delay (ms) |
| `CLAUDE_ENV_FILE` | SessionStart env persistence file |

---

## Related Documents

- [CLAUDE-CODE-EXTENSIBILITY-RECOMMENDATIONS.md](./CLAUDE-CODE-EXTENSIBILITY-RECOMMENDATIONS.md) - Implementation recommendations for The Agency
- [RESEARCH-DIRECTION-CLAUDE-CODE-EXTENSIBILITY.md](./RESEARCH-DIRECTION-CLAUDE-CODE-EXTENSIBILITY.md) - Research methodology

## Sources

All information sourced from official Claude Code documentation:
- https://code.claude.com/docs
- https://platform.claude.com/docs/en/agent-sdk/overview
