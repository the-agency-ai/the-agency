# REQUEST-jordan-0043: Agent Templates System

**Principal:** Jordan
**Workstream:** housekeeping
**Agent:** housekeeping
**Status:** In Progress
**Created:** 2026-01-13
**Priority:** Medium

---

## Summary

Create an agent templates system that allows `./tools/agent-create` to scaffold specialized agent types with pre-configured knowledge, purpose, and responsibilities.

---

## Background

### Current State

The `./tools/agent-create` tool creates generic agents with placeholder content:

```bash
./tools/agent-create my-agent my-workstream
```

Creates:
- `agency/agents/my-agent/agent.md` - Generic placeholder content
- `agency/agents/my-agent/WORKLOG.md`
- `agency/agents/my-agent/ADHOC-WORKLOG.md`
- etc.

### Problem

Users must manually customize each agent for specialized roles. This leads to:
1. Inconsistent agent definitions
2. Missing knowledge links
3. Repeated manual work for common agent types

### Solution

Create an agent template system with pre-defined agent types.

---

## Requested Deliverables

### 1. Template Directory Structure

```
agency/agents/templates/
├── INDEX.md              # Template directory overview
├── generic/              # Default template (current behavior)
│   ├── agent.md
│   ├── KNOWLEDGE.md
│   └── ONBOARDING.md
└── ux-dev/               # UX/UI development specialist
    ├── agent.md
    ├── KNOWLEDGE.md
    └── ONBOARDING.md
```

### 2. Enhanced `create-agent` Tool

**New Usage:**
```bash
./tools/agent-create <name> <workstream> [--type=<template>]

# Examples:
./tools/agent-create ui-specialist web --type=ux-dev
./tools/agent-create backend-dev api                    # Uses generic (default)
./tools/agent-create backend-dev api --type=generic     # Explicit default
```

**Behavior:**
1. Look for template in `agency/agents/templates/<type>/`
2. If not found, use `generic/` template
3. Replace placeholders: `{{AGENT_NAME}}`, `{{WORKSTREAM}}`, `{{TIMESTAMP}}`
4. Create agent directory with populated files

### 3. `ux-dev` Agent Template

**Purpose:** UX/UI development specialist for implementing designs pixel-perfect.

**agent.md:**
```markdown
# {{AGENT_NAME}} Agent

**Created:** {{TIMESTAMP}}
**Workstream:** {{WORKSTREAM}}
**Model:** Opus 4.5 (default)
**Type:** ux-dev

## Purpose

UX/UI development specialist focused on implementing designs with pixel-perfect fidelity.

## Responsibilities

- Implement UI components from Figma designs
- Apply design system tokens correctly
- Ensure responsive behavior matches specs
- Achieve high visual fidelity (95%+ match)
- Integrate with existing design systems

## Knowledge Base

- `claude/knowledge/ui-development/` - Implementation patterns
- `claude/knowledge/design-systems/` - Active design systems

## Key Tools

- `./tools/browser` - Visual verification
- `./tools/figma-diff` - Design comparison (when available)
- `./tools/designsystem-validate` - Design system verification

## Collaboration Patterns

- Receives work from housekeeping with design specs
- Collaborates with accessibility specialists for a11y review
- Hands off to code reviewers for final review
```

**KNOWLEDGE.md:**
```markdown
# {{AGENT_NAME}} Knowledge

## Imported Knowledge Bases

- [UI Development](../../knowledge/ui-development/INDEX.md)
- [Design Systems](../../knowledge/design-systems/INDEX.md)

## Agent-Specific Knowledge

### Visual Fidelity Standards

- Target: 95%+ pixel match to design
- Use `figma-diff` for automated comparison
- Manual QA using visual-qa-checklist.md

### Design System Integration

1. Always reference active design system for project
2. Use exact token values, never hardcode
3. Report gaps via GAPS.md in design system
```

---

## Implementation Plan

### Step 1: Create Template Directory
- Create `agency/agents/templates/`
- Create `INDEX.md` documentation
- Create `generic/` template from current behavior

### Step 2: Create `ux-dev` Template
- Create `ux-dev/agent.md` with specialized content
- Create `ux-dev/KNOWLEDGE.md` linking to ui-development
- Create `ux-dev/ONBOARDING.md` for quick start

### Step 3: Enhance `create-agent` Tool
- Add `--type` parameter parsing
- Add template lookup logic
- Add placeholder replacement
- Maintain backward compatibility (no --type = generic)

### Step 4: Testing
- Test creating agent with no type (should use generic)
- Test creating agent with `--type=ux-dev`
- Test creating agent with invalid type (should error)
- Test placeholder replacement

---

## Success Criteria

1. `./tools/agent-create my-ui web --type=ux-dev` creates properly configured UI specialist
2. Agent KNOWLEDGE.md links to ui-development knowledge base
3. Default behavior (no --type) unchanged
4. Invalid type produces helpful error message
5. Template system is extensible for future agent types

---

## Future Agent Types

Once the template system is proven, consider adding:

| Type | Purpose |
|------|---------|
| `architect` | System architecture decisions |
| `backend` | API and service development |
| `devops` | Infrastructure and deployment |
| `qa` | Quality assurance and testing |
| `docs` | Documentation specialist |

---

## Related Work

- **REQUEST-jordan-0042** - Phase 3 mentions `ui-dev` agent creation
- **claude/knowledge/ui-development/** - Knowledge base for ux-dev type

---

## Work Log

### 2026-01-13

**Initial Creation:**
- Created REQUEST document
- Defined template system structure
- Specified `ux-dev` agent template

---

**Next Step:** Implement template directory and enhance create-agent tool.
