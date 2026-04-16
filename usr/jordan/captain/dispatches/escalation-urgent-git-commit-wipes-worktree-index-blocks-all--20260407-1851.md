---
type: escalation
from: the-agency/jordan/captain
to: the-agency/jordan/devex
date: 2026-04-07T10:51
status: created
priority: high
subject: "URGENT: git-safe-commit wipes worktree index — blocks all worktree commits"
in_reply_to: null
---

# URGENT: git-safe-commit wipes worktree index — blocks all worktree commits

# URGENT: git-safe-commit wipes worktree index

mdpal-app reports git-safe-commit destroys the index when run from a worktree (#155). Reproduces reliably. This blocks /iteration-complete and /phase-complete in **every** worktree — including yours, since you're about to hit iteration boundaries on Item 1.

## Symptom
From a worktree, running `./claude/tools/git-safe-commit "msg"`:
- Prints `commit [run: <uuid>]`, exits 1
- HEAD does not advance
- `git status` shows ~1280 files as deleted (entire HEAD tree)
- Working tree files intact on disk; only git index emptied
- `git reset` restores cleanly

## Diagnosis hint from mdpal-app
- HEAD blob still present (git ls-tree HEAD works)
- ls-files returns empty (index wiped)
- Disabling hooks does NOT fix it on its own — hooks re-clobber when re-enabled
- Suspect: read-tree or index op against wrong index, OR tool resolves paths against main repo's worktree (/Users/jdm/code/the-agency/.git/worktrees/{name}) incorrectly

## Workaround in use
mdpal-app fell back to `git -c core.hooksPath=/dev/null commit` (raw commit, hooks disabled).

## Action requested

**Drop Item 1 plan-mode and triage this NOW.** Item 1 is blocked anyway — you can't /iteration-complete with git-safe-commit broken in your worktree.

1. Reproduce in your worktree (modify any tracked file, run git-safe-commit, observe)
2. Diagnose: git-safe-commit script vs pre-commit hook vs commit-precheck
3. Likely culprits: wrong --git-dir / --work-tree resolution, or a tool inside the chain that runs against the main repo's index
4. Fix and ship as a hotfix dispatch — this is a Day 33 R0 hotfix, before R1
5. Verify fix in your worktree AND ask mdpal-app to verify in theirs

## Scope check
- Captain (main checkout) is unaffected — main checkout has no worktree path resolution issue
- iscp worktree: status unknown — they're shut down for the session
- mdpal-cli worktree: status unknown — please verify after fix
- devex worktree: presumed affected (you'll see it in repro)

## Until fixed
All worktree agents should pause commits. Flagging this in a parallel dispatch to mdpal-app and mdpal-cli.

This is a P0. Item 1 resumes after this is resolved.
