# The Agency - Core Concepts

A comprehensive guide to the multi-agent development framework.

## Philosophy

### Convention Over Configuration

Like Ruby on Rails, The Agency is opinionated. We establish clear conventions and enforce them, reducing decisions and increasing consistency. The right thing should be the easy thing.

### Agents Are Specialists

Each agent has a focused domain with persistent context across sessions. Handoffs between agents are explicit, never assumed. Context is preserved via structured files, not memory.

### Principals Direct, Agents Execute

Humans (principals) provide direction via instructions. Agents own implementation decisions. Artifacts capture deliverables for principal review. This maintains human-in-the-loop while maximizing agent autonomy.

### Collaboration Is Explicit

Agents don't assume shared knowledge. They use collaboration tools to request help, broadcast updates, and coordinate work. All communication is logged and traceable.

## Core Components

### 1. Agents

An **agent** is a Claude Code instance with:

```
claude/agents/{agentname}/
  agent.md           # Identity, purpose, capabilities
  KNOWLEDGE.md       # Accumulated wisdom and patterns
  WORKLOG.md         # Sprint-based work tracking
  ADHOC-WORKLOG.md   # Out-of-plan work log
  IDEAS.md           # Future possibilities
  ONBOARDING.md      # How to onboard to this agent
```

**Key properties:**
- **Identity**: Clear purpose and domain
- **Context**: Persistent across sessions via file-based memory
- **Autonomy**: Owns implementation within their domain
- **Collaboration**: Explicit tools for inter-agent work

### 2. Workstreams

A **workstream** organizes related work:

```
claude/workstreams/{workstream}/
  KNOWLEDGE.md              # Shared knowledge for this area
  epic001/                  # Major initiative
    sprint001/              # Time-boxed work
      plan.md
      completion.md
    sprint002/
  epic002/
```

**Key properties:**
- **Scope**: Defines a coherent area of work
- **Shared knowledge**: All agents in workstream access same KNOWLEDGE.md
- **Planning structure**: Epics for major initiatives, sprints for execution
- **Multiple agents**: Different agents can work on same workstream

### 3. Principals

A **principal** is a human stakeholder:

```
claude/principals/{principal}/
  preferences.yaml           # How they like to work
  requests/                  # REQUEST-principal-XXXX files they've issued
  artifacts/                 # Deliverables produced for them
  resources/                 # Reference materials they've provided
```

**Key properties:**
- **Direction**: Issues requests that agents execute
- **Review**: Receives artifacts for approval
- **Preferences**: Agents adapt to their working style
- **HITL**: Maintains human-in-the-loop control

### 4. Requests (REQUEST)

A **request** is a directed task from a principal:

```markdown
# REQUEST-jordan-0001: Implement Dark Mode

**Principal:** jordan
**Date:** 2026-01-01
**To:** web/web
**Status:** Active

## Directive
Add dark mode toggle to the application...

## Context
Users have requested this feature...

## Scope
- In scope: Settings page, theme switching
- Out of scope: Full redesign

---

## Outcome
(Filled when complete)
```

**Naming:** `REQUEST-{principal}-XXXX-{agent}-{summary}.md`

### 5. Artifacts (ART)

An **artifact** is a deliverable for a principal:

```markdown
# ART-0001: Dark Mode Implementation Report

**Principal:** jordan
**Date:** 2026-01-01
**Workstream:** web
**Agent:** web
**Request:** REQUEST-jordan-0001
**Type:** report

---

## Content
(The actual deliverable)
```

**Types:** report, code, design, research, analysis

**Naming:** `ART-XXXX-{principal}-{workstream}-{agent}-{date}-{title}.md`

### 6. Collaboration

Agents communicate via explicit tools:

| Tool | Purpose |
|------|---------|
| `./tools/collaborate` | Request help from another agent |
| `./tools/collaboration-respond` | Respond to a request |
| `./tools/news-post` | Broadcast an update |
| `./tools/news-read` | Check for broadcasts |
| `./tools/nit-add` | Flag an issue for later |
| `./tools/dispatch-collaborations` | Launch agents for pending requests |

**Collaboration files:**
```
claude/agents/collaboration/
  FROM-{source}-COLLABORATE-{id}-{date}.md
```

### 7. Handoffs

A **handoff** transfers work context between agents or sessions:

