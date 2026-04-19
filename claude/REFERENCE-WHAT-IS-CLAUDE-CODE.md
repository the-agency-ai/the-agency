# What Is Claude Code — reference for agents and humans

A grounding reference on Claude Code's architecture: what it is, what the primitives are, and how they compose. Load before reasoning about skills, CLAUDE.md, hooks, subagents, or tools. Particularly important for agents authoring or reviewing skill methodology (see `REFERENCE-SKILL-AUTHORING.md`).

**Source consolidation:** compiled 2026-04-19 from Anthropic platform docs (platform.claude.com, code.claude.com, resources.anthropic.com), GitHub public repos (anthropics/claude-code, anthropics/skills), and community first-party writeups. Per-claim citations in the original research thread in `claude/workstreams/captain/transcripts/design-transcript-20260419.md`.

## Core platform components

### Claude Code (top-level agent)

The main agent that sits between the user and their project. Reads code, plans edits, runs commands, orchestrates subagents. It's the "brain" that decides what tools to call, what subagents to spawn, and how to structure multi-step coding tasks. It is the thing YOU ARE (if you are a Claude Code agent reading this).

### IDE / terminal UI

The interface (VS Code, JetBrains, CLI, web, etc.) where the user types prompts and sees plan/code diffs. Ships user messages to the agent and renders results. Decision logic lives in the agent layer, not in the UI.

### Tools (bash, read, edit/write, test, etc.)

The concrete "hands" of the agent. Shell execution, file reading/writing, code search, git, and custom tools exposed via the Model Context Protocol (MCP). The agent uses these to observe, change, and validate the project.

## Project-level configuration files

### CLAUDE.md

A markdown file in the project root that defines:

- Coding standards, architecture, and design decisions.
- Preferred libraries, frameworks, and file-layout patterns.
- Review checklists, guardrails, "what not to do."

**Scope:** Repo-wide, persistent.
**Focus:**
- **WHY** the project exists and **WHAT** it is (domain, business purpose, big picture).
- **WHAT** the main pieces are (architecture, directories, services, data flows).
- **HOW at a policy / convention level** — code style, patterns and anti-patterns, workflows, guardrails.

**Role:** Shapes **how Claude thinks** about the project and what "good work" looks like. Auto-loaded at the start of each session; becomes part of the agent's system prompt for that repo.

**Supports `@path/to/file.md` imports** — content is expanded inline at launch. (SKILL.md does NOT support this today; see `the-agency#306` for feature request.)

**Summary:** *"The project's WHY + WHAT + high-level HOW, baked into the agent's identity for that repo."*

### AGENTS.md (optional)

An open standard agent-instructions file any agent can read. If `CLAUDE.md` is absent, Claude Code falls back to `AGENTS.md` as baseline project guide. Lets a project maintain Claude-specific rules (`CLAUDE.md`) while still sharing a common agent-instructions schema with other tools.

## Agent, subagents, and delegation

### Agent (lead / main agent)

The primary Claude Code instance:
- Maintains session-wide context and memory.
- Plans the overall workflow (e.g., "modify X, add Y, run tests").

### Subagents

Lightweight, specialized Claude instances with:
- Their own system prompts and scopes (e.g., security-only, testing-only, refactor-only).
- Separate context windows to avoid polluting the main conversation.

The main agent can delegate tasks to subagents and merge or summarize results back into the top-level plan. Use cases: security audits, test-generation, refactors you want to keep conceptually isolated. In the-agency framework, subagents are formalized as `reviewer-code`, `reviewer-security`, `reviewer-design`, `reviewer-test`, `reviewer-scorer` — invoked by the quality-gate skill.

## Commands, skills, and automation

### Slash commands (e.g., `/review-pr`, `/deploy-staging`)

Shortcuts typed in the chat to invoke predefined workflows. Often tied to combinations of tools and hooks (run lint, run tests, deploy, post to Slack).

### Skills

A unified extensibility model that packages:
- Logic for when and how to react to user messages.
- Associated tools and MCP servers.
- Auto-invocation conditions (e.g., skills that fire when files in a certain directory change, via `paths:` frontmatter).

Skills are discovered and composed automatically when users ask a related question. They're how Claude "knows" which tools and patterns to pull in.

**Skill bundle structure** (per Anthropic skill-building guide):
```
my-skill/
├── SKILL.md           # required — overview + navigation + frontmatter
├── reference.md       # detailed protocol — loaded when needed
├── examples.md        # usage examples — loaded when needed
├── scripts/           # executable code — invoked, not loaded
└── assets/            # templates, static files
```

**Scope:** Per-task or per-workflow.
**Focus:** Concrete **HOW-to-execute** sequences — run this tool in this order with this agent type, under these preconditions, producing this output.
**Role:** Shapes **how Claude acts** to carry out tasks, often using the policies/context from `CLAUDE.md` as inputs.

