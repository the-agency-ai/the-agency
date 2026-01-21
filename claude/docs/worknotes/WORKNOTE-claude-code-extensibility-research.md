# WORKNOTE: Claude Code Extensibility Research

**Date:** 2026-01-21
**Agents:** captain (lead), research (parallel)
**Status:** Research Complete, Implementation Pending

---

## Executive Summary

Conducted comprehensive research into Claude Code's extensibility features to determine how they could enhance The Agency framework. Two agents (captain and research) independently explored official documentation, then findings were consolidated.

**Key Outcome:** Adopt a hybrid model preserving Agency's organizational structure while selectively adding native features (Stop hooks, subagents for tasks, skills wrapping tools).

---

## The Question

> How can we leverage Claude Code's native extensibility features to enhance The Agency without losing what makes it valuable?

---

## Research Approach

### Parallel Independent Research

1. **Captain** - Used browser automation to systematically explore Claude Code docs
2. **Research Agent** - Independent research via COLLABORATE-0047, same docs, different perspective

### Why Two Agents?

- Different emphases catch different things
- Research agent lacks Agency context, sees features fresh
- Captain has deep context, sees integration challenges
- Synthesis produces better recommendations than either alone

---

## Features Discovered

| Feature | Description | Agency Fit |
|---------|-------------|------------|
| **Skills** | SKILL.md files with frontmatter, `/skill` invocation | Wrap tools for discovery |
| **Subagents** | `.claude/agents/*.md` with model/tool config | Ephemeral workers |
| **Hooks** | Lifecycle events (Stop, SessionStart, PreToolUse) | Automation, validation |
| **Memory** | CLAUDE.md imports, `.claude/rules/` | Modular context |
| **Settings** | Hierarchical JSON configuration | Already aligned |
| **MCP** | External tool protocol | Future integration |
| **Plugins** | Distribution packages | Future distribution |
| **Agent SDK** | Programmatic access | CI/CD automation |

---

## Key Insight: The Hybrid Model

Native Claude Code features and The Agency serve different purposes:

### What Native Features Provide
- Ephemeral workers with isolated context
- Model selection (haiku/sonnet/opus)
- Tool restrictions
- Lifecycle hooks
- Discovery via skills

### What The Agency Provides
- Persistent agent identity with history
- Organizational model (workstreams, principals)
- AIADLC (AI Augmented Development Lifecycle)
- Principal relationships
- Tool enforcement with logging
- Collaboration patterns

### The Synthesis

```
Agency Agents (persistent, talk to principals)
    ↓ spawn
Native Subagents (ephemeral, do tasks, report back)
    ↓ use
Skills (discovery) → Tools (enforcement)
```

**Agents are identities. Subagents are workers.**

---

## Recommendations

### Do Now (Quick Wins)

1. **Prompt-Based Stop Hook**
   - LLM evaluates completion before stopping
   - Low effort, high value, no migration
   - Prevents premature session endings

2. **Path-Specific Rules**
   - `.claude/rules/` with path globs
   - Conditional context loading
   - Easy to implement incrementally

### Do Soon (Medium Effort)

3. **Native Subagents for Tasks**
   - code-reviewer, test-runner, security-scanner
   - Model selection, tool restrictions
   - Workers, not replacements for our agents

4. **Skills Wrapping Tools**
   - `/commit` skill provides context
   - `./tools/commit` does enforcement
   - Best of both worlds

### Do Later (When Needed)

5. MCP server for Agency operations
6. Agent SDK for CI/CD automation
7. Plugin packaging for distribution

---

## What We Don't Do

| Temptation | Why Not |
|------------|---------|
| Replace agents with subagents | Subagents can't talk to principals, no persistence |
| Abandon tools for skills | Skills guide, tools enforce |
| Migrate organizational model | No native equivalent for workstreams/principals |
| Full platform lock-in | Keep tools independent where practical |

---

## Trade-Offs Considered

### If We Went Full Native

**Gain:**
- Tighter platform integration
- Less custom code
- Native model selection

**Lose:**
- Workstream/principal model
- Persistent agent identity
- Tool enforcement + logging
- AIADLC framework

### Hybrid Approach (Chosen)

**Gain:**
- Best of both worlds
- Incremental adoption
- No breaking changes
- Preserve what works

**Lose:**
- Some elegance (two agent systems)
- More concepts to understand

---

## Documentation Produced

### Captain's Research (14 documents)
```
claude/docs/claude-code-extensibility/
├── CLAUDE-CODE-EXTENSIBILITY-2026-01-21-1250.md  # Overview
├── CLAUDE-CODE-SKILLS.md
├── CLAUDE-CODE-SUBAGENTS.md
├── CLAUDE-CODE-HOOKS.md
├── CLAUDE-CODE-MEMORY.md
├── CLAUDE-CODE-SETTINGS.md
├── CLAUDE-CODE-PERMISSIONS.md
├── CLAUDE-CODE-OUTPUT-STYLES.md
├── CLAUDE-CODE-PLUGINS.md
├── CLAUDE-CODE-MCP.md
├── CLAUDE-CODE-AGENT-SDK.md
├── CLAUDE-CODE-IDE.md
├── CLAUDE-CODE-GITHUB-ACTIONS.md
└── CLAUDE-CODE-EXTENSIBILITY-RECOMMENDATIONS.md
```

### Research Agent's Research (10 documents)
```
claude/docs/claude-code-extensibility/
├── CC-RESEARCH-EXTENSIBILITY-2026-01-21-1330.md  # Overview
├── CC-RESEARCH-SKILLS.md
├── CC-RESEARCH-SUBAGENTS.md
├── CC-RESEARCH-HOOKS.md
├── CC-RESEARCH-MEMORY.md
├── CC-RESEARCH-SETTINGS.md
├── CC-RESEARCH-PLUGINS.md
├── CC-RESEARCH-MCP.md
├── CC-RESEARCH-SDK.md
└── CC-RESEARCH-RECOMMENDATIONS.md
```

### Consolidated
```
├── FINDINGS-CLAUDE-CODE-EXTENSIBILITY.md  # Synthesized findings
└── RESEARCH-DIRECTION-CLAUDE-CODE-EXTENSIBILITY.md  # Methodology
```

---

## Lessons Learned

### On Parallel Research

1. **Different context = different emphasis** - Research agent focused on compatibility, captain on trade-offs
2. **Fresh eyes valuable** - Research agent caught details captain missed
3. **Context matters** - Captain's Agency knowledge informed hybrid model
4. **Synthesis > either alone** - Combined findings stronger than individual

### On Claude Code Extensibility

1. **Skills are discovery, not enforcement** - They guide, don't prevent
2. **Subagents are workers, not entities** - Ephemeral, no relationships
3. **Hooks are powerful** - Especially prompt-based Stop hook
4. **Full migration not needed** - Selective adoption works

### On The Agency

1. **AIADLC matters** - It's the framework, not just tooling
2. **Principal relationships matter** - Subagents can't have them
3. **Enforcement matters** - Ruthless tooling has value
4. **Hybrid is pragmatic** - Purity isn't the goal

---

## Next Steps

1. [ ] Implement Stop hook - test completion criteria
2. [ ] Create sample path-specific rules
3. [ ] Define code-reviewer subagent
4. [ ] Pilot `/commit` skill wrapping `./tools/commit`
5. [ ] Update KNOWLEDGE.md with hybrid model

---

## References

- Claude Code Docs: https://code.claude.com/docs
- Agent Skills Standard: https://agentskills.org
- Collaboration: `FROM-housekeeping-captain-COLLABORATE-0047-2026-01-21.md`
