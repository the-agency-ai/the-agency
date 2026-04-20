---
type: seed
date: 2026-04-05
source: captain session 19 — Jordan + captain discussion
subject: Context Manager — session resilience through persistent, queryable context
---

# Seed: Context Manager

## The Problem

Claude Code's context management is brittle. When context compacts or a session crashes, the agent loses state. The current mitigation — compaction summaries — failed catastrophically in session 19: the summary described Phase 3 skill porting as incomplete when it was done days ago. The agent bootstrapped from wrong information and gave the principal incorrect status.

The root cause: context lives in the conversation. When the conversation compresses, context is destroyed or distorted. No external persistence, no verification, no recovery path.

## The Idea

A **Context Manager** that persists agent state outside the conversation in a queryable database (ISCP's SQLite). On session start, crash recovery, or post-compaction, the agent bootstraps from the DB — not from compressed conversation history.

Three layers of persistent context:

### Layer 1: Handoff (JSON)

What we have today, but structured as JSON for token efficiency. Agent-written summary of state: current work, git state, what's next, blockers. Written continuously (at boundaries, on PreCompact, on SessionEnd).

### Layer 2: Session Transcript Extract (JSON, mined from JSONL)

Tool reads the raw `.claude/projects/` JSONL session file. Extracts for a defined activity window (time-based, event-based, or session-based). Pulls out: tool calls made, files changed, errors hit, decisions implied by actions. Objective record — what *actually happened*, not what the agent *thinks* happened.

This is what caught the bad compaction summary in session 19 — we manually mined the JSONL and found the real state.

### Layer 3: Conversation Transcript (stored in DB)

The `/transcript` skill output. Principal said → Agent replied → iterate → summary → continue. Captures the *why* — decisions, reasoning, context that doesn't exist in git or tool logs.

## The Query Model

All three layers go into the DB. On session start, the agent queries for what it needs based on context:

| Scenario | Query |
|----------|-------|
| Cold start, new task | Heavy pull — full transcript, all recent decisions |
| Resume after crash | Session extract to verify state, handoff for orientation |
| Quick follow-up | Light pull — just the handoff JSON |
| Post-compaction | Session extract + transcript — rebuild what was lost |

**Token-aware loading:** The agent knows its context budget. The query can be "give me the most important N tokens of context" instead of dumping a fixed-format file.

## What This Replaces

| Today | With Context Manager |
|-------|---------------------|
| Markdown handoff files | JSON in DB, queryable |
| Compaction summary (unreliable) | DB query for real state |
| Manual transcript mining on crash | Automated session extract |
| Fixed handoff format (too verbose or too sparse) | Dynamic context loading based on need |
| SessionStart reads files from disk | SessionStart queries DB |

## Relationship to ISCP

ISCP provides the storage layer (SQLite DB outside repo). The Context Manager is the intelligence layer on top — it decides what gets written when, and what gets queried on bootstrap. ISCP stores flags, dispatches, handoffs, session extracts, and transcripts. The Context Manager queries across all of them to answer: "what do I need to know right now?"

## Open Questions

1. Activity window definition — time-based, event-based, session-based, or adaptive?
2. Session extract granularity — every tool call, or summarized by activity type?
3. Token budget allocation — how much context window to spend on bootstrap vs leaving room for work?
4. Write triggers — continuous (after every exchange), at boundaries, or on-demand?
5. Compaction interaction — can the Context Manager feed Claude's compaction with better source material?
6. Cross-agent context — can one agent's Context Manager read another agent's state from the DB?

## Next Step

`/define` this as a proper PVR. May be part of ISCP or may be its own workstream — scope TBD.
