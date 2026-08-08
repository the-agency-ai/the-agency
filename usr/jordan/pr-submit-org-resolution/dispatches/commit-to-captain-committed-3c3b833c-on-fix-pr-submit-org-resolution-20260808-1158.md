---
type: commit
from: the-agency/jordan/pr-submit-org-resolution
to: the-agency/jordan/captain
date: 2026-08-08T03:58
status: created
priority: normal
subject: "Committed 3c3b833c on fix/pr-submit-org-resolution: fix(pr-create): don't abort on head/pipefail SIGPIPE in receipt search

pr-create's receipt-find pipelines (find | xargs ls -t | head -1) abort the
whole script under 'set -o pipefail' once there are enough receipts (~100+)
that head closing the pipe SIGPIPEs the upstream ls before it finishes — a
nondeterministic failure that silently blocked PR creation in this repo (120
receipts). The newest receipt is already captured before the signal; append
'|| true' so the benign pipeline failure can't abort. A genuine empty result
still falls through to the existing -z checks. Applied to all three receipt
tiers; src/ mirror kept identical."
in_reply_to: null
---

# Committed 3c3b833c on fix/pr-submit-org-resolution: fix(pr-create): don't abort on head/pipefail SIGPIPE in receipt search

pr-create's receipt-find pipelines (find | xargs ls -t | head -1) abort the
whole script under 'set -o pipefail' once there are enough receipts (~100+)
that head closing the pipe SIGPIPEs the upstream ls before it finishes — a
nondeterministic failure that silently blocked PR creation in this repo (120
receipts). The newest receipt is already captured before the signal; append
'|| true' so the benign pipeline failure can't abort. A genuine empty result
still falls through to the existing -z checks. Applied to all three receipt
tiers; src/ mirror kept identical.

## Commit: 3c3b833c

**Branch:** fix/pr-submit-org-resolution
**Agent:** the-agency/jordan/pr-submit-org-resolution
**Message:** fix/pr-submit-org: fix(pr-create): don't abort on head/pipefail SIGPIPE in receipt search

pr-create's receipt-find pipelines (find | xargs ls -t | head -1) abort the
whole script under 'set -o pipefail' once there are enough receipts (~100+)
that head closing the pipe SIGPIPEs the upstream ls before it finishes — a
nondeterministic failure that silently blocked PR creation in this repo (120
receipts). The newest receipt is already captured before the signal; append
'|| true' so the benign pipeline failure can't abort. A genuine empty result
still falls through to the existing -z checks. Applied to all three receipt
tiers; src/ mirror kept identical.

### Metadata
- commit_hash: 3c3b833c
- branch: fix/pr-submit-org-resolution
- files_changed: 3
- stage: none
- stage_hash: none
- work_item: none

### Files Changed
```
agency/tools/pr-create
src/agency/tools/pr-create
usr/jordan/pr-submit-org-resolution/dispatches/commit-to-captain-committed-977162e3-on-fix-pr-submit-org-resolution-20260808-1152.md
```
