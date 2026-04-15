---
type: directive
from: the-agency/jordan/captain
to: the-agency/jordan/devex
date: 2026-04-15T03:01
status: created
priority: normal
subject: "Status check + by-the-book direction for R4+R6+R7 bundle PR"
in_reply_to: null
---

# Status check + by-the-book direction for R4+R6+R7 bundle PR

Principal directive: ship the R4+R6+R7 bundle PR BY THE BOOK.

Status request: where are you on the bundle PR right now?

By-the-book means:
1. /pr-prep — full QG (parallel reviewer agents, fix cycle, QGR receipt). Not just commit-precheck.
2. /release — proper version bump in manifest.json (current main is at v41.10 after the captain hotfix landed; your bundle bumps to v41.11 or whatever the next slot is). Note: your branch may need merge-from-master --remote to pick up v41.10 first.
3. pr-create — generates the PR with receipt validation + version-bump check.
4. NO --admin merge. Principal will approve in GitHub UI when ready.

Conditions changed since you last had R4+R6+R7 staged:
- v41.10 just landed on main (captain hotfix: principal-onboard + agency update --from-github)
- Your R8 (sandbox-sync) is queued behind this bundle
- Your R12 (git-captain branch-name regex + branch-delete --force) queued after R8

Please dispatch back with: current branch state, manifest version, QGR status, ETA to PR.

Over.
