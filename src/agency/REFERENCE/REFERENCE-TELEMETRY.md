## Telemetry

### Dual Approach

The Agency provides two complementary telemetry systems:

1. **agency-service (`_log-helper`)** — structured logs sent to the agency-service backend. Queryable, real-time, supports dashboards.
2. **JSONL hooks** — lightweight file-based logging. Local, offline, good for analysis.

### Configuration

In `agency/config/agency.yaml`:

```yaml
telemetry:
  providers: ["log-helper", "jsonl"]
```

### agency-service

Tools source `_log-helper` which sends structured JSON to the agency-service:

```bash
source "$SCRIPT_DIR/_log-helper"
RUN_ID=$(log_start "tool-name" "tool-type" "$@")
# ... do work ...
log_end "$RUN_ID" "success" $? $OUTPUT_SIZE "summary" "output"
```

- Default endpoint: `http://127.0.0.1:3141`
- Silent failure — never blocks tool execution
- Supports: tool invocations, session starts/stops, errors

### JSONL Hooks

The `tool-telemetry.sh` hook logs every tool invocation to `~/.claude/telemetry/<YYYY-MM-DD>.jsonl`:

```json
{"ts": "2026-03-29T10:00:00Z", "session": "abc", "tool": "Bash", "input_summary": "git status", "branch": "main"}
```

- One file per day
- Append-only
- Safe input summaries (no file content, just paths/commands)
- Good for: friction analysis, tool usage patterns, session profiling

### Principles

- Telemetry is **additive** — never blocks, never breaks
- Both systems coexist — they serve different purposes
- Privacy-respecting: no file contents, no secrets, no PII in summaries
