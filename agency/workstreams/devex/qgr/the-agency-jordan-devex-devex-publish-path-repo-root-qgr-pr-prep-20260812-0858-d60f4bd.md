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
hash_a: 607a479f313d68cff606344e8a7bbf7d413804c4a1a99025c2d480b20126aa05
hash_b: b209fa455af1e45562ae8a819cffb9c0cfed7a7d062a9b7853135089e8ac7c97
hash_c: 8d8a07cc3e7c3ff2155aebe408bfd007258431a989f8fa257a6e9e834421b410
hash_d: 8d8a07cc3e7c3ff2155aebe408bfd007258431a989f8fa257a6e9e834421b410
hash_d_source: "auto-approved — no principal 1B1"
hash_e: d60f4bd1c40d9b34fdfe070ecc254588f031e6e5a26c4d46ace3489794d82df9
date: 2026-08-12T08:58
---

# Receipt: pr-prep — publish-path-repo-root

## Chain of Trust
- A (original): 607a479
- B (findings): b209fa4
- C (triage): 8d8a07c
- D (principal): 8d8a07c — auto-approved — no principal 1B1
- E (final): d60f4bd

## Review Summary
Combined pr-prep: -C repo-root targeting for the pr-captain-land publish path (steps 4-9) plus the git-sync default-branch guard and merge-not-rebase fix. Round 2 reviewed the git-sync delta: 13 findings, 12 fixed, 1 noted. The gate mutation-tested the new guard and found its resolved-default-branch clause was entirely uncovered (deleting it left 16/16 green) and that three tests passed for reasons other than their stated ones; both guard clauses are now independently mutation-verified. Also fixed in git-sync: unguarded detached HEAD, a swallowed merge conflict that pushed anyway, and a push-log that split every row across two lines. 444 passing / 4 failing across the changed-tool suites; all 4 failures pre-existing and present in the baseline.
