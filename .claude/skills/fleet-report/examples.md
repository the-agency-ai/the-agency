# fleet-report — Examples

## Happy-path examples

### 1. Quiet fleet at session start

```
/fleet-report
```

Principal invokes at 08:00 after a quiet night. Output:

```
FLEET REPORT — 2026-04-19 08:00

HEALTH (from agency-health)
  Workstreams: 8 healthy, 0 attention, 0 warning, 0 critical
  Agents:      9 healthy, 0 attention
  Worktrees:   9 healthy, 1 attention (designex 2 behind main)
  Overall:     0 warnings, 0 critical  [exit 0]

PRs IN FLIGHT
  #299  D45-R2: agency update --prune safety   opened 1d ago, updated 4h ago
  #294  D45-R3: worktree-sync refactor         opened 6h ago, updated 1h ago

RECENT MERGES
  #213  D45-R1: Python 3.13 floor              merged 8h ago → v45.1

UNREAD DISPATCHES
  captain:     3 unread (oldest: 2d)   ← commit self-dispatches, low priority
  devex:       1 unread (oldest: 5h)

UNREAD FLAGS
  captain:     3 (newest: "agent-tool-create discussion")

STALE HANDOFFS
  (none)

RECENT COMMITS (per worktree)
  (main):      e4f666c5  housekeeping/captain: pre-session-end handoff
  devex:       (matches main)
  designex:    a1b2c3d4  misc: Figma token sync (2 behind main)
  …

CROSS-REPO
  partner-a:   2 unread (1 @designex, 1 @captain)

─────────
NEXT ACTIONS (captain inference)
  1. designex 2 behind main — sync-all will catch it up
  2. partner-a: 2 unread collab dispatches — review
  3. captain: 3 unread flags — run /flag-triage
```

### 2. Brief mode post-merge

```
/fleet-report --brief
```

Right after merging a release PR. Output:

```
Fleet is healthy. 2 PRs open (1 stale). 4 unread dispatches across 2 agents. No stale handoffs. v45.1 merged 8h ago (PR #213). Top action: run /flag-triage on captain's 3 unread flags.
```

### 3. JSON mode for status line

```
/fleet-report --json > /tmp/fleet-status.json
```

Feeds downstream consumer (status line, dashboard). Output is the full JSON schema (see `reference.md`).

## Edge-case examples

### 4. Fleet with critical health finding

Health check reports one critical: a worktree has `MERGE_HEAD` residue.

```
FLEET REPORT — 2026-04-19 14:23

HEALTH (from agency-health)
  Workstreams: 8 healthy
  Agents:      9 healthy
  Worktrees:   8 healthy, 1 critical (mdpal-cli MERGE_HEAD present)
  Overall:     0 warnings, 1 critical  [exit 2]

PRs IN FLIGHT
  …
─────────
NEXT ACTIONS (captain inference)
  1. mdpal-cli: MERGE_HEAD residue — resolve or abort before other work
  2. …
```

Principal sees the critical finding at the top of NEXT ACTIONS. Fleet-report does not auto-resolve; principal decides.

### 5. Stale PR older than 72h

```
PRs IN FLIGHT
  #231  misc: icon pass                       opened 4d ago, updated 3d ago  [stale]
```

Surfaces to NEXT ACTIONS as:

```
1. PR #231 stale for 3d — needs attention or close
```

### 6. No handoffs found (cold start)

Fresh install, no agent sessions yet. Handoff glob returns nothing.

```
STALE HANDOFFS
  (none — no agents with handoff files)
```

Non-error. The principal sees a clean fleet-report with "no handoffs" confirming the cold-start state.

### 7. `gh` unauthenticated

```
PRs IN FLIGHT
  (PRs: unable to fetch — gh error: "gh: authentication required")

RECENT MERGES
  (unable to fetch)
```

Report continues with all other sections populated. Principal sees the gap clearly and can run `gh auth login` to fix.

### 8. Cross-repo collab dir missing

Principal has not configured any collaboration repos.

```
CROSS-REPO
  (no configured collaboration repos)
```

Section present to confirm "this was checked, there's nothing." No error surfaced to principal; the skill understands this as a valid state.

## Integration examples

### 9. Called at session-resume Step 4

`/session-resume` could invoke `/fleet-report --brief` as its final step instead of the current "Report session state" paragraph. Both produce the same data; fleet-report is the consolidated form.

```
# Inside /session-resume Step 4 (future refactor)
Result = Skill(fleet-report, "--brief")
Present Result to user.
```

### 10. Called pre-release by captain

Before `/release`, captain invokes `/fleet-report` to confirm:
- No critical health findings
- No stale PRs that might block the release branch
- No unread dispatches that should be addressed before cutting

If fleet-report returns critical findings → captain pauses release, dispatches to affected agent, retries.

### 11. Called post-merge to confirm absorption

After `/post-merge` runs and `/sync-all` completes, captain invokes `/fleet-report` to verify:
- Every worktree is now synced (no "N behind main" > 0)
- Main branch merge is visible in all worktrees
- No new critical findings from the merge

Clean fleet-report = clean post-merge. Drift-findings = something didn't absorb.

### 12. Feeding status line via JSON

The status line (from `project_statusline_discussion.md` memory) could periodically invoke `/fleet-report --json` and render the `next_actions[0]` or a one-line severity summary. This makes fleet state visible at all times without the principal asking.
