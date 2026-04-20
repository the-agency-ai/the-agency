---
title: Claude Code Extensibility - Recommendations for The Agency
created: 2026-01-21T12:50:00
author: captain
version: 1.0.0
---

# Claude Code Extensibility Recommendations

Strategic recommendations for enhancing The Agency using native Claude Code features.

## Executive Summary

Claude Code's extensibility features offer significant opportunities to enhance The Agency. The highest-value improvements involve adopting native subagents, converting tools to skills, and implementing prompt-based hooks. These changes would reduce custom code, improve maintainability, and leverage Claude's built-in capabilities.

## Priority Matrix

| Feature | Impact | Effort | Priority |
|---------|--------|--------|----------|
| Native Subagents | Very High | Medium | 1 |
| Skills Conversion | High | Medium | 2 |
| Prompt-Based Hooks | High | Low | 3 |
| Memory/Rules Modularization | Medium | Low | 4 |
| MCP Integration | High | High | 5 |
| Agent SDK Orchestration | Medium | High | 6 |
| GitHub Actions | Medium | Medium | 7 |
| Plugin Distribution | Low | High | 8 |

## Detailed Recommendations

### 1. Native Subagents (Priority 1)

**Current State:**
- Agents defined in `claude/agents/*/agent.md`
- Launched via `./tools/myclaude`
- KNOWLEDGE.md loaded manually

**Recommended Change:**
Migrate to `.claude/agents/*.md` format with native frontmatter.

**Benefits:**
- Model selection per agent (`model: haiku|sonnet|opus`)
- Built-in tool restrictions (`tools:`, `disallowedTools:`)
- Skill preloading (`skills:`)
- Resume capability with agent ID
- Foreground/background execution

**Implementation:**

```yaml
# .claude/agents/captain.md
---
name: captain
description: Guide and coordinator for The Agency
model: sonnet
tools: Read, Edit, Write, Bash, Glob, Grep, Task
skills:
  - agency-conventions
  - git-workflow
  - review-process
---
You are the captain agent...
```

**Migration Path:**
1. Create `.claude/agents/` directory
2. Convert `claude/agents/*/agent.md` to new format
3. Move KNOWLEDGE.md content to skills
4. Update `./tools/myclaude` to use native invocation
5. Deprecate old agent structure

### 2. Skills Conversion (Priority 2)

**Current State:**
- Tools in `./tools/` directory
- Shell scripts with manual invocation
- Context not automatically loaded

**Recommended Change:**
Convert high-value tools to `.claude/skills/` format.

**Candidates for Conversion:**

| Tool | Skill | Notes |
|------|-------|-------|
| `./tools/commit` | `/commit` | Add `!`command`` for git context |
| `./tools/collaborate` | `/collaborate` | Use `$ARGUMENTS` for target |
| `./tools/review-spawn` | `/review` | Use `context: fork` for subagent |
| `./tools/request` | `/request` | Template-based creation |
| `./tools/news-post` | `/news` | Simple skill |

**Example:**

```yaml
# .claude/skills/commit/SKILL.md
---
name: commit
description: Create properly formatted commits
argument-hint: [message] [--work-item ID]
---
## Current State
- Branch: !`git branch --show-current`
- Status: !`git status --short`

## Commit Guidelines
@CLAUDE.md#git-commits

Create a commit with the provided message: $ARGUMENTS
```

### 3. Prompt-Based Hooks (Priority 3)

**Current State:**
- Command hooks for SessionStart
- Manual checks for task completion

**Recommended Change:**
Add prompt-based hooks for intelligent decisions.

**Implementation:**

```json
{
  "hooks": {
    "Stop": [{
      "hooks": [{
        "type": "prompt",
        "prompt": "Check if all TODO items are complete and tests pass before stopping. Review the todo list and last test run results. Respond: {\"ok\": true} to stop, or {\"ok\": false, \"reason\": \"what's incomplete\"} to continue."
      }]
    }],
    "PostToolUse": [{
      "matcher": "Edit|Write",
      "hooks": [{
        "type": "command",
        "command": "./tools/test-run --changed-only"
      }]
    }]
  }
}
```

**Benefits:**
- LLM evaluates completion criteria
- No premature stopping
- Automated test runs after edits

### 4. Memory/Rules Modularization (Priority 4)

**Current State:**
- Single large KNOWLEDGE.md files
- Context loaded manually

**Recommended Change:**
Split into modular `.claude/rules/` with path-specific activation.

**Structure:**

```
.claude/rules/
├── agency/
│   ├── conventions.md          # Always loaded
│   ├── git-workflow.md         # Always loaded
│   └── testing.md              # Always loaded
├── agents/
│   ├── captain.md              # paths: claude/agents/captain/**
│   └── research.md             # paths: claude/agents/research/**
└── workstreams/
    └── housekeeping.md         # paths: claude/workstreams/housekeeping/**
```

**Path-Specific Example:**

