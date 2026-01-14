# REQUEST-jordan-0051: External Command Telemetry

**Principal:** jordan
**Workstream:** housekeeping
**Agent:** captain
**Status:** New
**Priority:** Medium
**Created:** 2026-01-14

---

## Summary

Capture telemetry for commands that are NOT Agency tools (not in `tools/`). This enables understanding what external commands agents run, their success/failure rates, and performance characteristics.

---

## Rationale

Currently we track telemetry for Agency tools via `_log-helper`. However, agents also run many external commands:
- `git status`, `git commit`, `git push`
- `npm install`, `npm run build`, `npm test`
- `curl`, `python`, `node`
- Various CLI tools

Understanding these invocations helps with:
1. **Debugging** - Which command failed? What was the error?
2. **Performance** - Which commands are slow?
3. **Patterns** - What commands do agents use most?
4. **Optimization** - Can we pre-fetch or cache anything?

---

## What to Capture

| Field | Description |
|-------|-------------|
| `command` | The command name (e.g., `git`, `npm`) |
| `args` | Arguments passed (sanitized - no secrets) |
| `status` | Success or failure |
| `exit_code` | Exit code returned |
| `duration_ms` | How long the command took |
| `output_size` | Size of stdout/stderr |
| `agent` | Which agent ran it |
| `workstream` | Which workstream context |
| `run_id` | Unique identifier for the invocation |
| `timestamp` | When it was run |

---

## Implementation Options

### Option A: Bash Wrapper

Create a wrapper that instruments external commands:

```bash
# Usage: run git status
# Or:    run npm install

run() {
    local cmd="$1"
    shift
    local run_id=$(log_start "$cmd" "external-cmd" "$@")
    local start_time=$(date +%s%3N)

    "$cmd" "$@"
    local exit_code=$?

    local end_time=$(date +%s%3N)
    local duration=$((end_time - start_time))

    log_end "$run_id" "$([ $exit_code -eq 0 ] && echo success || echo failure)" "$exit_code" "$duration" ""
    return $exit_code
}
```

**Pros:** Simple, explicit, no magic
**Cons:** Requires agents to use `run` prefix

### Option B: Claude Code Hook

Use Claude Code hooks to instrument Bash tool calls:

```json
{
  "hooks": {
    "Bash": {
      "pre": "command that logs invocation start",
      "post": "command that logs invocation end"
    }
  }
}
```

**Pros:** Automatic, no code changes
**Cons:** Depends on Claude Code hook features

### Option C: Shell Trap

Use bash DEBUG trap to intercept all commands:

```bash
trap 'log_command "$BASH_COMMAND"' DEBUG
```

**Pros:** Captures everything
**Cons:** Performance overhead, may be too noisy

---

## Recommended Approach

Start with **Option A (Bash Wrapper)** as it's:
- Explicit and predictable
- No performance overhead on non-instrumented commands
- Easy to understand and debug
- Can be gradually adopted

Create `./tools/run` that:
1. Captures command and args
2. Calls `log_start` with command info
3. Executes the actual command
4. Captures exit code and duration
5. Calls `log_end` with results
6. Returns the original exit code

---

## Log Service Changes

### New Types

```typescript
interface ExternalCommandRun {
  runId: string;
  command: string;
  args: string[];
  status: 'running' | 'success' | 'failure';
  exitCode?: number;
  durationMs?: number;
  outputSize?: number;
  agent?: string;
  workstream?: string;
  startedAt: Date;
  endedAt?: Date;
}
```

### New Endpoints

```
POST /api/log/cmd/start   - Start external command run
POST /api/log/cmd/end     - End external command run
GET  /api/log/cmd/stats   - External command statistics
GET  /api/log/cmd/get/:id - Get command run details
```

---

## Privacy Considerations

- **Sanitize arguments:** Remove anything that looks like a secret (tokens, passwords, API keys)
- **Truncate long args:** Limit arg length to prevent bloat
- **No output capture:** Don't store stdout/stderr content (just size)
- **Optional opt-out:** Allow disabling with `--no-telemetry` or env var

---

## Success Criteria

- [ ] `./tools/run` wrapper created
- [ ] Log service endpoints added
- [ ] Statistics exposed via `./tools/log cmds`
- [ ] Documentation updated
- [ ] Pattern documented in CLAUDE.md (when to use `run`)

---

## Work Log

### 2026-01-14

- Created REQUEST

---

## Decisions

TBD