### Hooks

Pre- or post-action scripts that run around tool invocations, edits, or session events:
- Auto-format after every edit (`PostToolUse:Edit`)
- Run linter or tests before committing (`PreToolUse:Bash`)
- Check ISCP dispatches on session start (`SessionStart`)
- Archive handoff before compact (`PreCompact`)

Hooks weave project conventions into the agent's behavior without rewriting prompts. Hook types include `SessionStart`, `PreToolUse`, `PostToolUse`, `PreCompact`, and others.

## How everything fits together

### Startup

- User opens a project; Claude Code session starts.
- Claude reads `CLAUDE.md` (or `AGENTS.md`) into agent context, establishing project rules and structure.
- `SessionStart` hooks fire (e.g., ISCP dispatch check, worktree sync, collaboration check).

### Planning

- User describes a task ("add a new endpoint").
- Main agent plans the work, selects relevant tools, may spawn subagents for specialized concerns.

### Execution

- Agent executes tools (reads files, edits code, runs shell commands) and composes results.
- Skills and hooks fire automatically or via slash commands to enforce linting, formatting, CI-style checks.

### Feedback loop

- Changes shown in IDE/terminal; user reviews, approves, or requests refinements.
- Agent updates internal memory; over time learns common patterns beyond what's in `CLAUDE.md`.

## Architecture layers (conceptual)

| Layer | What lives there |
|---|---|
| **User** | User in IDE/terminal, sending prompts and commands |
| **Agent** | Main agent + subagents planning and delegating |
| **Tool** | bash, read/write, MCP tools, CI/CD integrations |
| **Config** | `CLAUDE.md` / `AGENTS.md` as auto-loaded context; skills + hooks as reusable automation |

## Mental model — CLAUDE.md vs commands/skills

| | CLAUDE.md | Commands / Skills |
|---|---|---|
| **Scope** | Repo-wide, persistent | Per-task, per-workflow |
| **Focus** | WHY + WHAT + guideline-level HOW | Concrete HOW-to-execute |
| **Role** | Shapes how Claude **thinks** about the project | Shapes how Claude **acts** to carry out a task |
| **Lifetime** | Loaded at session start, part of system prompt | Loaded on invocation, used for the task |

`CLAUDE.md` tells the agent the repo's identity and conventions. Skills tell the agent how to execute specific procedures. Skills often reference or assume the conventions from `CLAUDE.md` as inputs.

## How the-agency framework layers on top

The-agency (and AIADLC methodology) extends Claude Code's primitives with framework-level conventions:

- **Principals + agents + captains** — formalized roles on top of Claude Code's agent primitive. Principal is the human; captain is the coordinator agent; worktree agents are specialized by workstream.
- **Skills as the interface** — every capability is a skill; agents use `/` autocomplete to discover.
- **Hookify** — behavioral enforcement rules that block unsafe actions (raw `git commit`, force-push, compound bash).
- **ISCP** — Inter-Session Communication Protocol (dispatches + flags) on top of file-based + SQLite-DB-based messaging.
- **Reference docs** — `claude/REFERENCE-*.md` as framework-level knowledge the agent pulls on demand.
- **Worktrees** — multi-agent per-workstream isolation, all sharing one `.git/`.
- **Quality gate** — subagent-based parallel review before commits cross boundaries.

See `claude/CLAUDE-THEAGENCY.md` for the-agency's own bootloader.

## For agents reading this: what to do with it

1. **On any skill authoring / review work**, treat this as required reading. `REFERENCE-SKILL-AUTHORING.md` references this doc.
2. **When proposing new skills, commands, or hooks**, map your proposal to one of the layers above. If it doesn't fit cleanly, question whether the primitive is right.
3. **When adopters ask "what does Claude Code do"**, point them here before the-agency-specific docs — this is the foundation.
4. **When you're confused about CLAUDE.md vs skills vs hooks**, re-read the mental-model table. Most confusion is in that axis.

## References

- [Claude Code overview](https://code.claude.com/docs/en/overview)
- [Platforms / IDEs](https://code.claude.com/docs/en/platforms)
- [Skills documentation](https://code.claude.com/docs/en/skills)
- [Memory / CLAUDE.md docs](https://code.claude.com/docs/en/memory.md)
- [Best Practices](https://code.claude.com/docs/en/best-practices)
- [The Complete Guide to Building Skills for Claude (PDF)](https://resources.anthropic.com/hubfs/The-Complete-Guide-to-Building-Skill-for-Claude.pdf)
- [Skill-creator (first-party)](https://github.com/anthropics/skills/tree/main/skills/skill-creator)
- [skills-cli on PyPI](https://pypi.org/project/skills-cli/)

---

*Captured during monofolk design session 2026-04-19. Upstreamed to the-agency. Keep current as Claude Code docs evolve.*
