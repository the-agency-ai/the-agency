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

## Architecture: Service-First Design

The log service already tracks tool runs via `ToolRun`. External commands should extend this existing infrastructure rather than creating parallel systems.

### Extend Existing ToolRun

Add a `runType` field to distinguish:
- `tool` - Agency tools in `tools/`
- `command` - External commands (git, npm, etc.)

```typescript
// Extend existing ToolRun type
interface ToolRun {
  runId: string;
  tool: string;              // Tool name OR command name
  runType: 'tool' | 'command';  // NEW: Distinguish tool vs external command
  args?: string[];           // NEW: Command arguments (sanitized)
  status: 'running' | 'success' | 'failure';
  exitCode?: number;
  durationMs?: number;
  outputSize?: number;
  userId?: string;
  userType?: string;
  startedAt: Date;
  endedAt?: Date;
  summary?: string;
}
```

### Log Service Changes

**Repository (`log.repository.ts`):**
- Update `createToolRun` to accept `runType` and `args`
- Update `getToolStats` to filter/group by `runType`
- Add `getCommandStats` for command-specific analytics

**Routes (`log.routes.ts`):**
- Existing `/run/start` works - just pass `runType: 'command'`
- Add `/stats/commands` endpoint for command-specific stats
- Add filtering by `runType` to existing endpoints

**Schema (`types.ts`):**
- Add `runType` to `CreateToolRunRequest`
- Add `args` field (optional, sanitized)

### CLI Tool: `./tools/run`

Thin wrapper that:
1. Calls `log_start` with `runType=command`
2. Executes the command
3. Calls `log_end` with result
4. Returns original exit code

```bash
# Usage
./tools/run git status
./tools/run npm install
./tools/run -- complex-command --with-flags
```

### Extend `_log-helper`

Add `log_cmd_start` / `log_cmd_end` functions that set `runType=command`:

```bash
log_cmd_start() {
    local cmd="$1"
    shift
    # Same as log_start but with runType=command
    curl -s -X POST "$LOG_SERVICE_URL/api/log/run/start" \
        -H "Content-Type: application/json" \
        -d "{\"tool\":\"$cmd\",\"runType\":\"command\",\"args\":$(printf '%s\n' "$@" | jq -R . | jq -s .)}"
}
```

### Expose via `./tools/log`

Add commands to query command telemetry:

```bash
./tools/log commands           # Command usage stats
./tools/log commands git       # Stats for specific command
./tools/log commands --recent  # Recent command runs
```

---

## Privacy Considerations

- **Sanitize arguments:** Remove anything that looks like a secret (tokens, passwords, API keys)
- **Truncate long args:** Limit arg length to prevent bloat
- **No output capture:** Don't store stdout/stderr content (just size)
- **Optional opt-out:** Allow disabling with `--no-telemetry` or env var

---

## Success Criteria

**Service Layer:**
- [ ] Add `runType` and `args` to ToolRun schema
- [ ] Update repository to handle command runs
- [ ] Add `/stats/commands` endpoint
- [ ] Add filtering by runType to existing endpoints

**CLI Layer:**
- [ ] Create `./tools/run` wrapper
- [ ] Add `log_cmd_start`/`log_cmd_end` to `_log-helper`
- [ ] Add `./tools/log commands` subcommand

**Documentation:**
- [ ] Update CLAUDE.md with `./tools/run` usage
- [ ] Document when to instrument external commands

---

## Work Log

### 2026-01-14

- Created REQUEST

---

## Decisions

TBD
