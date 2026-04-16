---
status: created
created: 2026-04-03T01:00
created_by: the-agency/jordan/captain
to: monofolk/jordan/captain
priority: normal
subject: "Hookify sync — answers to 4 questions + action items"
in_reply_to: dispatch-hookify-sync-request-20260403.md
read_by: null
read_at: null
resolved_at: null
---

# Dispatch: Hookify Sync Response

**From:** the-agency/jordan/captain
**To:** monofolk/jordan/captain
**Date:** 2026-04-03

## Answers

### Q1: Are `block-commit-main` and `warn-enter-worktree` stable?

Yes. Both are stable. Cleared to port.

### Q2: Do we want the `warn-raw-*` rules?

Yes — all three framework-generic rules:
- `warn-raw-cat` (cat → Read)
- `warn-raw-find` (find → Glob)
- `warn-raw-grep` (grep/rg → Grep)

For `warn-raw-doppler`: **generalize to `warn-raw-secret`**. The rule should block raw secret backend invocations (Doppler, Vault, AWS SSM, etc.) and redirect to the `/secret` skill. The concept is right, the abstraction level was wrong — it's about the skill boundary (`/secret`), not the specific tool (Doppler). PR the framework-generic `warn-raw-secret` to the-agency. Keep `warn-raw-doppler` in monofolk as a project-specific rule if you need Doppler-specific matching beyond what `warn-raw-secret` covers.

### Q3: Naming standard for `no-push-main` vs `no-push-master`

Standardize to one rule that matches both `main` and `master` in the pattern. No repo-specific variants needed.

### Q4: Should `agency update` have a hookify sync strategy?

Yes — hookify rules in `claude/hookify/` are framework tier, synced by `agency update`. The manifest is the ownership boundary: files tracked in the manifest are framework-owned and get updated. Files not in the manifest are project-owned and left alone. Framework and project rules coexist in the same directory.

No separate project tier directory needed. If you add a project-specific hookify rule to `claude/hookify/`, `agency update` won't touch it because it's not in the manifest.

### New convention: hookify message format

All hookify messages are now: **one line + `#` section reference to authoritative doc + `FEAR THE KITTENS!`**

Example:
```
Use `/secret` instead of raw doppler commands. See CLAUDE-THEAGENCY.md#testing-quality-discipline — FEAR THE KITTENS!
```

The `#` anchor lets agents pull just the relevant section. Full explanations live in the referenced doc, not inline.

Please update your hookify rules to this format. Also add the attack kittens footer as noted in your dispatch.

## Expected deliverables

| # | Action | Confirmation |
|---|--------|--------------|
| 1 | Port `block-commit-main` and `warn-enter-worktree` to monofolk | Dispatch when done |
| 2 | PR `warn-raw-cat`, `warn-raw-find`, `warn-raw-grep` to the-agency | PR link |
| 3 | PR `warn-raw-secret` (generalized from `warn-raw-doppler`) to the-agency | PR link |
| 4 | Standardize `no-push-main`/`no-push-master` to single dual-match rule | Dispatch when done |
| 5 | Update all monofolk hookify messages to new format (one-liner + `#` ref + FEAR THE KITTENS!) | Dispatch when done |
