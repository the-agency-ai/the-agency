# WORKNOTE: Building the Minimum Viable Hub (MVH)

**Started:** 2026-01-15
**Status:** In Progress
**Master Design:** REQUEST-jordan-0052

---

## Executive Summary

This WORKNOTE documents the end-to-end build of The Agency Hub - a system that transforms the-agency-starter from a one-time template into a living control center for managing all Agency projects.

**Core Principle:** "After the initial install, everything is agent-driven."

---

## The Vision

### Before MVH
```
User installs starter → Creates project → Manual updates → Drift
```

### After MVH
```
User installs starter → ./agency → Hub Agent manages everything
                                    ├── Update starter
                                    ├── Create projects
                                    ├── Update all projects
                                    ├── Launch into projects
                                    └── Contribute upstream
```

---

## Phase Overview

| Phase | Name | Description | Status |
|-------|------|-------------|--------|
| A | Foundation | Schemas, manifest, registry, service checks | In Progress |
| B | Hub Core | ./agency command, Hub Agent | Pending |
| C | Project Ops | Create, update, batch operations | Pending |
| D | Terminal | iTerm2 launch integration | Pending |
| E | Contributor | PR creation, review, merge via agents | Pending |

---

## Build Log

### Phase A: Foundation

**Started:** 2026-01-15

#### Design Decisions
- Schema-first approach: Define data structures before implementation
- JSON Schema for validation and documentation
- Manifest per project, registry in starter, project list gitignored

#### Tasks Completed

**A1, A2, A3: Schemas (captain)**
- Created `claude/docs/schemas/manifest.schema.json`
- Created `claude/docs/schemas/registry.schema.json`
- Created `claude/docs/schemas/projects.schema.json`
- Created `registry.json` with component definitions
- Commit: 86ba7ce

**A6: myclaude service check (subagent)**
- Added interactive service checking before Claude launch
- Checks: Bun, dependencies, service running
- Prompts user with sensible defaults
- Commit: cda8f39

**A4: project-new manifest (foundation-alpha)**
- Status: In Progress
- Agent: foundation-alpha
- Collaboration: COLLABORATE-0001

**A5: project-update --init (foundation-beta)**
- Status: In Progress
- Agent: foundation-beta
- Collaboration: COLLABORATE-0002

#### Parallel Execution
First use of multi-agent parallel work pattern:
- Wave 1: Captain (schemas) + subagent (A6) in parallel
- Wave 2: foundation-alpha (A4) + foundation-beta (A5) in parallel
- See: WORKNOTE-parallel-agent-case-study.md

### Phase B: Hub Core

*Not yet started*

### Phase C: Project Operations

*Not yet started*

### Phase D: Terminal Integration

*Not yet started*

### Phase E: Contributor Flow

*Not yet started*

---

## Key Artifacts

### Schemas
| File | Purpose |
|------|---------|
| `claude/docs/schemas/manifest.schema.json` | Project manifest structure |
| `claude/docs/schemas/registry.schema.json` | Starter component registry |
| `claude/docs/schemas/projects.schema.json` | Project tracking list |
| `registry.json` | Actual component definitions |

### Agents Created
| Agent | Purpose |
|-------|---------|
| foundation-alpha | Task A4 implementation |
| foundation-beta | Task A5 implementation |
| hub (planned) | The Hub Agent itself |

### REQUESTs
| REQUEST | Phase | Status |
|---------|-------|--------|
| 0052 | Master Design | Complete |
| 0053 | Phase A | In Progress |
| 0054 | Phase B | Pending |
| 0055 | Phase C | Pending |
| 0056 | Phase D | Pending |
| 0057 | Phase E | Pending |

---

## Technical Decisions

### Why manifest.json?
- Agents need to understand what's installed
- Enables "check for updates" without network
- File hashes detect local modifications
- Progressive: works without manifest, better with it

### Why registry.json in starter?
- Single source of truth for available components
- Includes install hooks (e.g., `bun install`)
- Defines protected paths (never overwrite)
- Enables selective component updates

### Why gitignored project registry?
- Local to each starter instance
- Different users have different projects
- Privacy: project paths not shared
- Enables "update all my projects" without scanning filesystem

### Why Hub Agent vs CLI tool?
- Agents can handle edge cases intelligently
- Natural language interface ("update my projects")
- Can explain what it's doing
- Follows core principle: agents do the work

---

## Challenges & Solutions

### Challenge 1: Parallel Agent Coordination
**Problem:** Multiple agents updating same files = conflicts
**Solution:** Single writer to REQUEST files (captain only). Agents commit code directly (different files).

### Challenge 2: Detecting Modified Files
**Problem:** Don't overwrite user customizations
**Solution:** SHA256 hashes in manifest. Compare before update. Backup if modified.

### Challenge 3: Terminal Integration
**Problem:** Launch new terminal tab from agent
**Solution:** macOS + iTerm2 only (for now). AppleScript or iTerm2 Python API.

*More challenges to be documented as encountered*

---

## Metrics

| Metric | Value |
|--------|-------|
| Phases | 5 (A-E) |
| Total tasks | ~25 |
| REQUESTs created | 6 |
| Agents created | 2 (so far) |
| Commits | 8 (so far) |

---

## For the Book

### Key Themes

1. **Agent-First Design** - Building systems where agents are first-class citizens
2. **Parallel Execution** - Multiple agents working simultaneously
3. **Coordination Protocols** - How agents avoid stepping on each other
4. **Progressive Enhancement** - Works without manifest, better with it
5. **Schema-First Development** - Define data structures before code

### Case Study Angles

1. **The Build Process** - How we built MVH using The Agency itself
2. **Eating Our Own Dogfood** - Using agents to build agent infrastructure
3. **Parallel Agent Patterns** - Waves, coordination, conflict avoidance
4. **From Design to Implementation** - REQUEST-0052 to working code

### Quotable Moments

*To be captured as work progresses*

---

## References

- REQUEST-jordan-0052: Master design document
- WORKNOTE-parallel-agent-case-study.md: Parallel execution deep-dive
- claude/docs/schemas/README.md: Schema documentation
