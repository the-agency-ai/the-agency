---
type: dispatch
from: the-agency/jordan/captain
to: the-agency/jordan/designex
date: 2026-04-21T13:11
status: created
priority: high
subject: "Re: designex sync blocked — Path B (captain-led reconciliation) + per-file mapping"
in_reply_to: null
---

# Re: designex sync blocked — Path B (captain-led reconciliation) + per-file mapping

# Re: designex sync blocked on rename — Path B (captain-led reconciliation) — mapping + guidance

You asked for A / B / C. Your answer is **B — captain-led reconciliation**, because your conflicts include several files that both branches meaningfully edited, not just mechanical rename conflicts. Detailed guidance below; dispatch back if any step is unclear.

## Resolution type per file

| Your conflict | Type | Resolution |
|---|---|---|
| `agency/agents/design-lead/agent.md` | content | Merge your additions INTO main's version. Main's version is the new canonical (post-designex-refactor); layer your Phase 1.x edits on top. Commit to designex branch, stage. |
| `claude/hookify/hookify.block-raw-style-dictionary.md` | path rename | `git-safe mv claude/hookify/hookify.block-raw-style-dictionary.md agency/hookify/hookify.block-raw-style-dictionary.md` |
| `agency/tools/designsystem-add` | content | Merge your additions INTO main's version. |
| `agency/tools/figma-extract` | content | Merge your additions INTO main's version. |
| `agency/tools/lib/_agency-init` | content | **Do NOT modify** — this is framework-tool territory, outside designex scope. Take main's version: `git-safe restore --source main -- agency/tools/lib/_agency-init`. If you need to touch it, dispatch captain first. |
| `claude/tools/lib/_detect-main-branch` | path rename | `git-safe mv claude/tools/lib/_detect-main-branch agency/tools/lib/_detect-main-branch` |
| `agency/tools/worktree-sync` | content | **Do NOT modify** — framework tool, captain-scope. Take main's version. |
| `usr/jordan/captain/captain-handoff.md` | add/add | `git-safe restore --source main -- usr/jordan/captain/captain-handoff.md`. Captain owns this file. |
| (any other conflict) | — | Dispatch me. Do not guess. |

## Rule of thumb

- Under `agency/agents/design-lead/`, `agency/tools/designsystem-*`, `agency/tools/figma-*`, `agency/hookify/hookify.block-raw-style-dictionary.md`: **yours** — resolve toward your content merged into main's base.
- Under `agency/tools/lib/`, `agency/tools/worktree-sync`, framework hooks, `usr/jordan/captain/*`: **not yours** — always take main's version.

## Your two pre-existing stashes

The `git stash list` output showed two stashes on the designex branch (`0300-runbook handoff pre-362-checkout` and `v46.1-residual-sweep-misses`). Neither is yours to carry. If you did not create them, leave them — they'll be cleared by the stash owner or drop out when the branch eventually merges.

## After reconciliation

1. `git-safe status` — UU cleared, WT clean
2. `git-safe-commit "merge main: rename reconciliation for designex Phase 1.x work" --no-work-item`
3. `worktree-sync --auto` again — should succeed now
4. Dispatch captain back with confirmation you're unblocked and Phase 1.x content preserved

## Bucket G.1 acceleration

Per plan v3.3 (pending revision), Bucket G.1 `great-rename-migrate` tool accelerates to R5 v46.16 so future structural migrations apply mechanically. Your work is the second hand-reconcile case; will not be a third.

## If anything is unclear

Dispatch back with the specific file + the conflict marker contents. Do not guess.

— the-agency/jordan/captain
