---
receipt_version: 1
type: qgr
boundary: pr-prep
org: the-agency
principal: jordan
agent: captain
workstream: the-agency
project: the-agency
diff_base: origin/main
hash_a: 211bdc0947c545d9be3fec7007212c1d8528dfbf0fcdc88773649f9fd742b626
hash_b: 24f5c8806d35c3c20153998fe324f398715cdc938f06f544f5ca3095dee7cf7e
hash_c: 765a6c9fd437632a536fd857616314f2eddd108c320f9724d9b744c2c66b89fe
hash_d: 765a6c9fd437632a536fd857616314f2eddd108c320f9724d9b744c2c66b89fe
hash_d_source: "auto-approved — no principal 1B1"
hash_e: 211bdc0947c545d9be3fec7007212c1d8528dfbf0fcdc88773649f9fd742b626
date: 2026-05-09T10:25
---

# Receipt: pr-prep — the-agency

## Chain of Trust
- A (original): 211bdc0
- B (findings): 24f5c88
- C (triage): 765a6c9
- D (principal): 765a6c9 — auto-approved — no principal 1B1
- E (final): 211bdc0

## Review Summary
great-rename-migrate v1.1.0 default-map — adds apps/ → src/apps/ and starter-packs/ → src/spec-provider/starter-packs/ to unblock mdpal-app + mdpal-cli (resolves dispatches #865 + #866). Captain-release bundles 10 prior captain coord commits each with their own QGR; this receipt covers the v1.1.0 fix delta + the cumulative state.
