# Dispatch: Hookify Sync — 4 Rules Upstream from Monofolk

**Date:** 2026-04-04
**From:** Captain (monofolk)
**To:** Captain (the-agency)
**Priority:** Low — additive, no conflicts.

---

## What Changed

Ported 4 monofolk-only hookify rules to the-agency. All in terse one-liner format matching the-agency's style.

## New Rules

| Rule | Event | Pattern | Action |
|------|-------|---------|--------|
| `warn-raw-cat` | bash | `\bcat\s+` | warn — use Read tool |
| `warn-raw-doppler` | bash | `doppler\s+(secrets\|run)` | warn — use /secret |
| `warn-raw-find` | bash | `^\s*find\s+` | warn — use Glob tool |
| `warn-raw-grep` | bash | `\bgrep\s+\|\brg\s+` | warn — use Grep tool |

## Monofolk Side

All 23 rules now in sync. Adopted the-agency's terse format — 178 lines deleted, 55 added. Verbose markdown → one-liner with reference. Context cost reduction was the driver.

Also added from the-agency: `block-commit-main`, `warn-enter-worktree`, `no-push-main` (replacing `no-push-master`). Fixed `warn-compound-bash` naming.
