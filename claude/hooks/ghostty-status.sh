#!/usr/bin/env bash
# ghostty-status.sh — Claude Code hook for Ghostty tab title + background color
#
# Updates Ghostty tab title with status indicator and sets a subtle background
# color tint based on agent state. Uses OSC escape sequences for portability
# and Ghostty's AppleScript API for persistent tab titles (survives Claude
# Code's continuous OSC 2 overwrites on macOS).
#
# Hook events:
#   PreToolUse, PostToolUse, PreCompact  -> working (green tint)
#   Notification                         -> attention (red tint)
#   Stop                                 -> available (blue tint)
#   SessionStart                         -> available (blue tint)
#   SessionEnd                           -> reset to plain shell
#
# Reads event from stdin JSON. Silent failure — never blocks Claude Code.
#
# Status indicators:
#   ○  available/idle   (blue)
#   ◑  working          (green)
#   ⚠  attention needed (red)

# --- Silent failure: trap all errors, never block ---
trap 'exit 0' ERR

# --- Guard: only run inside Ghostty ---
if [[ "${TERM_PROGRAM:-}" != "ghostty" ]]; then
    exit 0
fi

# --- Guard: /dev/tty must be writable ---
if [[ ! -w /dev/tty ]]; then
    exit 0
fi

# --- Read event from stdin ---
input=$(cat)

# --- Extract event name ---
# Try jq first, fall back to simple pattern matching
if command -v jq > /dev/null 2>&1; then
    event=$(echo "$input" | jq -r '.hook_event_name // .event // ""' 2>/dev/null)
    session_id=$(echo "$input" | jq -r '.session_id // "unknown"' 2>/dev/null)
else
    # Fallback: grep for event name
    event=$(echo "$input" | grep -o '"hook_event_name":"[^"]*"' | head -1 | cut -d'"' -f4 2>/dev/null) || true
    if [[ -z "$event" ]]; then
        event=$(echo "$input" | grep -o '"event":"[^"]*"' | head -1 | cut -d'"' -f4 2>/dev/null) || true
    fi
    session_id=$(echo "$input" | grep -o '"session_id":"[^"]*"' | head -1 | cut -d'"' -f4 2>/dev/null) || true
    session_id="${session_id:-unknown}"
fi

# --- Determine session name ---
# Cache file persists the name across hook invocations within a session.
CACHE_FILE="/tmp/ghostty-agency-session-${session_id}"

if [[ -n "${CLAUDE_SESSION_NAME:-}" ]]; then
    session_name="$CLAUDE_SESSION_NAME"
elif [[ -n "${AGENTNAME:-}" ]]; then
    session_name="$AGENTNAME"
elif [[ -f "$CACHE_FILE" ]]; then
    session_name=$(cat "$CACHE_FILE")
elif [[ -f "/tmp/ghostty-session-name-${session_id}" ]]; then
    # Status line writes session_name here (hooks don't get it in JSON)
    session_name=$(cat "/tmp/ghostty-session-name-${session_id}")
    echo "$session_name" > "$CACHE_FILE"
else
    # Last resort — try git branch
    if command -v git > /dev/null 2>&1; then
        branch=$(git branch --show-current 2>/dev/null) || true
        session_name="${branch:-Claude}"
    else
        session_name="Claude"
    fi
    echo "$session_name" > "$CACHE_FILE"
fi

# --- Color definitions ---
# Subtle tints — just enough to notice at a glance
BG_DEFAULT="#FFFFFF"      # pure white — no Claude session
BG_IDLE="#E3F2FD"         # faint blue — available, idle
BG_WORKING="#E8F5E9"      # faint green — agent working
BG_INPUT="#FFF0F0"        # faint red — needs attention

# --- OSC helper for background ---
set_bg() {
    printf '\e]11;%s\a' "$1" > /dev/tty
}

# --- Tab title via OSC 2 (universal) and Ghostty AppleScript (persistent) ---
set_title() {
    local title="$1"
    # OSC 2 — immediate, but Claude Code may overwrite
    printf '\e]2;%s\a' "$title" > /dev/tty

    # Ghostty AppleScript API — persistent, survives OSC 2 overwrites
    # Run async so it doesn't slow down the hook
    if [[ "$(uname)" == "Darwin" ]]; then
        osascript -e "tell application \"Ghostty\" to perform action \"set_tab_title:${title}\" on focused terminal of selected tab of front window" 2>/dev/null &
        disown 2>/dev/null
    fi
}

# --- Map event to state ---
case "${event:-}" in
    # Session ended — restore plain shell appearance
    "SessionEnd")
        set_title "– zsh"
        set_bg "$BG_DEFAULT"
        rm -f "$CACHE_FILE"
        ;;

    # Claude finished responding — available
    "Stop")
        set_title "○ ${session_name}"
        set_bg "$BG_IDLE"
        ;;

    # Needs attention — permission prompt or waiting for input
    "Notification")
        set_title "⚠ ${session_name}"
        set_bg "$BG_INPUT"
        ;;

    # Agent is actively working
    "PreToolUse"|"PostToolUse"|"PreCompact")
        set_title "◑ ${session_name}"
        set_bg "$BG_WORKING"
        ;;

    # Session just started — available
    "SessionStart")
        # Cache the session name on start
        echo "$session_name" > "$CACHE_FILE"
        set_title "○ ${session_name}"
        set_bg "$BG_IDLE"
        ;;

    # Default — treat as available
    *)
        set_title "○ ${session_name}"
        set_bg "$BG_IDLE"
        ;;
esac
