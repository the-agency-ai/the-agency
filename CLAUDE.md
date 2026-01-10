# The Agency

A multi-agent development framework for Claude Code.

## What is The Agency?

The Agency is a convention-over-configuration system for running multiple Claude Code agents that collaborate on a shared codebase. It provides:

- **Workstreams** - Organized areas of work (features, infrastructure, etc.)
- **Agents** - Specialized Claude Code instances with context and memory
- **Principals** - Human stakeholders who direct work via instructions
- **Collaboration** - Inter-agent communication and handoffs
- **Quality Gates** - Enforced standards via pre-commit hooks

## Quick Start

```bash
# Launch the housekeeping agent (your guide)
./tools/myclaude housekeeping housekeeping

# Ask housekeeping to help you set up your project
```

## Core Concepts

### Agents
Each agent has:
- `agent.md` - Identity, purpose, and capabilities
- `KNOWLEDGE.md` - Accumulated wisdom and patterns
- `WORKLOG.md` - Sprint-based work tracking
- `ADHOC-WORKLOG.md` - Out-of-plan work tracking

### Workstreams
Workstreams organize related work:
- Shared `KNOWLEDGE.md` across agents in the workstream
- Sprint directories for planned work
- Multiple agents can work on the same workstream

### Principals
Human stakeholders who provide direction:
- Instructions (`INSTR-XXXX`) - Directed tasks
- Artifacts - Deliverables produced for principals
- Preferences - How they like to work

### Collaboration
Agents communicate via:
- `./tools/collaborate` - Request help from another agent
- `./tools/post-news` / `./tools/read-news` - Broadcast updates
- `./tools/add-nit` - Flag issues for later

## Directory Structure

```
CLAUDE.md                    # This file - the constitution
claude/
  agents/                    # Agent definitions and context
    housekeeping/            # Your guide agent (ships with The Agency)
    collaboration/           # Inter-agent messages
  workstreams/               # Workstream knowledge and sprints
    housekeeping/            # Default workstream
  principals/                # Human stakeholders
  docs/                      # Guides and reference
  logs/                      # Session and activity logs
  claude-desktop/            # Claude Desktop / MCP integration
tools/                       # CLI tools for The Agency
```

## Tools

**Session:**
- `./tools/myclaude WORKSTREAM AGENT` - Launch an agent
- `./tools/welcomeback` - Session restoration
- `./tools/backup-session` - Save session context

**Scaffolding:**
- `./tools/create-workstream` - Add a new workstream
- `./tools/create-agent` - Add a new agent
- `./tools/create-epic` - Plan major work
- `./tools/create-sprint` - Plan sprint work

**Collaboration:**
- `./tools/collaborate` - Request help
- `./tools/respond-collaborate` - Respond to requests
- `./tools/post-news` / `./tools/read-news` - Broadcasts
- `./tools/dispatch-collaborations` - Launch agents for pending work

**Quality:**
- `./tools/pre-commit-check` - Run quality gates
- `./tools/run-unit-tests` - Run tests
- `./tools/code-review` - Automated code review

**Git:**
- `./tools/sync` - Push with pre-commit checks
- `./tools/doc-commit` - Commit documentation

## Conventions

### Naming
- Agents: lowercase, hyphenated (`agent-manager`, `web`)
- Workstreams: lowercase (`agents`, `web`, `analytics`)
- Instructions: `INSTR-XXXX-principal-workstream-agent-title.md`
- Artifacts: `ART-XXXX-principal-workstream-agent-date-title.md`

### Git Commits
```
workstream/agent: type(scope): message

[body]

Generated with [Claude Code](https://claude.com/claude-code)
Co-Authored-By: Claude <noreply@anthropic.com>
```

### API Design (Explicit Operations)
All API endpoints use explicit operation names. Do NOT rely on HTTP verb semantics.

**Pattern:**
```
POST /api/resource/create      # Create
GET  /api/resource/list        # List with filters
GET  /api/resource/get/:id     # Get single
POST /api/resource/update/:id  # Update
POST /api/resource/delete/:id  # Delete
POST /api/resource/action/:id  # Specific actions (approve, archive, etc.)
GET  /api/resource/stats       # Statistics
```

**Why explicit operations:**
- Self-documenting URLs
- Clear intent without needing to know HTTP semantics
- Easier to grep/search for operations
- Consistent across all services

**Anti-patterns (do NOT use):**
```
POST   /api/resource           # Ambiguous - is this create?
PATCH  /api/resource/:id       # Relies on verb semantics
DELETE /api/resource/:id       # Relies on verb semantics
GET    /api/resource/:id       # Ambiguous - use /get/:id
```

### Quality Gates
Pre-commit hooks enforce:
1. Code formatting
2. Linting
3. Type checking
4. Unit tests
5. Code review checks
6. API design patterns

## Starter Packs

Starter packs provide framework-specific conventions:

- `claude/starter-packs/nextjs/` - Next.js projects
- `claude/starter-packs/react-native/` - React Native apps
- `claude/starter-packs/python/` - Python projects

Each pack adds opinionated patterns and enforcement for that ecosystem.

## Getting Help

Your housekeeping agent is always available:

```bash
./tools/myclaude housekeeping housekeeping "I need help with..."
```

## Contributing

See `CONTRIBUTING.md` for how to:
- Submit starter packs
- Improve core tools
- Report issues

---

*The Agency - Multi-agent development, done right.*
