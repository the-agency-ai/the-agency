# Claude Code Extensibility: Consolidated Findings

**Date:** 2026-01-21
**Research By:** captain (primary), research agent (parallel)
**Status:** Complete

---

## Executive Summary

Comprehensive research into Claude Code's extensibility features to inform enhancement of The Agency framework. Two agents conducted independent research, then findings were consolidated.

**Key Conclusion:** Adopt a **hybrid model** that preserves The Agency's organizational structure (workstreams, principals, AIADLC) while selectively adopting native Claude Code features where they add value without replacing what works.

---

## Features Researched

| Feature | Purpose | Agency Relevance |
|---------|---------|------------------|
| Settings | JSON configuration hierarchy | High - already aligned |
| Memory (CLAUDE.md) | Instructions and context | High - imports, path rules |
| Skills | Reusable prompts/workflows | High - discovery layer for tools |
| Subagents | Specialized AI workers | High - ephemeral task workers |
| Hooks | Lifecycle event automation | Very High - Stop hooks, validation |
| MCP Servers | External tool integration | Medium - future consideration |
| Plugins | Distribution packages | Low - future consideration |
| Agent SDK | Programmatic access | Medium - CI/CD potential |

---

## The Hybrid Model

### Core Insight

The Agency and Claude Code native features serve different purposes:

| Aspect | The Agency | Native Claude Code |
|--------|------------|-------------------|
| **Agents** | Persistent entities with identity, history, principal relationships | Ephemeral workers for specific tasks |
| **Organization** | Workstreams, principals, REQUESTs, collaboration | Flat structure, no hierarchy |
| **Tools** | Enforcement, logging, conventions | Discovery, context, guidance |
| **Lifecycle** | AIADLC (AI Augmented Development Lifecycle) | Session-based work |

