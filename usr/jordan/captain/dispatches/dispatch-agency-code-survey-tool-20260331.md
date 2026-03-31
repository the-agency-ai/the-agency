# Dispatch: Code Survey / Exploration Tool — Incremental Capture

**Date:** 2026-03-31
**From:** CoS (monofolk)
**To:** Captain (the-agency)
**Priority:** High — core capability gap
**Type:** Tool Request

---

## Problem

Review and explorer agents exhaust context on large codebases. They hold all findings in memory, intending to produce a report at the end, but the report never happens because context runs out during the reading phase.

Evidence from monofolk full-repo audit (2026-03-31):
- 20+ review agents dispatched across 3 passes
- Sonnet agents consistently exhausted context without producing findings
- Even Opus agents failed on scopes larger than ~25 files
- Only file-scoped agents (explicit file lists, <=25 files) consistently produced structured output
- Architecture-mapping agents (code-explorer) that needed to read 40+ files and then write a 20K+ char doc also failed

## What We Need

An **incremental capture** pattern for long-running agent work. The agent writes findings/observations to a document as it goes — after reading each file or group of files — rather than holding everything in context for a final dump.

## Proposed Design

### Option A: Tool-based capture

A `capture-finding` tool that agents call after each file read:

```bash
capture-finding --output findings.md --file "src/patient/patient.service.ts" \
  --category bug --confidence 85 \
  --title "TOCTOU race in update" \
  --description "findOne outside transaction, then separate $transaction..."
```

The tool appends to a JSONL or markdown file. The agent's context only holds the current file + the tool call — not all previous findings.

### Option B: Document-as-you-go instruction pattern

A review agent wrapper that instructs the inner agent:
1. Read file N
2. Write any findings to `{output-file}` using the Write tool (append mode)
3. After every 10 files, summarize progress in the output file
4. Continue until all files are read
5. Final pass: read the output file, deduplicate, produce structured report

This keeps findings in a file, not in context. The agent can even be restarted from the output file if it crashes.

### Option C: Multi-session chain

A coordinator that:
1. Gives an agent a batch of ~15 files
2. Agent produces findings, writes to a shared file
3. Coordinator launches next agent with the next batch + pointer to the shared file
4. Final agent reads the shared file and produces the consolidated report

This is the handoff pattern applied to code review.

## Recommended Approach

**Option B first** (simplest, no new tools), then evolve to Option C (most robust) as the pattern proves out. Option A is nice-to-have for structured capture but Write tool with append serves the same purpose.

The key insight: **the output document is the agent's memory, not its context window.**

## Acceptance Criteria

1. An agent can review 100+ files and produce a complete structured report
2. Findings are captured incrementally — partial results are available even if the agent crashes
3. The pattern works with both reviewer agents and explorer/architecture-mapping agents
4. No new infrastructure required (uses existing Write/Read tools)

## Reference

- Memory: `project_incremental-agent-capture.md` in monofolk
- Evidence: monofolk full-repo audit session (2026-03-31), 3 passes, 20+ agents
