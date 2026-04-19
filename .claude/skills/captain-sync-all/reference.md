# captain-sync-all — unique protocol

## Recovery tag convention

Before any master merge, Step 3 tags the pre-merge state:

```
git tag sync/pre-merge-YYYYMMDD-HHMMSS
```

These tags accumulate but are cheap (just refs). Captain can prune manually if needed. Tag enables roll-back if the subsequent merge goes sideways:

```
git reset --hard sync/pre-merge-YYYYMMDD-HHMMSS  # ONLY before the merge is pushed anywhere
```

**Never roll back after a push / after any worktree has picked up the merge.** At that point the merge is shared history.

## Worktree merge order

Step 5 merges each worktree's work into master SEQUENTIALLY. Order: whatever `git worktree list` returns (typically alphabetical by path). If worktree A introduces conflicts with worktree B when both merge into master, captain resolves A first (as it appears first), then B's merge may conflict against A's newly-merged content.

This is rare because worktree agents work in different workstream directories. When it happens, captain holds 1B1 with the two agents about which should land first.

## `main-updated` dispatch semantics

Sent to every worktree agent after a merge in Step 5. The dispatch type is `main-updated` (legacy name; some docs call it `master-updated`). Agents' `/session-resume` checks for unread dispatches and surfaces the notification.

The dispatch itself is lightweight: just "main-updated, merged X from branch Y." Agents pick up the actual content via `git merge master` (Step 6 of this skill propagates it automatically) or on their next `/session-resume`.

## Step 6 failure semantics

If a worktree's `git merge master` (Step 6) fails with conflict:

- The worktree is left with unresolved conflict markers.
- Skill reports it as NOT synced.
- Agent resolves on their next `/session-resume` via `worktree-sync --auto` or manual conflict resolution.
- Captain does NOT resolve agent conflicts (that's their workstream; they know their content).

## Invocation from `/pr-captain-post-merge`

When `/pr-captain-post-merge` runs as part of PR land flow, it invokes `/captain-sync-all` at Step 5. In that composition:

- Steps 1-2 are fast (captain already clean on master).
- Step 3 merge-from-origin picks up the just-merged PR.
- Steps 4-7 propagate to fleet.
- Step 8 (handoff) is included.

## Frequency

Captain runs `/captain-sync-all` at:

- **Session start** — to reconcile with any overnight/external PR merges.
- **After each PR land** (automatic via `/pr-captain-post-merge`).
- **Session end** — optional; ensures next session starts clean.
- **On demand** when captain notices worktree drift (agent reports "merge conflict on session-resume").

Typical frequency: 2-5x per active captain session.
