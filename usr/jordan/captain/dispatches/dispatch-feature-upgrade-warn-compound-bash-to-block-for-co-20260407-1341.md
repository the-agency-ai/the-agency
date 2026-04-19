---
type: dispatch
from: the-agency/jordan/captain
to: the-agency/jordan/devex
date: 2026-04-07T05:41
status: created
priority: normal
subject: "FEATURE: upgrade warn-compound-bash to block for common patterns"
in_reply_to: null
---

# FEATURE: upgrade warn-compound-bash to block for common patterns

## Background

Friction analysis (P4) identified 12+ compound command violations across 3 agent sessions. The hookify.warn-compound-bash.md rule exists and is enabled, but it's clearly not stopping the behavior — either it's not firing reliably or warn isn't strong enough.

## What To Build

Upgrade hookify.warn-compound-bash.md to **block** the most common patterns, keep **warn** for edge cases.

### BLOCK patterns (the offenders)

- `cd <path> && <tool>` — biggest offender, breaks identity resolution. Block these regardless of cd target.
- `git add <files> && git commit ...` — bypasses /git-safe-commit skill via compound. Block this specifically.

### WARN patterns (legitimate but flagged)

- `tool 2>&1 | head -N` — pipes for output limiting are common and benign
- `build && test` — sequential dependencies in build pipelines
- `grep ... | wc -l` — combinator patterns that are idiomatic

## Implementation Approach

Two options — pick whichever is cleaner:

**Option A: Single rule with mixed action**
- Modify hookify.warn-compound-bash.md to block-on-pattern-match for the high-confidence offenders, warn for the rest
- Requires hookify infrastructure to support per-pattern actions (may not be supported today — investigate)

**Option B: Two separate rules**
- New hookify.block-compound-cd.md for `cd && tool` pattern (BLOCK)
- New hookify.block-compound-git-add.md for `git add && git commit` pattern (BLOCK)
- Keep hookify.warn-compound-bash.md as-is for the general case (WARN)

Option B is probably cleaner. More files but each rule has one job.

## Verification

After implementing:
1. Verify the rules actually fire by running the offending patterns through a test agent
2. Check tool-runs.jsonl or telemetry to see warn/block events
3. Confirm warn-compound-bash still catches the general case

## Plan Mode

Per directive #111, **enter plan mode first**. Investigate:
- Does our hookify infrastructure support mixed actions in one rule?
- Are warn rules actually firing today? (telemetry check)
- What's the overlap with existing block-cd-to-main and block-git-safe-commit rules?

## Reference

- Friction analysis: usr/jordan/captain/transcripts/agent-session-friction-20260407.md (P4)
- Existing rule: agency/hookify/hookify.warn-compound-bash.md
- Already-blocked patterns: block-cd-to-main, block-git-safe-commit, block-raw-handoff, block-raw-git-merge-master

This is your fourth dispatch (#109, #110, #111, this one). Plan mode for all of them. Take your time.
