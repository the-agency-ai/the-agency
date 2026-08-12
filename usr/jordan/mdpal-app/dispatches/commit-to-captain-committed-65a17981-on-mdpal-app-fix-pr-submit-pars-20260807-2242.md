---
type: commit
from: the-agency/jordan/mdpal-app
to: the-agency/jordan/captain
date: 2026-08-07T14:42
status: created
priority: normal
subject: "Committed 65a17981 on mdpal-app: fix(pr-submit): parse credential-bearing and .git-suffixed origin URLs

Two defects in the ORG resolution, both hit in sequence submitting the
mdpal-app branch.

1. A remote of the form https://<token>@github.com/org/repo.git — what you
   get on any machine authenticating with a PAT — did not match, so the
   script aborted. Worse, the failure path echoed the raw remote URL,
   printing the token into the terminal and from there into logs and
   transcripts. Userinfo is now stripped before matching AND before the
   URL appears in the error message.

2. The https branch was written as ([^/.]+?)(\.git)?/? — bash uses POSIX
   ERE, which has no lazy quantifier, so '+?' never meant what it looks
   like and the branch failed to match ANY .git-suffixed https remote,
   token or not. Replaced with tail normalization (strip .git, strip
   trailing slash) plus a plain pattern.

Verified against all five forms: token-bearing https, plain https with and
without .git, scp-style git@, and user:pass with a trailing slash."
in_reply_to: null
---

# Committed 65a17981 on mdpal-app: fix(pr-submit): parse credential-bearing and .git-suffixed origin URLs

Two defects in the ORG resolution, both hit in sequence submitting the
mdpal-app branch.

1. A remote of the form https://<token>@github.com/org/repo.git — what you
   get on any machine authenticating with a PAT — did not match, so the
   script aborted. Worse, the failure path echoed the raw remote URL,
   printing the token into the terminal and from there into logs and
   transcripts. Userinfo is now stripped before matching AND before the
   URL appears in the error message.

2. The https branch was written as ([^/.]+?)(\.git)?/? — bash uses POSIX
   ERE, which has no lazy quantifier, so '+?' never meant what it looks
   like and the branch failed to match ANY .git-suffixed https remote,
   token or not. Replaced with tail normalization (strip .git, strip
   trailing slash) plus a plain pattern.

Verified against all five forms: token-bearing https, plain https with and
without .git, scp-style git@, and user:pass with a trailing slash.

## Commit: 65a17981

**Branch:** mdpal-app
**Agent:** the-agency/jordan/mdpal-app
**Message:** housekeeping/captain: fix(pr-submit): parse credential-bearing and .git-suffixed origin URLs

Two defects in the ORG resolution, both hit in sequence submitting the
mdpal-app branch.

1. A remote of the form https://<token>@github.com/org/repo.git — what you
   get on any machine authenticating with a PAT — did not match, so the
   script aborted. Worse, the failure path echoed the raw remote URL,
   printing the token into the terminal and from there into logs and
   transcripts. Userinfo is now stripped before matching AND before the
   URL appears in the error message.

2. The https branch was written as ([^/.]+?)(\.git)?/? — bash uses POSIX
   ERE, which has no lazy quantifier, so '+?' never meant what it looks
   like and the branch failed to match ANY .git-suffixed https remote,
   token or not. Replaced with tail normalization (strip .git, strip
   trailing slash) plus a plain pattern.

Verified against all five forms: token-bearing https, plain https with and
without .git, scp-style git@, and user:pass with a trailing slash.

### Metadata
- commit_hash: 65a17981
- branch: mdpal-app
- files_changed: 1
- stage: none
- stage_hash: none
- work_item: none

### Files Changed
```
.claude/skills/pr-submit/scripts/pr-submit
```
