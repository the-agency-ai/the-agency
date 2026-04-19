---
type: seed
date: 2026-04-06
from: the-agency/jordan/captain
subject: "Flag triage workflow — structured flag review skill"
---

# Flag Triage Workflow Seed

## Origin

Captured during captain session 20 after manually triaging 62 legacy flags. The manual process worked but needs to be a repeatable skill.

## Flag Command Improvements

- `/flag` routes to current agent's queue by default
- Enhanced syntax: `/flag [agent_name]` to route to specific agent
- Works anywhere, anytime (like Claude's BTW feature — quick capture, zero friction)
- Must not pollute conversation context — silent capture, confirm only

## Flag Triage Skill (`/flag-triage`)

Structured flag review session. Agent pre-categorizes, human approves dispositions.

### Three Buckets

1. **Resolved** — agent identifies items that are already done. Reviews evidence. Human confirms.
2. **Autonomous** — agent takes ownership, no collaboration needed. Works separately. Human approves the assignment.
3. **Collaborative** — requires 1B1 discussion and joint work. Worked through together in the triage session.

### Process

1. Agent reads all unprocessed flags
2. Agent categorizes into three buckets with reasoning
3. Human reviews bucket assignments — approves, moves items between buckets
4. Bucket 1: mark resolved
5. Bucket 2: agent dispatches work to self or other agents (not just flags — actual dispatches, seeds, etc.)
6. Bucket 3: enter 1B1 mode, work through each item

### Key Constraints

- All bucket assignments require human approval before proceeding
- Bucket 2 items must be properly disposed (dispatches, seeds, PRs) — not just "flagged"
- Bucket 3 items use the standard 1B1 protocol with three dispositions: action now, flag to project, bin
- Flag triage opens a dedicated conversation mode (like /discuss)

## What We Learned From the Manual Triage

- 62 flags → 22 resolved, 16 autonomous, 18 collaborative (roughly 1/3 each)
- The collaborative items needed real decisions — routing, prioritization, "is this still relevant?"
- Autonomous items need proper disposal — writing seeds, sending dispatches, updating docs — not just mental tracking
- The legacy flag-queue.jsonl was principal-scoped, not agent-scoped — every agent saw all 62. ISCP flags are agent-scoped, which is correct.
- The triage itself took ~30 minutes for 18 collaborative items. Efficient.

## Implementation

This is an ISCP workstream item — flag tool + new skill. Needs:
- `/flag-triage` skill in `.claude/skills/flag-triage/SKILL.md`
- Possible flag tool enhancements (categorization metadata, batch operations)
- Integration with dispatch tool for Bucket 2 disposal
