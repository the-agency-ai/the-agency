---
title: Claude Code Memory
created: 2026-01-21T12:50:00
author: captain
version: 1.0.0
source: https://code.claude.com/docs/en/memory
---

# Claude Code Memory

Memory files provide project instructions and context that Claude loads at startup.

## Overview

Claude Code reads CLAUDE.md files and rules to understand your project's conventions, standards, and preferences. Memory is hierarchical with organization, user, and project levels.

## Key Features

### Memory Hierarchy (Highest to Lowest)

| Type | Location | Scope |
|------|----------|-------|
| Enterprise policy | `/Library/Application Support/ClaudeCode/CLAUDE.md` | Organization-wide |
| Project memory | `./CLAUDE.md` or `./.claude/CLAUDE.md` | Team-shared |
| Project rules | `./.claude/rules/*.md` | Modular project |
| User memory | `~/.claude/CLAUDE.md` | Personal (all projects) |
| User rules | `~/.claude/rules/*.md` | Personal rules |
| Project local | `./CLAUDE.local.md` | Personal (this project) |

Files higher in hierarchy take precedence.

### Memory Imports

Use `@path/to/file` syntax to import additional files:

```markdown
See @README for project overview and @package.json for npm commands.

# Additional Instructions
- Git workflow: @docs/git-instructions.md
- Individual prefs: @~/.claude/my-project-instructions.md
```

- Relative and absolute paths allowed
- Imports not evaluated inside code blocks
- Recursive imports (max depth: 5)
- Avoids collisions with `@username` mentions

### Path-Specific Rules

Rules can be scoped to specific files using `paths:` frontmatter:

```yaml
# .claude/rules/api-standards.md
---
paths:
  - "src/api/**/*.ts"
  - "lib/handlers/**/*.ts"
---
# API Development Rules
- All API endpoints must include input validation
- Use the standard error response format
- Include OpenAPI documentation comments
```

### Glob Pattern Support

| Pattern | Matches |
|---------|---------|
| `**/*.ts` | All TypeScript files |
| `src/**/*` | All files under src/ |
| `*.md` | Markdown in project root |
| `src/**/*.{ts,tsx}` | TS and TSX files in src |
| `{src,lib}/**/*.ts` | TS files in src or lib |

## Configuration

### Rules Directory Structure
```
.claude/rules/
├── frontend/
│   ├── react.md
│   └── styles.md
├── backend/
│   ├── api.md
│   └── database.md
└── general.md
```

All `.md` files discovered recursively.

### Symlinks for Shared Rules
```bash
# Symlink shared rules directory
ln -s ~/shared-claude-rules .claude/rules/shared

# Symlink individual rule files
ln -s ~/company-standards/security.md .claude/rules/security.md
```

### View Loaded Memory
```
/memory
```

### Initialize Project Memory
```
/init
```

## Examples

### Project CLAUDE.md
```markdown
# Project Guidelines

See @README.md for project overview.
See @docs/architecture.md for system design.

## Code Style
- Use 2-space indentation
- Prefer async/await over promises
- Include JSDoc for public APIs

## Commands
- Build: `npm run build`
- Test: `npm test`
- Lint: `npm run lint`

## Patterns
@docs/patterns/error-handling.md
```

### Path-Specific Rule
```yaml
# .claude/rules/testing.md
---
paths:
  - "**/*.test.ts"
  - "**/*.spec.ts"
  - "tests/**/*"
---
# Testing Standards
- Use describe/it pattern
- One assertion per test when possible
- Mock external dependencies
- Include edge cases
```

### User Memory
```markdown
# ~/.claude/CLAUDE.md

## My Preferences
- Prefer functional components
- Use TypeScript strict mode
- Include error boundaries

## Common Aliases
- `nr` = `npm run`
- `gst` = `git status`
```

### Enterprise Policy
```markdown
# /Library/Application Support/ClaudeCode/CLAUDE.md

## Security Requirements
- Never commit secrets to code
- Use environment variables for config
- Sanitize all user inputs
- Follow OWASP guidelines

## Compliance
- All code must be reviewed
- Include audit logging
- Document data flows
```

## Agency Relevance

**High** - Could modularize our knowledge files:

| Current Agency | Native Memory Equivalent |
|----------------|-------------------------|
| `KNOWLEDGE.md` (single file) | `.claude/rules/*.md` (modular) |
| Agent-specific knowledge | Path-specific rules |
| Manual context loading | Imports with `@path` |

### Benefits
1. **Modular rules** - Split large KNOWLEDGE.md into focused files
2. **Path-specific** - Apply rules only to relevant files
3. **Symlinks** - Share rules across workstreams
4. **Imports** - Reference external docs without copying
5. **Hierarchy** - Organization → Project → User precedence

### Implementation Ideas
```
.claude/rules/
├── agency/
│   ├── conventions.md      # Agency conventions
│   ├── git-workflow.md     # Commit standards
│   └── testing.md          # Test requirements
├── agents/
│   ├── captain.md          # Captain-specific (paths: claude/agents/captain/**)
│   └── research.md         # Research-specific
└── workstreams/
    └── housekeeping.md     # Workstream rules
```

### CLAUDE.md with Imports
```markdown
# The Agency

@README.md for project overview.
@claude/docs/PERMISSIONS.md for permission model.

## Agent Context
@claude/agents/captain/agent.md
@claude/agents/captain/KNOWLEDGE.md

## Conventions
@claude/docs/conventions.md
```

## Links/Sources

- [Memory Documentation](https://code.claude.com/docs/en/memory)
- [/memory Command](https://code.claude.com/docs/en/interactive#memory)
- [/init Command](https://code.claude.com/docs/en/interactive#init)
