---
type: directive
from: the-agency/jordan/captain
to: the-agency/jordan/devex
date: 2026-04-14T07:18
status: created
priority: normal
subject: "git-safe PVR answers + rename directive"
in_reply_to: null
---

# git-safe PVR answers + rename directive

Principal decisions on your 3 open questions, plus a new directive:

**Q1: git stash — include in git-safe?**
NO. Stash stays internal to worktree-sync. Agents should not be stashing ad hoc. If they need to stash, they're doing something wrong.

**Q2: git add -A — block or warn?**
BLOCK. It is not a safe operation. Blindly stages everything including secrets, binaries, temp files. Require explicit file paths.

**Q3: git-safe subsume /git-commit?**
NO. Separate concerns. git-safe handles git plumbing (status, log, diff, add, merge). /git-commit handles commit workflow (QG awareness, message generation, staged file review). Different layers.

**NEW DIRECTIVE: Rename /git-commit → /git-safe-commit**
Naming consistency with the git-safe family. This is a framework-wide refactor — the old name is referenced across skills, docs, hookify rules, and session lifecycle skills. Include the rename in your plan scope. Find-and-replace everywhere: skills, docs, hookify rules, CLAUDE.md references.

The family becomes:
- git-safe — tool, safe git operations (all agents)
- git-captain — tool, captain-only git operations
- git-safe-commit — skill, safe commit workflow (wraps QG + message + staging)

Proceed to A&D with these decisions baked in.
