---
type: ad
project: dispatch-monitor
workstream: agency
date: 2026-04-17
status: draft
author: the-agency/jordan/captain
pvr: agency/workstreams/agency/dispatch-monitor-pvr-20260417.md
---

# dispatch-monitor — Architecture & Design

## Overview

Drop-in Python 3.9+ rewrite of `agency/tools/dispatch-monitor`. Replaces bash script that uses bash 4+ features (`declare -A`) unavailable on macOS. First Python tool in the framework — sets the pattern.

## Architecture

### Component Model

```
dispatch-monitor (Python 3.9+, stdlib only)
  ├── main loop (poll, filter, emit)
  ├── seen_ids: set[int]          — in-memory, lost on restart (by design)
  ├── dispatch checker             — subprocess: ./agency/tools/dispatch list --status unread
  ├── collab checker (optional)    — subprocess: ./agency/tools/collaboration check
  └── stdout emitter               — line-buffered, [DISPATCH]/[COLLAB] prefixed
```

### Key Design Decisions

**1. seen_ids is in-memory only (not persistent).**
On restart, the monitor re-emits any currently-unread dispatches. This is correct — if the monitor crashed, the agent needs to see what's unread. The stale-read problem (#144) was dispatches re-surfacing within a single session due to query timing, not across restarts. Memory-only set solves this cleanly.

**2. Subprocess calls to existing bash tools.**
dispatch-monitor calls `dispatch list` and `collaboration check` as subprocesses. It does NOT reimplement their logic in Python. Those tools handle DB access, identity resolution, and formatting. This tool is purely a polling wrapper with deduplication.

**3. stdout is the event stream, stderr for diagnostics.**
The Monitor tool reads stdout lines as events. Diagnostic messages (startup, errors, polling status) go to stderr. This matches the Monitor tool contract.

**4. Line-buffered stdout.**
Python buffers stdout by default when not connected to a TTY (which is the case under Monitor). Must explicitly flush after every print or use `sys.stdout.reconfigure(line_buffering=True)` (Python 3.7+).

**5. No telemetry integration.**
Unlike most tools, dispatch-monitor is a long-running background process. Writing telemetry log_start/log_end per poll cycle would flood the log. Skip telemetry — the tool's value is in its stdout output, not its logs.

## Interface

```
Usage: dispatch-monitor [--interval N] [--include-collab] [--help]

Options:
  --interval N        Poll interval in seconds (default: 10)
  --include-collab    Also check cross-repo collaboration dispatches
  --help              Show this help
```

Identical to the bash version. Drop-in replacement.

## Implementation Details

### Main Loop

```python
seen_ids: set[int] = set()

while True:
    # 1. Run dispatch list --status unread
    output = run_dispatch_list()
    
    # 2. Parse output, extract IDs
    new_lines = []
    for line in output.splitlines():
        dispatch_id = extract_id(line)
        if dispatch_id and dispatch_id not in seen_ids:
            seen_ids.add(dispatch_id)
            new_lines.append(line)
    
    # 3. Emit if new
    if new_lines:
        print(f"[DISPATCH] {chr(10).join(new_lines)}", flush=True)
    
    # 4. Optional collab check
    if include_collab:
        collab_output = run_collab_check()
        collab_key = hash(collab_output[:80])
        if collab_output and collab_key not in seen_collab:
            seen_collab.add(collab_key)
            print(f"[COLLAB] {collab_output}", flush=True)
    
    # 5. Sleep
    time.sleep(interval)
```

### ID Extraction

Parse the first whitespace-delimited token from each line. If it's a digit string, it's a dispatch ID. Non-ID lines (headers, separators) are included with new dispatches but don't affect dedup.

### Signal Handling

```python
import signal

def shutdown(signum, frame):
    sys.exit(0)

signal.signal(signal.SIGINT, shutdown)
signal.signal(signal.SIGTERM, shutdown)
```

### Error Handling

Subprocess failures (dispatch tool not found, DB locked, permission error) are caught and silenced — `stderr` gets a diagnostic, but the loop continues. A transient failure shouldn't kill a session-length monitor.

```python
try:
    result = subprocess.run([...], capture_output=True, text=True, timeout=30)
except (subprocess.TimeoutExpired, FileNotFoundError, OSError) as e:
    print(f"dispatch-monitor: {e}", file=sys.stderr)
    # Continue polling — transient failures are expected
```

### Script Resolution

The dispatch tool path is resolved relative to the script's own location:

```python
SCRIPT_DIR = Path(__file__).resolve().parent
DISPATCH_TOOL = SCRIPT_DIR / "dispatch"
COLLAB_TOOL = SCRIPT_DIR / "collaboration"
```

## File Changes

| File | Change |
|------|--------|
| `agency/tools/dispatch-monitor` | Replace bash with Python (same path, new shebang) |
| `agency/REFERENCE-PROVENANCE-HEADERS.md` | Add Python tool guidance |

## Testing

- Verify Monitor tool integration (start, receive events, stop)
- Verify stale-read prevention (same ID not emitted twice)
- Verify silence when no dispatches
- Verify `--include-collab` flag
- Verify graceful handling of subprocess failures
- Verify SIGINT/SIGTERM clean shutdown

## What This Does NOT Cover

- Rewriting other tools in Python
- Adding pip/package management
- Persistent seen_ids across restarts
- Telemetry for the monitor itself
