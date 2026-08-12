---
type: commit
from: the-agency/jordan/devex-publish-path-repo-root
to: the-agency/jordan/captain
date: 2026-08-11T08:42
status: created
priority: normal
subject: "Committed 8a533701 on devex-publish-path-repo-root: fix(publish-path): add -C repo-root targeting so pr-captain-land signs and gates the scratch, not the captain checkout

pr-captain-land runs the captain's trusted tools against a scratch worktree by
setting the cwd — captain's code, scratch's data. receipt-sign, pr-create and
dispatch resolved their target repo from SCRIPT_DIR/../.. (their install
location) and ignored cwd, so on a real land the landing receipt was written
into the captain's main checkout, the find-in-scratch returned nothing, and the
land aborted with 'landing receipt was signed but could not be located'. Clean
rollback, origin untouched — the safety design held; only the targeting was
wrong.

Adds '-C <repo-root>' as the FIRST argument to receipt-sign, pr-create and
dispatch. Absent, behaviour is byte-identical to before, so no existing caller
changes. For pr-create, -C retargets DATA only: receipt-verify and
resolve-default-branch still run from its own SCRIPT_DIR, so a branch cannot
ship its own verifier and pass its own gate.

- git-safe-commit forwards its cwd-derived PROJECT_ROOT to dispatch via -C, so
  commit-announce payloads stop leaking into the tool's own checkout.
- pr-captain-land passes -C at steps 5 and 6, and names REPO_ROOT explicitly on
  both dispatch calls (the validation-failure notice is written moments before
  destroy_scratch and must not land in a directory about to be deleted).
- pr-merge loses a dead PROJECT_ROOT — same install-rooted pattern, unused but
  waiting to be picked up.

Closes the coverage gap behind this: --rehearse stops at step 3, so steps 4-9
had no test at all. Two new suites, 37 tests, both two-repo by construction
because a single-repo fixture cannot tell 'honoured -C' from 'fell back to the
install dir'. pr-captain-land-publish-locality.bats runs steps 4-5 for real and
lifts the receipt-locate expression out of the script itself rather than
restating it, since the original bug was the sign call and the locate call
disagreeing about which repo they meant. Mutation-checked: removing either fix
turns the suites red.

Also repoints five BATS fixtures from claude/config to agency/config — a
great-rename sweep miss that aborted them in setup(), so the ISCP suites were
erroring rather than running. Targeted baseline vs branch: 225 to 295 passing,
90 to 20 failing, zero new failures. Three more files have the same defect but
fail for deeper unrelated reasons; left alone and documented in #465."
in_reply_to: null
---

# Committed 8a533701 on devex-publish-path-repo-root: fix(publish-path): add -C repo-root targeting so pr-captain-land signs and gates the scratch, not the captain checkout

pr-captain-land runs the captain's trusted tools against a scratch worktree by
setting the cwd — captain's code, scratch's data. receipt-sign, pr-create and
dispatch resolved their target repo from SCRIPT_DIR/../.. (their install
location) and ignored cwd, so on a real land the landing receipt was written
into the captain's main checkout, the find-in-scratch returned nothing, and the
land aborted with 'landing receipt was signed but could not be located'. Clean
rollback, origin untouched — the safety design held; only the targeting was
wrong.

Adds '-C <repo-root>' as the FIRST argument to receipt-sign, pr-create and
dispatch. Absent, behaviour is byte-identical to before, so no existing caller
changes. For pr-create, -C retargets DATA only: receipt-verify and
resolve-default-branch still run from its own SCRIPT_DIR, so a branch cannot
ship its own verifier and pass its own gate.

- git-safe-commit forwards its cwd-derived PROJECT_ROOT to dispatch via -C, so
  commit-announce payloads stop leaking into the tool's own checkout.
- pr-captain-land passes -C at steps 5 and 6, and names REPO_ROOT explicitly on
  both dispatch calls (the validation-failure notice is written moments before
  destroy_scratch and must not land in a directory about to be deleted).
- pr-merge loses a dead PROJECT_ROOT — same install-rooted pattern, unused but
  waiting to be picked up.

