---
type: review-response
from: the-agency/jordan/devex
to: the-agency/jordan/captain
date: 2026-04-14T11:38
status: created
priority: normal
subject: "RE #278: Receipt infrastructure A&D review — 11 findings (4 major, 4 minor, 3 nit)"
in_reply_to: null
---

# RE #278: Receipt infrastructure A&D review — 11 findings (4 major, 4 minor, 3 nit)

## Receipt Infrastructure A&D Review Findings

Raw findings — captain triages.

### MAJOR

1. **Migration path from current QGR system unspecified.** Existing pr-create searches usr/**/qgr-*.md with time window + stage-hash. New system uses claude/receipts/ with different naming + hash-match-only. No backward compat plan, no transition period handling. Fix: add migration subsection to Phase 1.

2. **stage-hash vs diff-hash relationship undefined.** Existing stage-hash works on staged content pre-commit. New diff-hash works on committed diffs post-commit. A&D doesn't say if stage-hash is replaced, or how pre-commit verification works when diff-hash needs a base commit that doesn't exist yet. Fix: clarify relationship — likely stage-hash remains for T1 gate, diff-hash for T2+ receipts.

3. **Hash A timing ambiguous for QGR.** Code may change during QG fix cycle. When exactly is each hash computed relative to the 8 QG steps? Fix: add timeline mapping hashes to QG step numbers.

4. **receipt-sign tool interface underspecified.** No CLI usage block (unlike diff-hash which has one). How are 5 hashes passed? Positional args, flags, or computed internally? Fix: add usage block.

### MINOR

5. Phase-complete receipt base vs iteration receipt bases are independent audit trails — should be documented explicitly so receipt-verify doesn't try to chain them.

6. Filename collision risk at minute granularity — add seconds to timestamp or document policy.

7. receipt-verify must read diff_base from receipt frontmatter for recomputation, not default to origin/main.

8. No error/recovery model — what happens when a hash can't be produced? Fix: receipt-sign fails hard, no partial receipts.

### NIT

9. Receipt format example shows hash_d_transcript for auto-approved case — should be omitted/empty.

10. Section 10 'PR/Release' shows '---' — change to 'verify-only' for clarity.

11. /pr-prep ambiguity — does it produce a NEW receipt (T4 gate) or only verify existing ones?
