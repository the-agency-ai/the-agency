# The Agency v46.0 Migration Runbook

**For adopters** upgrading from v45.x to v46.0.

**Release notes:** `agency/workstreams/the-agency/release-notes-v46.0.md`
**Version bump:** `agency_version: 46.0.0` in `agency/config/manifest.json`
**Rollback anchor:** `v45.3-pre-reset` (origin tag, tagged before Phase 1)

---

## Overview

v46.0 renames the framework code directory from `claude/` to `agency/`. Every adopter path that references `claude/` (settings.json hook commands, CLAUDE.md `@import`, skill `required_reading:`, agent registrations, tool invocations in scripts/docs) must be rewritten once.

Three tools do the work:

1. `agency-migrate-prep` — dry-run sweep + apply + create local rollback tag + write prep marker.
2. `agency-update-migrate --migrate` — pull v46.0 framework code and apply the rewrite.
3. `agency-verify-v46 --customer` — confirm the result.

## Prep (dry-run first, then apply)

```bash
# 1. Run prep in dry-run mode — shows what will change, no side effects
./agency/tools/agency-migrate-prep

# 2. Review the diff. When satisfied:
./agency/tools/agency-migrate-prep --apply --yes
```

Prep creates:
- `v45.3-pre-reset-local` git tag (local rollback anchor — separate from the origin tag)
- `.agency/migrate-prep-v46.ok` marker (required by `agency update --migrate`)

Exit codes:

| Code | Meaning |
|------|---------|
| 0 | Prep complete |
| 10 | Prep marker already present (idempotent no-op; re-running is safe) |
| 11 | Sweep dry-run found unresolvable pattern (file an issue with the diagnostic) |
| 12 | Config update failed |
| 13 | Backup tag creation failed |

## Update

```bash
./agency/tools/agency-update-migrate --migrate
```

The `--migrate` flag is required — the tool refuses to run without explicit acknowledgement that this is a breaking migration.

Exit codes:

| Code | Meaning |
|------|---------|
| 0 | Migration complete |
| 10 | Refused — `--migrate` flag missing |
| 11 | Refused — prep marker missing, run `agency-migrate-prep` first |
| 12 | Mid-update integrity check failed |

## Verify

```bash
./agency/tools/agency-verify-v46 --customer
```

Exit 0 means all five structural checks pass. If non-zero, match the code to the table and act.

| Code | Check | Action |
|------|-------|--------|
| 10 | tree-shape mismatch (`claude/` still present OR `agency/` missing) | Re-run prep; investigate if prep says complete but check fails |
| 11 | settings.json references `/claude/hooks/` (stale v45 paths) | `sed -i '' 's\|/claude/hooks/\|/agency/hooks/\|g' .claude/settings.json` OR re-run prep |
| 12 | Agent registration uses `@claude/agents/` | `sed -i '' 's\|@claude/agents/\|@agency/agents/\|g' .claude/agents/**/*.md` OR re-run prep |
| 13 | ISCP smoke fails (agent-identity doesn't resolve) | Re-run `agency-migrate-prep` to refresh agent registration and re-derive identity |
| 14 | Hook path ENOENT — settings.json references a file that doesn't exist | Inspect the flagged path; confirm the sweep applied to it |

## Common failure modes

| Symptom | Diagnosis | Action |
|---------|-----------|--------|
| `Hook fire ENOENT claude/hooks/*.sh` | settings.json not rewritten | Re-run `agency-migrate-prep` OR manual: `sed -i '' 's\|/claude/hooks\|/agency/hooks\|g' .claude/settings.json` |
| `@import resolve error` at session start | `CLAUDE.md` `@import` stale | Manual: `sed -i '' 's\|@claude/\|@agency/\|g' CLAUDE.md` |
| `required_reading not found` when a skill runs | Skill frontmatter stale | Re-run prep OR `./agency/tools/agency-sweep --apply --files=.claude/skills/` |
| `agency-verify-v46 --customer` fails | Customer-side validator detected inconsistency | Run `agency-report` to generate diagnostic; file an issue |
| ISCP `dispatch list` errors | Agent registration path still v45 format | Re-run prep — updates `.claude/agents/**/*.md` `@import` headers |

## Rollback decision tree

| State | Mechanism | Preserved | NOT preserved |
|-------|-----------|-----------|---------------|
| Prep done, update not run | `rm .agency/migrate-prep-v46.ok` (plus `git reset --hard` if the sweep already ran against working tree) | Everything | Prep-side working-tree mutations if any |
| Update done, v46 not committed | `./agency/tools/agency-update-migrate-back` | `usr/` data, v45-format dispatches, and any v46-format dispatches rescued by the tool | Un-rescuable dispatches — flagged in `.agency/migrate-back-rescue-v46.log` with per-entry manual-action instructions |
| v46 committed locally, not pushed | `git reset --hard v45.3-pre-reset-local` | Git history up to pre-reset-local tag | Post-reset commits (including `usr/` edits) |
| v46 pushed | `git reset --hard v45.3-pre-reset` (origin tag) + `git push --force-with-lease origin master` | Git history up to pre-reset origin tag | Post-reset commits, any unpushed work |

## Post-migration dispatch rescue detail

`agency-update-migrate-back` includes explicit rescue for v46-format dispatches created between `--migrate` and rollback:

1. Scans for v46-format dispatches at `agency/workstreams/*/dispatch-*.md`
2. Renames surviving entries to v45-format paths
3. Writes rescue report at `.agency/migrate-back-rescue-v46.log`
4. Any un-rescuable entry (e.g., referenced a tool/path that only exists in v46) is listed in the log with manual-action instructions

**Dispatches are never silently lost.** Adopter reviews the log post-rollback and acts on any manual entries.

## Contact + report

If migration fails in ways not covered above:

```bash
./agency/tools/agency-report --output /tmp/my-v46-report.md
```

Then:

- Attach `/tmp/my-v46-report.md` to a GitHub issue at the-agency-ai/the-agency/issues, **OR**
- Send a cross-repo dispatch via `./agency/tools/collaboration send the-agency --subject "v46 migration failure" --body "$(cat /tmp/my-v46-report.md)"`

Support channel: `the-agency/captain` (cross-repo dispatch routing).

## Known captain-side issues (not adopter-blocking)

- **Phase 4 sweep residual misses (#195):** cosmetic comments + examples in a few framework tools retain v45 path references. No runtime impact on adopters.
- **Canary coverage gap (#350):** 6 of 42 hookify rules un-synthesizable by the current canary harness. Rules fire correctly at runtime; only test coverage is gapped.
- **`git-captain push` no-arg form (#196):** errors under `set -u` when invoked without an explicit remote + branch. Use `git-captain push origin <branch>`. Low priority.
