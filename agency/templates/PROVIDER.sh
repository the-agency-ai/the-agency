#!/bin/bash
# {{TOOL_NAME}} — {{TOOL_DESCRIPTION}}
#
# Provider for the {{PROVIDER_PATTERN}} plugin pattern.
# Dispatched via: ./claude/tools/{{DISPATCHER_NAME}}
#
# Usage:
#   ./claude/tools/{{TOOL_NAME}} <verb> [args...]
#
# Standard verbs:
#   set <name> [value]   Store/create an item
#   get <name>           Retrieve an item
#   list                 List all items
#   delete <name>        Remove an item
#
# This tool follows the Agency token-conservation pattern:
#   - Minimal stdout (tool name, result, checkmark)
#   - Verbose output to .claude/logs/tool-runs.jsonl

set -euo pipefail

# Tool version (semver-build, build is monotonically increasing)
TOOL_VERSION="1.0.0-{{BUILD_NUMBER}}"

# Configuration
SCRIPT_DIR="${SCRIPT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source helpers
if [[ -f "$SCRIPT_DIR/lib/_log-helper" ]]; then
    source "$SCRIPT_DIR/lib/_log-helper"
fi
RUN_ID=""
if type log_start &>/dev/null; then
    RUN_ID=$(log_start "{{TOOL_NAME}}" "$@")
fi

# Parse global flags
VERBOSE=false
ARGS=()
for arg in "$@"; do
    case "$arg" in
        --verbose|-v) VERBOSE=true ;;
        --version)    echo "{{TOOL_NAME}} $TOOL_VERSION"; exit 0 ;;
        --help|-h)
            echo "{{TOOL_NAME}} — {{TOOL_DESCRIPTION}}"
            echo ""
            echo "Usage: ./claude/tools/{{TOOL_NAME}} <verb> [args...]"
            echo ""
            echo "Verbs:"
            echo "  set <name> [value]   Store/create an item"
            echo "  get <name>           Retrieve an item"
            echo "  list                 List all items"
            echo "  delete <name>        Remove an item"
            echo ""
            echo "Options:"
            echo "  --verbose, -v  Show detailed output"
            echo "  --version      Show version"
            echo "  --help, -h     Show this help"
            exit 0
            ;;
        *) ARGS+=("$arg") ;;
    esac
done

VERB="${ARGS[0]:-}"
shift_args=()
(( ${#ARGS[@]} > 1 )) && shift_args=("${ARGS[@]:1}")

# ─────────────────────────────────────────────────────────────────────────────
# Provider implementation
# ─────────────────────────────────────────────────────────────────────────────

cmd_set() {
    local name="${1:?Usage: {{TOOL_NAME}} set <name> [value]}"
    local value="${2:-}"
    # TODO: Implement set
    echo "{{TOOL_NAME}} [run: ${RUN_ID:-none}]"
    echo "set: not yet implemented"
    echo "✗"
    exit 1
}

cmd_get() {
    local name="${1:?Usage: {{TOOL_NAME}} get <name>}"
    # TODO: Implement get
    echo "{{TOOL_NAME}} [run: ${RUN_ID:-none}]"
    echo "get: not yet implemented"
    echo "✗"
    exit 1
}

cmd_list() {
    # TODO: Implement list
    echo "{{TOOL_NAME}} [run: ${RUN_ID:-none}]"
    echo "list: not yet implemented"
    echo "✗"
    exit 1
}

cmd_delete() {
    local name="${1:?Usage: {{TOOL_NAME}} delete <name>}"
    # TODO: Implement delete
    echo "{{TOOL_NAME}} [run: ${RUN_ID:-none}]"
    echo "delete: not yet implemented"
    echo "✗"
    exit 1
}

# ─────────────────────────────────────────────────────────────────────────────
# Dispatch verb
# ─────────────────────────────────────────────────────────────────────────────

case "$VERB" in
    set)    cmd_set ${shift_args[@]+"${shift_args[@]}"} ;;
    get)    cmd_get ${shift_args[@]+"${shift_args[@]}"} ;;
    list)   cmd_list ;;
    delete) cmd_delete ${shift_args[@]+"${shift_args[@]}"} ;;
    "")
        echo "{{TOOL_NAME}} [run: ${RUN_ID:-none}]"
        echo "No verb specified. Use --help for usage."
        echo "✗"
        exit 1
        ;;
    *)
        echo "{{TOOL_NAME}} [run: ${RUN_ID:-none}]"
        echo "Unknown verb: $VERB. Use --help for usage."
        echo "✗"
        exit 1
        ;;
esac
