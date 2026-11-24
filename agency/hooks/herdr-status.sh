#!/usr/bin/env bash
# herdr-status.sh — Claude Code hook: show the Agency agent identity in Herdr
#
# What Problem: Terminal integration was Ghostty-only (ghostty-status.sh), and
# Ghostty has no Windows build, so under WSL an agent's pane carried no Agency
# identity at all. Herdr (https://herdr.dev) is a terminal workspace manager
# for coding agents that runs on Linux/WSL/macOS and has an API for exactly
# this.
#
# How & Why: Herdr's own Claude integration already reports lifecycle state
# (idle / working / blocked) for every pane, so this hook does NOT report
# state — two reporters would fight. It adds the one thing Herdr cannot know:
# which Agency agent is in the pane. Display-only metadata, own source id
# ("agency"), so it never touches Herdr's agent detection.
#
#   SessionStart -> display agent = <agent>, title = <repo>/<principal>/<agent>
#   SessionEnd   -> cleared
#   anything else -> no-op
#
# Reads the event from stdin JSON. Silent failure — never blocks Claude Code.
# No-op outside Herdr (HERDR_ENV != 1), so it is safe to register everywhere.
#
# Written: 2026-11-24 for the WSL/Ubuntu port.

trap 'exit 0' ERR

# --- Guards: only inside a Herdr-managed pane, with the CLI available ---
[[ "${HERDR_ENV:-}" == "1" ]] || exit 0
[[ -n "${HERDR_PANE_ID:-}" ]] || exit 0
HERDR_BIN="${HERDR_BIN_PATH:-herdr}"
command -v "$HERDR_BIN" > /dev/null 2>&1 || exit 0

input=$(cat)

if command -v jq > /dev/null 2>&1; then
    event=$(printf '%s' "$input" | jq -r '.hook_event_name // .event // ""' 2>/dev/null) || event=""
else
    event=$(printf '%s' "$input" | grep -o '"hook_event_name":"[^"]*"' | head -1 | cut -d'"' -f4) || event=""
fi

report() {
    # Bounded: a stuck Herdr server must not hold up the session.
    if command -v timeout > /dev/null 2>&1; then
        timeout 2 "$HERDR_BIN" pane report-metadata "$HERDR_PANE_ID" --source agency "$@" > /dev/null 2>&1 || true
    else
        "$HERDR_BIN" pane report-metadata "$HERDR_PANE_ID" --source agency "$@" > /dev/null 2>&1 || true
    fi
}

case "${event:-}" in
    SessionStart)
        HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        IDENTITY_TOOL="$HOOK_DIR/../tools/agent-identity"
        address="" agent=""
        if [[ -x "$IDENTITY_TOOL" ]]; then
            address=$("$IDENTITY_TOOL" 2>/dev/null) || address=""
            agent=$("$IDENTITY_TOOL" --agent 2>/dev/null) || agent=""
        fi
        # Fallbacks mirror ghostty-status.sh: explicit names, then the branch.
        [[ -n "$agent" ]] || agent="${CLAUDE_SESSION_NAME:-${AGENTNAME:-}}"
        if [[ -z "$agent" ]] && command -v git > /dev/null 2>&1; then
            agent=$(git branch --show-current 2>/dev/null) || agent=""
        fi
        [[ -n "$agent" ]] || exit 0
        # Single line, no control characters, bounded length.
        agent=$(printf '%s' "$agent" | tr -d '\000-\037' | cut -c1-48)
        address=$(printf '%s' "${address:-$agent}" | tr -d '\000-\037' | cut -c1-96)
        report --display-agent "$agent" --title "$address"
        ;;
    SessionEnd)
        report --clear-display-agent --clear-title
        ;;
esac

exit 0