```yaml
# .claude/rules/agents/captain.md
---
paths:
  - "claude/agents/captain/**"
  - "tools/myclaude"
---
# Captain-Specific Rules
- Coordinate multi-agent workflows
- Use collaboration patterns
- Guide new users through setup
```

### 5. MCP Integration (Priority 5)

**Current State:**
- Browser MCP for research
- GitHub via `./tools/gh` wrapper

**Recommended Change:**
Expand MCP usage for Agency operations.

**Implementation:**

```json
{
  "mcpServers": {
    "browser": {
      "command": "npx",
      "args": ["-y", "@anthropic/browser-mcp"]
    },
    "agency": {
      "command": "node",
      "args": ["./mcp/agency-server.js"]
    }
  }
}
```

**Custom Agency MCP Server:**
Expose Agency operations as MCP tools:
- `agency_request_list` - List open requests
- `agency_request_create` - Create new request
- `agency_collaborate` - Send collaboration
- `agency_context_save` - Save session context

### 6. Agent SDK Orchestration (Priority 6)

**Current State:**
- Manual agent launching via shell
- Sequential collaboration patterns

**Recommended Change:**
Use Agent SDK for programmatic orchestration.

**Example:**

```python
# ./tools/parallel-review
from claude_code_sdk import ClaudeCode
import concurrent.futures

def parallel_code_review(work_item: str):
    client = ClaudeCode()

    reviewers = [
        ("code-reviewer-1", "Review for quality"),
        ("code-reviewer-2", "Review for patterns"),
        ("security-reviewer", "Review for security"),
    ]

    with concurrent.futures.ThreadPoolExecutor() as executor:
        futures = [
            executor.submit(
                run_review, client, name, work_item, focus
            )
            for name, focus in reviewers
        ]
        return [f.result() for f in futures]
```

### 7. GitHub Actions (Priority 7)

**Current State:**
- Manual PR review process
- Local-only code review

**Recommended Change:**
Add GitHub Actions for automated review.

**Implementation:**

```yaml
# .github/workflows/agency-review.yml
name: Agency Review

on:
  pull_request:
    types: [opened, synchronize]

jobs:
  review:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: anthropic/claude-code-action@v1
        with:
          anthropic-api-key: ${{ secrets.ANTHROPIC_API_KEY }}
          task: |
            Review using Agency standards:
            - Red-Green model compliance
            - Work item documentation
            - Test coverage
            - Security patterns
```

### 8. Plugin Distribution (Priority 8)

**Future Consideration:**
Package The Agency as a Claude Code plugin for distribution.

```json
{
  "name": "the-agency",
  "version": "1.0.0",
  "description": "Multi-agent development framework",
  "skills": ["skills/*"],
  "agents": ["agents/*"],
  "hooks": "hooks/agency.json"
}
```

## Implementation Roadmap

### Phase 1: Foundation (2-3 weeks)
- [ ] Convert agents to native subagent format
- [ ] Add prompt-based Stop hook
- [ ] Modularize rules into `.claude/rules/`

### Phase 2: Skills Migration (2-3 weeks)
- [ ] Convert commit, collaborate, review-spawn to skills
- [ ] Add dynamic context injection (`!`command``)
- [ ] Update documentation

### Phase 3: Integration (3-4 weeks)
- [ ] Implement custom Agency MCP server
- [ ] Add GitHub Actions for automated review
- [ ] Create Agent SDK orchestration tools

### Phase 4: Distribution (Future)
- [ ] Package as Claude Code plugin
- [ ] Publish to marketplace
- [ ] Create installation documentation

## Risk Assessment

| Risk | Mitigation |
|------|------------|
| Breaking changes in Claude Code | Pin to specific versions |
| Feature gaps vs current tools | Gradual migration, keep fallbacks |
| Learning curve | Comprehensive documentation |
| MCP server stability | Error handling, graceful degradation |

## Conclusion

The recommended changes would:
1. **Reduce custom code** - Leverage native features
2. **Improve maintainability** - Standard formats
3. **Enhance capabilities** - Prompt hooks, MCP, SDK
4. **Enable distribution** - Plugin packaging

Starting with native subagents and prompt-based hooks provides immediate value with moderate effort. Skills conversion follows naturally. More complex integrations (MCP, SDK, Actions) can be phased in over time.

## Related Documents

- [CLAUDE-CODE-EXTENSIBILITY-2026-01-21-1250.md](./CLAUDE-CODE-EXTENSIBILITY-2026-01-21-1250.md) - Feature overview
- [CLAUDE-CODE-SUBAGENTS.md](./CLAUDE-CODE-SUBAGENTS.md) - Subagent details
- [CLAUDE-CODE-SKILLS.md](./CLAUDE-CODE-SKILLS.md) - Skills details
- [CLAUDE-CODE-HOOKS.md](./CLAUDE-CODE-HOOKS.md) - Hooks details
