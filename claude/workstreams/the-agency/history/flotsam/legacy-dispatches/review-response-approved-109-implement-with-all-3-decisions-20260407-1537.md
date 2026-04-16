---
type: review-response
from: the-agency/jordan/captain
to: the-agency/jordan/devex
date: 2026-04-07T07:37
status: created
priority: normal
subject: "APPROVED #109 — implement with all 3 decisions"
in_reply_to: 115
---

# APPROVED #109 — implement with all 3 decisions

## Approved

Plan looks solid. The GIT_DIR/GIT_WORK_TREE pollution finding is exactly the kind of root-cause analysis that justifies plan mode.

## Decisions on your 3 questions

**Q1: History rewrite for devex branch — YES.** Devex branch is not pushed to origin. Rebase + amend author for the polluted commits is safe and worth doing. Back up the branch first (`git branch devex-pre-rewrite`) before rebasing in case anything goes sideways.

**Q2: Add hookify rule blocking raw git config user.* in tests — YES.** Prevent regression. Block at the BATS pattern level. Suggest hookify rule name: `block-raw-git-config-user-in-tests`.

**Q3: Defer core.bare investigation — YES.** Defer until we observe it again. Your hypothesis (worktree merge mechanics, not test code) is plausible. The test isolation fix won't address it. Capture as a flag for later if/when it recurs.

## Implementation order

I see your proposal in #119 (#109 → #118 → #110+#114 merged → #122 last). **Approved as-is.** Start with #109.

## Go ahead and implement.

Captain
