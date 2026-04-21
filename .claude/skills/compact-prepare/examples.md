# compact-prepare — examples

## Happy-path examples

### Clean tree, continuation handoff

```
/compact-prepare
```

Expected:
- No handoff-only pre-commit (Step 1 no-op, tree clean).
- session-pause runs, emits `status=ok`, `commit_sha=none`, `framing=continuation`.
- Skill authors new handoff at returned `handoff_path`, sets `mode: continuation`.
- Skill prints: branch, last commit, "Handoff: <path>", "Run `/compact` now."

### Dirty coord work only (handoff + dispatches)

```
/compact-prepare "mid-iteration refresh before QG"
```

Expected:
- Step 1 sees only coord files dirty → skips handoff-only commit.
- session-pause commits all coord files as `compact-prepare: <agent> coord checkpoint`.
- `commit_sha=<sha>`, `framing=continuation`.
- Handoff authored + directive printed.

## Edge-case examples

### Dirty handoff + dirty framework code (the 3.1a workaround case)

```
/compact-prepare
```

State: handoff.md edited AND claude/tools/some-tool.sh edited.

Expected:
- Step 1 detects both: stages handoff only, commits as `compact-prepare: persist handoff before framework-code QG gate`.
- Step 2 session-pause runs; sees framework code still dirty → aborts with `status=aborted`, `error_reason=framework code uncommitted: claude/tools/some-tool.sh`.
- Skill surfaces error_reason to user. **Handoff is persisted** (Step 1 saved it) even though overall PAUSE aborted.
- User runs `/quality-gate` + `/iteration-complete` on the framework code, then re-runs `/compact-prepare`.

### Lock contention

Another `/compact-prepare` or `/session-end` is running in a parallel shell on the same handoff.

Expected:
- session-pause returns exit 2 with `status=aborted`, `error_reason=lock timeout (5s)`.
- Skill waits a few seconds, retries. Or user kills the stale PID (error_reason gives the lock dir path).

## Integration examples

### Paired with /compact-resume

```
/compact-prepare              # PAUSE — writes continuation handoff
/compact                      # Claude Code built-in
/compact-resume               # PICKUP — reads handoff, verifies state, resumes next_action
```

### Mid-session vs end-of-session

| Scenario | Use |
|---|---|
| Context heavy, will keep working after /compact | `/compact-prepare` |
| Done for the day, will /exit | `/session-end` (not this skill) |
| Just came back from /compact | `/compact-resume` (not this skill) |
| Fresh session startup after /exit | `/session-resume` (not this skill) |
