# compact-resume — examples

## Happy-path example

### Clean resume after compact

```
/compact-resume
```

Expected:
- session-pickup emits `status=ok`, `handoff_mode=continuation`, `tree_state=clean`, all three monitor types either `ok` or `unknown`.
- Skill reports: branch, last commit, handoff mode, monitor summary ("3 ok / 0 dead / 0 unknown"), dispatch counts ("2 unread, 0 drift since PAUSE"), `next_action` verbatim.
- Agent resumes the `next_action`.

## Edge-case examples

### Dead monitors — re-launch on the fly

State after `/compact`: dispatch monitor registered but PID now stale (Claude Code restarted the subprocess, cmdline hash mismatched).

Expected:
- session-pickup emits `monitor_health_dispatch=dead`, `monitor_health_ci=ok`, `monitor_health_issue=unknown`.
- Skill Step 3: invokes `/monitor-dispatches` to re-launch the dispatch monitor.
- Report includes "Monitors: 2 ok / 0 dead (dispatch re-launched) / 1 unknown".
- Agent resumes.

### Dispatch drift since PAUSE

State: 3 dispatches arrived between `/compact-prepare`'s commit and this `/compact-resume`.

Expected:
- session-pickup emits `dispatches_unread=3`, `dispatches_drift_since_pause=3`.
- Skill Step 4: lists via `./claude/tools/dispatch list --status unread`.
- Report includes "Dispatches: 3 unread, 3 drifted since PAUSE — READ BEFORE RESUMING (unread dispatch = blocked person)."
- Agent reads the drifted dispatches, then resumes.

### Dirty tree → blocked

State: something mutated the working tree during/after compact (background hook, accidental edit).

Expected:
- session-pickup emits `status=blocked`, `tree_state=dirty`, `error_reason=working tree dirty — commit or stash before resuming`.
- Skill surfaces the error. Agent runs `git status --porcelain` to see what, commits or stashes, then re-runs `/compact-resume`.

### Missing handoff → aborted

State: no `/compact-prepare` before this — handoff file doesn't exist.

Expected:
- session-pickup emits `status=aborted`, `error_reason=handoff file missing at <path> — run session-pause first`.
- Skill surfaces. Agent runs `/compact-prepare` (if context is fresh enough) or accepts the loss and writes a handoff manually.

### Handoff mode drift

State: the handoff says `mode: resumption` (from a `/session-end` that never got a `/session-resume`, then somebody ran `/compact` and called this skill).

Expected:
- session-pickup emits `handoff_mode=resumption`, `status=ok`.
- Skill surfaces the mismatch: "Handoff mode is `resumption` (expected `continuation`). Use `/session-resume` instead for a fresh-session PICKUP, or continue here knowing the handoff was framed for a full restart."
- Agent decides.

### Legacy handoff (pre-refactor)

State: handoff uses `mode: resume` (the pre-refactor spelling).

Expected:
- session-pickup emits `handoff_mode=legacy` (migration tolerance per A&D §6).
- Skill notes the legacy mode; proceeds with resume. Agent can re-run `/compact-prepare` next time to upgrade the mode.

## Integration examples

### Paired with /compact-prepare

```
# ... working on a task, context heavy ...
/compact-prepare "mid-investigation refresh"
# report: handoff written, clean tree
/compact
# ... compact completes ...
/compact-resume
# report: mode=continuation, monitors ok, next_action="continue investigating the dispatch routing regression"
# ... agent resumes the investigation ...
```

### Contrast with /session-resume

| Scenario | Use |
|---|---|
| Just came back from `/compact` (same process) | `/compact-resume` — trimmed, skips sync + preflight |
| Just started a fresh session after `/exit` | `/session-resume` — full preflight + worktree-sync |
| Mid-session context refresh coming up | `/compact-prepare` — not this skill |
| End of day, shutting down | `/session-end` — not this skill |
