#!/bin/bash
# {{TOOL_NAME}} - {{TOOL_DESCRIPTION}}
#
# Usage:
#   ./tools/{{TOOL_NAME}} [options]
#
# This tool uses context-efficient logging:
# - Logs details to log-service
# - Returns single-line output
# - Use --verbose for immediate output
# - On failure: ./tools/agency-service log run <run-id> errors

set -e

# Tool version (semver-build, build is monotonically increasing)
TOOL_VERSION="1.0.0-{{BUILD_NUMBER}}"

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Parse arguments
VERBOSE=false
while [[ $# -gt 0 ]]; do
    case $1 in
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
        --version)
            echo "{{TOOL_NAME}} $TOOL_VERSION"
            exit 0
            ;;
        --help|-h)
            echo "{{TOOL_NAME}} - {{TOOL_DESCRIPTION}}"
            echo ""
            echo "Usage:"
            echo "  ./tools/{{TOOL_NAME}} [options]"
            echo ""
            echo "Options:"
            echo "  --verbose, -v  Show detailed output instead of logging"
            echo "  --version      Show version"
            echo "  --help, -h     Show this help"
            exit 0
            ;;
        *)
            shift
            ;;
    esac
done

# Logging helpers
log() {
    local level="$1"
    local message="$2"
    local data="$3"

    if [[ "$VERBOSE" == "true" ]]; then
        echo "[$level] $message"
    elif [[ -n "$RUN_ID" ]]; then
        local json="{\"service\":\"{{TOOL_NAME}}\",\"level\":\"$level\",\"message\":\"$message\",\"runId\":\"$RUN_ID\""
        if [[ -n "$data" ]]; then
            json="$json,\"data\":$data"
        fi
        json="$json}"
        curl -s -X POST "http://127.0.0.1:3141/api/log" \
            -H "Content-Type: application/json" \
            -d "$json" > /dev/null 2>&1 || true
    fi
}

log_info() { log "info" "$1" "$2"; }
log_warn() { log "warn" "$1" "$2"; }
log_error() { log "error" "$1" "$2"; }

# Start tool run (returns run-id for logging)
start_run() {
    if [[ "$VERBOSE" == "true" ]]; then
        RUN_ID=""
        return
    fi

    RUN_ID=$(curl -s -X POST "http://127.0.0.1:3141/api/log/run" \
        -H "Content-Type: application/json" \
        -d "{\"tool\":\"{{TOOL_NAME}}\"}" 2>/dev/null | grep -o '"runId":"[^"]*"' | cut -d'"' -f4 || true)
}

# End tool run
end_run() {
    local status="$1"
    local summary="$2"

    if [[ "$VERBOSE" == "true" ]]; then
        return
    fi

    if [[ -n "$RUN_ID" ]]; then
        curl -s -X POST "http://127.0.0.1:3141/api/log/run/${RUN_ID}/end" \
            -H "Content-Type: application/json" \
            -d "{\"status\":\"$status\",\"summary\":\"$summary\"}" > /dev/null 2>&1 || true
    fi
}

# Output result (single line)
output_success() {
    local message="$1"
    if [[ -n "$RUN_ID" ]]; then
        echo "SUCCESS: $message (run-id: $RUN_ID)"
    else
        echo "SUCCESS: $message"
    fi
}

output_failure() {
    local message="$1"
    if [[ -n "$RUN_ID" ]]; then
        echo "FAILURE: $message (run-id: $RUN_ID)"
        echo "  Debug: ./tools/agency-service log run $RUN_ID errors"
    else
        echo "FAILURE: $message"
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# Main tool logic
# ─────────────────────────────────────────────────────────────────────────────

main() {
    # Start logging run
    start_run

    log_info "Starting {{TOOL_NAME}}"

    # TODO: Add your tool logic here
    # Example:
    # log_info "Processing step 1"
    # if ! do_step_1; then
    #     log_error "Step 1 failed"
    #     end_run "failure" "Step 1 failed"
    #     output_failure "Step 1 failed"
    #     exit 1
    # fi

    # Success
    log_info "{{TOOL_NAME}} completed successfully"
    end_run "success" "Completed"
    output_success "{{TOOL_NAME}} completed"
}

main "$@"
