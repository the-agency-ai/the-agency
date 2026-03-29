# Claude Code Concepts Primer

**Purpose:** Reference for conference talk, workshop, and book.
**Date:** 2026-03-28 | **Version:** 1.1

---

## Overview

Claude Code has seven core architectural concepts. Together they form the primitives of an agent-native development environment.

**Agents** are isolated AI workers. **Skills** are reusable instructions. **Commands** are how you invoke skills. **Hooks** are mechanical enforcement. **Events** are the lifecycle moments that trigger hooks. **MCP Servers** bring in external tools. **Settings** tie it all together as declarative policy.

Two additional concepts cut across everything: the **Status Line** (real-time session display) and **Permissions** (declarative tool access control).

---

## Agents

An agent is a specialized AI assistant that runs in its own context window, separate from the main conversation. It gets its own system prompt, tool restrictions, and permission model.

### How they work

Claude spawns an agent with a task. The agent runs agentic loops in its own isolated context. When it finishes, it returns a summary to the parent. The verbose work stays in the agent's context and never pollutes the parent's.

This context isolation is the primary benefit. A code review agent can read dozens of files, run tests, and produce detailed analysis — and the parent conversation only sees the summary.

### Key properties

Agents can use a different model than the parent. They can be restricted to specific tools via allowlists or denylists. They cannot spawn other agents (no nesting). They are resumable — their full transcript persists and can be continued later.

### How you invoke them

Three ways. Claude can delegate automatically based on the agent's description. You can mention an agent explicitly with `@"agent-name"`. Or you can make an agent the main thread for an entire session with `--agent <name>`.

### Execution modes

Agents can run in the foreground (blocking), background (concurrent), or in an isolated git worktree (separate checkout of the repo).

### Configuration

Defined as Markdown files with YAML frontmatter in `.claude/agents/`. The frontmatter declares the name, description, allowed tools, model, and permission mode. The body is the system prompt.

---

## Skills

A skill is a Markdown file with optional frontmatter that provides reusable instructions. Claude applies skills when they're relevant to the task, or you invoke them directly with `/skill-name`.

### How they work

Claude loads skill descriptions into context at session start. When a task matches a skill's description, Claude loads the full content and follows those instructions. Skills can run inline in the main conversation or fork into an isolated subagent.

### Key properties

Skills can auto-load based on description matching, or be restricted to manual invocation only. They support dynamic content injection — shell commands that run before Claude sees the skill content, with output substituted in. They can include supporting files like templates, examples, and scripts.

### Invocation control

By default, skills are both auto-loadable and manually invocable via `/skill-name`. Setting `disable-model-invocation: true` restricts to manual only. Setting `user-invocable: false` hides the skill from the slash menu — it becomes background knowledge Claude applies automatically.

### Configuration

Lives in `.claude/skills/<name>/SKILL.md` with YAML frontmatter declaring name, description, allowed tools, and execution mode.

---

## Commands

A command is a slash-invoked action. There are three kinds.

**Built-in commands** like `/help`, `/config`, and `/compact` execute fixed logic directly. **Skill-based commands** are user-defined Markdown files that give Claude instructions. **MCP prompts** are commands exposed by connected MCP servers.

### Relationship to skills

Commands in `.claude/commands/` are skills — same frontmatter, same mechanism. The newer `.claude/skills/` format is recommended because it supports additional features like supporting files and auto-loading. Commands still work for backward compatibility.

You invoke any command by typing `/` followed by its name, optionally with arguments.

---

## Hooks

A hook is a deterministic shell command that executes automatically at specific lifecycle events. Unlike skills, hooks don't rely on LLM judgment. They're mechanical enforcement.

### How they work

An event fires — say, Claude is about to run a Bash command. All hooks matching that event receive JSON data on stdin. Each hook returns a decision via its exit code and stdout. Exit code 0 means success. Exit code 2 means block the action. Claude Code applies the decisions and proceeds.

### Four types

**Command hooks** run a shell script. **HTTP hooks** POST to an endpoint. **Prompt hooks** have a lightweight LLM evaluate a policy question. **Agent hooks** spin up a subagent with tool access for complex verification.

### What makes them different from skills

Hooks are deterministic. A hook either blocks or allows based on exit codes and pattern matching. Skills are judgment-based — Claude reads the instructions and decides how to apply them. Hooks fire automatically at events. Skills are loaded when relevant or invoked manually.

### Hooks vs. Hookify rules

Hooks are the standard Claude Code mechanism — configured in settings.json, fired at events. Hookify is a higher-level plugin that analyzes conversation context to prevent unwanted behaviors. Hookify rules are stored as `.claude/hookify.*.local.md` files and are built on top of hooks.

### Configuration

Hooks are defined in settings.json at any scope. Each hook specifies an event, an optional matcher (regex on tool name), and one or more handlers with type, command, and timeout.

---

## Events

Events are lifecycle points in Claude Code where hooks can trigger. The event system provides structured JSON data to hooks so they can make informed decisions.

### The lifecycle

A session starts (`SessionStart`). The user submits a prompt (`UserPromptSubmit`). Claude enters its agentic loop, where each tool call fires `PreToolUse` before execution and `PostToolUse` after. Permission prompts fire `PermissionRequest`. When Claude finishes responding, `Stop` fires. When the session ends, `SessionEnd` fires.

Async events fire independently: `FileChanged` when watched files change, `PreCompact` before context compression, `SubagentStart` and `SubagentStop` for agent lifecycle.

### Blocking vs. non-blocking