```markdown
# Handoff: web → agent-manager

**Date:** 2026-01-01
**From:** web/web
**To:** agents/agent-manager
**Context:** REQUEST-jordan-0005

## What Was Done
- Implemented UI components
- Added client-side validation

## What Remains
- Server-side validation
- API integration

## Key Files
- src/components/Form.tsx
- src/hooks/useValidation.ts

## Blockers
None

## Notes
Using zod for schema validation, recommend same on server.
```

## Workflow Patterns

### Session Start

1. Agent launches via `./tools/myclaude {workstream} {agent}`
2. Session hook provides context (last work, uncommitted changes, instructions)
3. Agent tells user what they were working on
4. Agent asks what to work on next

### Sprint Execution

1. Read ALL sprint plans before starting
2. Execute tasks, writing completions IMMEDIATELY
3. STOP on blockers - don't proceed without resolution
4. Use ad-hoc log for out-of-plan work

### Collaboration Flow

1. Agent A identifies need for Agent B's help
2. Agent A creates collaboration: `./tools/collaborate {agent} "subject" "request"`
3. Agent B is launched, reads collaboration file
4. Agent B does work, responds: `./tools/collaboration-respond {file} "response"`
5. Agent A sees response, integrates work

### Instruction Flow

1. Principal creates instruction (directly or via housekeeping)
2. Instruction assigned to agent(s)
3. Agent executes, creating artifacts as needed
4. Agent marks instruction complete with outcome
5. Principal reviews artifacts

## Quality Gates

Pre-commit hooks enforce standards:

1. **Formatting** - Code formatted consistently
2. **Linting** - No lint errors
3. **Type checking** - No type errors
4. **Unit tests** - All tests pass
5. **Code review** - Automated security/quality checks

**Tools:**
- `./tools/commit-precheck` - Run all gates
- `./tools/test-run` - Just tests
- `./tools/code-review` - Just review

## Git Discipline

- **Push via:** `./tools/sync` only (runs quality gates)
- **Stay on HEAD:** `git fetch && git pull --rebase` at session start
- **Push frequently:** Other agents need your work
- **Commit format:**
  ```
  workstream/agent: type(scope): message

  🤖 Generated with [Claude Code](https://claude.com/claude-code)

  Co-Authored-By: Claude <noreply@anthropic.com>
  ```

## Integration Points

### Claude Desktop via MCP

The Agency can expose coordination primitives via MCP:

```json
{
  "mcpServers": {
    "agency": {
      "type": "stdio",
      "command": "npx",
      "args": ["tsx", "claude/claude-desktop/agency-server/index.ts"]
    }
  }
}
```

**Exposed tools:**
- `get_workstream_context` - Current status
- `check_handoff_queue` - Pending collaborations
- `report_blockers` - Flag issues

### Claude in Chrome

Browser automation bridges Claude.ai ↔ Claude Code:

- **Scheduled tasks** - Periodic sync
- **Shortcuts** - Common automations
- **Native Messaging** - Direct Code ↔ Browser link

See `claude/claude-desktop/CHROME_INTEGRATION.md`

## Starter Packs

Framework-specific conventions:

```
claude/starter-packs/
  nextjs/
    PATTERNS.md       # Next.js specific patterns
    QUALITY.md        # Additional quality gates
    SCAFFOLDING.md    # Component/route generation
  react-native/
  python/
  swift/
```

Each pack adds:
- Opinionated patterns for that framework
- Additional quality enforcement
- Framework-specific tools

## Naming Conventions

| Entity | Pattern | Example |
|--------|---------|---------|
| Agent | lowercase-hyphen | `agent-manager` |
| Workstream | lowercase | `agents` |
| Request | `REQUEST-principal-XXXX-...` | `REQUEST-jordan-0001-web-dark-mode.md` |
| Artifact | `ART-XXXX-...` | `ART-0001-jordan-web-web-2026-01-01-report.md` |
| Collaboration | `COLLABORATE-XXXX` | `FROM-web-web-COLLABORATE-0001-2026-01-01.md` |
| Sprint | `sprint###` | `sprint001` |
| Epic | `epic###` | `epic001` |

## The Housekeeping Agent

Every Agency project has a `housekeeping` agent:

- **Role**: Meta-agent that maintains The Agency itself
- **Capabilities**: Setup, coordination, quality audits, guidance
- **Always available**: Your guide when you're unsure
- **Dogfooding**: Uses Agency patterns to maintain Agency

Launch: `./tools/myclaude housekeeping captain`

---

*The Agency - Multi-agent development, done right.*
