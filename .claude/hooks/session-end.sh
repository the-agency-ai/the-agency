#!/bin/bash
# SessionEnd hook: Save context, unregister instance, stop agency-service if last one
#
# This hook runs when a Claude Code session ends. It:
# 1. Auto-saves session context
# 2. Removes this instance's registration
# 3. If no other instances remain, stops the agency-service

# Enable trace mode if DEBUG_HOOKS is set
if [[ -n "${DEBUG_HOOKS}" ]]; then
    set -x
fi

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

# Auto-save context on exit
if [[ -x "$REPO_ROOT/tools/context-save" ]]; then
    "$REPO_ROOT/tools/context-save" --checkpoint "Session ended" 2>/dev/null || true
fi
INSTANCES_DIR="$REPO_ROOT/claude/data/instances"

# Get this instance's ID (use CLAUDE_SESSION_ID if available, otherwise use parent PID)
INSTANCE_ID="${CLAUDE_SESSION_ID:-$$}"
INSTANCE_FILE="$INSTANCES_DIR/$INSTANCE_ID"

# Remove this instance's registration
if [[ -f "$INSTANCE_FILE" ]]; then
    rm -f "$INSTANCE_FILE"
fi

# Count remaining instances
remaining_instances() {
    if [[ ! -d "$INSTANCES_DIR" ]]; then
        echo 0
        return
    fi

    local count=0
    for file in "$INSTANCES_DIR"/*; do
        if [[ -f "$file" ]]; then
            # Check if the registered process is still running
            local pid
            pid=$(cat "$file" 2>/dev/null)
            if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
                count=$((count + 1))
            else
                # Stale instance file, remove it
                rm -f "$file"
            fi
        fi
    done
    echo "$count"
}

# Check if we should stop the agency-service
remaining=$(remaining_instances)
if [[ "$remaining" -eq 0 ]]; then
    # No more instances, stop the agency-service
    if [[ -x "$REPO_ROOT/tools/agency-service" ]]; then
        "$REPO_ROOT/tools/agency-service" stop 2>/dev/null || true
    fi
fi

exit 0