Some events can block. `PreToolUse` can prevent a tool call. `PermissionRequest` can auto-approve or deny. `Stop` can re-prompt Claude to keep working. Other events like `PostToolUse` and `SessionStart` are informational only.

### Data

Every event includes the session ID, transcript path, current working directory, and the event name. Event-specific data varies: `PreToolUse` includes the tool name and input, `PostToolUse` adds the output, `UserPromptSubmit` includes the user's prompt text.

---

## MCP Servers

MCP (Model Context Protocol) servers are external tool and data providers that extend Claude Code's capabilities. They expose tools Claude can call, resources Claude can reference, and prompts that appear as commands.

### How they work

An MCP server runs as a local process (communicating via stdin/stdout) or as an HTTP endpoint. Claude Code discovers the server's tools and resources at startup. Tools appear in Claude's available actions with names like `mcp__github__search_repositories`. Claude calls them like any other tool.

### What they provide

**Tools** are functions Claude can invoke — sending a Slack message, querying a database, creating a GitHub issue. **Resources** are data Claude can reference on demand. **Prompts** are pre-configured instruction templates that appear in the slash command menu.

### Configuration

MCP servers are configured in `.mcp.json` at the project or user level. Each entry specifies the server name, transport type (stdio, http, sse), and connection details.

---

## Settings

Settings are configuration files that control Claude Code's behavior. They exist at multiple scopes with a clear precedence hierarchy.

### Scopes

Four levels, from highest to lowest priority: **Managed** (server-controlled by IT/admin, org-wide, cannot be overridden), **User** (`~/.claude/settings.json`, personal), **Project** (`.claude/settings.json`, team-wide via git), and **Local** (`.claude/settings.local.json`, personal and gitignored).

The rule is simple: managed always wins. User overrides project. Project overrides local.

### What they control

Model and effort level. Permission rules (allow/deny for specific tools). Hook configurations (event-to-handler mappings). Environment variables. Status line configuration. Plugin enablement.

---

## Status Line

The status line is a customizable bar at the bottom of Claude Code that displays real-time session data.

### How it works

You configure a shell script in settings. After each Claude message, the script runs. It receives JSON on stdin containing session data — context window usage, cost, rate limits, git status, model name, session name. The script prints formatted text to stdout, and Claude Code displays it at the bottom of the terminal.

The status line runs locally with no token cost. It updates after each Claude message and debounces at 300ms.

---

## How They All Relate

### The design philosophy

Each concept serves a distinct role. **Hooks** are mechanical enforcement — the machine follows rules. **Skills** are reusable judgment — the LLM applies instructions. **Agents** are isolated delegation — the LLM works independently. **Settings** are declarative configuration — the human sets policy. **MCP** is extensibility — the ecosystem provides capabilities.

### The interaction patterns

Settings configure everything: permissions, hooks, status line, MCP servers. Events trigger hooks. Hooks enforce rules on tool calls — blocking, approving, or adding context. Skills load into Claude's context and guide its judgment. Skills can fork into agents for isolated execution. Commands are the user-facing entry point to skills. MCP servers expose tools, resources, and prompts that integrate with all of the above.

### Key distinctions

Hooks are deterministic and stateless — they fire based on event patterns and return exit codes. Skills are judgment-based — Claude decides how to apply them. Agents are context-isolated — their work doesn't consume the parent's context. Commands are invocation mechanisms — the `/` entry point. These are not interchangeable; each fills a gap the others can't.

---

## The SDLC Lens

This section connects Claude Code's architecture to the conference talk, workshop, and book.

### What traditional SDLCs assume

Traditional software development lifecycles are designed around humans. Human users interacting via graphical interfaces. Human judgment at every decision point. Human memory for context and conventions. Synchronous collaboration through meetings, reviews, and standups.

Even the tooling is biased. IDEs assume a human clicking through menus. CI/CD dashboards assume a human watching a browser. Review tools assume a human reading diffs. The entire ecosystem optimizes for graphical, synchronous, human-in-the-loop workflows.

### The CLI developer vs. the GUI developer

There's a fundamental divide. The developer comfortable on the CLI — who thinks in small tools, composable pipelines, text streams, and scriptable interfaces — already operates in the paradigm that agent-native development requires. The developer stuck in the GUI needs to make a conceptual leap. Not just in tooling, but in how they think about process itself.

The Unix philosophy maps naturally to agent workflows: small, composable tools that do one thing well, connected by text streams. This is exactly how hooks, skills, agents, and MCP servers compose.

### What Claude Code reveals

Claude Code's architecture is a working model of an agent-native development lifecycle:

**Agents** replace human delegation. Instead of assigning a task to a colleague and waiting for a standup update, you spawn an agent that works concurrently and returns results.

**Hooks** replace human discipline. Instead of team agreements that everyone promises to follow (and half actually do), you have mechanical enforcement that fires every time, with no exceptions.

**Skills** replace tribal knowledge. Instead of onboarding docs that nobody reads and conventions that live in senior engineers' heads, you have codified instructions that Claude applies automatically.

**Events** replace human observation. Instead of someone noticing that a build broke or a test failed, the system watches itself and reacts.

**Settings** replace team agreements. Instead of a wiki page describing "how we work," you have a declarative policy file with scoped enforcement.

### The key insight

These aren't just developer tools. They're the primitives of an agent-native development lifecycle. The "development environment" isn't an IDE — it's a configured agent with skills, hooks, and integrations. The "team process" isn't a wiki page — it's a settings file with mechanical enforcement.

The AIADLC doesn't replace what we know about software development. It mechanically enforces what we've always said we'd do — and then cranks it past what humans could sustain alone.
