# Knowledge Base

**Purpose:** Shared knowledge and patterns for all agents.

**Location:** `claude/knowledge/`

---

## Overview

The knowledge base contains reusable patterns, guidelines, and reference material that any agent can access. Knowledge is organized by domain.

## Contents

| Directory | Purpose | When to Use |
|-----------|---------|-------------|
| `claude-code/` | Claude Code patterns and conventions | Working with Claude Code features |
| `ui-development/` | UI implementation patterns | Implementing user interfaces |
| `design-systems/` | Design system documentation | Working with design tokens and specs |

---

## Quick Start

### UI Development

For implementing user interfaces from designs:

```bash
# See UI development patterns
cat claude/knowledge/ui-development/INDEX.md
```

### Design Systems

For working with design tokens:

```bash
# Create a new design system
./tools/designsystem-add <brand> <version>

# Validate a design system
./tools/designsystem-validate claude/knowledge/design-systems/<name>

# See design systems index
cat claude/knowledge/design-systems/INDEX.md
```

---

## Adding Knowledge

### When to Add

Add knowledge when:
- A pattern works well and is reusable
- You solve a tricky problem worth documenting
- You discover a convention that should be followed

### Structure

Each knowledge area should have:
- `INDEX.md` - Overview and quick reference
- Topic-specific `.md` files
- Code examples where applicable

### Good Knowledge

- Specific and actionable
- Includes code examples
- Explains the "why" not just the "what"
- Portable across projects

### Bad Knowledge

- Vague generalizations
- Project-specific hacks
- Outdated patterns
- "It depends" without guidance

---

## Related

- `claude/docs/` - Guides and reference documentation
- `claude/agents/*/KNOWLEDGE.md` - Agent-specific knowledge

---

**Last Updated:** 2026-01-13
**Maintainer:** housekeeping agent
