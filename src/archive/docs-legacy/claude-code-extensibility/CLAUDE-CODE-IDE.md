---
title: Claude Code IDE Integrations
created: 2026-01-21T12:50:00
author: captain
version: 1.0.0
source: https://code.claude.com/docs/en/ide
---

# Claude Code IDE Integrations

Claude Code integrates with popular IDEs to provide AI assistance directly in your development environment.

## Overview

IDE integrations bring Claude Code capabilities into your editor. You can interact with Claude, run commands, and get AI assistance without leaving your IDE.

## Key Features

### Supported IDEs

| IDE | Extension | Features |
|-----|-----------|----------|
| VS Code | Claude Code Extension | Full integration |
| JetBrains | Claude Code Plugin | Full integration |
| Neovim | claude.nvim | Basic integration |
| Emacs | claude.el | Basic integration |

### Core Features

| Feature | Description |
|---------|-------------|
| Chat panel | Conversational interface |
| Inline suggestions | Context-aware completions |
| Code actions | Refactor, explain, fix |
| Terminal integration | Run Claude Code CLI |
| Diff view | Review proposed changes |

## Configuration

### VS Code Extension

```json
// .vscode/settings.json
{
  "claude.model": "sonnet",
  "claude.enableInlineSuggestions": true,
  "claude.enableCodeActions": true,
  "claude.terminal.enabled": true,
  "claude.projectSettings": ".claude/settings.json"
}
```

### JetBrains Plugin

```xml
<!-- .idea/claude.xml -->
<component name="ClaudeSettings">
  <option name="model" value="sonnet" />
  <option name="enableInspections" value="true" />
  <option name="enableIntentions" value="true" />
</component>
```

### Keybindings

| Action | VS Code | JetBrains |
|--------|---------|-----------|
| Open chat | `Cmd+Shift+C` | `Cmd+Shift+C` |
| Explain selection | `Cmd+Shift+E` | `Alt+Shift+E` |
| Fix issue | `Cmd+Shift+F` | `Alt+Shift+F` |
| Refactor | `Cmd+Shift+R` | `Alt+Shift+R` |

## Examples

### VS Code Workflow

1. **Select code** in editor
2. **Right-click** → "Ask Claude"
3. **Type question** in chat panel
4. **Review** suggested changes in diff view
5. **Apply** changes with one click

### JetBrains Workflow

1. **Alt+Enter** on code with issue
2. **Select** "Ask Claude to fix"
3. **Review** inline suggestion
4. **Accept** or modify

### Terminal Integration

```bash
# In IDE terminal
claude "Explain this function" src/utils.ts:42

# Run skill
/commit

# Ask for help
claude --help
```

### Code Actions

```typescript
// Select this function and use "Explain" code action
function complexAlgorithm(data: number[]): number {
  return data.reduce((acc, val, idx) =>
    acc + val * Math.pow(2, idx), 0);
}

// Claude explains:
// "This function computes a weighted sum where each element
// is multiplied by 2 raised to its index position..."
```

## IDE-Specific Features

### VS Code

- **Workspace awareness** - Claude sees your project structure
- **Problem integration** - Claude can address diagnostics
- **Source control** - Claude sees git status
- **Tasks** - Run Claude as VS Code task

### JetBrains

- **Inspection integration** - Claude as code inspector
- **Intention actions** - Claude-powered quick fixes
- **Run configurations** - Claude as run target
- **Tool windows** - Dedicated Claude panel

## Agency Relevance

**Medium** - IDE integration complements CLI usage:

| Current Agency | IDE Equivalent |
|----------------|---------------|
| CLI-based workflow | IDE chat panel |
| Terminal tab colors | IDE status indicators |
| `./tools/myclaude` | IDE extension launch |

### Benefits
1. **Seamless integration** - AI in your editor
2. **Context awareness** - Claude sees your code
3. **Quick actions** - One-click operations
4. **Diff review** - Visual change inspection

### Considerations

The Agency is CLI-first by design:
- Multiple agents in multiple terminals
- Workstream/agent organization
- Collaboration patterns

IDE integration works best for:
- Individual developer sessions
- Quick questions and fixes
- Single-agent interactions

### Hybrid Workflow

```bash
# Terminal: Run Agency captain for orchestration
./tools/myclaude housekeeping captain

# IDE: Quick code questions and fixes
# Use VS Code Claude extension for in-editor assistance

# Terminal: Collaboration and multi-agent work
./tools/collaborate research "Need analysis of..."
```

## Links/Sources

- [IDE Integration Overview](https://code.claude.com/docs/en/ide)
- [VS Code Extension](https://marketplace.visualstudio.com/items?itemName=anthropic.claude-code)
- [JetBrains Plugin](https://plugins.jetbrains.com/plugin/claude-code)
- [Configuration Guide](https://code.claude.com/docs/en/ide-config)
