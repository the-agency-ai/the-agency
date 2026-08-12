---
type: commit
from: the-agency/jordan/devex-publish-path-repo-root
to: the-agency/jordan/captain
date: 2026-08-12T00:40
status: created
priority: normal
subject: "Committed ded0dd41 on devex-publish-path-repo-root: fix(git-sync): refuse on the default branch and merge instead of rebasing

git-sync violated two of the framework's sacred invariants and nothing stopped
it. It ran `git pull --rebase origin $BRANCH` — the rule is merge, never
rebase — and `git push -u origin $BRANCH` with no main/master guard at all —
the rule is that nothing reaches the default branch except through a PR.
Invoked on main it did both at once: rewrote main's history and pushed main
straight past the PR flow. That happened; the content was benign captain
coordination so it was recoverable. git-push sits in the same directory and has
blocked main since Day 40, so the tool contradicted the methodology and its own
neighbour simultaneously.

- Refuses on main/master, and on the default branch resolved via
  resolve-default-branch rather than hardcoded, so master-default repos are
  covered too. Both literals are ALSO checked unconditionally: the resolver
  falls back to "main" when it cannot reach origin, and a guard that softens
  when the network does is not a guard. The check sits before the pull, the
  push, AND the push-log append, so a refused run mutates nothing.
- Pull is now `--no-rebase`, explicitly rather than by relying on git's
  default — pull.rebase=true in a user's global config would otherwise quietly
  restore the rewrite.
- The push log recorded every agent as "unknown" because it read $AGENTNAME,
  which Claude Code does not set; an accountability log that accounts for nobody
  is decoration. Resolves via agent-identity, best-effort, and never blocks a
  push on failing to.

16 tests against a REAL local bare origin, not a mock — a refusal that holds
only because the network was absent proves nothing. Each refusal case asserts
both the block and that nothing moved: origin's main unchanged, local history
unchanged, no push-log row. The merge behaviour is proved behaviourally by
diverging two clones and asserting the pre-sync commit survives under its
ORIGINAL sha with a merge commit present. Mutation-checked: disabling the guard
fails 8 tests including the one that catches the real push to origin; restoring
--rebase fails 3 including the divergence test."
in_reply_to: null
---

# Committed ded0dd41 on devex-publish-path-repo-root: fix(git-sync): refuse on the default branch and merge instead of rebasing

git-sync violated two of the framework's sacred invariants and nothing stopped
it. It ran `git pull --rebase origin $BRANCH` — the rule is merge, never
rebase — and `git push -u origin $BRANCH` with no main/master guard at all —
the rule is that nothing reaches the default branch except through a PR.
Invoked on main it did both at once: rewrote main's history and pushed main
straight past the PR flow. That happened; the content was benign captain
coordination so it was recoverable. git-push sits in the same directory and has
blocked main since Day 40, so the tool contradicted the methodology and its own
neighbour simultaneously.

- Refuses on main/master, and on the default branch resolved via
  resolve-default-branch rather than hardcoded, so master-default repos are
  covered too. Both literals are ALSO checked unconditionally: the resolver
  falls back to "main" when it cannot reach origin, and a guard that softens
  when the network does is not a guard. The check sits before the pull, the
  push, AND the push-log append, so a refused run mutates nothing.
- Pull is now `--no-rebase`, explicitly rather than by relying on git's
  default — pull.rebase=true in a user's global config would otherwise quietly
  restore the rewrite.
- The push log recorded every agent as "unknown" because it read $AGENTNAME,
  which Claude Code does not set; an accountability log that accounts for nobody
  is decoration. Resolves via agent-identity, best-effort, and never blocks a
  push on failing to.

16 tests against a REAL local bare origin, not a mock — a refusal that holds
only because the network was absent proves nothing. Each refusal case asserts
both the block and that nothing moved: origin's main unchanged, local history
unchanged, no push-log row. The merge behaviour is proved behaviourally by
diverging two clones and asserting the pre-sync commit survives under its
ORIGINAL sha with a merge commit present. Mutation-checked: disabling the guard
fails 8 tests including the one that catches the real push to origin; restoring
--rebase fails 3 including the divergence test.

## Commit: ded0dd41

**Branch:** devex-publish-path-repo-root
**Agent:** the-agency/jordan/devex-publish-path-repo-root
**Message:** housekeeping/captain: fix(git-sync): refuse on the default branch and merge instead of rebasing

git-sync violated two of the framework's sacred invariants and nothing stopped
it. It ran `git pull --rebase origin $BRANCH` — the rule is merge, never
rebase — and `git push -u origin $BRANCH` with no main/master guard at all —
the rule is that nothing reaches the default branch except through a PR.
Invoked on main it did both at once: rewrote main's history and pushed main
straight past the PR flow. That happened; the content was benign captain
coordination so it was recoverable. git-push sits in the same directory and has
blocked main since Day 40, so the tool contradicted the methodology and its own
neighbour simultaneously.

- Refuses on main/master, and on the default branch resolved via
  resolve-default-branch rather than hardcoded, so master-default repos are
  covered too. Both literals are ALSO checked unconditionally: the resolver
  falls back to "main" when it cannot reach origin, and a guard that softens
  when the network does is not a guard. The check sits before the pull, the
  push, AND the push-log append, so a refused run mutates nothing.
- Pull is now `--no-rebase`, explicitly rather than by relying on git's
  default — pull.rebase=true in a user's global config would otherwise quietly
  restore the rewrite.
- The push log recorded every agent as "unknown" because it read $AGENTNAME,
  which Claude Code does not set; an accountability log that accounts for nobody
  is decoration. Resolves via agent-identity, best-effort, and never blocks a
  push on failing to.

16 tests against a REAL local bare origin, not a mock — a refusal that holds
only because the network was absent proves nothing. Each refusal case asserts
both the block and that nothing moved: origin's main unchanged, local history
unchanged, no push-log row. The merge behaviour is proved behaviourally by
diverging two clones and asserting the pre-sync commit survives under its
ORIGINAL sha with a merge commit present. Mutation-checked: disabling the guard
fails 8 tests including the one that catches the real push to origin; restoring
--rebase fails 3 including the divergence test.

### Metadata
- commit_hash: ded0dd41
- branch: devex-publish-path-repo-root
- files_changed: 4
- stage: none
- stage_hash: none
- work_item: none

### Files Changed
```
agency/tools/git-sync
src/agency/tools/git-sync
src/tests/tools/git-sync-guard.bats
usr/jordan/devex-publish-path-repo-root/dispatches/dispatch-to-captain-ready-for-pr-landing-devex-publish-path-repo-root--20260811-1705.md
```
