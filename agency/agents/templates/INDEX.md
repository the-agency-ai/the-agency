# Agent Templates

Pre-defined templates for specialized agent types.

## Usage

```bash
./agency/tools/agent-create <name> <workstream> [--type=<template>]

# Examples:
./agency/tools/agent-create my-ui web --type=ux-dev
./agency/tools/agent-create ds-extractor design --type=design-system
./agency/tools/agent-create backend api                    # Uses generic (default)
```

## Available Templates

| Template | Purpose | Knowledge Base |
|----------|---------|----------------|
| `generic` | Default general-purpose agent | None |
| `ux-dev` | UX/UI development specialist | ui-development, design-systems |
| `design-system` | Design system extraction specialist | design-systems, ui-development |
| `security` | Security review, threat modeling, vulnerability assessment | security-patterns |
| `tester` | Test strategy, coverage, test implementation | testing-patterns |
| `reviewer` | Code review, architecture review, PR review | code-review-patterns |
| `docs` | Technical writing, API docs, guides | documentation-patterns |
| `services` | API design, DB schema, data modeling, service architecture | services-patterns |

## Template Structure

Each template directory contains:

```
templates/<type>/
├── agent.md          # Agent identity and purpose
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

1. Create directory: `agency/agents/templates/<type>/`
2. Add `agent.md` with placeholders
3. Optionally add `ONBOARDING.md`
5. Update this INDEX.md

## Related

- `claude/knowledge/` - Knowledge bases that templates reference
- `./agency/tools/agent-create` - Tool that uses these templates
