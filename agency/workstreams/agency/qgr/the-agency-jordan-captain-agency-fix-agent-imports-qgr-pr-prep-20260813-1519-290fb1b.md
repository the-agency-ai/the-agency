---
receipt_version: 1
type: qgr
boundary: pr-prep
org: the-agency
principal: jordan
agent: captain
workstream: agency
project: fix-agent-imports
diff_base: origin/main
hash_a: 290fb1b2f4cb5a4c55f20bcae354ba64be6466b69e9feddd7543febd14287417
hash_b: 290fb1b2f4cb5a4c55f20bcae354ba64be6466b69e9feddd7543febd14287417
hash_c: 290fb1b2f4cb5a4c55f20bcae354ba64be6466b69e9feddd7543febd14287417
hash_d: 290fb1b2f4cb5a4c55f20bcae354ba64be6466b69e9feddd7543febd14287417
hash_d_source: "auto-approved — captain-authored; parallel QG via the newly-registered reviewer-design + reviewer-test agents, both CLEAN (0 blocking defects). Validation: new @claude/-guard test + 15/15 skill-validation green; 0 @claude/ imports remain; mirrors byte-identical; resolvable targets confirmed."
hash_e: 290fb1b2f4cb5a4c55f20bcae354ba64be6466b69e9feddd7543febd14287417
date: 2026-08-13T15:19
---

# Receipt: pr-prep — fix-agent-imports

## Chain of Trust
- A (original): 290fb1b
- B (findings): 290fb1b
- C (triage): 290fb1b
- D (principal): 290fb1b — auto-approved — captain-authored; parallel QG via the newly-registered reviewer-design + reviewer-test agents, both CLEAN (0 blocking defects). Validation: new @claude/-guard test + 15/15 skill-validation green; 0 @claude/ imports remain; mirrors byte-identical; resolvable targets confirmed.
- E (final): 290fb1b

## Review Summary
flag #246: repair broken @claude/ imports in agent registrations -> @agency/ (18 files) + guard test. Content gaps (missing workstream fragments/per-agent docs) flagged #248.
