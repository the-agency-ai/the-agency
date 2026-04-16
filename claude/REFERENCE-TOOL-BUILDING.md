# Building Framework Tools

How to create tools for The Agency framework. Tools are bash scripts in `claude/tools/` that follow specific patterns for consistency and observability.

## Creating a New Tool

```bash
./claude/tools/tool-create <tool-name> "<description>"
```

This generates a tool from `claude/templates/TOOL.sh` with argument parsing, logging integration, and run ID tracking.

## Tool Structure

```bash
#!/bin/bash
# my-tool — Brief description
#
# What Problem: ...
# How & Why: ...
# Written: YYYY-MM-DD
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source helpers
if [[ -f "$SCRIPT_DIR/lib/_log-helper" ]]; then
    source "$SCRIPT_DIR/lib/_log-helper"
fi
if [[ -f "$SCRIPT_DIR/lib/_colors" ]]; then
    source "$SCRIPT_DIR/lib/_colors"
fi

# Tool version
TOOL_VERSION="1.0.0"

# Start tracking
RUN_ID=$(log_start "my-tool" "$@" 2>/dev/null) || true

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --help|-h) usage; exit 0 ;;
        --version) echo "my-tool $TOOL_VERSION"; exit 0 ;;
        --verbose|-v) VERBOSE=true; shift ;;
        *) shift ;;
    esac
done

# Do work...

# End tracking
log_end "$RUN_ID" "success" 0 0 "Completed" 2>/dev/null || true

# Output (context-efficient — 2-3 lines max)
echo "my-tool [run: $RUN_ID]"
echo "✓"
```

## Output Standard

Tools must minimize stdout to save context window tokens.

```bash
# stdout (what Claude sees) — 2-3 lines max
my-tool [run: abc123]
✓

# Everything else goes to log DB, not stdout
```

| Location | Content | Token Impact |
|----------|---------|--------------|
| stdout | 10-20 tokens | In context |
| Log DB | Full verbose output | Zero |

## Helpers

- `_log-helper` — JSONL logging, run tracking, `log_start`/`log_end`/`log_info`/`log_warn`/`log_error`
- `_colors` — terminal colors (`$RED`, `$GREEN`, `$YELLOW`, `$BLUE`, `$NC`)
- `_path-resolve` — principal resolution (`$USER` → `agency.yaml` → principal)

## Provenance Headers

Every tool has a What/How/Written provenance header:

```bash
# What Problem: <what this tool solves>
# How & Why: <approach and rationale>
# Written: YYYY-MM-DD during <context>
```

## Guards

Tools should validate inputs before acting:
- Block wildcards (`*`, `?`)
- Block path traversal (`..`)
- Block dangerous flags (`-A`, `--all`, `-rf`)
- Validate file existence before operating
- Die with clear error messages via `die()` function

## Related

- `claude/tools/tool-create` — scaffolding tool
- `claude/templates/TOOL.sh` — template
- `claude/REFERENCE-PROVENANCE-HEADERS.md` — header spec
- `claude/REFERENCE-TOOL-LOGGING-PATTERN.md` — logging details
