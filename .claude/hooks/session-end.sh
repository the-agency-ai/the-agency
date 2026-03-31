#!/bin/bash
# SessionEnd hook: Clean up instance registration
#
# This hook runs when a Claude Code session ends.

# Enable trace mode if DEBUG_HOOKS is set
if [[ -n "${DEBUG_HOOKS}" ]]; then
    set -x
fi

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

INSTANCES_DIR="$REPO_ROOT/claude/data/instances"

# Get this instance's ID (use CLAUDE_SESSION_ID if available, otherwise use parent PID)
INSTANCE_ID="${CLAUDE_SESSION_ID:-$$}"
INSTANCE_FILE="$INSTANCES_DIR/$INSTANCE_ID"

# Remove this instance's registration
if [[ -f "$INSTANCE_FILE" ]]; then
    rm -f "$INSTANCE_FILE"
fi

exit 0
