# Agent Templates

Pre-defined templates for specialized agent types.

## Usage

```bash
./tools/create-agent <name> <workstream> [--type=<template>]

# Examples:
./tools/create-agent my-ui web --type=ux-dev
./tools/create-agent backend api                    # Uses generic (default)
```

## Available Templates

| Template | Purpose | Knowledge Base |
|----------|---------|----------------|
| `generic` | Default general-purpose agent | None |
| `ux-dev` | UX/UI development specialist | ui-development, design-systems |

## Template Structure

Each template directory contains:

```
templates/<type>/
├── agent.md          # Agent identity and purpose
├── KNOWLEDGE.md      # Imported knowledge and patterns
└── ONBOARDING.md     # Quick start guide (optional)
```

## Placeholders

Templates use these placeholders (replaced during creation):

| Placeholder | Replaced With |
|-------------|---------------|
| `{{AGENT_NAME}}` | Agent name |
| `{{WORKSTREAM}}` | Workstream name |
| `{{TIMESTAMP}}` | Creation timestamp |

## Creating New Templates

1. Create directory: `claude/agents/templates/<type>/`
2. Add `agent.md` with placeholders
3. Add `KNOWLEDGE.md` linking to relevant knowledge bases
4. Optionally add `ONBOARDING.md`
5. Update this INDEX.md

## Related

- `claude/knowledge/` - Knowledge bases that templates reference
- `./tools/create-agent` - Tool that uses these templates
