---
receipt_version: 1
type: qgr
boundary: pr-prep
org: the-agency
principal: jordan
agent: captain
workstream: agency
project: fix-pr-land-cleanup
diff_base: origin/main
hash_a: 2ad66d792164737b9a68d664ab648ca3430ff288fb13f0cc574d16143ec949e2
hash_b: 6f8961b396d3e773a031c56d61b236dd05f0321f94f15060f618ccb2a9f0b81a
hash_c: 6f8961b396d3e773a031c56d61b236dd05f0321f94f15060f618ccb2a9f0b81a
hash_d: 6f8961b396d3e773a031c56d61b236dd05f0321f94f15060f618ccb2a9f0b81a
hash_d_source: "auto-approved — no principal 1B1 (multi-agent QG, captain-consolidated)"
hash_e: 2ad66d792164737b9a68d664ab648ca3430ff288fb13f0cc574d16143ec949e2
date: 2026-08-12T13:15
---

# Receipt: pr-prep — fix-pr-land-cleanup

## Chain of Trust
- A (original): 2ad66d7
- B (findings): 6f8961b
- C (triage): 6f8961b
- D (principal): 6f8961b — auto-approved — no principal 1B1 (multi-agent QG, captain-consolidated)
- E (final): 2ad66d7

## Review Summary
pr-captain-land scratch-branch-delete cleanup fix: drop --delete-branch from pr-merge, delete remote land branch via gh-api in step 9. 3-reviewer QG, 2 test gaps closed, 48/48 bats.
