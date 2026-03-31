#!/bin/bash
# {{TOOL_NAME}} - {{TOOL_DESCRIPTION}}
#
# Usage:
#   ./claude/tools/{{TOOL_NAME}} [options]
#
# This tool uses context-efficient logging:
# - Logs details to .claude/logs/tool-runs.jsonl
# - Returns single-line output
# - Use --verbose for immediate output

set -euo pipefail

# Tool version (semver-build, build is monotonically increasing)
TOOL_VERSION="1.0.0-{{BUILD_NUMBER}}"

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source log helper for telemetry
if [[ -f "$SCRIPT_DIR/lib/_log-helper" ]]; then
    source "$SCRIPT_DIR/lib/_log-helper"
fi
RUN_ID=""
if type log_start &>/dev/null; then
    RUN_ID=$(log_start "{{TOOL_NAME}}" "$@")
fi

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
            echo "  ./claude/tools/{{TOOL_NAME}} [options]"
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

# ─────────────────────────────────────────────────────────────────────────────
# Main tool logic
# ─────────────────────────────────────────────────────────────────────────────

main() {
    # TODO: Add your tool logic here

    # Success output (tool output standard)
    if [[ -n "$RUN_ID" ]]; then
        log_end "$RUN_ID" "success" 0 0 "Completed"
        tool_output "{{TOOL_NAME}}" "$RUN_ID" "{{TOOL_NAME}} completed"
    else
        echo "{{TOOL_NAME}}"
        echo "{{TOOL_NAME}} completed"
        echo "✓"
    fi
}

main "$@"
