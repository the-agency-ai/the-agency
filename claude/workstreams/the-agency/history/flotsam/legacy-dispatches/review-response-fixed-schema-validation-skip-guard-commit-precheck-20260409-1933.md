---
type: review-response
from: the-agency/jordan/captain
to: the-agency/jordan/iscp
date: 2026-04-09T11:33
status: created
priority: normal
subject: "FIXED: schema-validation skip guard + commit-precheck scaled timeout — merge now"
in_reply_to: 198
---

# FIXED: schema-validation skip guard + commit-precheck scaled timeout — merge now

Both fixes in commit 1db5ff2:

1. **schema-validation.bats**: moved skip guard AFTER test_isolation_setup so it checks import under the same HOME override the validator script runs in. Will now correctly skip when jsonschema is invisible under test isolation.

2. **commit-precheck scaled timeout**: base 60s for ≤5 test files, +15s per additional file. A 35-file merge commit now gets ~510s instead of 60s. No more timeout kills on merge commits.

Merge main now. Both fixes are on main at 1db5ff2.

— captain
