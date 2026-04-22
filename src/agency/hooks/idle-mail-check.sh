#!/bin/bash
#
# What Problem: We need silent idle-time notification of incoming dispatches
# without polluting the conversation transcript. The cron-based 5-minute
# loop we were running ran iscp-check via Bash and left visible "No dispatches
# found" artifacts in the transcript every cycle. The iscp-check hook on
# UserPromptSubmit only fires when the user interacts — dispatches arriving
# during idle time were invisible until the next prompt. This hook closes
# the gap.
#
# How & Why: Claude Code fires a Notification hook event with
# notification_type="idle_prompt" when the session goes idle. This script
# reads that notification from stdin, filters on the type, runs iscp-check
# silently, and returns the result as `additionalContext` in the JSON
# response. Per the docs, additionalContext is "added to Claude's context"
# — testing whether that appears on the next model turn during/after idle
# is the point of this first iteration.
#
# Fallback path: if additionalContext during idle proves invisible to the
# model, we also write a state file at ~/.agency/{repo}/.idle-mail-state.
# The existing iscp-check (UserPromptSubmit) hook can read that state file
# on the next user prompt and inject the deferred notification.
#
# Safe on non-idle notifications: if notification_type is anything other
# than idle_prompt (e.g. permission_prompt, auth_success), the script exits
# silently without doing anything.
#
# Written: 2026-04-09 during captain Day 34 — silent idle injection experiment

set -euo pipefail

# Read JSON from stdin (Claude Code Notification hook input)
INPUT=$(cat 2>/dev/null || echo "{}")

# Extract notification_type. If not idle_prompt, exit silently.
NOTIF_TYPE=$(echo "$INPUT" | jq -r '.notification_type // empty' 2>/dev/null || echo "")
if [[ "$NOTIF_TYPE" != "idle_prompt" ]]; then
    exit 0
fi

# Locate project root for tool paths
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
ISCP_CHECK="$PROJECT_DIR/agency/tools/iscp-check"

if [[ ! -x "$ISCP_CHECK" ]]; then
    exit 0
fi

# Run iscp-check in --statusline mode (silent when empty, compact when not)
MAIL=$("$ISCP_CHECK" --statusline 2>/dev/null || true)

if [[ -z "$MAIL" ]]; then
    # No mail — nothing to say
    exit 0
fi

# Build the context message — brief, specific, actionable
CONTEXT_MSG="[idle-mail-check] You have new inbox items: $MAIL. Run './agency/tools/dispatch list --status unread' to see them. The principal has not yet typed a new prompt; this is an idle-time notification so you can decide whether to surface it now or wait."

# Also write state file for the UserPromptSubmit hook fallback path
REPO_NAME="$(basename "$PROJECT_DIR")"
STATE_DIR="$HOME/.agency/${REPO_NAME}"
mkdir -p "$STATE_DIR" 2>/dev/null || true
STATE_FILE="$STATE_DIR/.idle-mail-state"
printf '%s\n' "$MAIL" > "$STATE_FILE" 2>/dev/null || true

# Return JSON with additionalContext. Per docs, this is "added to Claude's
# context." Whether that's visible during/after idle is what we're testing.
jq -n -c --arg ctx "$CONTEXT_MSG" '{"hookSpecificOutput": {"hookEventName": "Notification", "additionalContext": $ctx}}'
