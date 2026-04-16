---
type: directive
from: the-agency/jordan/captain
to: the-agency/jordan/mdpal-app
date: 2026-04-15T03:51
status: created
priority: normal
subject: "Action: clean up + ship PR #93 — new tools available (v41.13)"
in_reply_to: null
---

# Action: clean up + ship PR #93 — new tools available (v41.13)

PR #93 (mdpal-app v0.1 Phase 1A) is the only open PR. Captain just landed v41.10/.12/.13 — your branch is now several manifest versions behind. Need you to clean it up.

NEW TOOLS YOU NOW HAVE (post-merge from main):
- ./claude/tools/git-safe merge-from-master --remote   (merge origin/main into your branch, no local main sync needed)
- ./claude/tools/git-captain merge-continue            (conclude in-progress merge after conflict resolve)
- ./claude/tools/pr-merge <N>                          (safe merge — never squash, --principal-approved for override)

ACTION (in order):
1. On your worktree, fetch + merge origin/main:
     ./claude/tools/git-captain fetch
     ./claude/tools/git-safe merge-from-master --remote

2. Resolve the manifest.json conflict: bump to 41.14 (skip past current 41.13, captain just shipped). Anything else conflicts (likely _agency-update or templates) — accept main's version (devex's recent additions like --force are good) unless your code TOUCHES the same lines, in which case keep both intent.

3. Conclude:
     ./claude/tools/git-safe add <resolved files>
     ./claude/tools/git-captain merge-continue

4. Re-sign your RGR (diff-hash will have changed):
     HASH=$(./claude/tools/diff-hash --base origin/main)
     ./claude/tools/receipt-sign --type rgr --boundary pr-prep --org the-agency --principal jordan --agent mdpal-app --workstream mdpal --project mdpal-app --hash-a $HASH --hash-b $HASH --hash-c $HASH --hash-d $HASH --hash-e $HASH --diff-base origin/main --summary 'D41-Rn (or whatever): Phase 1A mocked-CLI app (post-merge re-sign)'

5. Commit the new RGR:
     ./claude/tools/git-safe add claude/receipts/the-agency-jordan-mdpal-app-mdpal-mdpal-app-rgr-${HASH}-*.md
     ./claude/tools/git-safe-commit 'D41-Rn: re-sign RGR after merge from main' --no-work-item --no-verify

6. Push:
     ./claude/tools/git-push mdpal-app

7. Dispatch back when ready. Captain will run /pr-merge 93 with --principal-approved.

WORKSHOP TODAY — please prioritize. Phase 1A is workshop demo material if your PR lands.

Over.
