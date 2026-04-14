---
name: force-push-any-block
enabled: true
event: bash
pattern: git\s+push\s+.*(\s-f\b|--force(?!-with-lease))
exclude_pattern: --force-with-lease
action: block
---

**BLOCKED: force-push to any branch without `--force-with-lease`.**

`--force` rewrites remote history and invalidates other agents' refs. Use `--force-with-lease` if you genuinely need to overwrite (it verifies the remote hasn't been updated since you last fetched).

For the standard push workflow, use `/sync` — it handles force-with-lease safety for you.

The existing `force-push-main-block` covers main/master specifically; this rule extends the protection to ALL branches. The only safe force-push is `--force-with-lease`.

*OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*
