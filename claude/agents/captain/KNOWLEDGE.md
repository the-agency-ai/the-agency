# Housekeeping Knowledge Base

Accumulated patterns and wisdom for running The Agency effectively.

## Core Principles

### Convention Over Configuration
- Establish clear conventions, enforce them
- Reduce decisions, increase consistency
- Make the right thing the easy thing

### Agents Are Specialists
- Each agent has a focused domain
- Context is preserved across sessions
- Handoffs are explicit, not assumed

### Principals Direct, Agents Execute
- Humans provide direction via instructions
- Agents own implementation decisions
- Artifacts capture deliverables for review

### Collaboration Is Explicit
- Use `./tools/collaborate` for cross-agent work
- Use `./tools/news-post` for broadcasts
- Don't assume other agents know your context

## Patterns

### Starting a New Project

1. Launch captain: `./tools/myclaude housekeeping captain`
2. Describe your project and tech stack
3. I'll help you:
   - Choose/create appropriate starter pack
   - Set up initial workstreams
   - Create your first agents
   - Configure quality gates

### Adding a New Feature Area

1. Create a workstream: `./tools/workstream-create {name}`
2. Create an agent: `./tools/agent-create {workstream} {name}`
3. Plan work with epics/sprints as needed
4. Launch the agent and start working

### Handling Cross-Cutting Work

When work spans multiple agents:
1. Lead agent creates collaboration requests
2. Use `./tools/dispatch-collaborations` to launch helpers
3. Each agent responds when done
4. Lead agent consolidates results

### Code Review Workflow

1. Create request: `REQUEST-principal-XXXX-agent-code-review.md`
2. Housekeeping spawns review subagents in parallel
3. Findings distributed via collaboration requests
4. Agents address issues, respond when done
5. Artifact captures final report

## Anti-Patterns

### Don't
- Skip session restoration - you'll lose context
- Work without logging - use ADHOC-WORKLOG for out-of-plan work
- Assume shared knowledge - use collaboration tools
- Bypass quality gates - they exist for good reasons
- Create agents without purpose - each agent needs a clear role

### Do
- Read your context at session start
- Track all work (sprints or ad-hoc)
- Communicate explicitly via tools
- Run pre-commit checks before pushing
- Document learnings in KNOWLEDGE.md

## Tool Mastery

### Essential Daily Tools
```bash
./tools/myclaude {ws} {agent}  # Launch agent
./tools/sync                    # Push with checks
./tools/news-read               # Check broadcasts
./tools/dispatch-collaborations # Handle pending requests
```

### When Stuck
```bash
./tools/session-backup          # Save your context
./tools/collaborate {agent}     # Ask for help
./tools/nit-add {file}          # Flag for later
```

### Discovery
```bash
./tools/tool-find {keyword}     # Find a tool
./tools/list-tools              # See all tools
./tools/instruction-show       # See active instructions
```

## Agency Service

The agency-service runs on port 3141 and provides the API layer for all embedded services.

### Key Endpoints
- `/health` - Health check (no auth required, for monitoring/load balancers)
- `/api` - Service index (lists all available service routes)
- `/api/*` - All service routes (require auth)

**Note:** The health endpoint is at `/health`, NOT `/api/health`. This is intentional - health checks must be accessible without authentication.

### Checking Service Status
```bash
curl http://127.0.0.1:3141/health
```

## Framework-Specific Notes

_This section grows as you add starter packs._

### Next.js
- See `claude/starter-packs/nextjs/` when available
- Patterns for app router, server components, etc.

### React Native
- See `claude/starter-packs/react-native/` when available

### Python
- See `claude/starter-packs/python/` when available

## Known Issues

### Test Pollution: principals/INDEX.md
Tests in `tests/tools/principal.bats` create test principals using `principal-create`. The cleanup removes directories but not the INDEX.md entries that `principal-create` appends. This causes test pollution in `claude/principals/INDEX.md`.

**Workaround:** Manually clean up INDEX.md after running tests.

**Fix needed:** Tests should remove their INDEX.md entries in cleanup, or use a test-specific INDEX.md.

## Claude Code Extensibility: Hybrid Model

Research conducted 2026-01-21 into Claude Code's native extensibility features.

**Key Finding:** Adopt a hybrid model - preserve Agency's organizational structure while selectively adding native features.

### Agents vs Subagents

| Type | Purpose | Principal Access | Persistence |
|------|---------|------------------|-------------|
| **Agency Agent** | Entity with identity | Yes | WORKLOG, KNOWLEDGE |
| **Native Subagent** | Ephemeral worker | No | None |

**Pattern:** Agents spawn subagents for tasks, then consolidate results.

```
Principal → Agent (captain) → Subagents (reviewers) → Agent consolidates → Principal
```

### Skills Wrap Tools

- **Skills** provide discovery and context (`/commit`)
- **Tools** provide enforcement and logging (`./tools/commit`)
- Skills guide, tools enforce

### Quick Wins Identified

1. **Prompt-based Stop hook** - LLM verifies completion before stopping
2. **Path-specific rules** - `.claude/rules/` with path globs
3. **Worker subagents** - code-reviewer, test-runner in `.claude/agents/`

### What We Keep

- Organizational model (workstreams, principals, REQUESTs)
- Persistent agent identity (WORKLOG, KNOWLEDGE)
- Tool enforcement + logging infrastructure
- AIADLC framework

**Full research:** `claude/docs/claude-code-extensibility/FINDINGS-CLAUDE-CODE-EXTENSIBILITY.md`

## Learnings Log

_Add significant learnings here as you work._

### 2026-01-21: Parallel Research Value

Two agents (captain + research) independently researched Claude Code extensibility. Different contexts produced different emphases:
- Research agent (fresh eyes): Focused on compatibility, incremental adoption
- Captain (deep context): Focused on trade-offs, what we'd lose

Synthesis was stronger than either alone. Consider parallel research for future investigations.

---

*Last updated: 2026-01-21*
