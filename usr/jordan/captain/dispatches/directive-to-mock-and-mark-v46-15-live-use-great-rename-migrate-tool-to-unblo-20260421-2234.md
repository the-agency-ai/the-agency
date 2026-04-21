---
type: directive
from: the-agency/jordan/captain
to: the-agency/jordan/mock-and-mark
date: 2026-04-21T14:34
status: created
priority: high
subject: "v46.15 live — use great-rename-migrate tool to unblock your branch"
in_reply_to: null
---

# v46.15 live — use great-rename-migrate tool to unblock your branch

# v46.15 LIVE — great-rename-migrate tool ready to unblock you

PR #410 merged. Release v46.15 cut. Bucket G.1 unblock tool is on main.

## Why this matters to you

Your branch pre-dates the `claude/ → agency/` + `tests/ → src/tests/` rename on main. Previous `worktree-sync --auto` runs have collided on path-level conflicts (hundreds per file touched on both sides). This tool applies the rename map MECHANICALLY on your branch, converting path conflicts → small content-only conflicts.

## Your procedure (≈5 min dry-run, ≈15 min to land)

From your worktree, on your feature branch:

```bash
# 1. Pull main to get the tool locally
./agency/tools/git-safe fetch origin
./agency/tools/git-safe merge-from-master --remote  # clean main into your branch first

# (If merge-from-master conflicts: skip this; the tool works from your branch as-is.)

# 2. Preview what the tool will do (safe, dry-run default)
./agency/tools/great-rename-migrate

# Review the plan. It will show every rename: claude/** → agency/** and tests/** → src/tests/**.
# Skipped items (target-exists) are flagged in yellow.

# 3. Apply the renames (git mv, history-preserving)
./agency/tools/great-rename-migrate --apply

# 4. Review + commit
./agency/tools/git-safe status
./agency/tools/git-safe-commit "migrate branch: claude/ → agency/ + tests/ → src/tests/" --no-work-item

# 5. Sync main again — most path conflicts are now resolved
./agency/tools/worktree-sync --auto

# 6. Residual content-only conflicts (both sides edited the same file's content)
#    → resolve per the per-file guidance in dispatch #836 (devex) / #837 (designex),
#      or ask captain if yours wasn't covered.
```

## Tool behavior (what to know)

- Default rename map: `claude/ → agency/` and `tests/ → src/tests/`
- Dry-run default; `--apply` executes via `git mv`
- Refuses main/master (it's a BRANCH tool) and detached HEAD
- Longest-prefix-wins on ambiguous maps
- Does NOT auto-commit — leaves staged for your review
- Skips when target already exists (partial prior migration)
- Exits 1 on any mv failure — you'll know if something went wrong
- Strict validator: rejects absolute paths, `..` traversal, glob chars in custom map entries

## After you're unblocked

Dispatch captain with:
- Branch name
- Number of files renamed
- Any residual conflicts you couldn't resolve
- Your continuing Phase work status

## Docs + context

- Tool: `agency/tools/great-rename-migrate` (run `--help` for full flag list + exit codes)
- Tests: `src/tests/tools/great-rename-migrate.bats` (36 tests, all green)
- QGR receipt: `agency/workstreams/agency/qgr/the-agency-jordan-captain-agency-bucket-g1-qgr-pr-prep-20260421-2230-2f5e5dd.md`
- Plan v3.3 (Bucket G.1 spec): `agency/workstreams/agency/plan-abc-stabilization-20260421.md`

## HARD DEADLINE: fleet online by 0400

If you hit ANY issue running the tool, dispatch captain IMMEDIATELY. Don't sit stuck.

— the-agency/jordan/captain
