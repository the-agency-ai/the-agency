---
receipt_version: 1
type: qgr
boundary: pr-prep
org: the-agency
principal: jordan
agent: devex
workstream: devex
project: publish-path-repo-root
diff_base: origin/main
hash_a: 281c0abae0f08bf7cb48426a14c10058783c86cb506910ebd918d5a45822d2a6
hash_b: 87ed7bb29a18965eebff00ee66844c57accd7c534ec733633351e2e611ddd568
hash_c: 079771bf28973854f10e16bb4b93e1bd28c1b6bc1c7f3a5bd0daab030b1970e3
hash_d: 079771bf28973854f10e16bb4b93e1bd28c1b6bc1c7f3a5bd0daab030b1970e3
hash_d_source: "auto-approved — no principal 1B1"
hash_e: 8f81cefa31586a2c7ee16fbfcbca069c588720ad11520de2dc3ad4c4e8b158fe
date: 2026-08-11T17:04
---

# Receipt: pr-prep — publish-path-repo-root

## Chain of Trust
- A (original): 281c0ab
- B (findings): 87ed7bb
- C (triage): 079771b
- D (principal): 079771b — auto-approved — no principal 1B1
- E (final): 8f81cef

## Review Summary
pr-prep for -C repo-root targeting on the pr-captain-land publish path (steps 4-9). 14 findings scored, 10 accepted and fixed, 4 deferred with rationale. Critical: the first cut of the fix was inert in a real captain session because git-safe-commit's PROJECT_ROOT prefers CLAUDE_PROJECT_DIR, and both new suites ran with that variable unset so they passed against broken code. Fixed via COMMIT_REPO_ROOT + a test that runs with the variable set. Also fixed pr-create's cwd/-C hash-verification split, dispatch's branch-supplied ISCP DB name, receipt-sign's partial traversal check, and two portability/assertion defects in the new suites. 368 passing / 2 failing on the changed-tool suites; both failures pre-existing hookify-rule tests present in the baseline.
