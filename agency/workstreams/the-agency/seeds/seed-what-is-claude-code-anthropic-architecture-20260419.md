---
type: seed
workstream: the-agency
slug: what-is-claude-code-anthropic-architecture
principal: jordan
agent: the-agency/jordan/captain
date: 2026-04-19
topic: "What is Claude Code — canonical Anthropic architecture reference (captured for the-agency-group shared context)"
status: captured (reference material for fleet-wide framing)
source: "principal-provided research summary, pasted 2026-04-19 D45-R3 session"
intended_scope: "the-agency-group — shared grounding across adopters + framework"
---

# Seed — What is Claude Code (Anthropic architecture reference)

Captured per principal directive: *"Capture both of those in the-agency-group for 'What is Claude' and 'What are the components of Claude'."*

This is the **first of two companion seeds** — the architecture of Claude Code itself. Companion: `seed-what-is-claude-code-components-20260419.md`.

## Why capture this

The-agency layers methodology (Valueflow, 1B1, three-bucket, Enforcement Triangle, hookify, ISCP) on top of Claude Code. Every agent, principal, and adopter needs a shared mental model of the underlying platform they're building on. This seed preserves Anthropic's canonical framing — provides the "floor" that the-agency layers above.

Related to #308 (`REFERENCE-WHAT-IS-CLAUDE-CODE.md` — monofolk PR pending merge upstream to the-agency). This seed captures the same content from primary-source research and should be considered during the #308 review.

## Content — Claude Code architecture (verbatim research summary)

Claude Code is structured as an agentic coding platform layered around a core "agent" that plans, reasons, and acts inside your project, with several files and primitives that compose behavior and delegation. Below is a breakdown of the main components and how they fit together from your perspective as a user.

### Core platform components

- **Claude Code (top-level agent)**
  The main agent that sits between you and your project: it reads your code, plans edits, runs commands, and orchestrates subagents. It's the "brain" that decides what tools to call, what subagents to spawn, and how to structure multi-step coding tasks.

- **IDE / terminal UI**
  The interface (VS Code, JetBrains, CLI, web, etc.) where you type prompts and see plan/code diffs. It ships your messages to the agent and renders results, but the decision logic lives in the agent layer, not in the UI.

- **Tools (bash, read, edit/write, test, etc.)**
  The concrete "hands" of the agent: shell execution, file reading/writing, code search, git, and custom tools exposed via the Model Context Protocol (MCP). The agent uses these to observe, change, and validate the project.

### Project-level configuration files

- **`CLAUDE.md`**
  A markdown file in your project root that defines:
  - Coding standards, architecture, and design decisions.
  - Preferred libraries, frameworks, and file-layout patterns.
  - Review checklists, guardrails, and "what not to do".

  Claude Code auto-loads `CLAUDE.md` at the start of each session and uses it as the foundational context for every decision and code edit.

- **`AGENTS.md` (optional)**
  An open standard agent instructions file that any agent can read. If `CLAUDE.md` is absent, Claude Code falls back to `AGENTS.md` as a baseline project guide. That lets you maintain one primary set of Claude-specific rules (`CLAUDE.md`) while still sharing a common agent-instructions schema with other tools.

### Agent, subagents, and delegation

- **Agent (lead / main agent)**
  The primary Claude Code instance that:
  - Maintains session-wide context and memory.
  - Plans the overall workflow (e.g., "modify X, add Y, run tests").

- **Subagents**
  Lightweight, specialized Claude instances with:
  - Their own system prompts and scopes (e.g., "security-only", "testing-only", "refactor-only").
  - Separate context windows to avoid polluting your main conversation.

  The main agent can delegate tasks to subagents and then merge or summarize results back into the top-level plan. Use cases include security audits, test-generation, and refactors you want to keep conceptually isolated.

### Commands, skills, and automation

