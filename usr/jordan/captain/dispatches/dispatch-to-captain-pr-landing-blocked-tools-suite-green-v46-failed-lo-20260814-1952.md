---
type: dispatch
from: the-agency/jordan/captain
to: the-agency-ai/jordan/captain
date: 2026-08-14T11:52
status: created
priority: normal
subject: "PR landing BLOCKED: tools-suite-green-v46 failed local validation (PR_LAND_VALIDATE_CMD)"
in_reply_to: null
---

# PR landing BLOCKED: tools-suite-green-v46 failed local validation (PR_LAND_VALIDATE_CMD)

Captain ran /pr-captain-land on `tools-suite-green-v46` and it failed the LOCAL validation gate before anything was published.

- Failed step: `PR_LAND_VALIDATE_CMD`
- Validated against: `origin/main`
- Nothing was pushed. No PR. No version bump. No release.

Fix locally, re-run /pr-prep, push, then re-run /pr-submit.

-- the-agency-ai/jordan/captain
