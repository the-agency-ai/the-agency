# Explore: Workstreams

**Time:** 3 minutes
**Goal:** Understand how workstreams organize work

## What Are Workstreams?

Workstreams are organized areas of focus. They're how you structure work in The Agency.

Think of them as:
- Departments in a company
- Modules in a codebase
- Teams in an organization

## Workstream Structure

Show them a workstream directory:

```bash
ls -la claude/workstreams/housekeeping/
```

Explain what they'll see:
- `KNOWLEDGE.md` - Shared knowledge across agents in this workstream
- `sprints/` - Planned work organized by sprint
- Agents in this workstream share this knowledge

## Creating a Workstream

Walk through creating a workstream:

```bash
./tools/workstream-create demo
```

Show what was created:
```bash
ls -la claude/workstreams/demo/
```

## Workstream Patterns

**By Technical Area:**
- `web` - Frontend/UI work
- `api` - Backend services
- `mobile` - Mobile apps
- `infrastructure` - DevOps, deployment

**By Product Area:**
- `auth` - Authentication system
- `billing` - Payment and billing
- `analytics` - Data and reporting

**By Project Phase:**
- `foundation` - Core infrastructure
- `features` - New capabilities
- `polish` - UX improvements

## Agents and Workstreams

Relationship:
- Multiple agents can work on one workstream
- Each agent belongs to one workstream
- Agents share the workstream's KNOWLEDGE.md

Example:
```
workstream: web
  ├── agent: frontend-components
  ├── agent: frontend-ux
  └── agent: web-testing
```

## Sprint-Based Work

Workstreams organize work into sprints:

```bash
./tools/sprint-create web 2026-01
```

Creates:
```
claude/workstreams/web/sprints/2026-01/
  ├── README.md - Sprint goals
  └── ... work items ...
```

## When to Create a Workstream

Create a new workstream when:
- Starting a new technical area
- Adding a major feature that needs focus
- Organizing a team around a responsibility
- Separating concerns in the codebase

Don't over-create - start with 2-3 and grow as needed.

## Demo: Create and Use

If they want, walk through:

1. Create a workstream
2. Create an agent in it
3. Show how the agent has access to workstream knowledge

## Key Takeaways

✓ Workstreams organize related work
✓ Agents belong to workstreams
✓ Shared knowledge lives at the workstream level
✓ Sprints organize planned work

## Next Steps

Ask if they want to explore:
- Agents (who does the work)
- Tools (what's available)
- Collaboration (how work flows)

## Track Progress

Update `onboarding.yaml`:
```yaml
completed_sections:
  - welcome
  - explore.workstreams
```
