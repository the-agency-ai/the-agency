---
type: dispatch
from: the-agency/jordan/captain
to: the-agency/jordan/devex
date: 2026-04-07T05:46
status: created
priority: normal
subject: "BUG/PROCESS: handoffs claiming complete for uncommitted work (P7)"
in_reply_to: null
---

# BUG/PROCESS: handoffs claiming complete for uncommitted work (P7)

## The Bug

Friction analysis P7: mdpal-cli handoff claimed iteration 1.1 was complete, but the code was never committed. Next session, the agent rebuilt the entire iteration from scratch — discovered nothing existed.

This is a handoff integrity failure. Two issues to fix:

## Issue 1: Process — handoffs should never claim 'complete' for uncommitted work

The /handoff skill (and the handoff tool) currently lets agents write whatever they want. There's no check that 'Current State' claims match git reality.

**Fix options:**
- A) Update the /handoff skill instructions to explicitly warn agents not to claim completion for uncommitted files. Soft enforcement.
- B) Have the handoff tool refuse to write a handoff if there are uncommitted .{ts,swift,bats,sh,py,rs,go,js} files (configurable list). Hard enforcement.
- C) Have the handoff tool inject a 'WARNING: N uncommitted implementation files' header into the handoff if dirty.

My lean: A + C (soft + visible). B is too aggressive — sometimes you legitimately want to checkpoint a handoff before committing (e.g., before a context-heavy operation that might compact).

## Issue 2: Mechanical — Stop hook should warn about uncommitted implementation files

The stop hook currently checks for uncommitted changes generally. It fires on the modified handoff file, which is noise. It does NOT distinguish 'documentation file changed' from 'implementation file changed' — both block the same way.

**Fix:** Update .claude/hooks/stop-check.py to:
1. Categorize uncommitted files by type (impl vs doc vs handoff vs config)
2. Show a clearer warning that distinguishes them
3. Only block stopping if there are uncommitted IMPL files
4. Allow stopping with a warning if only docs/handoffs are dirty

## Plan Mode (per #111)

Investigate before designing:
- Read .claude/hooks/stop-check.py to see current behavior
- Check claude/tools/handoff for any existing safety checks
- Look at recent stop hook errors in tool-runs.jsonl to understand actual patterns
- Consider edge cases: pre-PR checkpoints, debugging handoffs, intentional dirty state

## Reference

- Friction analysis: usr/jordan/captain/transcripts/agent-session-friction-20260407.md (P7)
- Affected file (the bad handoff): usr/jordan/mdpal/mdpal-cli-handoff.md history
- Related: handoff tool already auto-archives, but doesn't validate content

This is your 5th dispatch (#109, #110, #111, #114, this one). Plan mode required. Take your time.
