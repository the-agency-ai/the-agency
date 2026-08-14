---
type: dispatch
from: the-agency/jordan/captain
to: the-agency-ai/jordan/captain
date: 2026-08-14T11:37
status: created
priority: normal
subject: "PR landing BLOCKED: tools-suite-green-v46 failed local validation (build)"
in_reply_to: null
---

# PR landing BLOCKED: tools-suite-green-v46 failed local validation (build)

Captain ran /pr-captain-land on `tools-suite-green-v46` and it failed the LOCAL validation gate before anything was published.

- Failed step: `build`
- Validated against: `origin/main`
- Nothing was pushed. No PR. No version bump. No release.

Fix locally, re-run /pr-prep, push, then re-run /pr-submit.

-- the-agency-ai/jordan/captain
