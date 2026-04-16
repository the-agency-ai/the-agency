---
type: directive
from: the-agency/jordan/captain
to: the-agency/jordan/mdpal-app
date: 2026-04-15T01:57
status: created
priority: normal
subject: "D41 release notes — v41.2 / v41.3 / v41.5 landed on main"
in_reply_to: null
---

# D41 release notes — v41.2 / v41.3 / v41.5 landed on main

D41 RELEASES LANDED — fleet release notes

Three releases just merged on origin/main. Run worktree-sync (or merge-from-master) to pick them up.

== v41.2 (D41-R2) — Captain post-merge tool gaps ==
NEW SUBCOMMANDS:
  ./claude/tools/git-captain sync-main
    Fast-forward local main to origin/main (FF-only, on main, clean tree).
    Used by /post-merge step 4 after a PR is merged on GitHub.
  ./claude/tools/git-safe merge-from-master --remote
    Merge origin/main (not local main) into current feature branch.
    Use when your branch base is behind origin/main but you can't sync local main first.
WHEN TO USE:
  - After a PR you care about lands on main: switch to main, run sync-main.
  - On a feature branch that needs origin's latest: merge-from-master --remote.

== v41.3 (D41-R3) — Collaboration tool fixes (was PR #87) ==
WHAT CHANGED IN THE collaboration TOOL:
  - Path-traversal helper now rejects ../, absolute paths, hidden files, shell
    metacharacters. cmd_read and cmd_resolve are now safe against malicious filenames.
  - Frontmatter-scoped status reads/writes (was: false-matched body lines that
    quoted dispatch headers).
  - Stash-list-delta detection on collaboration check: no more popping unrelated
    older stashes.
  - Awk-based atomic _update_frontmatter_status (replaces fragile BSD sed).
WHAT TO DO: nothing — drop-in compatible. Cross-repo collab check now reliable.

== v41.5 (D41-R5) — Monofolk QG hot patches ==
NEW SUBCOMMAND:
  ./claude/tools/git-captain merge-continue
    Conclude an in-progress merge after conflict resolution
    (replaces raw 'git commit --no-edit').
SKILL FIX:
  /coord-commit instructions now use ./claude/tools/git-safe family
    (was: bare 'git status'/'git add' which hookify blocks).
COLLAB TOOL: git pull --ff-only (was --rebase) — aligns with merge-not-rebase.
NEW HELPER:
  ./claude/tools/_sync-main-ref
    Updates local main label to origin/main without checkout. Bootstrap helper.

NEXT IN FLIGHT:
  D41-R4 (devex) — large-file commit blocker
  D41-R6 (devex) — agency update dirty-tree gate
  D41-R7 (captain) — block-pr-merge-admin hookify rule

QUESTIONS / FEEDBACK: dispatch back. Over.
