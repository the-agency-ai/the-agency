---
type: commit
from: the-agency/jordan/devex-publish-path-repo-root
to: the-agency/jordan/captain
date: 2026-08-12T00:57
status: created
priority: normal
subject: "Committed a16b9043 on devex-publish-path-repo-root: fix(git-sync): QG findings — detached HEAD, swallowed conflicts, self-corrupting log

The gate mutation-tested the guard I had just written and found the clause the
commit message argued hardest for was not covered at all: deleting the
resolved-default-branch test left 16/16 green, because every case reached the
block through the two hardcoded literals instead. Three tests also passed for
reasons other than the ones their comments claimed.

Tool:
- Detached HEAD was unguarded. `git branch --show-current` prints nothing, which
  matched no clause, so the tool ran `git push -u origin ""` — fatal, so origin
  was never at risk, but only after appending a push-log row with an empty
  branch column and reporting "push failed" instead of "you are not on a
  branch". Now refused by name.
- A conflicted pull was treated as identical to "no remote branch yet": the
  merge was left half-done with conflict markers in the tree, the push was
  attempted anyway, and the output never mentioned the conflict. Now
  distinguished — the run stops, the merge is left in place deliberately, and
  the message says how to resolve or abort.
- Every push-log row after the first sync was split across two lines.
  `grep -c ... || echo "0"` appended a second zero on top of grep's own, since
  grep -c prints 0 AND exits 1 when nothing matches. The log this change exists
  to make usable was corrupting itself on every run. Now `|| true`.
- The guard now reports through output_failure like every other failure path,
  instead of speaking only on stderr where callers grepping stdout could not
  see it, and it runs before the uncommitted-changes check so `--check` on a
  dirty main answers BLOCKED rather than "uncommitted changes".

Tests (16 → 23):
- Added a genuinely trunk-default repo, so the resolver clause is exercised at
  all; and a trunk-default repo carrying a stale local master, which is the only
  case that makes the two literals load-bearing. Both clauses are now
  independently mutation-verified: remove either one and exactly one test fails.
- "master-default repo" only renamed the LOCAL branch, leaving origin on main,
  so it tested the literal it claimed to be testing the alternative to. Rebuilt
  via a helper that makes origin/HEAD agree.
- "remote unreachable" did not make resolution fail — resolve-default-branch
  reads refs/remotes/origin/main, which is local data.
- The merge test could not fail: GIT_CONFIG_GLOBAL is nulled so git already
  defaults to merge. Sets pull.rebase=true, the config --no-rebase exists to
  defeat.
- "identity never blocks the push" never reached the failure path (the tool is
  invoked by absolute path, so PATH changes nothing). Shadows agent-identity
  with a failing stub and asserts both the successful push and the degraded row.
- The 'not unknown' assertion passed vacuously when grep matched nothing — which
  the split rows made likely. Asserts positively now, plus a row-integrity test.
- Added detached-HEAD, merge-conflict, and src/-parity tests. The parity test
  caught its own un-mirrored copy on first run."
in_reply_to: null
---

# Committed a16b9043 on devex-publish-path-repo-root: fix(git-sync): QG findings — detached HEAD, swallowed conflicts, self-corrupting log

The gate mutation-tested the guard I had just written and found the clause the
commit message argued hardest for was not covered at all: deleting the
resolved-default-branch test left 16/16 green, because every case reached the
block through the two hardcoded literals instead. Three tests also passed for
reasons other than the ones their comments claimed.

Tool:
- Detached HEAD was unguarded. `git branch --show-current` prints nothing, which
  matched no clause, so the tool ran `git push -u origin ""` — fatal, so origin
  was never at risk, but only after appending a push-log row with an empty
  branch column and reporting "push failed" instead of "you are not on a
  branch". Now refused by name.
- A conflicted pull was treated as identical to "no remote branch yet": the
  merge was left half-done with conflict markers in the tree, the push was
  attempted anyway, and the output never mentioned the conflict. Now
  distinguished — the run stops, the merge is left in place deliberately, and
  the message says how to resolve or abort.
- Every push-log row after the first sync was split across two lines.
  `grep -c ... || echo "0"` appended a second zero on top of grep's own, since
  grep -c prints 0 AND exits 1 when nothing matches. The log this change exists
  to make usable was corrupting itself on every run. Now `|| true`.
- The guard now reports through output_failure like every other failure path,
  instead of speaking only on stderr where callers grepping stdout could not
  see it, and it runs before the uncommitted-changes check so `--check` on a
  dirty main answers BLOCKED rather than "uncommitted changes".

