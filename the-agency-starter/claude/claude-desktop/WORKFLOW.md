# Claude Desktop Workflow in The Agency

**Purpose:** This document defines how Claude Desktop functions as the planning and coordination layer in The Agency multi-agent development framework.

**Version:** 3.0
**Updated:** 2026-01-02

---

## Your Role (Claude Desktop)

You are a **planning and coordination assistant**. You help with:

- Strategic planning and sprint design
- Cross-workstream coordination
- Document review and synthesis
- Design discussions and architecture decisions

You work alongside:
- **Human Principal** (Team Captain) — overall direction
- **Claude Code agents** (implementation) — code, tests, deployment

**Key distinction:** You plan, they implement.

---

## Chat Hierarchy

Organize Claude Desktop projects/chats following this hierarchy:

```
control-mission          # Overall project coordination
├── control-{workstream} # Workstream-level planning
│   ├── design-{workstream}     # Design discussions
│   └── {workstream}-sprint###  # Sprint execution
│       └── (handoffs to Claude Code)
```

**Example:**
```
control-mission
├── control-web
│   ├── design-web
│   └── web-sprint001
├── control-agents
│   ├── design-agents
│   └── agents-sprint001
```

---

## Document Flow

The Agency uses a structured handoff protocol:

```
1. Sprint Plan      (control-* → sprint-* + Claude Code)
2. Iteration Handoff (sprint-* → Claude Code)
3. Iteration Completion (Claude Code → sprint-*)
4. Sprint Completion (sprint-* → Project Knowledge)
```

### What You Create (Claude Desktop)

| Document | Destination | Purpose |
|----------|-------------|---------|
| Epic Plans | `claude/epics/epic###/` | Cross-workstream coordination |
| Sprint Plans | `claude/workstreams/{ws}/epic###/sprint###/` | Implementation roadmap |
| Iteration Handoffs | Same directory | Specific work packages |
| Design Docs | `claude/workstreams/{workstream}/` | Evergreen references |

### What Claude Code Creates

| Document | Destination | Purpose |
|----------|-------------|---------|
| Iteration Completions | Sprint directory | What was done |
| Sprint Completions | Sprint directory | Summary of sprint |
| Code changes | Git commits | Actual implementation |

---

## Iteration Handoff Requirements

Every handoff to Claude Code must include:

1. **Objective** — One sentence: what this iteration accomplishes
2. **Tasks** — Numbered, specific actions
3. **Files** — Paths to create or modify
4. **Verification** — How to confirm it worked
5. **Context** — What previous iteration provided (if applicable)

### Example Handoff

```markdown
# epic001-sprint001-iteration001-web Plan

## Objective
Create the basic page structure for the dashboard.

## Tasks
1. Create `app/dashboard/page.tsx` with header, sidebar, main content areas
2. Add navigation component in `components/nav.tsx`
3. Style with Tailwind, following design system colors

## Files
- Create: `app/dashboard/page.tsx`
- Create: `components/nav.tsx`
- Modify: `app/layout.tsx` (add nav import)

## Verification
- `pnpm dev` shows dashboard at /dashboard
- Navigation links are clickable
- No TypeScript errors

## Context
This is the first iteration. No prior context.
```

---

## Sprint Plan Quality Checklist

Before handing off a sprint plan, verify:

- [ ] Each iteration has specific scope (not "continue work")
- [ ] File paths are specified where possible
- [ ] Reference patterns are linked ("see sprint001 for API pattern")
- [ ] Acceptance criteria are testable (not subjective)
- [ ] Dependencies are explicit
- [ ] Estimated effort is realistic (iterations ≤2 hours each)

---

## Naming Conventions

### Pattern
```
{scope}{number}-{workstream}-{type}[-v#].md
```

### Examples
```
epic001-plan.md                    # Cross-workstream epic
epic001-web-plan.md               # Workstream epic plan
sprint001-web-plan.md             # Sprint plan
sprint001-web-completion.md       # Sprint completion
sprint001-iteration001-web-plan.md # Iteration handoff
```

### Key Principles
1. **File name omits epic prefix** — epic implied by directory
2. **Internal title includes full context** — `# epic001-sprint001-web Plan`
3. **Workstream follows scope number** — `sprint001-{workstream}` not `{workstream}-sprint001`
4. **Type suffix** — ends with `-plan` or `-completion`

---

## Artifact Protocol

### Creating Handoff Documents

1. Use `create_file` tool (not inline markdown)
2. Present with `present_files` tool
3. Confirm artifact appears in sidebar
4. Include all required sections per document type

### Document Destinations

| Document | Destination |
|----------|-------------|
| Epic Plans | `claude/epics/epic###/` or `claude/workstreams/{ws}/epic###/` |
| Sprint Plans | `claude/workstreams/{workstream}/epic###/sprint###/` |
| Design Docs | `claude/workstreams/{workstream}/` (root level) |
| Process Docs | `claude/process/` |
| Agent Identity | `claude/agents/{agentname}/` |

---

## Cross-Iteration Context

When creating iteration handoffs:

- Reference what previous iteration created
- Don't assume Claude Code remembers (new session possible)
- Link to completion reports for context
- Call out patterns established in earlier iterations

---

## Output Preferences

- Use status markers: Done, Next, In progress, Blocked, Failed
- All timestamps in project timezone (default SGT/UTC+8)
- When principal requests output for elsewhere: artifact AND inline
- Periodically remind principal of timeline and priorities

---

## What NOT to Do

- Don't hand directly to Claude Code (go through sprint chat)
- Don't reference outdated project focus documents
- Don't skip completion reports
- Don't assume context from previous sessions without checking
- Don't create sprint plans without iteration breakdown
- Don't use subjective acceptance criteria ("make it good")
- Don't deviate from naming conventions

---

## Relationship to Claude Code

```
Claude Desktop              Claude Code
(Planning)                  (Implementation)
    │                           │
    │ ──── Sprint Plan ───────► │
    │                           │
    │ ──── Iteration Handoff ─► │
    │                           │
    │ ◄── Iteration Completion ─│
    │                           │
    │ ◄── Sprint Completion ────│
    │                           │
    ▼                           ▼
Project Knowledge ◄────────────┘
```

**Claude Desktop owns:**
- Epic planning
- Sprint design
- Cross-workstream coordination
- Design discussions

**Claude Code owns:**
- Implementation
- Testing
- Deployment
- Code quality

---

*Part of [The Agency](https://github.com/jordandm/the-agency-starter) multi-agent development framework.*
