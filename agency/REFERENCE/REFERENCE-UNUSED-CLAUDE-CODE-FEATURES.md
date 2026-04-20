# Unused Claude Code Features - Gap Analysis

*Generated: 2026-03-03*

Analysis of Claude Code features The Agency is **not currently using** that could provide benefit.

## High-Value Gaps

### 1. Custom Agents (`.claude/agents/` directory)

Claude Code supports defining custom subagent types with frontmatter (model, tools, skills, spawn-mode, memory). The Agency has agent identity docs in `agency/agents/`, but doesn't use Claude Code's native `.claude/agents/*.md` agent definitions. This would enable:

- Restrict tools per agent type (e.g., research agent can't edit files)
- Set different models per agent (haiku for simple tasks, opus for complex)
- Define `isolation: worktree` for agents that need it
- Auto-delegate based on agent descriptions

### 2. Modular Rules (`.claude/rules/`)

Instead of one large CLAUDE.md, rules can be split into path-scoped files:

```
.claude/rules/
├── api-design.md          # applies everywhere
├── services/*.md          # applies only in services/
├── tools/*.md             # applies only in tools/
```

CLAUDE.md is already quite large. Modular rules would reduce token overhead by only loading relevant rules for the files being touched.

### 3. `/batch` Skill

Built-in skill for large-scale parallel changes across many files. Useful for framework-wide refactors (like tool output standard migrations).

### 4. Effort Level Control

`effortLevel: "low" | "medium" | "high"` - Could set `low` for simple agents (housekeeping, formatting) and `high` for complex work (captain, research). Currently everything runs at default.

### 5. `opusplan` Model

Uses Opus for planning/reasoning but Sonnet for execution. Could save significant cost on agents that do lots of file edits after deciding what to do.

### 6. Plugins System

The Agency's tools, skills, hooks, and agents could be packaged as a Claude Code plugin. This would make installation for new users trivial (`/plugin install the-agency`) and enable auto-updates.

### 7. `--from-pr` Flag

Resume a session from a PR number. Useful for the review workflow - instead of manually checking out and reviewing, an agent could `claude --from-pr 42`.

### 8. `PreCompact` Hook

Fires before context compaction. Could auto-save context checkpoints before the LLM summarizes, ensuring nothing is lost.

### 9. `TaskCompleted` Hook

Quality gate enforcer - block task completion unless tests pass and tree is clean. Already identified in myclaude upgrade research but not yet implemented.

### 10. `SubagentStart` / `SubagentStop` Hooks

Track when subagents spawn and finish. Could feed into the dispatch system for visibility into parallel work.

### 11. `ConfigChange` Hook

Detect when settings files change. Could auto-reload or validate configuration.

### 12. Tool Search (`ENABLE_TOOL_SEARCH`)

When there are many MCP tools, this auto-filters which tools are shown to the model. Not critical yet but would matter if MCP integrations expand.

## Medium-Value Gaps

| Feature | Benefit |
|---------|---------|
| `excludeSensitiveFiles` | Hide `.env`, vault files from context automatically |
| `--fork-session` | Fork a running session into a worktree mid-conversation |
| Session naming (`/rename`) | Better session identification in `/resume` picker |
| `sonnet[1m]` | 1M context for agents doing large codebase analysis |
| Headless mode (`-p`) | Script Claude invocations from tools (e.g., automated reviews) |
| `claude mcp serve` | Expose Claude Code itself as an MCP server to other tools |
| Prompt hooks | LLM-based decision hooks (use an LLM to decide whether to allow/block) |
| `CLAUDE_CODE_SUBAGENT_MODEL` | Set a cheaper model for all subagents globally |

## Top 3 Recommendations

1. **Modular rules (`.claude/rules/`)** - Immediate context window savings, easy to implement
2. **Custom agent definitions (`.claude/agents/*.md`)** - Native tool/model restrictions per agent type, replaces manual agent management
3. **`TaskCompleted` + `PreCompact` hooks** - Quality gates and context safety net, both low effort
