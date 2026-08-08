---
receipt_version: 1
type: qgr
boundary: pr-prep
org: the-agency
principal: jordan
agent: devex
workstream: devex
project: worktree-create-origin-branch
diff_base: origin/main
hash_a: a5e3928620d02abc0acf43e42ef1605f516370a800e461a2f16a22cadb0905d1
hash_b: 7b3e75fadc81eef7c2bdc47e2dc5493b4044cc13fdb206ae73d77f1de132395e
hash_c: 034f30694749bc47792fd46f7e690bba5dab8e066a45edb57b395f4d130f9da2
hash_d: 034f30694749bc47792fd46f7e690bba5dab8e066a45edb57b395f4d130f9da2
hash_d_source: "auto-approved — no principal 1B1"
hash_e: 9815b51b8d5175c94d230a36f5011a490eb59d513af1cef594acb8fe9da046c2
date: 2026-08-08T12:04
---

# Receipt: pr-prep — worktree-create-origin-branch

## Chain of Trust
- A (original): a5e3928
- B (findings): 7b3e75f
- C (triage): 034f306
- D (principal): 034f306 — auto-approved — no principal 1B1
- E (final): 9815b51

## Review Summary
worktree-create v2.2.0 — origin/<branch> DWIM so stale-PR branches are checked out instead of forked empty from HEAD; multi-remote resolution; branch-name and flag-value validation; loud staleness reporting. Tests 20 to 31, isolation guards added after the tests themselves leaked worktrees into the live checkout. 2 reviewers, 14 distinct findings, 13 accepted and fixed, 1 rejected with rationale (see triage).
