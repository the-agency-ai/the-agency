---
title: Claude Code Skills
created: 2026-01-21T12:50:00
author: captain
version: 1.0.0
source: https://code.claude.com/docs/en/skills
---

# Claude Code Skills

Skills are reusable instruction packages that extend Claude's capabilities. They can be invoked via `/skill-name` or loaded automatically when relevant.

## Overview

Skills extend what Claude can do by providing structured instructions in SKILL.md files. They follow the Agent Skills open standard and can include supporting files like templates, scripts, and examples.

## Key Features

### Skill Structure
```
my-skill/
├── SKILL.md           # Main instructions (required)
├── template.md        # Template for Claude to fill in
├── examples/
│   └── sample.md      # Example output
└── scripts/
    └── validate.sh    # Script Claude can execute
```

### YAML Frontmatter
```yaml
---
name: my-skill
description: What this skill does and when to use it
argument-hint: [filename] [format]
disable-model-invocation: true  # Manual only
user-invocable: false           # Claude only
allowed-tools: Read, Grep, Glob
model: sonnet
context: fork                   # Run in subagent
agent: Explore                  # Subagent type
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "./validate.sh"
---
```

### Frontmatter Fields

| Field | Description | Default |
|-------|-------------|---------|
| `name` | Skill name (kebab-case, max 64 chars) | Directory name |
| `description` | When to use (Claude uses this for auto-loading) | First paragraph |
| `argument-hint` | Autocomplete hint | None |
| `disable-model-invocation` | Prevent Claude auto-loading | false |
| `user-invocable` | Show in / menu | true |
| `allowed-tools` | Tools Claude can use | All |
| `model` | Model to use | Inherit |
| `context` | Set to `fork` for subagent | Inline |
| `agent` | Subagent type when `context: fork` | general-purpose |
| `hooks` | Skill-scoped lifecycle hooks | None |

## Configuration

### Skill Locations

| Location | Path | Scope |
|----------|------|-------|
| Enterprise | Managed settings | All users |
| Personal | `~/.claude/skills/<name>/SKILL.md` | All your projects |
| Project | `.claude/skills/<name>/SKILL.md` | This project only |
| Plugin | `<plugin>/skills/<name>/SKILL.md` | Where plugin enabled |

Project skills override personal skills with the same name.

### String Substitutions

| Variable | Description |
|----------|-------------|
| `$ARGUMENTS` | All arguments passed when invoking |
| `${CLAUDE_SESSION_ID}` | Current session ID |

### Dynamic Context Injection

Use `!`command`` to run shell commands before skill content is sent:

```markdown
## Current Context
- Branch: !`git branch --show-current`
- Status: !`git status --short`
```

## Examples

### Reference Skill (Inline)
```yaml
---
name: api-conventions
description: API design patterns for this codebase
---
When writing API endpoints:
- Use RESTful naming conventions
- Return consistent error formats
- Include request validation
```

### Task Skill (Forked Subagent)
```yaml
---
name: deploy
description: Deploy the application to production
context: fork
disable-model-invocation: true
---
Deploy the application:
1. Run the test suite
2. Build the application
3. Push to the deployment target
```

### Skill with Hooks
```yaml
---
name: secure-operations
description: Perform operations with security checks
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "./scripts/security-check.sh"
          once: true  # Only run once per session
---
```

### Visual Output Skill
Skills can bundle scripts that generate HTML visualizations:
```yaml
---
name: codebase-visualizer
description: Generate interactive tree view of codebase
allowed-tools: Bash(python:*)
---
Run the visualization script:
```bash
python ~/.claude/skills/codebase-visualizer/scripts/visualize.py .
```
```

## Agency Relevance

**High** - Skills could replace our `./tools/` scripts:

| Current Agency | Native Skill Equivalent |
|----------------|------------------------|
| `./tools/commit` | `.claude/skills/commit/SKILL.md` |
| `./tools/review-spawn` | `.claude/skills/review/SKILL.md` with `context: fork` |
| `./tools/collaborate` | `.claude/skills/collaborate/SKILL.md` |

### Benefits
- Native Claude Code integration
- Subagent isolation with `context: fork`
- Dynamic context with `!`command``
- Skill-scoped hooks
- No external script dependencies

### Migration Path
1. Create `.claude/skills/` directory
2. Convert tool scripts to SKILL.md format
3. Use `allowed-tools` for permission control
4. Add `context: fork` for isolated execution

## Links/Sources

- [Skills Documentation](https://code.claude.com/docs/en/skills)
- [Agent Skills Standard](https://agentskills.org)
