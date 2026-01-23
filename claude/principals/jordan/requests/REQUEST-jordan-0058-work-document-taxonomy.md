# REQUEST-jordan-0058: Work and Document Taxonomy

**Principal:** jordan
**Workstream:** housekeeping
**Agent:** captain
**Status:** Open - Design Discussion
**Priority:** High
**Created:** 2026-01-15

**Related:**
- REQUEST-jordan-0018 (Work Item Taxonomy & Tooling - established REQUEST workflow: impl→review→tests→complete)
- REQUEST-jordan-0040 (Unified Work Item Tracker - unified Bug, Idea, Request, Observation types)

---

## Summary

Define a comprehensive taxonomy for work and documentation in The Agency, establishing clear hierarchies for both **Product-driven work** (customer value delivery) and **Project-driven work** (goal-oriented initiatives). This extends the foundations laid in REQUEST-0018 and REQUEST-0040.

---

## Proposed Taxonomy

### Track 1: Products (Customer Value Delivery)

At the top level, we have **Products** - the delivery of customer value to some kind of customer.

```
Product Vision
    └── Epic (feature/feature collection delivering usable customer value)
            └── Sprint (usable increment of customer value)
                    └── Iteration (verifiable increment toward Sprint completion)
                            └── Work Item (discrete assignable unit)
```

#### Artifacts

| Level | Artifact | Created By |
|-------|----------|------------|
| Product | Product Vision | Principals + Agents (partnership) |
| Epic | Epic Plan | Principals + Agents (mapped together) |
| Sprint | Sprint Plan | Agent (reviewed by Principals + Agents) |
| Iteration | Iteration Plan | Agent (can include work item breakdown) |

#### Completion Reports

- **Iteration Completion Report** - generated when iteration completes
- **Sprint Completion Report** - generated when sprint completes
- **Epic Completion Report** - generated when epic completes

Reports flow upward and inform planning of subsequent Sprints, Epics, etc.

#### Scope Boundaries

| Level | Workstream Scope | Parallelization |
|-------|------------------|-----------------|
| Epic | Single OR multiple workstreams | N/A |
| Sprint | Single workstream | Sprints in different workstreams can run in parallel; sometimes within same workstream |
| Iteration | Single workstream | Sequential or parallel; can be guided or autonomous |

---

### Track 2: Projects/Initiatives (Goal-Driven Work)

**Projects/Initiatives** are focused efforts that deliver value - customer or internal.

- Projects have a goal defined by a Principal
- Projects are defined by a set of Requests
- Requests can have phases or work items; phases can have work items

```
Project (goal defined by Principal)
    └── Requests (Principal or Agent initiated)
            └── Phases (optional)
                    └── Work Item (discrete assignable unit)
```

**Key distinction:** Requests do not have to belong to a Project.

---

### Work Items

**Work Items** are the fundamental unit of assignable work in The Agency. They appear at the bottom of both tracks and represent discrete, verifiable pieces of work.

#### Key Characteristics

| Property | Description |
|----------|-------------|
| **Cross-instance** | Work Items span multiple Claude Code instances |
| **Cross-session** | Work Items persist across sessions (unlike CC Tasks) |
| **Cross-agent** | Work Items can be assigned to and picked up by different agents |
| **Persisted** | Stored in Agency database, tracked through completion |

#### Work Item Properties

Inspired by Claude Code's native task system, Work Items support:

| Property | Type | Description |
|----------|------|-------------|
| `id` | string | Unique identifier (e.g., `WI-0073-1`) |
| `subject` | string | Brief title describing the work |
| `description` | string | Detailed description with acceptance criteria |
| `status` | enum | `open` → `in_progress` → `completed` |
| `owner` | string | Agent assigned to work on this item |
| `blockedBy` | array | Work Item IDs that must complete first |
| `blocks` | array | Work Item IDs waiting on this one |
| `parentType` | string | `request`, `iteration`, `phase` |
| `parentId` | string | ID of parent work item |

#### Work Item vs Claude Code Task

| Aspect | Work Item (Agency) | Claude Code Task |
|--------|-------------------|------------------|
| **Scope** | Cross-instance, cross-session, cross-agent | Within a single CC session |
| **Persistence** | Database + files | Memory only (ephemeral) |
| **Visibility** | Agency tools, AgencyBench UI | Terminal spinner, CC UI |
| **Dependencies** | Yes (blockedBy/blocks) | Yes (blockedBy/blocks) |
| **Assignment** | Yes (to agents) | Yes (owner field) |
| **Purpose** | Planning & tracking across sessions | Real-time progress within session |

#### Workflow Integration

When an agent picks up a Work Item:

1. **Claim Work Item** - Agent marks Work Item as `in_progress` with themselves as owner
2. **Create CC Tasks** - Agent breaks Work Item into Claude Code Tasks for within-session tracking
3. **Execute** - CC Tasks show real-time progress in terminal
4. **Complete** - When CC Tasks done, agent marks Work Item as `completed`

```
Work Item: WI-0073-2 "Implement exclude patterns"     ← Agency (persisted)
    │
    └── [Claude Code Session]
            ├── #1 [completed] Parse git status       ← CC Task (ephemeral)
            ├── #2 [completed] Add fnmatch logic      ← CC Task (ephemeral)
            └── #3 [completed] Test patterns          ← CC Task (ephemeral)
```

