# The Agency v46.0 Migration Runbook — SKELETON (Phase 6 finalizes)

**Status:** SKELETON only. Phase 6 fills every section.

**For adopters** upgrading from v45.x to v46.0.

---

## Prep

```bash
# 1. Run prep (dry-run by default)
./agency/tools/agency-migrate-prep

# 2. Review the output, then apply
./agency/tools/agency-migrate-prep --apply --yes
```

Prep creates:
- `v45.3-pre-reset-local` git tag (local rollback anchor)
- `.agency/migrate-prep-v46.ok` marker (required by `agency update --migrate`)

Exit codes:
- 0: prep complete
- 10: prep marker already present (idempotent noop; re-running is safe)
- 11: sweep dry-run found unresolvable pattern (file a bug)
- 12: config update failed
- 13: backup tag creation failed

## Update

```bash
./agency/tools/agency-update-migrate --migrate
```

Exit codes:
- 0: migration complete
- 10: refused (missing `--migrate` flag)
- 11: refused (prep marker missing — run prep first)
- 12: mid-update integrity check failed

## Verify

```bash
./agency/tools/agency-verify-v46 --customer
```

Exit codes:
- 0: all checks passed
- 10: tree-shape mismatch (claude/ still present OR agency/ missing)
- 11: settings.json stale (references claude/hooks/)
- 12: agent registration path mismatch
- 13: ISCP smoke fail
- 14: hook path ENOENT

## Common failure modes

| Symptom | Diagnosis | Action |
|---|---|---|
| `Hook fire ENOENT claude/hooks/*.sh` | settings.json not rewritten | Re-run `agency-migrate-prep` OR manual sed: `sed -i 's|claude/hooks|agency/hooks|g' .claude/settings.json` |
| `@import resolve error` at session start | CLAUDE.md @import stale | Manual rewrite: `sed -i 's|@claude/|@agency/|g' CLAUDE.md` |
| `required_reading not found` in skill | Skill frontmatter stale | Re-run prep OR `agency-sweep --apply --files=.claude/skills/` |
| `agency-verify-v46 --customer` fails | Customer-side validator detects inconsistency | Run `agency-report` to dispatch diagnostic + auto-file issue |
| ISCP `dispatch list` errors | Agent registration path format v45 | Re-run prep to update `.claude/agents/**/*.md` @imports |

## Rollback decision tree

| State | Mechanism | Preserved | NOT preserved |
|---|---|---|---|
| Prep done, update not run | `rm .agency/migrate-prep-v46.ok` | Everything | (reverts prep cleanup in working tree if mutated) |
| Update done, v46 not committed | `agency-update-migrate-back` (includes **dispatch rescue**: scans v46-format dispatches at `agency/workstreams/*/dispatch-*.md`, renames to v45-format paths, writes rescue report at `.agency/migrate-back-rescue-v46.log`) | `usr/` data, v45-format dispatches + any v46 dispatches rescued by tool | Any un-rescuable **dispatches** flagged in rescue log — require manual action per log instructions |
| v46 committed locally, not pushed | `git reset --hard v45.3-pre-reset-local` | Git history up to pre-reset | Post-reset commits (including `usr/` edits) |
| v46 pushed | `git reset --hard v45.3-pre-reset` (origin tag) | Git history up to pre-reset origin | Post-reset commits + any unpushed work |

## Post-migration dispatch rescue detail

`agency-update-migrate-back` includes explicit rescue for v46-format dispatches
created between `--migrate` and rollback. Tool scans, renames, logs. Adopter
reviews `.agency/migrate-back-rescue-v46.log` post-rollback. Un-rescuable
entries are listed with manual-action instructions; **never silently lost**.

## Contact + report

If migration fails in ways not covered above:

```bash
./agency/tools/agency-report --output /tmp/my-v46-report.md
```

Then either:
- File a GitHub issue at the-agency-ai/the-agency with the output attached
- Or send a cross-repo dispatch via `./claude/tools/collaboration send`

Your support channel: `the-agency/captain` (cross-repo dispatch routing).
