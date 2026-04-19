# Phase 0a Baseline — Known Exceptions

## Symlinks (baseline-symlink-check.txt)

**Expected per Plan v4 §3 Phase 0a**: empty.

**Actual**: 1 pre-existing symlink:

```
./claude/principals/jordan/resources/cloud
```

**Rationale**: iCloud Drive symlink in the legacy `claude/principals/` tree. Pre-dates v46.0 reset work. Gets handled by Phase 3 legacy cleanup (`claude/principals/` → `history/flotsam/`). Not a blocker for Gate 0 — a pre-existing artifact that the reset itself will clean up.

**Gate 0 adjustment**: treat `baseline-symlink-check.txt` as "≤1 pre-existing symlink under claude/principals/" rather than strictly empty, pending Phase 3c cleanup.

## Baseline artifact captures (Phase 0a)

Captured at `2026-04-19T15:24-23:27Z`:
- `content-inventory.sha256` — 2230 tracked files
- `hookify-rule-count.txt` — 41 rules
- `skill-count.txt` — 62 skills
- `settings-checksum.txt` — `.claude/settings.json` SHA
- `claude-md-checksum.txt` — `CLAUDE.md` + `claude/CLAUDE-THEAGENCY.md` SHA
- `baseline-symlink-check.txt` — documented above
- `sensitive-dirs-sha256.txt` — `claude/hooks/` + `claude/tools/` + `.claude/` per-file SHA
- `env-file-inventory.txt` — find `.env*` results
- `bats-baseline.txt` — full BATS run (re-captured; initial invocation scoped to `tests/` matched 0 — corrected to `tests/tools/`)

## ref-inventory-pre.txt

Deferred until `ref-inventory-gen` tool is built in Phase 0b. Captured immediately after tool lands + passes BATS.

## v45.3-pre-reset tag

Created on `91dcfcd7` (pre-reset HEAD on `v46.0-structural-reset` branch). Pushed to origin as rollback anchor.
