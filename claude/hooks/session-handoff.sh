#!/bin/bash
# session-handoff.sh — Inject handoff context on session start
#
# Wired as: SessionStart hook
#
# Behavior:
#   1. Derives slug from branch name (last segment after /)
#   2. Strips worktree- prefix (e.g., worktree-mycroft -> mycroft)
#   3. Looks for handoff at $AGENCY_PRINCIPAL_DIR/{slug}/handoff.md
#   4. Special case for master: prompts user to confirm captain session
#   5. Also checks for .claude-session-recap.md (auto-generated recaps)
#   6. Never blocks — always exits 0

# ERR trap: skip gracefully instead of blocking
trap 'exit 0' ERR

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../tools/lib/_path-resolve
source "$SCRIPT_DIR/../tools/lib/_path-resolve" 2>/dev/null || true

# --- PATH resolution (for non-login shells) ---
[ -d /opt/homebrew/bin ] && export PATH="/opt/homebrew/bin:$PATH"
[ -d "$HOME/.asdf/shims" ] && export PATH="$HOME/.asdf/shims:$PATH"

# jq is required for safe JSON output — bail silently if missing
command -v jq >/dev/null 2>&1 || { printf '{}'; exit 0; }

# Prefer CLAUDE_PROJECT_DIR if set (allows test fixtures), else use git
if [ -n "${CLAUDE_PROJECT_DIR:-}" ]; then
  PROJECT_DIR="$CLAUDE_PROJECT_DIR"
else
  PROJECT_DIR=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
fi

# Principal directory from _path-resolve (falls back to usr/$USER)
PRINCIPAL_DIR="${AGENCY_PRINCIPAL_DIR:-$PROJECT_DIR/usr/${USER:-unknown}}"

# Get current branch name for scoped handoff file
BRANCH=$(git -C "$PROJECT_DIR" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
# Sanitize branch name for filename: proto/catalog -> catalog, folio/main -> main
BRANCH_SLUG=$(echo "$BRANCH" | sed 's|.*/||')
# Strip worktree- prefix: worktree-mycroft -> mycroft
BRANCH_SLUG=$(echo "$BRANCH_SLUG" | sed 's|^worktree-||')

# Special case: master branch -> captain project, but ask first
if [ "$BRANCH_SLUG" = "master" ]; then
  CAPTAIN_HANDOFF="$PRINCIPAL_DIR/captain/handoff.md"
  CAPTAIN_REL=$(echo "$CAPTAIN_HANDOFF" | sed "s|^$PROJECT_DIR/||")
  RECAP_FILE="$PROJECT_DIR/.claude-session-recap.md"
  CONTEXT="Is this a captain session? The captain handoff is available at ${CAPTAIN_REL}. If this is a captain session, read it now."
  if [ -f "$RECAP_FILE" ]; then
    RECAP_CONTENT=$(cat "$RECAP_FILE")
    CONTEXT="${CONTEXT}

---

${RECAP_CONTENT}"
  fi
  printf '{"systemMessage":%s}' "$(printf '%s' "$CONTEXT" | jq -Rs '.')"
  exit 0
fi

# Look for handoff file in principal directory
HANDOFF_FILE=""
if [ -n "$BRANCH_SLUG" ] && [ -f "$PRINCIPAL_DIR/${BRANCH_SLUG}/handoff.md" ]; then
  HANDOFF_FILE="$PRINCIPAL_DIR/${BRANCH_SLUG}/handoff.md"
fi

RECAP_FILE="$PROJECT_DIR/.claude-session-recap.md"

CONTEXT=""

if [ -n "$HANDOFF_FILE" ]; then
  CONTEXT=$(cat "$HANDOFF_FILE")
fi

if [ -f "$RECAP_FILE" ]; then
  if [ -n "$CONTEXT" ]; then
    CONTEXT="${CONTEXT}

---

"
  fi
  CONTEXT="${CONTEXT}$(cat "$RECAP_FILE")"
fi

# Output context if found, otherwise empty JSON (hook runner expects JSON on stdout)
if [ -n "$CONTEXT" ]; then
  printf '{"systemMessage":%s}' "$(printf '%s' "$CONTEXT" | jq -Rs '.')"
else
  printf '{}'
fi

exit 0
