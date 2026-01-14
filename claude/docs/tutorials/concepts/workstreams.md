# Concepts: Workstreams

**Time:** 3 minutes
**Goal:** Deep dive into workstreams and how they organize work

## Workstream Definition

A workstream is:
- An organized area of focus
- Shared knowledge across agents
- Sprint-based work planning
- Logical grouping of related work

Think of it as a "department" or "module" in your project.

## Workstream Structure

Each workstream has:

```
claude/workstreams/{name}/
  ├── KNOWLEDGE.md           # Shared knowledge
  ├── sprints/              # Planned work
  │   ├── 2026-01/
  │   ├── 2026-02/
  │   └── ...
  └── epics/                # Major initiatives
```

### Shared Knowledge

The `KNOWLEDGE.md` in a workstream is shared by all agents working in that stream.

Example for `web` workstream:
```markdown
# Web Workstream Knowledge

## Component Patterns
- Use shadcn/ui for base components
- Follow atomic design principles
- Co-locate styles with components

## State Management
- Use Zustand for global state
- React Context for feature state
- URL state for shareable views

## Testing
- Vitest for unit tests
- Playwright for E2E
- Aim for 80% coverage
```

All agents in `web` workstream see and use this knowledge.

## Workstream Patterns

**By Technical Layer:**
```
frontend/     # UI and presentation
backend/      # APIs and business logic
database/     # Schema and migrations
infrastructure/  # DevOps and deployment
```

**By Product Feature:**
```
auth/         # Authentication system
billing/      # Payment and subscriptions
analytics/    # Data and reporting
admin/        # Admin dashboard
```

**By Project Phase:**
```
mvp/          # Initial product
v2/           # Major upgrade
polish/       # UX refinements
performance/  # Optimization work
```

## Sprint Planning

Workstreams organize work into sprints:

### Create a Sprint
```bash
./tools/sprint-create web 2026-02
```

### Sprint Structure
```
claude/workstreams/web/sprints/2026-02/
  ├── README.md            # Sprint goals
  ├── REQUEST-...          # Work items
  ├── RETROSPECTIVE.md     # Post-sprint review
  └── METRICS.md           # Sprint metrics
```

### Sprint Workflow
1. **Plan** - Define goals and REQUESTs
2. **Execute** - Agents work on items
3. **Review** - Check completions
4. **Retrospective** - Learn and improve

## Epics

For major initiatives that span sprints:

```bash
./tools/epic-create web user-profiles
```

Creates:
```
claude/workstreams/web/epics/user-profiles/
  ├── README.md            # Epic overview
  ├── DESIGN.md            # Technical design
  ├── PROGRESS.md          # Track implementation
  └── related-requests/    # Associated work
```

## Workstream vs Agent

**Workstream:**
- Logical area of work
- Shared knowledge
- Multiple agents can contribute
- Long-lived

**Agent:**
- Individual worker
- Belongs to one workstream
- Focused role
- Can be retired/replaced

Example:
```
Workstream: web
  ├── Agent: frontend-components (UI implementation)
  ├── Agent: frontend-ux (User experience)
  └── Agent: web-testing (QA)
```

## When to Create Workstreams

**Create new workstream when:**
- Adding distinct technical area
- Major feature needs dedicated focus
- Team reorganization
- Clear boundary in codebase

**Start small:**
- Begin with 2-3 workstreams
- `core`, `web`, `api` is a good start
- Grow as project grows
- Don't over-organize early

## Knowledge Sharing

Knowledge flows:

**Agent → Workstream:**
- Agent learns pattern
- Documents in workstream KNOWLEDGE.md
- All agents benefit

**Workstream → Agent:**
- New agent created
- Reads workstream KNOWLEDGE.md
- Starts with accumulated wisdom

## Key Takeaways

✓ Workstreams organize related work
✓ Knowledge is shared across agents in the stream
✓ Sprints plan and track work
✓ Epics coordinate major initiatives

## Next Steps

Ask if they want to:
- Learn about principals (who directs work)
- Learn about agents (who does work)
- Try creating a workstream

## Track Progress

Update `onboarding.yaml`:
```yaml
completed_sections:
  - welcome
  - concepts.workstreams
```
