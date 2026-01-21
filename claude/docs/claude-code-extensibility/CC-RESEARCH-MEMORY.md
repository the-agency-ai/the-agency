---
title: Claude Code Memory System (CLAUDE.md)
created: 2026-01-21T13:40:00+08:00
author: research-agent
version: 1.0.0
source: Claude Code Documentation
---

# Claude Code Memory System (CLAUDE.md)

## Overview

Claude Code uses CLAUDE.md files to remember preferences and instructions across sessions. These files are automatically loaded into Claude's context at startup.

## Memory Locations

| Type | Location | Shared With | Purpose |
|------|----------|-------------|---------|
| Enterprise | System directory | All users in org | Company standards |
| User | `~/.claude/CLAUDE.md` | Just you | Personal preferences |
| Project | `./CLAUDE.md` or `./.claude/CLAUDE.md` | Team (via git) | Project instructions |
| Project Rules | `./.claude/rules/*.md` | Team (via git) | Modular rules |
| Local | `./CLAUDE.local.md` | Just you | Personal project prefs |

## Enterprise Memory Locations

| Platform | Path |
|----------|------|
| macOS | `/Library/Application Support/ClaudeCode/CLAUDE.md` |
| Linux | `/etc/claude-code/CLAUDE.md` |
| Windows | `C:\Program Files\ClaudeCode\CLAUDE.md` |

## Memory Precedence

Files higher in the hierarchy take precedence:
1. Enterprise policy
2. Project memory
3. Project rules
4. User memory
5. Project local memory

## Import Syntax

CLAUDE.md files can import other files using `@path/to/file`:

```markdown
See @README for project overview and @package.json for available commands.

# Additional Instructions
- git workflow @docs/git-instructions.md
```

Features:
- Relative and absolute paths supported
- Home directory imports: `@~/.claude/my-project-instructions.md`
- Not evaluated inside code blocks/spans
- Recursive imports (max depth: 5)

## Recursive Directory Lookup

Claude Code reads CLAUDE.md recursively:
- Starting in cwd, recurses up to (not including) root
- Discovers CLAUDE.md in subtrees when reading files in those directories

Example structure:
```
project/
├── CLAUDE.md              # Loaded at startup
├── foo/
│   └── CLAUDE.md          # Loaded when working in foo/
└── foo/bar/
    └── CLAUDE.md          # Loaded when working in foo/bar/
```

## Modular Rules (.claude/rules/)

Organize instructions into focused files:

```
.claude/
├── CLAUDE.md              # Main instructions
└── rules/
    ├── code-style.md      # Code style guidelines
    ├── testing.md         # Testing conventions
    └── security.md        # Security requirements
```

All `.md` files in `.claude/rules/` are loaded automatically.

## Path-Specific Rules

Use YAML frontmatter with `paths` field for conditional rules:

```markdown
---
paths:
  - "src/api/**/*.ts"
---

# API Development Rules

- All API endpoints must include input validation
- Use the standard error response format
```

Glob patterns supported:
- `**/*.ts` - All TypeScript files
- `src/**/*` - All files under src/
- `*.md` - Markdown files in root
- `src/**/*.{ts,tsx}` - Brace expansion

## The /memory Command

Use `/memory` to open memory files in your editor.

## Bootstrap with /init

Create initial CLAUDE.md:
```
> /init
```

## CLAUDE.md Best Practices

1. **Be specific**: "Use 2-space indentation" not "Format code properly"
2. **Use structure**: Bullet points and markdown headings
3. **Review periodically**: Update as project evolves
4. **Include commands**: Document frequently used build/test commands

## Example CLAUDE.md

```markdown
# Project: My App

## Build Commands
- `npm run dev` - Start development server
- `npm run test` - Run tests
- `npm run lint` - Lint code

## Code Style
- Use TypeScript strict mode
- Prefer functional components
- Use 2-space indentation

## Architecture
- `/src/components` - React components
- `/src/hooks` - Custom hooks
- `/src/utils` - Utility functions

## Conventions
- Use kebab-case for file names
- Use PascalCase for components
- Always include unit tests
```

## Symlink Support

The `.claude/rules/` directory supports symlinks:

```bash
# Symlink shared rules
ln -s ~/shared-claude-rules .claude/rules/shared

# Symlink individual files
ln -s ~/company-standards/security.md .claude/rules/security.md
```

## User-Level Rules

Personal rules in `~/.claude/rules/`:

```
~/.claude/rules/
├── preferences.md         # Personal coding preferences
└── workflows.md           # Preferred workflows
```

User rules loaded before project rules (lower priority).

## Agency Relevance

The memory system could enhance The Agency:

1. **Agent Context** - Each agent has its own `agent.md` (similar to CLAUDE.md)
2. **Workstream Knowledge** - Shared `KNOWLEDGE.md` files
3. **Project Rules** - `.claude/rules/` for modular conventions
4. **Import System** - `@` imports for shared instructions
5. **Path-Specific Rules** - Different rules for different areas

## Links/Sources

- [Memory Documentation](https://code.claude.com/docs/en/memory)
