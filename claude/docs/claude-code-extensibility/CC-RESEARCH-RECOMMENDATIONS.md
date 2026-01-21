---
title: Claude Code Extensibility - Recommendations for The Agency
created: 2026-01-21T13:45:00+08:00
author: research-agent
version: 1.0.0
source: Claude Code Documentation Research
---

# Recommendations for The Agency Framework

## Executive Summary

Based on comprehensive research of Claude Code's extensibility features, this document provides prioritized recommendations for enhancing The Agency framework.

## High Priority Recommendations

### 1. Adopt SessionStart Hooks for Agent Context

**Feature:** SessionStart hooks with `CLAUDE_ENV_FILE`

**Current State:** The Agency uses `./tools/welcomeback` for session restoration.

**Recommendation:** Implement SessionStart hooks to automatically load agent context:

```json
{
  "hooks": {
    "SessionStart": [{
      "matcher": "startup",
      "hooks": [{
        "type": "command",
        "command": "$CLAUDE_PROJECT_DIR/tools/session-restore"
      }]
    }]
  }
}
```

**Benefits:**
- Automatic context restoration on every session
- Environment variable persistence via `CLAUDE_ENV_FILE`
- No manual invocation needed

### 2. Convert Agency Tools to Skills

**Feature:** Skills system with YAML frontmatter

**Current State:** Agency uses custom `./tools/*` scripts and CLAUDE.md instructions.

**Recommendation:** Create skills for common workflows:

```
.claude/skills/
├── commit/SKILL.md           # /commit workflow
├── pr-create/SKILL.md        # /pr-create workflow
├── code-review/SKILL.md      # Code review process
├── collaborate/SKILL.md      # Collaboration request
└── request-complete/SKILL.md # Complete a request
```

**Example Skill (commit):**
```markdown
---
name: commit
description: Create a properly formatted commit
disable-model-invocation: true
allowed-tools: Bash(git:*), Read
---

Follow The Agency commit conventions:
1. Run `./tools/commit-precheck`
2. Format: `{WORK-ITEM} - {WORKSTREAM}/{AGENT}: {SUMMARY}`
3. Include trailers
```

**Benefits:**
- Claude can discover and use workflows contextually
- Standardized invocation via `/commit`
- Tool restrictions for safety

### 3. Use Subagents for Specialized Tasks

**Feature:** Custom subagents with isolated contexts

**Current State:** The Agency uses Task tool for subagents but without custom configuration.

**Recommendation:** Create specialized subagents:

```
.claude/agents/
├── code-reviewer.md     # Read-only code review
├── test-runner.md       # Test execution and analysis
├── security-reviewer.md # Security analysis
└── doc-writer.md        # Documentation generation
```

**Example (code-reviewer.md):**
```markdown
---
name: code-reviewer
description: Expert code reviewer. Use proactively after code changes.
tools: Read, Grep, Glob, Bash(git diff:*)
model: sonnet
---

You are a senior code reviewer for The Agency framework.
Follow these review criteria:
1. Code quality and readability
2. Security concerns (OWASP top 10)
3. Test coverage
4. Agency conventions compliance
```

**Benefits:**
- Isolated context for verbose operations
- Model selection (Haiku for fast tasks)
- Tool restrictions for safety
- Consistent review criteria

### 4. Implement PreToolUse Hooks for Safety

**Feature:** PreToolUse hooks with decision control

**Recommendation:** Add validation hooks:

```json
{
  "hooks": {
    "PreToolUse": [{
      "matcher": "Bash",
      "hooks": [{
        "type": "command",
        "command": "$CLAUDE_PROJECT_DIR/tools/validate-bash"
      }]
    }]
  }
}
```

**Use Cases:**
- Block dangerous commands
- Validate git operations
- Enforce test requirements before commit
- Log all operations for audit

### 5. Create Agency Plugin for Distribution

**Feature:** Plugin system with marketplace

**Recommendation:** Package The Agency as a plugin:

```
agency-plugin/
├── .claude-plugin/
│   └── plugin.json
├── skills/
│   ├── commit/SKILL.md
│   ├── collaborate/SKILL.md
│   └── request/SKILL.md
├── agents/
│   ├── code-reviewer.md
│   └── test-runner.md
├── hooks/
│   └── hooks.json
└── .mcp.json
```

**Benefits:**
- Easy installation for new projects
- Version control and updates
- Namespace isolation
- Marketplace distribution

