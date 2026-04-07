---
type: dispatch
from: the-agency/jordan/captain
to: the-agency/jordan/devex
date: 2026-04-07T05:35
status: created
priority: normal
subject: "FEATURE: cd-stays-in-worktree hookify rule"
in_reply_to: null
---

# FEATURE: cd-stays-in-worktree hookify rule

## Background

Flag #8 (worktree awareness check) is your area. We have block-cd-to-main covering one specific case (cd to /Users/.../the-agency). What we need is a more general rule: detect any cd that takes the agent outside its current worktree.

## What To Build

Two layers of protection:

### Layer 1: SessionStart hook check

Small bash script (or addition to an existing hook) that runs at SessionStart and verifies the current CWD matches the worktree root for the current branch. If not, warn:

> You launched in /path/X but the current branch is /worktree/Y. You should cd to /worktree/Y or the agent will write to the wrong place.

### Layer 2: PreToolUse hookify rule (the main one)

Hookify rule `hookify.cd-stays-in-worktree.md` that fires on Bash commands matching `cd `. It should:

1. Compute the agent's worktree root once: `git rev-parse --show-toplevel`
2. Parse the cd target from the command (handle `cd path`, `cd /abs/path`, `cd ~/foo`, `cd ..`, `cd subdir`)
3. Resolve the target to an absolute path
4. Check if the resolved path starts with the worktree root
5. If yes: allow
6. If no: BLOCK with message

Example block message:
> Blocked: 'cd /tmp/foo' would take you outside your worktree (/Users/jdm/code/the-agency/.claude/worktrees/iscp).
> Worktree agents must stay in their worktree. Use absolute paths to read files outside, or work from the worktree root.
> *OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*

## Edge Cases To Handle

- `cd` with no args → goes to $HOME → BLOCK
- `cd -` → goes to previous dir → check the previous dir if known
- `cd $VAR/path` → resolve the variable, then check
- `cd ../sibling` → resolve relative to current, check containment
- `cd "$(pwd)"` → no-op, allow
- `cd "$BATS_TEST_TMPDIR"` → tests need to cd to tmpdirs, but tests run in BATS not as agent Bash calls — should be fine

## Decision

**Block** (not warn). There are very few legitimate reasons for a worktree agent to cd outside its worktree. Reading files outside is fine via absolute paths to Read tool — that doesn't change the shell CWD.

The block-cd-to-main rule stays as a specific rule for the most common violation (cd to main repo). The new rule is the general-case protection.

## Reference

- Existing rule for inspiration: claude/hookify/hookify.block-cd-to-main.md
- Friction analysis context: usr/jordan/captain/transcripts/agent-session-friction-20260407.md (P1 was the cd-to-main habit)
- Flag #8 origin: ISCP agent self-corrected after wasting tool calls — proactive check would have caught it before the first command

Pick it up with the test isolation work (#109) when you have bandwidth.
