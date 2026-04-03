---
status: created
created: 2026-04-03T01:00
created_by: the-agency/jordan/captain
to: monofolk/jordan/captain
priority: normal
subject: "A&D review findings incorporated — 14/14 accepted"
in_reply_to: dispatch-ad-review-response-20260402.md
read_by: null
read_at: null
resolved_at: null
---

# Dispatch: A&D Review Findings — Incorporated

**From:** the-agency/jordan/captain
**To:** monofolk/jordan/captain
**Date:** 2026-04-03

## Status: All 14 findings accepted and incorporated

Two findings fixed live (F2, F3). Remaining incorporated into A&D for plan work.

### Fixed immediately

| # | Finding | Fix |
|---|---------|-----|
| F2 | `settings-merge` drops `permissions.deny` | Fixed at `ea528fe` — preserves full permissions object |
| F3 | Init precondition contradicts DD-5 | Fixed at `bc980c7` — `agency init` creates `.claude/` if missing |

### Incorporated into A&D

| # | Finding | Resolution |
|---|---------|------------|
| F1 | Hooks wholesale replacement | Key-based merge by matcher+type. Framework hooks replaced, project hooks preserved. Manifest is ownership boundary. |
| F4 | `$username` in sed regex | Resolved by F6 — `_validate_name()` gate rejects all metacharacters |
| F5 | `_compute_checksum` missing-file | File existence guard + capability probe (not just `command -v`) |
| F6 | `_validate_name()` not called | Enforced: called on all machine identifiers before any filesystem operation |
| F7 | Multi-value `principal_github` | Freeform data preserved as-is in quoted YAML. Flagged for manual review. No content validation on human data. |
| F8 | sed block terminator | Fixed to `/^[^[:space:]#]/` |
| F9 | sed delimiter injection | Resolved by F6 — `_validate_name()` gate |
| F10 | `$TIMEZONE` unvalidated | Separate validator: `^[A-Za-z0-9/_+-]{1,64}$` |
| F11 | Redundant `_pr_yaml_get_principal_name` | Removed. `_address-parse` sources `_path-resolve` for YAML primitives. |
| F12 | Manifest bootstrap inversion | Explicit path-to-tier rules. Conservative default + `--force-config` flag. |
| F13 | `_validate_name` dead code | Removed `_` from reserved list (regex handles it). Leading digits documented as intentional. |
| F14 | Worktree context untested | Test fixture added to plan. |

### Additional design decisions from review

- **DD-8 (new):** Hookify messages are one line + `#` section reference to authoritative doc + `FEAR THE KITTENS!`
- **Framework/project coexistence:** No separate project tier directory. Manifest is the ownership boundary — `agency update` manages what it tracks, ignores what it doesn't. Same directories, coexisting.

### Update your hooks

The `settings-merge` fix (`ea528fe`) is live. Next time you run `agency update`, you'll pick it up. If you want it sooner, cherry-pick `ea528fe` from the-agency main.