Tests (16 → 23):
- Added a genuinely trunk-default repo, so the resolver clause is exercised at
  all; and a trunk-default repo carrying a stale local master, which is the only
  case that makes the two literals load-bearing. Both clauses are now
  independently mutation-verified: remove either one and exactly one test fails.
- "master-default repo" only renamed the LOCAL branch, leaving origin on main,
  so it tested the literal it claimed to be testing the alternative to. Rebuilt
  via a helper that makes origin/HEAD agree.
- "remote unreachable" did not make resolution fail — resolve-default-branch
  reads refs/remotes/origin/main, which is local data.
- The merge test could not fail: GIT_CONFIG_GLOBAL is nulled so git already
  defaults to merge. Sets pull.rebase=true, the config --no-rebase exists to
  defeat.
- "identity never blocks the push" never reached the failure path (the tool is
  invoked by absolute path, so PATH changes nothing). Shadows agent-identity
  with a failing stub and asserts both the successful push and the degraded row.
- The 'not unknown' assertion passed vacuously when grep matched nothing — which
  the split rows made likely. Asserts positively now, plus a row-integrity test.
- Added detached-HEAD, merge-conflict, and src/-parity tests. The parity test
  caught its own un-mirrored copy on first run.

## Commit: a16b9043

**Branch:** devex-publish-path-repo-root
**Agent:** the-agency/jordan/devex-publish-path-repo-root
**Message:** housekeeping/captain: fix(git-sync): QG findings — detached HEAD, swallowed conflicts, self-corrupting log

The gate mutation-tested the guard I had just written and found the clause the
commit message argued hardest for was not covered at all: deleting the
resolved-default-branch test left 16/16 green, because every case reached the
block through the two hardcoded literals instead. Three tests also passed for
reasons other than the ones their comments claimed.

Tool:
- Detached HEAD was unguarded. `git branch --show-current` prints nothing, which
  matched no clause, so the tool ran `git push -u origin ""` — fatal, so origin
  was never at risk, but only after appending a push-log row with an empty
  branch column and reporting "push failed" instead of "you are not on a
  branch". Now refused by name.
- A conflicted pull was treated as identical to "no remote branch yet": the
  merge was left half-done with conflict markers in the tree, the push was
  attempted anyway, and the output never mentioned the conflict. Now
  distinguished — the run stops, the merge is left in place deliberately, and
  the message says how to resolve or abort.
- Every push-log row after the first sync was split across two lines.
  `grep -c ... || echo "0"` appended a second zero on top of grep's own, since
  grep -c prints 0 AND exits 1 when nothing matches. The log this change exists
  to make usable was corrupting itself on every run. Now `|| true`.
- The guard now reports through output_failure like every other failure path,
  instead of speaking only on stderr where callers grepping stdout could not
  see it, and it runs before the uncommitted-changes check so `--check` on a
  dirty main answers BLOCKED rather than "uncommitted changes".

Tests (16 → 23):
- Added a genuinely trunk-default repo, so the resolver clause is exercised at
  all; and a trunk-default repo carrying a stale local master, which is the only
  case that makes the two literals load-bearing. Both clauses are now
  independently mutation-verified: remove either one and exactly one test fails.
- "master-default repo" only renamed the LOCAL branch, leaving origin on main,
  so it tested the literal it claimed to be testing the alternative to. Rebuilt
  via a helper that makes origin/HEAD agree.
- "remote unreachable" did not make resolution fail — resolve-default-branch
  reads refs/remotes/origin/main, which is local data.
- The merge test could not fail: GIT_CONFIG_GLOBAL is nulled so git already
  defaults to merge. Sets pull.rebase=true, the config --no-rebase exists to
  defeat.
- "identity never blocks the push" never reached the failure path (the tool is
  invoked by absolute path, so PATH changes nothing). Shadows agent-identity
  with a failing stub and asserts both the successful push and the degraded row.
- The 'not unknown' assertion passed vacuously when grep matched nothing — which
  the split rows made likely. Asserts positively now, plus a row-integrity test.
- Added detached-HEAD, merge-conflict, and src/-parity tests. The parity test
  caught its own un-mirrored copy on first run.

### Metadata
- commit_hash: a16b9043
- branch: devex-publish-path-repo-root
- files_changed: 5
- stage: none
- stage_hash: none
- work_item: none

### Files Changed
```
agency/tools/git-sync
history/push-log.md
src/agency/tools/git-sync
src/tests/tools/git-sync-guard.bats
usr/jordan/devex-publish-path-repo-root/dispatches/commit-to-captain-committed-ded0dd41-on-devex-publish-path-repo-root-20260812-0840.md
```
