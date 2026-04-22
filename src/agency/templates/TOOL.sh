#!/usr/bin/env bash
# What Problem: {{TOOL_DESCRIPTION}}
#
# How & Why: [Explain the approach and rationale]
#
# Usage:
#   ./agency/tools/{{TOOL_NAME}} [options] <args>
#
# Written: {{TOOL_DATE}} by {{TOOL_AUTHOR}}

set -euo pipefail

# ── Tool metadata ────────────────────────────────────────────────────────────
TOOL_VERSION="1.0.0-{{BUILD_NUMBER}}"
TOOL_NAME="{{TOOL_NAME}}"

# ── Path resolution ──────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# ── Colors (for terminal output) ─────────────────────────────────────────────
if [[ -f "$SCRIPT_DIR/lib/_colors" ]]; then
    source "$SCRIPT_DIR/lib/_colors"
else
    RED="\033[0;31m"; GREEN="\033[0;32m"; YELLOW="\033[1;33m"; NC="\033[0m"
fi

# ── Telemetry ────────────────────────────────────────────────────────────────
# Source _log-helper for structured JSONL logging to .claude/logs/tool-runs.jsonl.
# Functions available after sourcing:
#   log_start "tool-name" "$@"  → returns RUN_ID (UUID7)
#   log_end "$RUN_ID" "success|failure" $exit_code $duration_ms "summary"
#   log_detail "$RUN_ID" "channel" "content"
#   tool_output "tool-name" "$RUN_ID" "result text" "icon"
#
# When _log-helper is unavailable (e.g., standalone use outside the framework),
# the tool still works — it just skips telemetry.
RUN_ID=""
if [[ -f "$SCRIPT_DIR/lib/_log-helper" ]]; then
    source "$SCRIPT_DIR/lib/_log-helper"
    RUN_ID=$(log_start "$TOOL_NAME" "$@" 2>/dev/null) || true
fi

# ── Helpers ──────────────────────────────────────────────────────────────────

# die "message" [exit_code]
# Print an error, log failure telemetry, and exit.
die() {
    local msg="$1"
    local code="${2:-1}"
    echo -e "${RED}ERROR:${NC} $msg" >&2
    if [[ -n "$RUN_ID" ]]; then
        log_end "$RUN_ID" "failure" "$code" 0 "$msg" 2>/dev/null || true
    fi
    exit "$code"
}

# info "message" — print to stderr when verbose, log to telemetry always
info() {
    if [[ "$VERBOSE" == "true" ]]; then
        echo -e "${GREEN}[INFO]${NC} $1" >&2
    fi
    if [[ -n "$RUN_ID" ]]; then
        log_detail "$RUN_ID" "info" "$1" 2>/dev/null || true
    fi
}

# warn "message" — always print to stderr, log to telemetry
warn() {
    echo -e "${YELLOW}[WARN]${NC} $1" >&2
    if [[ -n "$RUN_ID" ]]; then
        log_detail "$RUN_ID" "warn" "$1" 2>/dev/null || true
    fi
}

# ── Cleanup trap ─────────────────────────────────────────────────────────────
# Catches unexpected exits (set -e failures, signals). Ensures log_end is
# always called so telemetry records don't have orphaned starts.
_cleanup() {
    local exit_code=$?
    if [[ $exit_code -ne 0 && -n "$RUN_ID" ]]; then
        log_end "$RUN_ID" "failure" "$exit_code" 0 "Unexpected exit" 2>/dev/null || true
    fi
}
trap _cleanup EXIT

# ── Argument parsing ─────────────────────────────────────────────────────────
VERBOSE=false

# Collect positional args separately from flags
POSITIONAL_ARGS=()

while [[ $# -gt 0 ]]; do
    case $1 in
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
        --version)
            echo "$TOOL_NAME $TOOL_VERSION"
            exit 0
            ;;
        --help|-h)
            cat <<HELP
$TOOL_NAME - {{TOOL_DESCRIPTION}}

Usage:
  ./agency/tools/$TOOL_NAME [options] <args>

Options:
  --verbose, -v  Show detailed output (default: log to telemetry DB)
  --version      Show version
  --help, -h     Show this help

Examples:
  ./agency/tools/$TOOL_NAME --verbose arg1
  ./agency/tools/$TOOL_NAME arg1 arg2
HELP
            exit 0
            ;;
        --)
            shift
            POSITIONAL_ARGS+=("$@")
            break
            ;;
        -*)
            die "Unknown option: $1 (use --help for usage)"
            ;;
        *)
            POSITIONAL_ARGS+=("$1")
            shift
            ;;
    esac
done

# ── Main logic ───────────────────────────────────────────────────────────────

main() {
    local start_time
    start_time=$(date +%s)

    # --- Your tool logic here ---
    #
    # Access positional args: "${POSITIONAL_ARGS[0]}", "${POSITIONAL_ARGS[1]}", etc.
    # Required arg example:
    #   [[ ${#POSITIONAL_ARGS[@]} -ge 1 ]] || die "Missing required argument: <name>"
    #   local name="${POSITIONAL_ARGS[0]}"
    #
    # Use info/warn/die for output:
    #   info "Processing $name..."       # visible only with --verbose
    #   warn "File already exists"       # always visible
    #   die "Cannot find config" 1       # prints error + exits
    #
    # Log details for post-mortem (always captured, never printed):
    #   [[ -n "$RUN_ID" ]] && log_detail "$RUN_ID" "stdout" "$output"

    info "Starting $TOOL_NAME"

    # TODO: Replace with your implementation

    info "Done"

    # --- End of tool logic ---

    # ── Success output ───────────────────────────────────────────────────────
    # Tool output standard: 2-3 lines max. Details go to telemetry.
    local end_time duration_ms
    end_time=$(date +%s)
    duration_ms=$(( (end_time - start_time) * 1000 ))

    if [[ -n "$RUN_ID" ]]; then
        log_end "$RUN_ID" "success" 0 "$duration_ms" "$TOOL_NAME completed"
        tool_output "$TOOL_NAME" "$RUN_ID" "$TOOL_NAME completed"
    else
        echo "$TOOL_NAME"
        echo "$TOOL_NAME completed"
        echo "done"
    fi

    # Clear the trap — we logged success explicitly
    trap - EXIT
}

main
