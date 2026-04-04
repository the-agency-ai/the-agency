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

# main/master branch -> captain project directory
if [ "$BRANCH_SLUG" = "main" ] || [ "$BRANCH_SLUG" = "master" ]; then
  BRANCH_SLUG="captain"
fi

# Look for handoff file in principal directory
HANDOFF_FILE=""
if [ -n "$BRANCH_SLUG" ] && [ -f "$PRINCIPAL_DIR/${BRANCH_SLUG}/handoff.md" ]; then
  HANDOFF_FILE="$PRINCIPAL_DIR/${BRANCH_SLUG}/handoff.md"
fi

RECAP_FILE="$PROJECT_DIR/.claude-session-recap.md"

CONTEXT=""

if [ -n "$HANDOFF_FILE" ]; then
  # Parse type from YAML frontmatter (default: session)
  # Forgiving on read: missing type, malformed frontmatter, or parse failure all default to "session"
  HANDOFF_TYPE=$(sed -n '/^---$/,/^---$/{ /^type:/{ s/^type: *//; p; } }' "$HANDOFF_FILE" 2>/dev/null || true)
  HANDOFF_TYPE="${HANDOFF_TYPE:-session}"

  # Type-aware context prefix
  case "$HANDOFF_TYPE" in
    agency-bootstrap)
      CONTEXT="This is a fresh Agency installation. The bootstrap handoff below was written by agency init. Help the user get oriented — verify the install, walk through first steps. The user can break out at any time.

---

$(cat "$HANDOFF_FILE")"
      ;;
    agency-update)
      CONTEXT="The Agency framework was just updated. The handoff below contains the update summary and previous session context. Review what changed, verify nothing broke, then continue normal work.

---

$(cat "$HANDOFF_FILE")"
      ;;
    *)
      CONTEXT=$(cat "$HANDOFF_FILE")
      ;;
  esac
fi

if [ -f "$RECAP_FILE" ]; then
  if [ -n "$CONTEXT" ]; then
    CONTEXT="${CONTEXT}

---

"
  fi
  CONTEXT="${CONTEXT}$(cat "$RECAP_FILE")"
fi

# Check for unprocessed flag queue
# Use AGENCY_PRINCIPAL (resolved via agency.yaml by _path-resolve) not raw $USER,
# since the flag tool writes to usr/$AGENCY_PRINCIPAL/ not usr/$USER/
FLAG_PRINCIPAL="${AGENCY_PRINCIPAL:-${USER:-unknown}}"
FLAG_QUEUE="$PROJECT_DIR/usr/$FLAG_PRINCIPAL/flag-queue.jsonl"
if [ -f "$FLAG_QUEUE" ] && [ -s "$FLAG_QUEUE" ]; then
  FLAG_COUNT=$(grep -c . "$FLAG_QUEUE" 2>/dev/null || echo 0)
  if [ "$FLAG_COUNT" -gt 0 ]; then
    FLAG_WARNING="

⚠ **$FLAG_COUNT unprocessed flag(s)** in queue. Run \`./claude/tools/flag list\` to review, or \`./claude/tools/flag discuss\` to start a /discuss."
    CONTEXT="${CONTEXT}${FLAG_WARNING}"
  fi
fi

# Output context if found, otherwise empty JSON (hook runner expects JSON on stdout)
if [ -n "$CONTEXT" ]; then
  printf '{"systemMessage":%s}' "$(printf '%s' "$CONTEXT" | jq -Rs '.')"
else
  printf '{}'
fi

exit 0
