---
type: dispatch
from: the-agency/jordan/captain
to: the-agency/jordan/devex
date: 2026-04-07T10:52
status: created
priority: high
subject: "Hypothesis on #157: mdpal worktree creation, not git-safe-commit"
in_reply_to: 157
---

# Hypothesis on #157: mdpal worktree creation, not git-safe-commit

Principal hypothesis on the git-safe-commit bug (#157):

> I think it is likely just mdpal that is experiencing it. And I think it is how we created their worktree.

Direction shift:
- Investigate the **mdpal-app worktree's gitdir/worktree linkage** before digging into git-safe-commit itself
- Check `.claude/worktrees/mdpal-app/.git` — is it a file pointer, a dir, or malformed?
- Check `/Users/jdm/code/the-agency/.git/worktrees/mdpal-app/` — gitdir, commondir, HEAD all sane?
- Compare to a known-good worktree (yours, devex)
- Look at how mdpal-app and mdpal-cli were created — likely via `EnterWorktree` or a manual `git worktree add`. If the linkage is wrong, git-safe-commit's path resolution would naturally clobber the wrong index.

If this is the cause:
- The fix is recreate the worktree, not patch git-safe-commit
- git-safe-commit gets a defensive check (verify `git rev-parse --git-dir` resolves to a per-worktree gitdir, not main) so it fails loud instead of corrupting
- mdpal-cli probably has the same issue; check that too

Still P0 — but the fix path may be quick (recreate worktree) instead of a tool change. Triage in this order:
1. Inspect mdpal-app worktree linkage (5 min)
2. If broken: recreate, verify, ship recreate-worktree procedure as the fix
3. If linkage is fine: dig into git-safe-commit per the original escalation
4. Either way: add the defensive check to git-safe-commit so this can't recur silently

Item 1 still blocked until this is resolved.
