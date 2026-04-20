---
title: Claude Code Skills System
created: 2026-01-21T13:35:00+08:00
author: research-agent
version: 1.0.0
source: Claude Code Documentation
---

# Claude Code Skills System

## Overview

Skills extend Claude's capabilities with reusable prompts and instructions. They can be invoked automatically by Claude or manually via `/skill-name`.

## Key Features

- YAML frontmatter configuration
- Automatic or manual invocation
- Tool restrictions
- Subagent execution
- Dynamic context injection
- Supporting files (templates, scripts)

## Skill Locations

| Type | Location | Scope |
|------|----------|-------|
| Enterprise | Managed settings | All users in org |
| Personal | `~/.claude/skills/<name>/SKILL.md` | All your projects |
| Project | `.claude/skills/<name>/SKILL.md` | This project only |
| Plugin | `<plugin>/skills/<name>/SKILL.md` | Where plugin enabled |

## SKILL.md Structure

```markdown
---
name: my-skill
description: What this skill does and when to use it
allowed-tools: Read, Grep, Glob
---

Your skill instructions here...
```

## Frontmatter Fields

| Field | Required | Description |
|-------|----------|-------------|
| name | No | Display name (defaults to directory name) |
| description | Recommended | When to use (Claude uses for auto-invocation) |
| argument-hint | No | Hint for expected arguments |
| disable-model-invocation | No | Prevent auto-invocation (manual only) |
| user-invocable | No | Hide from / menu (default: true) |
| allowed-tools | No | Tools Claude can use |
| model | No | Model to use |
| context | No | Set to `fork` for subagent execution |
| agent | No | Subagent type when context: fork |
| hooks | No | Lifecycle hooks for this skill |

## String Substitutions

| Variable | Description |
|----------|-------------|
| `$ARGUMENTS` | Arguments passed to skill |
| `${CLAUDE_SESSION_ID}` | Current session ID |

## Invocation Control

| Frontmatter | You Can Invoke | Claude Can Invoke |
|-------------|----------------|-------------------|
| (default) | Yes | Yes |
| `disable-model-invocation: true` | Yes | No |
| `user-invocable: false` | No | Yes |

## Example: Reference Content Skill

```markdown
---
name: api-conventions
description: API design patterns for this codebase
---

When writing API endpoints:
- Use RESTful naming conventions
- Return consistent error formats
- Include request validation
```

## Example: Task Skill

```markdown
---
name: deploy
description: Deploy the application to production
context: fork
disable-model-invocation: true
---

Deploy $ARGUMENTS to production:
1. Run the test suite
2. Build the application
3. Push to the deployment target
```

## Dynamic Context Injection

Use `!command` syntax to inject live data:

```markdown
---
name: pr-summary
description: Summarize changes in a pull request
context: fork
agent: Explore
---

## Pull request context
- PR diff: !`gh pr diff`
- PR comments: !`gh pr view --comments`

## Your task
Summarize this pull request...
```

## Supporting Files

Skills can include multiple files:

```
my-skill/
├── SKILL.md           # Main instructions (required)
├── template.md        # Template for output
├── examples/
│   └── sample.md      # Example output
└── scripts/
    └── validate.sh    # Script to execute
```

Reference from SKILL.md:
```markdown
For complete API details, see [reference.md](reference.md)
```

## Subagent Execution

Run skills in isolated context with `context: fork`:

```markdown
---
name: deep-research
description: Research a topic thoroughly
context: fork
agent: Explore
---

Research $ARGUMENTS thoroughly:
1. Find relevant files using Glob and Grep
2. Read and analyze the code
3. Summarize findings
```

Available agents: `Explore`, `Plan`, `general-purpose`, or custom subagents.

## Visual Output Example

Skills can bundle scripts for visual output:

```markdown
---
name: codebase-visualizer
description: Generate interactive tree visualization
allowed-tools: Bash(python:*)
---

Run the visualization script:
```bash
python ~/.claude/skills/codebase-visualizer/scripts/visualize.py .
```
```

## Legacy Commands

Files in `.claude/commands/` still work and are equivalent to skills. Skills take precedence over commands with the same name.

## Agency Relevance

Skills could enhance The Agency with:

1. **Workflow Skills** - `/commit`, `/pr-create`, `/review`
2. **Context Skills** - Load agent context, knowledge bases
3. **Tool Skills** - Agency-specific operations
4. **Template Skills** - Generate standard documents
5. **Research Skills** - Codebase exploration patterns

## Links/Sources

- [Skills Documentation](https://code.claude.com/docs/en/skills)
- [Agent Skills Standard](https://agentskills.org/)
