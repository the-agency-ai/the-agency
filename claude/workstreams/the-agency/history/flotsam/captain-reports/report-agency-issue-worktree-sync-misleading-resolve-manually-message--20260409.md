---
report_type: agency-issue
issue_type: bug
filing_agent: the-agency/jordan/captain
filed_by: jordan
date_filed: 2026-04-09
target_repo: the-agency-ai/the-agency
github_issue: https://github.com/the-agency-ai/the-agency/issues/57
github_issue_number: 57
status: open
---

# worktree-sync: misleading 'resolve manually' message after successful conflict-abort

**Filed:** 2026-04-09T00:49:59Z
**Target:** [the-agency-ai/the-agency](https://github.com/the-agency-ai/the-agency)
**Issue:** [#57](https://github.com/the-agency-ai/the-agency/issues/57)
**Type:** bug
**Status:** open

## Filed Body

**Type:** bug

**Type:** bug

## Problem

When `worktree-sync --auto` hits a merge conflict with master, it internally runs `git merge --abort` (successfully) and pops any stash it took. The tool then exits non-zero with the message:

```
worktree-sync: merge conflict with master. Resolve manually.
```

But the repo is NOT in a conflicted state at this point — the merge was already aborted. MERGE_HEAD is gone. The user sees a dirty working tree (from the stash pop) and tries to run `git merge --abort` manually, which fails with 'no merge to abort'.

This caused a devex agent to get stuck in dispatch #171. They reported:
- 'file staged as new file'
- 'no MERGE_HEAD so git merge --abort fails with no merge to abort'
- blocked because /session-resume relies on worktree-sync and has no documented recovery path

## Impact

1. **Confusing error message** — says 'resolve manually' when the merge was already aborted; user doesn't know what to resolve.
2. **/session-resume fragility** — the skill's Step 1 calls worktree-sync; when it exits non-zero, the skill has no documented recovery path and the entire session-resume ritual blocks.
3. **Devex-class blocker** — when a worktree agent can't complete session-resume, their entire queue blocks on a friendly mid-session bug.

## Expected

After a conflict-then-abort, the tool should print something like:

```
worktree-sync: merge with master had conflicts — the merge was automatically aborted.
  Repo state: restored to pre-merge HEAD (SHA).
  Conflict files: .claude/logs/tool-runs.jsonl
  Stash: popped (or: still in stash@{0}).
  
  Next steps:
    1. Review the conflict files — decide whether they should be deleted, kept, or reconciled.
    2. If deleted on master (common for gitignored files), run: git rm <file>
    3. Retry worktree-sync after cleanup.
```

And `/session-resume` should catch worktree-sync failure, print the diagnostic, and continue with handoff read + dispatch check even if sync failed.

## Fix scope (this issue)

This issue covers ONLY the misleading worktree-sync message. The /session-resume recovery path is tracked separately.

## Related

- Dispatch #171 (devex blocker that surfaced this)
- Dispatch #109 (original Test User pollution — separately fixed on main today as Gate 0)

## Response Log

_(append responses, comments, and state changes here as they occur)_

- **2026-04-09:** Filed via `agency-issue file`. Issue created at https://github.com/the-agency-ai/the-agency/issues/57