## Medium Priority Recommendations

### 6. Leverage CLAUDE.md Imports

**Feature:** `@path/to/file` import syntax

**Recommendation:** Modularize agent context:

```markdown
# Agent: Captain

See @claude/agents/captain/agent.md for identity.
See @claude/agents/captain/KNOWLEDGE.md for accumulated wisdom.
See @claude/workstreams/housekeeping/KNOWLEDGE.md for workstream patterns.

## Current Work
@claude/agents/captain/WORKLOG.md
```

**Benefits:**
- Modular, maintainable instructions
- Share knowledge across agents
- Reduce duplication

### 7. Use Path-Specific Rules

**Feature:** `.claude/rules/*.md` with `paths` frontmatter

**Recommendation:** Create contextual rules:

```markdown
---
paths:
  - "tools/**/*.sh"
---

# Shell Script Standards

- Use `set -euo pipefail`
- Include usage documentation
- Follow Tool Output Standard
```

**Benefits:**
- Rules apply only to relevant files
- Organized by concern
- Automatic loading

### 8. Integrate MCP Servers

**Feature:** MCP protocol for external tools

**Recommendation:** Connect to relevant services:

```bash
# GitHub integration
claude mcp add --transport http github https://api.githubcopilot.com/mcp/

# Issue tracking (if using Linear/Jira)
claude mcp add --transport http linear https://mcp.linear.app/mcp
```

**Benefits:**
- Direct PR/issue management
- No manual API calls
- Consistent tool interface

### 9. Implement Stop Hooks for Work Tracking

**Feature:** Stop hooks with prompt-based evaluation

**Recommendation:** Ensure proper work documentation:

```json
{
  "hooks": {
    "Stop": [{
      "hooks": [{
        "type": "prompt",
        "prompt": "Check if work has been properly documented. Verify: 1) WORKLOG updated 2) Changes committed 3) Context saved. Return {\"ok\": true} if complete."
      }]
    }]
  }
}
```

**Benefits:**
- Prevent incomplete sessions
- Enforce documentation
- Intelligent evaluation

## Lower Priority Recommendations

### 10. Agent SDK for CI/CD

**Feature:** Claude Agent SDK

**Recommendation:** Use SDK for automated pipelines:

```python
async def run_pr_review(pr_number: int):
    async for msg in query(
        prompt=f"Review PR #{pr_number} following Agency standards",
        options=ClaudeAgentOptions(
            allowed_tools=["Read", "Glob", "Grep"],
            setting_sources=["project"]
        )
    ):
        yield msg
```

### 11. PostToolUse Hooks for Automation

**Feature:** PostToolUse hooks

**Recommendation:** Auto-run quality checks:

```json
{
  "hooks": {
    "PostToolUse": [{
      "matcher": "Write|Edit",
      "hooks": [{
        "type": "command",
        "command": "npm run lint:fix $FILE"
      }]
    }]
  }
}
```

### 12. Custom Status Line

**Feature:** statusLine configuration

**Recommendation:** Show Agency context:

```json
{
  "statusLine": {
    "type": "command",
    "command": "$CLAUDE_PROJECT_DIR/tools/agency-status"
  }
}
```

## Implementation Roadmap

### Phase 1: Foundation (Quick Wins)
1. SessionStart hooks for context restoration
2. Basic skills for common workflows
3. Path-specific rules for conventions

### Phase 2: Specialization
4. Custom subagents for reviews
5. PreToolUse hooks for safety
6. CLAUDE.md imports for modularity

### Phase 3: Distribution
7. Agency plugin package
8. MCP server integrations
9. Stop hooks for quality

### Phase 4: Automation
10. Agent SDK for CI/CD
11. PostToolUse automation
12. Custom status line

## Compatibility Notes

- All features work with existing Agency tools
- Gradual adoption possible
- No breaking changes to current workflow
- Settings can be project-scoped or user-scoped

## Conclusion

Claude Code's extensibility features align well with The Agency's goals:

| Agency Concept | Claude Code Feature |
|----------------|---------------------|
| Agent context | SessionStart hooks + CLAUDE.md imports |
| Workflows | Skills |
| Review process | Subagents |
| Quality gates | PreToolUse hooks |
| Distribution | Plugins |
| Automation | Agent SDK |

The recommended approach is incremental adoption, starting with SessionStart hooks and skills, then expanding to subagents and plugins as needed.
