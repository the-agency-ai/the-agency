---
receipt_version: 1
type: qgr
boundary: pr-prep
org: the-agency
principal: jordan
agent: captain
workstream: agency
project: qg-hash-order
diff_base: origin/main
hash_a: 58a86b33441bcaa19f4165225121e3d45a67a18819f5a34bc66b4cc99ebe7dff
hash_b: 58a86b33441bcaa19f4165225121e3d45a67a18819f5a34bc66b4cc99ebe7dff
hash_c: 58a86b33441bcaa19f4165225121e3d45a67a18819f5a34bc66b4cc99ebe7dff
hash_d: 58a86b33441bcaa19f4165225121e3d45a67a18819f5a34bc66b4cc99ebe7dff
hash_d_source: "auto-approved — captain-authored; parallel QG via reviewer-code + reviewer-test. Both found a real defect (untracked files omitted by --working → false receipt BLOCK); FIXED via temp-index intent-to-add (their recommended approach), proven: untracked matches post-commit, real index untouched, worktree-compatible. 20 diff-hash tests green incl. the exact scenario; receipt-sign/verify unaffected."
hash_e: 58a86b33441bcaa19f4165225121e3d45a67a18819f5a34bc66b4cc99ebe7dff
date: 2026-08-13T17:34
---

# Receipt: pr-prep — qg-hash-order

## Chain of Trust
- A (original): 58a86b3
- B (findings): 58a86b3
- C (triage): 58a86b3
- D (principal): 58a86b3 — auto-approved — captain-authored; parallel QG via reviewer-code + reviewer-test. Both found a real defect (untracked files omitted by --working → false receipt BLOCK); FIXED via temp-index intent-to-add (their recommended approach), proven: untracked matches post-commit, real index untouched, worktree-compatible. 20 diff-hash tests green incl. the exact scenario; receipt-sign/verify unaffected.
- E (final): 58a86b3

## Review Summary
flag #207: diff-hash --working (BASE vs working tree incl. untracked via throwaway-index intent-to-add) so the QG hashes uncommitted work; Hash A/E use it. Cross-boundary consistent — receipt-verify (default) still matches.