---

## Open Questions

The following questions will be addressed in a point-by-point interview:

### 1. Product vs Project Relationship
- Is a Project essentially an Epic not tied to a Product?
- Are they distinct concepts?
- Example: "The Agency Hub" - Product, Epic, or Project?

### 2. Where Do REQUESTs Live?
- Are REQUESTs only in the Project track?
- Can Iteration work also be captured as REQUESTs?
- How does REQUEST-jordan-0052 (Hub with phases A→E) map to this taxonomy?

### 3. Standalone Requests
- The "Requests don't need a Project" clause - is this the escape valve for ad-hoc work?
- How does ad-hoc work interact with the Product track?

### 4. Completion Reports
- Who generates them? (Agent with Principal review? Automated?)
- What's the format/template?
- How do they "flow upward"?

### 5. Cross-Workstream Coordination
- For Epics spanning multiple workstreams, is there a lead workstream?
- How do we coordinate parallel Sprints across workstreams?

### 6. Tooling Implications
Current: `epic-create`, `sprint-create`, `request`

Potential additions:
- `product-vision-create`
- `iteration-create`
- `completion-report` (per level)
- `project-create`
- `work-item` (create, list, claim, complete)

### 7. Service Implications
Options:
- New services: `product-service`, `epic-service`, `sprint-service`
- Extend `request-service` with hierarchy fields
- Or hybrid approach?

### 8. Guided vs Autonomous Iterations
- What triggers which mode?
- How is this specified in the Iteration Plan?

### 9. Work Item Service
- New `work-item-service` or extend `request-service`?
- How do Work Items relate to the existing unified tracker (Bug, Idea, Request, Observation)?
- Should Work Items be a new type in the unified tracker, or a separate concept?
- ID format: `WI-{parent}-{seq}` vs `WORKITEM-{seq}` vs other?

---

## Next Steps

1. **Point-by-point interview** to resolve open questions
2. **Review embedded services** in agency-service to ensure they support this taxonomy
3. **Document final taxonomy** with worked examples
4. **Design tooling and service changes**

---

## Activity Log

### 2026-01-23 - Work Item Concept Added
- Replaced "Tasks" with "Work Item" throughout taxonomy
- Added comprehensive Work Item section:
  - Key characteristics (cross-instance, cross-session, cross-agent, persisted)
  - Work Item properties (inspired by Claude Code Tasks)
  - Work Item vs Claude Code Task comparison
  - Workflow integration showing how agents use both
- Added Open Question #9 about Work Item service design
- Context: Claude Code 2.1.17 introduced native task system (TaskCreate, TaskUpdate, TaskList, TaskGet)
- Decision: Work Items for Agency-level tracking, Claude Code Tasks for within-session progress

### 2026-01-15 - Created
- Captured taxonomy proposal from Principal jordan
- Linked to prior work (REQUEST-0018, REQUEST-0040)
- Documented open questions for follow-up interview

---

## Original Request

*The following is the original input that initiated this REQUEST, preserved for reference:*

---

**Work and Document Taxonomy**

At its top, we have Products and Projects/Initiatives. Products are the delivery of customer value to some kind of customer.

Products at their root node, are defined in a Product Vision.
- Artifact: Product Vision
- Product Visions are written by Principals in partnership with one or more agents.

We then tackle the implementation of a Product Vision in Epics. Epics are about delivering a feature or collection of features that deliver usable customer value. Epics can define work with a single work stream or across multiple work streams (the usual).
- Artifact: Epic Plan
- Epics are mapped out by Principals in partnership with one or more agents.

Epics get broken up into Sprints which deliver usable increments of customer value. Sprints define work within a single work stream and sprints in different workstreams can be executed in parallel. And at times sprints within the same work stream can be executed in parallel.
- Artifact: Sprint Plan
- Sprint Planning from an Epic is done by an Agent and reviewed by Principals and collections of Agents.

Sprints get broken into iterations which deliver verifiable increments of work towards the completion of a Sprint and the customer value to be delivered in that Sprint. Iterations define work within a single work stream. Iterations can require sequential execution or can be executed in parallel. Iterations can be executed either with guidance or autonomously.
- Artifact: Iteration Plan
- Iterations are defined based on the Sprint Plan and are done by an Agent. Iterations can be further broken up into tasks which are described in the Iteration Plan.

When an Iteration is completed, an Iteration Completion Report is generated.
When a Sprint is completed, a Sprint Completion Report is generated.
When an Epic is completed, an Epic Completion Report is generated.
The completion reports flow upwards and can and will inform the planning of the next Sprint, Epic, etc.

---

**Projects/Initiatives** are focused effort that delivers value. It can be customer value or internal value. Projects/Initiatives have a goal and that goal is defined by a Principal.

Projects are defined by a set of Requests and Requests can be broken up to phases or tasks. Phases can be broken into tasks.

Requests do not have to belong to a Project.

Requests and their breakdown into phases or tasks is usually done by an agent in collaboration with principals.

Requests can be Principal or Agent initiated.