- **Slash commands (e.g., `/review-pr`, `/deploy-staging`)**
  Shortcuts you type in the chat to invoke predefined workflows. They're often tied to combinations of tools and hooks (run lint, run tests, deploy, post to Slack).

- **Skills**
  A unified extensibility model that packages:
  - Logic for when and how to react to user messages.
  - Associated tools and MCP servers.
  - Auto-invocation conditions (e.g., skills that fire when files in a certain directory change).

  Skills are discovered and composed automatically when you ask a related question; they're how Claude "knows" which tools and patterns to pull in.

- **Hooks**
  Pre- or post-action scripts that run around tool invocations or edits, for example:
  - Auto-format after every edit.
  - Run linter or tests before committing.

  Hooks let you weave project conventions (formatting, linting, CI/CD rituals) into the agent's behavior without rewriting prompts.

### How everything fits together

1. **Startup**
   - You open a project and start a Claude Code session.
   - Claude reads `CLAUDE.md` (or `AGENTS.md`) into the agent's context, establishing project rules and structure.

2. **Planning**
   - You describe a task (e.g., "add a new endpoint").
   - The main agent plans the work, selects relevant tools, and may spawn subagents for specialized concerns (tests, security checks).

3. **Execution**
   - The agent executes tools (reads files, edits code, runs shell commands) and composes results.
   - Skills and hooks fire automatically or via slash commands to enforce linting, formatting, and CI-style checks.

4. **Feedback loop**
   - Changes are shown in the IDE/terminal; you can review, approve, or ask for refinements.
   - The agent updates its internal memory and, over time, learns common patterns even beyond what's in `CLAUDE.md`.

### High-level architecture diagram (conceptual)

- **User layer:** You in your IDE/terminal, sending prompts and commands.
- **Agent layer:** Main agent + subagents planning and delegating work.
- **Tool layer:** bash, read/write, MCP tools, CI/CD integrations.
- **Config layer:** `CLAUDE.md` / `AGENTS.md` as auto-loaded context, plus skills and hooks as reusable automation.

## Anthropic canonical sources

- Claude Code overview — https://code.claude.com/docs/en/overview
- Platforms and integrations — https://code.claude.com/docs/en/platforms
- Features overview (API) — https://platform.claude.com/docs/en/build-with-claude/overview
- Commands — https://code.claude.com/docs/en/commands
- Skills — https://code.claude.com/docs/en/skills
- Anthropic Managed Agents — https://platform.claude.com/docs/en/managed-agents/overview
- Claude Code product — https://claude.com/product/claude-code
- Anthropic internal usage PDF — https://www-cdn.anthropic.com/58284b19e702b49db9302d5b6f135ad8871e7658.pdf
- AGENTS.md standard — Issue anthropics/claude-code#6235

## How this fits with the-agency

The-agency adds layers on top of Claude Code's primitives:

| Claude Code primitive | the-agency layer |
|---|---|
| CLAUDE.md | `CLAUDE.md` + `@claude/CLAUDE-THEAGENCY.md` bootloader + REFERENCE-*.md injected on demand |
| Tools | safe-tools family (`git-safe`, `git-captain`, `cp-safe`, `pr-create`) + ISCP (`dispatch`, `flag`) |
| Skills | v2 bundle structure (SKILL.md + reference.md + examples.md + scripts/ + assets/) |
| Subagents | captain orchestration + worktree agents + MAR pattern |
| Hooks | hookify Enforcement Triangle (block / warn / inform) |
| AGENTS.md | agent classes in `agency/agents/<class>/agent.md` + principal-scoped registrations |

## Related

- #308 `REFERENCE-WHAT-IS-CLAUDE-CODE.md` (monofolk PR, pending merge upstream to the-agency)
- #309 `REFERENCE-SKILL-AUTHORING.md` (v2 skill methodology)
- Companion seed: `seed-what-is-claude-code-components-20260419.md`

*Captured as seed for the-agency-group context so adopters, new principals, and framework agents share one grounding source.*
