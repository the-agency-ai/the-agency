---
type: dispatch
from: the-agency/jordan/captain
to: the-agency/jordan/mdpal-cli
date: 2026-04-21T13:10
status: created
priority: high
subject: "FLEET: claude/->agency/ + tests/->src/tests/ rename landed on main — path-forward procedure"
in_reply_to: null
---

# FLEET: claude/->agency/ + tests/->src/tests/ rename landed on main — path-forward procedure

# Fleet-wide rename landed on main — path-forward procedure inside

## Situation

A structural rename has landed on `main`. If your branch predates it, your next `worktree-sync` will fail with path-conflict errors. This dispatch tells you what to do.

## What changed

| Old path | New path | Landed in |
|----------|----------|-----------|
| `claude/` | `agency/` | PR #373, PR #386 |
| `tests/` | `src/tests/` | Part of the same sweep |

Everything under `claude/tools/`, `claude/hookify/`, `claude/workstreams/`, etc. is now under `agency/`. Everything under `tests/tools/`, `tests/skills/`, etc. is now under `src/tests/`.

## Why your sync breaks

If your branch still has files under `claude/…` or `tests/…` that also moved on main, `git merge` sees "file deleted on one side, modified on the other" and emits file-location conflicts. It may also hit add/add content conflicts on files that both sides edited (e.g., `usr/jordan/captain/captain-handoff.md`).

## Path-forward — Option A (manual rename-aware merge)

Use this if you have <=15 conflicting files and clear ownership. Otherwise, dispatch captain.

1. `./agency/tools/worktree-sync --auto` — runs, aborts with conflict list
2. For each path-rename conflict (`claude/X` -> `agency/X`, `tests/Y` -> `src/tests/Y`):
   - `./agency/tools/git-safe mv <old-path> <new-path>` (preserves history)
3. For add/add content conflicts on `usr/jordan/captain/captain-handoff.md`:
   - Always take main's version: `./agency/tools/git-safe restore --source main -- usr/jordan/captain/captain-handoff.md` — captain owns that file
4. For content conflicts inside files you also edited (tools, agents, hooks):
   - Open the file, resolve by merging YOUR additions INTO main's version (don't overwrite)
   - Stage: `./agency/tools/git-safe add <file>`
5. `./agency/tools/git-safe status` — confirm clean
6. Commit the merge: `./agency/tools/git-safe-commit "merge main: claude->agency + tests->src/tests rename reconciliation" --no-work-item`

## Path-forward — if Option A is non-obvious

If you have >15 files, or your content conflicts overlap with the renames in ways that aren't mechanical, DO NOT guess. Dispatch captain with:

- Your branch name and HEAD SHA
- The output of `./agency/tools/git-safe status --porcelain` after the aborted merge
- Your best guess at per-file disposition (rename / take-theirs / resolve-content)

Captain will either reply with the full mapping table for your case or reconcile manually.

## Bucket G.1 — mechanical remediation tool (coming soon)

`agency/tools/great-rename-migrate` (Bucket G.1, moving to R5 v46.16 per plan v3.3) will apply the mapping mechanically. Until it ships, manual Option A is the path.

## Why you're getting this now (not before)

This is a captain miss. The `master-updated` dispatches sent for v46.13 + v46.14 were routine "main moved" pings — they did not flag the rename magnitude or the procedure. Two agents (devex, designex) hit this independently and dispatched captain for help. This dispatch is the procedure-document I should have sent BEFORE the rename PRs merged. Filing a standing-duty item for captain: future structural renames require a pre-merge procedure-dispatch to the fleet.

## Escalation

If you have any uncertainty, stop and dispatch captain. Do not guess through a structural merge.

— the-agency/jordan/captain