Closes the coverage gap behind this: --rehearse stops at step 3, so steps 4-9
had no test at all. Two new suites, 37 tests, both two-repo by construction
because a single-repo fixture cannot tell 'honoured -C' from 'fell back to the
install dir'. pr-captain-land-publish-locality.bats runs steps 4-5 for real and
lifts the receipt-locate expression out of the script itself rather than
restating it, since the original bug was the sign call and the locate call
disagreeing about which repo they meant. Mutation-checked: removing either fix
turns the suites red.

Also repoints five BATS fixtures from claude/config to agency/config — a
great-rename sweep miss that aborted them in setup(), so the ISCP suites were
erroring rather than running. Targeted baseline vs branch: 225 to 295 passing,
90 to 20 failing, zero new failures. Three more files have the same defect but
fail for deeper unrelated reasons; left alone and documented in #465.

## Commit: 8a533701

**Branch:** devex-publish-path-repo-root
**Agent:** the-agency/jordan/devex-publish-path-repo-root
**Message:** housekeeping/captain: fix(publish-path): add -C repo-root targeting so pr-captain-land signs and gates the scratch, not the captain checkout

pr-captain-land runs the captain's trusted tools against a scratch worktree by
setting the cwd — captain's code, scratch's data. receipt-sign, pr-create and
dispatch resolved their target repo from SCRIPT_DIR/../.. (their install
location) and ignored cwd, so on a real land the landing receipt was written
into the captain's main checkout, the find-in-scratch returned nothing, and the
land aborted with 'landing receipt was signed but could not be located'. Clean
rollback, origin untouched — the safety design held; only the targeting was
wrong.

Adds '-C <repo-root>' as the FIRST argument to receipt-sign, pr-create and
dispatch. Absent, behaviour is byte-identical to before, so no existing caller
changes. For pr-create, -C retargets DATA only: receipt-verify and
resolve-default-branch still run from its own SCRIPT_DIR, so a branch cannot
ship its own verifier and pass its own gate.

- git-safe-commit forwards its cwd-derived PROJECT_ROOT to dispatch via -C, so
  commit-announce payloads stop leaking into the tool's own checkout.
- pr-captain-land passes -C at steps 5 and 6, and names REPO_ROOT explicitly on
  both dispatch calls (the validation-failure notice is written moments before
  destroy_scratch and must not land in a directory about to be deleted).
- pr-merge loses a dead PROJECT_ROOT — same install-rooted pattern, unused but
  waiting to be picked up.

Closes the coverage gap behind this: --rehearse stops at step 3, so steps 4-9
had no test at all. Two new suites, 37 tests, both two-repo by construction
because a single-repo fixture cannot tell 'honoured -C' from 'fell back to the
install dir'. pr-captain-land-publish-locality.bats runs steps 4-5 for real and
lifts the receipt-locate expression out of the script itself rather than
restating it, since the original bug was the sign call and the locate call
disagreeing about which repo they meant. Mutation-checked: removing either fix
turns the suites red.

Also repoints five BATS fixtures from claude/config to agency/config — a
great-rename sweep miss that aborted them in setup(), so the ISCP suites were
erroring rather than running. Targeted baseline vs branch: 225 to 295 passing,
90 to 20 failing, zero new failures. Three more files have the same defect but
fail for deeper unrelated reasons; left alone and documented in #465.

### Metadata
- commit_hash: 8a533701
- branch: devex-publish-path-repo-root
- files_changed: 20
- stage: none
- stage_hash: none
- work_item: none

### Files Changed
```
.claude/skills/pr-captain-land/SKILL.md
.claude/skills/pr-captain-land/reference.md
.claude/skills/pr-captain-land/scripts/pr-captain-land
agency/REFERENCE/REFERENCE-RECEIPT-INFRASTRUCTURE.md
agency/REFERENCE/REFERENCE-SAFE-TOOLS.md
agency/tools/dispatch
agency/tools/git-safe-commit
agency/tools/pr-create
agency/tools/pr-merge
agency/tools/receipt-sign
src/agency/REFERENCE/REFERENCE-RECEIPT-INFRASTRUCTURE.md
src/agency/REFERENCE/REFERENCE-SAFE-TOOLS.md
src/agency/tools/dispatch
src/agency/tools/git-safe-commit
src/agency/tools/pr-create
src/agency/tools/pr-merge
src/agency/tools/receipt-sign
src/claude/skills/pr-captain-land/SKILL.md
src/claude/skills/pr-captain-land/reference.md
src/claude/skills/pr-captain-land/scripts/pr-captain-land
```
