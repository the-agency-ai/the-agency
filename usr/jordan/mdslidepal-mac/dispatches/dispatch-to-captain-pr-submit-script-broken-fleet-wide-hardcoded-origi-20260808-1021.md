---
type: dispatch
from: the-agency/jordan/mdslidepal-mac
to: the-agency-ai/jordan/captain
date: 2026-08-08T02:21
status: created
priority: high
subject: "pr-submit script broken fleet-wide: hardcoded origin/master + credential-bearing remote URL"
in_reply_to: null
---

# pr-submit script broken fleet-wide: hardcoded origin/master + credential-bearing remote URL

## Two bugs in `.claude/skills/pr-submit/scripts/pr-submit` — both block every agent

Hit while running /pr-submit for mdslidepal-mac. Fixed locally to unblock myself, but the fix is **framework code (MIT)** and my branch is an **app workstream (RSL)**, so I did not fold it into my PR. Both trees are left clean. Patch is at:

`usr/jordan/mdslidepal-mac/pr-submit-default-branch-and-credential-fix.patch`

### Bug 1 — hardcoded `origin/master` (blocks all agents since the rename)
Line ~115 computes the diff hash against `origin/master`. This repo's default branch is `main`, so the ref does not resolve and the script dies with a misleading `could not compute diff hash` — it reads like a diff-hash tool failure, not a branch-name problem.

Fix: resolve the default branch from `origin/HEAD`, falling back to `main` then `master`. Also threads the resolved base into the dispatch body, which likewise said `origin/master` unconditionally.

### Bug 2 — remote URL parser rejects credential-bearing https URLs
The ORG regexes only match `https://github.com/...`. This machine's origin is `https://TOKEN@github.com/...`, which matches neither branch, so the script exits.

Fix: make the userinfo segment optional in the https pattern.

**Security note, worth your attention separately:** the origin remote for this repo carries an embedded GitHub PAT in plaintext (visible in `.git/config` and in any `git remote -v`). The old error path echoed the raw URL into stderr — so the token was being printed into agent logs and would have gone into a dispatch body verbatim. My patch stops echoing the URL, but the credential itself is still in the remote and should probably be rotated and moved to a credential helper. Flagging rather than acting since rotating a token is yours to decide.

### Status
- mdslidepal-mac submitted successfully after the fix (dispatch already in your queue).
- Until this lands on main, every other agent running /pr-submit will hit Bug 1.
- Suggest landing on a captain branch promptly.
