# Tool Logging Pattern

## Overview

All Agency tools should follow this pattern to minimize context window usage while enabling debugging via the Log Service.

## Pattern

### 1. Source the log helper

```bash
#!/bin/bash
# tool-name - Description
set -e

SCRIPT_DIR="${SCRIPT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
if [[ -f "$SCRIPT_DIR/_log-helper" ]]; then
    source "$SCRIPT_DIR/_log-helper"
fi
RUN_ID=$(log_start "tool-name" "agency-tool" "$@" 2>/dev/null) || true
```

### 2. Add verbose flag and logging functions

```bash
# Parse arguments
VERBOSE=false
for arg in "$@"; do
    case $arg in
        --verbose)
            VERBOSE=true
            ;;
        *)
            # Other args
            ;;
    esac
done

# Logging functions
log_info() { [[ "$VERBOSE" == "true" ]] && echo -e "${GREEN}[INFO]${NC} $1" || true; }
log_warn() { [[ "$VERBOSE" == "true" ]] && echo -e "${YELLOW}[WARN]${NC} $1" || true; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }  # Always show errors
log_step() { [[ "$VERBOSE" == "true" ]] && echo -e "${BLUE}[STEP]${NC} $1" || true; }
verbose_echo() { [[ "$VERBOSE" == "true" ]] && echo "$@" || true; }
```

### 3. Show run ID and set trap

```bash
main() {
    # Trap unexpected exits
    trap 'log_end "$RUN_ID" "failure" $? 0 "Unexpected exit" 2>/dev/null || true' EXIT

    echo "tool-name [run: ${RUN_ID:-none}]"

    # ... tool logic ...
}
```

### 4. Call log_end at all exit points

```bash
# On error:
trap - EXIT  # Clear trap
log_end "$RUN_ID" "failure" 1 0 "Error description"
exit 1

# On success:
trap - EXIT  # Clear trap
log_end "$RUN_ID" "success" 0 0 "Success summary"
exit 0
```

### 5. Use verbose functions for detail output

```bash
# Replace:
echo "  Syncing file: $file"

# With:
verbose_echo "  Syncing file: $file"

# Replace:
echo "[INFO] Processing..."

# With:
log_info "Processing..."
```

## Output Behavior

### Default (Quiet)
```
tool-name [run: abc-123-def]
```

### With --verbose
```
tool-name [run: abc-123-def]
[INFO] Starting process
[STEP] Step 1: Initialize
  Processing item 1
  Processing item 2
[INFO] Complete
```

### On Error
```
tool-name [run: abc-123-def]
[ERROR] File not found: /path/to/file
```

## Debugging

Query the log service for run details:

```bash
# Get run details
curl -s "http://127.0.0.1:3141/api/log/run/get/abc-123-def" | jq

# Get only errors
curl -s "http://127.0.0.1:3141/api/log/run/errors/abc-123-def" | jq
```

## Benefits

1. **Reduced context window usage** - Only show summary by default
2. **Debugging capability** - Full details available via log service
3. **Consistent UX** - All tools follow same pattern
4. **Traceability** - Every run has a unique ID
5. **Error tracking** - Failed runs are logged for analysis

## Tools to Update

Priority order:
1. High-traffic tools (myclaude, commit, sync, tag, release)
2. Build tools (starter-release, starter-verify, project-create)
3. Utility tools (all others)

## Reference Implementation

See `tools/starter-release` for complete example.