### The Hybrid Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    THE AGENCY                           │
│  Workstreams · Principals · REQUESTs · Collaboration    │
│  (Our organizational model - KEEP)                      │
├─────────────────────────────────────────────────────────┤
│                    AGENTS                               │
│  Persistent entities: captain, research, web-dev...    │
│  Have: WORKLOG, KNOWLEDGE, principal relationships     │
│  Can: Interact with humans, accumulate wisdom          │
│  (Our agent model - KEEP)                              │
├─────────────────────────────────────────────────────────┤
│                   SUBAGENTS                             │
│  Ephemeral workers: code-reviewer, test-runner...      │
│  Have: Isolated context, tool restrictions, model spec │
│  Cannot: Talk to principals, persist state             │
│  (Native subagents - ADD for task work)                │
├─────────────────────────────────────────────────────────┤
│                 SKILLS + TOOLS                          │
│  Skills: Discovery, context, guidance (/commit)        │
│  Tools: Enforcement, logging, execution (./tools/*)    │
│  (Hybrid - skills wrap tools)                          │
├─────────────────────────────────────────────────────────┤
│                    HOOKS                                │
│  Stop: Prompt-based completion verification            │
│  SessionStart: Context restoration (already have)      │
│  PreToolUse: Validation (future)                       │
│  (Native hooks - ADD for automation)                   │
└─────────────────────────────────────────────────────────┘
```

---

## Recommendations by Priority

### Tier 1: Quick Wins (Low Effort, High Value)

#### 1. Prompt-Based Stop Hook

**What:** LLM evaluates whether work is complete before allowing session to end.

**Why:** Prevents premature stopping, ensures tasks complete, no migration needed.

**Implementation:**
```json
{
  "hooks": {
    "Stop": [{
      "hooks": [{
        "type": "prompt",
        "prompt": "Before stopping, verify:\n1. All TODO items complete?\n2. Tests passing?\n3. Context saved?\n4. Changes committed?\n\nRespond {\"ok\": true} to stop, or {\"ok\": false, \"reason\": \"...\"} to continue."
      }]
    }]
  }
}
```

**Explore:** What state can the evaluator access? Cost/latency impact? Criteria refinement?

#### 2. Path-Specific Rules

**What:** Rules in `.claude/rules/` that activate based on file paths.

**Why:** Conditional context loading reduces noise, easy to implement.

**Implementation:**
```yaml
# .claude/rules/shell-scripts.md
---
paths:
  - "tools/**/*.sh"
---
# Shell Script Standards
- Use `set -euo pipefail`
- Follow Tool Output Standard
- Include usage documentation
```

### Tier 2: Valuable Additions (Medium Effort)

#### 3. Native Subagents for Task Work

**What:** Define ephemeral workers in `.claude/agents/` for code review, testing, etc.

**Why:** Model selection, tool restrictions, isolated context - without replacing our agents.

**Key Distinction:**
- **Agency Agent** = talks to principals, has history, persistent identity
- **Native Subagent** = worker bee, does task, reports to agent, disappears

**Implementation:**
```yaml
# .claude/agents/code-reviewer.md
---
name: code-reviewer
description: Code review specialist. Use proactively after changes.
model: haiku
tools: Read, Grep, Glob, Bash(git diff:*)
---
You are a code reviewer. Analyze for quality, security, conventions.
Return structured findings.
```

#### 4. Skills Wrapping Tools

**What:** Skills provide discovery and context, tools do enforcement.

**Why:** Claude discovers `/commit` contextually, but `./tools/commit` enforces conventions.

**Implementation:**
```yaml
# .claude/skills/commit/SKILL.md
---
name: commit
description: Create properly formatted commits following Agency conventions
disable-model-invocation: true
---
## Current State
- Branch: !`git branch --show-current`
- Status: !`git status --short`

## Usage
Use `./tools/commit` which enforces format and logs properly:
./tools/commit "message" --work-item REQUEST-xxx --stage impl
```

### Tier 3: Future Considerations (Higher Effort)

#### 5. Custom Agency MCP Server

**When:** Need tighter integration for request/collaboration operations.

**What:** Expose Agency operations as MCP tools.

#### 6. Agent SDK for CI/CD

**When:** Want automated PR reviews in GitHub Actions.

**What:** Python/TypeScript programmatic agent control.

#### 7. Plugin Distribution

**When:** Ready to package The Agency for easy installation.

**What:** Bundle skills, agents, hooks as installable plugin.

---

## What We Keep (And Why)

### 1. Organizational Model
- Workstreams organize related work
- Principals provide direction
- REQUESTs track lifecycle
- Collaboration enables handoffs

**Why:** This is AIADLC. Native features don't have it.

### 2. Persistent Agent Identity
- Agents have history (WORKLOG)
- Agents accumulate wisdom (KNOWLEDGE)
- Agents have relationships (to principals, workstreams)

**Why:** Subagents are ephemeral. Our agents are entities.

### 3. Tool Enforcement + Logging
- Minimal stdout (10-20 tokens in context)
- Verbose output to database
- Run IDs for tracing
- Programmatic enforcement

**Why:** Skills are guidance, tools are enforcement. Keep both.

### 4. Custom Workflows
- `./tools/commit` enforces format
- `./tools/tag` verifies tests pass
- `./tools/review-spawn` generates prompts

**Why:** Ruthless enforcement via tooling has value.

---

## What We Don't Do

1. **Replace agents with native subagents** - Different purposes
2. **Abandon tools for pure skills** - Lose enforcement
3. **Migrate organizational model** - No native equivalent
4. **Rush to MCP/SDK/Plugins** - Complexity without immediate need

---

## Research Comparison

### Captain's Research
- 14 documents covering all feature areas
- Emphasized trade-offs and what we'd give up
- Initially prioritized native subagents as foundation change
- Detailed recommendations document with phased roadmap

### Research Agent's Research
- 10 documents covering same areas
- Emphasized compatibility and incremental adoption
- Prioritized SessionStart hooks and skills first
- Noted: "Gradual adoption possible, no breaking changes"

### Synthesis
Research agent's conservative "enhance what works" approach combined with captain's analysis of trade-offs led to the hybrid model. Neither full migration nor status quo - selective adoption.

---

## Next Steps

1. **Implement Stop hook** - Add to `.claude/settings.json`, test criteria
2. **Create path-specific rules** - Start with shell scripts, API patterns
3. **Define worker subagents** - code-reviewer, test-runner in `.claude/agents/`
4. **Pilot skill wrapping** - `/commit` skill that calls `./tools/commit`
5. **Document hybrid model** - Update CLAUDE.md with approach

---

## Source Documents

### Captain's Research
- `CLAUDE-CODE-EXTENSIBILITY-2026-01-21-1250.md` - Overview
- `CLAUDE-CODE-*.md` - 12 detail documents
- `CLAUDE-CODE-EXTENSIBILITY-RECOMMENDATIONS.md` - Recommendations

### Research Agent's Research
- `CC-RESEARCH-EXTENSIBILITY-2026-01-21-1330.md` - Overview
- `CC-RESEARCH-*.md` - 8 detail documents
- `CC-RESEARCH-RECOMMENDATIONS.md` - Recommendations
