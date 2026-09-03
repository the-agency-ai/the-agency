---
receipt_version: 1
type: qgr
boundary: pr-prep
org: the-agency
principal: jordan
agent: captain
workstream: agency
project: fix-config-dup-and-testrun-parsing
diff_base: origin/main
hash_a: f86ce81ccdc4ed971d0bab5942f2893f6b5f66e0f84d6bffaeccc35358ed0113
hash_b: fe0c2b7e1c82364df25ccae84e27f41a36765c016d7aed1ad9814f4cccb0ed47
hash_c: f2e8faf94ba658953f24b3bd4d3c527da272bd815e1ea074e0fb62713ed81c37
hash_d: f2e8faf94ba658953f24b3bd4d3c527da272bd815e1ea074e0fb62713ed81c37
hash_d_source: "auto-approved — no principal 1B1 transcript"
hash_e: ce2de4aff5fee196dd4f0ca20d3a85dc7a086900e3c0efac4600c9a8cce1a294
date: 2026-09-03T23:38
---

# Receipt: pr-prep — fix-config-dup-and-testrun-parsing

## Chain of Trust
- A (original): f86ce81
- B (findings): fe0c2b7
- C (triage): f2e8faf
- D (principal): f2e8faf — auto-approved — no principal 1B1 transcript
- E (final): ce2de4a

## Review Summary
2 flagged bugs: agency.yaml dup collaboration key (#240) + test-run |-delimiter truncation (#242); QG clean, both regression-pinned, +tests
