#!/bin/bash
# branch-freshness.sh — Informational warning when branch is behind origin
#
# Wired as: SessionStart hook (fires when a new Claude session begins)
#
# Behavior:
#   1. Fetches origin (fast, no merge)
#   2. Computes divergence from origin/master (or configured base branch)
#   3. If behind, injects a systemMessage suggesting sync
#   4. Never blocks — always exits 0
#
# IMPORTANT: stdout must contain ONLY the final JSON object.
# The hook runner expects JSON on stdout — output '{}' for no-op paths.
#
# Config: branch-freshness.config.json in the same directory as this hook.
# Config schema:
# {
#   "base_branch": "master",
#   "sync_command": "/sync"
# }

# ERR trap: skip gracefully instead of blocking
trap 'printf "{}"; exit 0' ERR

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../tools/lib/_path-resolve
source "$SCRIPT_DIR/../tools/lib/_path-resolve" 2>/dev/null || true

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
cd "$PROJECT_DIR"

# Ensure git tools and jq are available
if [ -d /opt/homebrew/bin ]; then
  export PATH="/opt/homebrew/bin:$PATH"
fi
if [ -d "$HOME/.asdf/shims" ]; then
  export PATH="$HOME/.asdf/shims:$PATH"
fi

# jq is required for safe JSON output — bail with empty JSON if missing
command -v jq >/dev/null 2>&1 || { printf '{}'; exit 0; }

# --- Config defaults ---
BASE_BRANCH="master"
SYNC_COMMAND="/sync"

# Resolve through symlink to find the real hook directory
REAL_SCRIPT=$(readlink -f "$0" 2>/dev/null || echo "$0")
HOOKS_DIR="$(dirname "$REAL_SCRIPT")"
CONFIG_FILE="$HOOKS_DIR/branch-freshness.config.json"

if [ -f "$CONFIG_FILE" ]; then
  CONFIGURED_BASE=$(jq -r '.base_branch // empty' "$CONFIG_FILE")
  if [ -n "$CONFIGURED_BASE" ]; then
    BASE_BRANCH="$CONFIGURED_BASE"
  fi
  CONFIGURED_SYNC=$(jq -r '.sync_command // empty' "$CONFIG_FILE")
  if [ -n "$CONFIGURED_SYNC" ]; then
    SYNC_COMMAND="$CONFIGURED_SYNC"
  fi
fi

# Fetch origin silently (timeout after 5s to avoid blocking on network issues)
timeout 5 git fetch origin >/dev/null 2>&1 || true

# Get current branch
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
if [ -z "$BRANCH" ] || [ "$BRANCH" = "HEAD" ]; then
  printf '{}'
  exit 0
fi

# Compute divergence from origin/<base_branch>
COUNTS=$(git rev-list --left-right --count "origin/${BASE_BRANCH}...HEAD" 2>/dev/null)
if [ -z "$COUNTS" ]; then
  printf '{}'
  exit 0
fi

BEHIND=$(echo "$COUNTS" | awk '{print $1}')
AHEAD=$(echo "$COUNTS" | awk '{print $2}')

# Guard against empty values from awk (would cause arithmetic errors)
if [ -z "$BEHIND" ] || [ -z "$AHEAD" ]; then
  printf '{}'
  exit 0
fi

if [ "$BEHIND" -gt 0 ] 2>/dev/null; then
  MSG="Branch \`${BRANCH}\` is ${BEHIND} commit(s) behind \`origin/${BASE_BRANCH}\` (${AHEAD} ahead). Consider running \`${SYNC_COMMAND}\` to rebase and push."
  echo "{\"systemMessage\": $(echo "$MSG" | jq -Rs '.')}"
else
  printf '{}'
fi

exit 0
