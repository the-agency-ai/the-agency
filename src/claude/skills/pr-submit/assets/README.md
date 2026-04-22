# assets/

Empty by design. `pr-submit` has no static templates or assets — the dispatch body is generated dynamically from runtime state (branch, SHA, hash, receipt path, scope) at emission time.

Bundle structure requires this directory (v2 spec §5); this README explains the intentional emptiness so audit tooling doesn't flag it as drift.

If future extensions need templates (e.g., a captain-side reply template for `pr-submit-rejected`), they land here.
