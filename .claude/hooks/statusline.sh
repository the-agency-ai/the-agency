#!/bin/bash
# Claude Code status line
# Shows: version | [workstream/agent] | project_dir | current_dir | branch | +lines/-lines | context%
# workstream/agent only shown when launched via myclaude (Agency project)

input=$(cat)

# Extract fields
VERSION=$(echo "$input" | jq -r '.version // "?"')
PROJECT_DIR=$(echo "$input" | jq -r '.workspace.project_dir // ""')
PROJECT_NAME="${PROJECT_DIR##*/}"
CURRENT_DIR=$(echo "$input" | jq -r '.workspace.current_dir // ""')
CURRENT_NAME="${CURRENT_DIR##*/}"
LINES_ADDED=$(echo "$input" | jq -r '.cost.total_lines_added // 0')
LINES_REMOVED=$(echo "$input" | jq -r '.cost.total_lines_removed // 0')
CONTEXT_USED=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)

# Get git branch
GIT_BRANCH=""
if git rev-parse --git-dir > /dev/null 2>&1; then
    BRANCH=$(git branch --show-current 2>/dev/null)
    if [ -n "$BRANCH" ]; then
        GIT_BRANCH="$BRANCH"
    fi
fi

# Agency detection - show workstream/agent if launched via myclaude
AGENCY_INFO=""
if [ -n "$AGENTNAME" ] && [ -n "$WORKSTREAM" ]; then
    AGENCY_INFO=" | $WORKSTREAM/$AGENTNAME"
fi

# Context indicator with color
if [ "$CONTEXT_USED" -gt 80 ]; then
    CONTEXT_COLOR="\033[31m"  # Red
elif [ "$CONTEXT_USED" -gt 60 ]; then
    CONTEXT_COLOR="\033[33m"  # Yellow
else
    CONTEXT_COLOR="\033[32m"  # Green
fi
RESET="\033[0m"
GREEN="\033[32m"
RED="\033[31m"

# Output single line
echo -e "$VERSION$AGENCY_INFO | $PROJECT_NAME | $CURRENT_NAME | $GIT_BRANCH | ${GREEN}+${LINES_ADDED}${RESET}/${RED}-${LINES_REMOVED}${RESET} | ${CONTEXT_COLOR}${CONTEXT_USED}%${RESET}"
