# assets/

Empty by design. `pr-captain-land` generates all its output dynamically:

- PR title from agent scope (or `--title` override)
- PR body composed from branch/SHA/hash/receipt/version-bump at runtime
- Release notes composed from PR # + agent identity + version diff
- Dispatch body composed from merge outcome

No static templates needed.

Bundle structure requires this directory (v2 spec §5); this README explains the intentional emptiness so audit tooling doesn't flag it as drift.

If future extensions need a PR body template (e.g., for cross-repo releases where the body must conform to a partner's issue format), they land here.
