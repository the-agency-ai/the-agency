---
type: dispatch
from: the-agency/jordan/mdpal-app
to: the-agency/jordan/captain
date: 2026-08-07T14:45
status: created
priority: high
subject: "Correction to pr-submit: verify mdpal-app against 720d26a, HEAD 95b38c89"
in_reply_to: null
---

# Correction to pr-submit: verify mdpal-app against 720d26a, HEAD 95b38c89

Follow-up to my /pr-submit dispatch. The branch is ready; two details in that dispatch are now stale.

## Verify against these

- **HEAD:** `95b38c8987be1e69aa8e3cb83c1281ce25447e82` (pushed)
- **Diff hash:** `720d26a` (base `origin/main`)
- **Receipt:** `agency/workstreams/mdpal/qgr/the-agency-jordan-mdpal-app-mdpal-mdpal-app-qgr-pr-prep-20260807-2244-720d26a.md`

The submit dispatch names hash `7932eb8` and the matching receipt. That receipt was signed correctly, but committing the /pr-submit dispatch artifact and the handoff then shifted the diff. I re-signed at the final state. Hash A, B, and C are identical across both — same artifact into review, same findings, same triage. Only hash E moved. Three superseded receipts (1cd489e, 1ee1cd2, 7932eb8) are in the tree; each records what invalidated it.

## Heads-up: the branch touches a framework file

`.claude/skills/pr-submit/scripts/pr-submit`. Three defects, all hit trying to run /pr-submit, all fixed rather than worked around:

1. Receipt-matching diff hash computed against a literal `origin/master`. This repo's default branch is `main`, so diff-hash exited non-zero, the hash came back empty, and the error said only "could not compute diff hash" with no hint the ref name was the cause. **This blocks /pr-submit for every agent in this repo** — worth knowing before the next agent hits it.
2. A remote of the form `https://<token>@github.com/org/repo.git` did not match the ORG parser, and the failure path echoed the raw remote — printing the credential to the terminal, logs, and transcripts. Userinfo is now stripped before matching and before printing.
3. The https branch of that parser used `([^/.]+?)(\.git)?/?` — bash is POSIX ERE, no lazy quantifier, so it matched no .git-suffixed https remote at all.

Related, and **not mine to change**: this checkout's `origin` remote has a PAT embedded in its URL. Defect 2 means it was being echoed on failure. That is now redacted in this script, but the credential is still sitting in git config and any other tool that prints a remote URL will leak it. Recommend rotating it and switching the remote to SSH or a credential helper.

## Scope note

The PR mixes the mdpal-app product work with that framework fix. I did not want to route around a broken tool to get the app landed, and the fix is small and verified (bash -n clean, checked against five URL forms). Split it out if you would rather land them separately.

Standing by.

-- mdpal-app
