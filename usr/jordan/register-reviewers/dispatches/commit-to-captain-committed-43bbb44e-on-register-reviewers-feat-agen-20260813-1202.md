---
type: commit
from: the-agency/jordan/register-reviewers
to: the-agency/jordan/captain
date: 2026-08-13T04:02
status: created
priority: normal
subject: "Committed 43bbb44e on register-reviewers: feat(agents): register the 5 quality-gate reviewer subagents + guard test (flag #186/#194)

The reviewer-* classes (reviewer-code/security/design/test/scorer) existed in
agency/agents/ but were NEVER registered under .claude/agents/, so every
/quality-gate invocation of subagent_type: reviewer-code (etc.) failed with
'Agent type not found' and the gate silently degraded to general-purpose agents
(hit live this session). Register all 5 (+ src mirrors), importing the class
agent.md via the correct @agency/ path. Scorer defaults to haiku (its
cost-optimized QG role); reviewers to sonnet.

Durable guard: new skill-validation test asserts every reviewer subagent_type
the quality-gate skill names has a registration under .claude/agents/ — this
rotted precisely because nothing checked it.

Note: existing agent registrations still carry broken @claude/ imports (flag
#246) — a riskier startup-behavior fix, deferred to its own PR."
in_reply_to: null
---

# Committed 43bbb44e on register-reviewers: feat(agents): register the 5 quality-gate reviewer subagents + guard test (flag #186/#194)

The reviewer-* classes (reviewer-code/security/design/test/scorer) existed in
agency/agents/ but were NEVER registered under .claude/agents/, so every
/quality-gate invocation of subagent_type: reviewer-code (etc.) failed with
'Agent type not found' and the gate silently degraded to general-purpose agents
(hit live this session). Register all 5 (+ src mirrors), importing the class
agent.md via the correct @agency/ path. Scorer defaults to haiku (its
cost-optimized QG role); reviewers to sonnet.

Durable guard: new skill-validation test asserts every reviewer subagent_type
the quality-gate skill names has a registration under .claude/agents/ — this
rotted precisely because nothing checked it.

Note: existing agent registrations still carry broken @claude/ imports (flag
#246) — a riskier startup-behavior fix, deferred to its own PR.

## Commit: 43bbb44e

**Branch:** register-reviewers
**Agent:** the-agency/jordan/register-reviewers
**Message:** housekeeping/captain: feat(agents): register the 5 quality-gate reviewer subagents + guard test (flag #186/#194)

The reviewer-* classes (reviewer-code/security/design/test/scorer) existed in
agency/agents/ but were NEVER registered under .claude/agents/, so every
/quality-gate invocation of subagent_type: reviewer-code (etc.) failed with
'Agent type not found' and the gate silently degraded to general-purpose agents
(hit live this session). Register all 5 (+ src mirrors), importing the class
agent.md via the correct @agency/ path. Scorer defaults to haiku (its
cost-optimized QG role); reviewers to sonnet.

Durable guard: new skill-validation test asserts every reviewer subagent_type
the quality-gate skill names has a registration under .claude/agents/ — this
rotted precisely because nothing checked it.

Note: existing agent registrations still carry broken @claude/ imports (flag
#246) — a riskier startup-behavior fix, deferred to its own PR.

### Metadata
- commit_hash: 43bbb44e
- branch: register-reviewers
- files_changed: 11
- stage: none
- stage_hash: none
- work_item: none

### Files Changed
```
.claude/agents/jordan/reviewer-code.md
.claude/agents/jordan/reviewer-design.md
.claude/agents/jordan/reviewer-scorer.md
.claude/agents/jordan/reviewer-security.md
.claude/agents/jordan/reviewer-test.md
src/claude/agents/jordan/reviewer-code.md
src/claude/agents/jordan/reviewer-design.md
src/claude/agents/jordan/reviewer-scorer.md
src/claude/agents/jordan/reviewer-security.md
src/claude/agents/jordan/reviewer-test.md
src/tests/skills/skill-validation.bats
```
