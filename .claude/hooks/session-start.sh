#!/bin/bash
# SessionStart hook: Restore context and register instance
#
# This hook runs when a Claude Code session starts. It:
# 1. Registers this instance for tracking (for graceful shutdown)
# 2. Restores context from previous session

# Enable trace mode if DEBUG_HOOKS is set
if [[ -n "${DEBUG_HOOKS}" ]]; then
    set -x
fi

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
AGENTNAME="${AGENTNAME:-captain}"
CONTEXT_FILE="$REPO_ROOT/claude/agents/$AGENTNAME/backups/latest/context.jsonl"
GIT_STATUS_FILE="$REPO_ROOT/claude/agents/$AGENTNAME/backups/latest/status.txt"
INSTANCES_DIR="$REPO_ROOT/claude/data/instances"

# Register this instance
mkdir -p "$INSTANCES_DIR"
INSTANCE_ID="${CLAUDE_SESSION_ID:-$$}"
echo "$$" > "$INSTANCES_DIR/$INSTANCE_ID"

# Check if context exists
if [[ ! -f "$CONTEXT_FILE" ]] || [[ ! -s "$CONTEXT_FILE" ]]; then
  echo "No previous session context found. Starting fresh."
  exit 0
fi

# Display context header
echo "=== PREVIOUS SESSION CONTEXT ==="
echo ""

# Parse and format last 10 entries
tail -10 "$CONTEXT_FILE" | while IFS= read -r line; do
  # Extract fields using grep
  TYPE=$(echo "$line" | grep -o '"type":"[^"]*"' | cut -d'"' -f4)
  TIMESTAMP=$(echo "$line" | grep -o '"timestamp":"[^"]*"' | cut -d'"' -f4)
  CONTENT=$(echo "$line" | sed 's/.*"content":"\(.*\)"}/\1/')

  # Format based on type
  case "$TYPE" in
    checkpoint) echo "✓ $CONTENT" ;;
    park)       echo "⏸ PARKED: $CONTENT" ;;
    append)     echo "• $CONTENT" ;;
  esac
done

echo ""

# Show git status summary
if [[ -f "$GIT_STATUS_FILE" ]]; then
  UNCOMMITTED=$(grep -c "modified:" "$GIT_STATUS_FILE" 2>/dev/null || echo 0)
  if [[ "$UNCOMMITTED" -gt 0 ]]; then
    echo "⚠ You have $UNCOMMITTED uncommitted file(s)"
    echo ""
  fi
fi

echo "=== END PREVIOUS SESSION CONTEXT ==="

# Register with dispatch service (fire-and-forget)
AGENCY_SERVICE_URL="${AGENCY_SERVICE_URL:-http://localhost:3141}"
if curl -s --connect-timeout 1 "${AGENCY_SERVICE_URL}/health" >/dev/null 2>&1; then
  curl -s --connect-timeout 1 -X POST "${AGENCY_SERVICE_URL}/api/dispatch/instance/register" \
    -H "Content-Type: application/json" \
    -d "{\"id\": \"$INSTANCE_ID\", \"agentName\": \"$AGENTNAME\", \"workstream\": \"${WORKSTREAM:-}\", \"pid\": $$}" \
    >/dev/null 2>&1 || true

  # Check for unread messages
  UNREAD=$(curl -s --connect-timeout 1 "${AGENCY_SERVICE_URL}/api/message/unread/${AGENTNAME}" 2>/dev/null)
  UNREAD_COUNT=$(echo "$UNREAD" | jq -r '.unreadCount // 0' 2>/dev/null || echo 0)
  if [[ "$UNREAD_COUNT" -gt 0 ]]; then
    echo ""
    echo "=== UNREAD MESSAGES ($UNREAD_COUNT) ==="
    echo "$UNREAD" | jq -r '.messages[] | "  [\(if .type == "direct" then "DM" else "BC" end)] \(.fromAgent): \(.subject)"' 2>/dev/null || true
    echo "=== END MESSAGES ==="
  fi

  # Check dispatch queue
  NEXT_ITEM=$(curl -s --connect-timeout 1 "${AGENCY_SERVICE_URL}/api/dispatch/next/${AGENTNAME}" 2>/dev/null)
  ITEM_TITLE=$(echo "$NEXT_ITEM" | jq -r '.item.title // empty' 2>/dev/null)
  if [[ -n "$ITEM_TITLE" ]]; then
    ITEM_QUEUE=$(echo "$NEXT_ITEM" | jq -r '.item.queueType // "agent"' 2>/dev/null)
    ITEM_PRI=$(echo "$NEXT_ITEM" | jq -r '.item.priority // 0' 2>/dev/null)
    echo ""
    echo "=== QUEUED WORK ==="
    echo "  [$ITEM_QUEUE] $ITEM_TITLE (priority: $ITEM_PRI)"
    echo "  Claim with: ./tools/dispatch claim"
    echo "=== END QUEUED WORK ==="
  fi
else
  # Fallback to legacy news-read
  NEWS_OUTPUT=$("$REPO_ROOT/tools/news-read" --quiet 2>/dev/null)
  if [[ -n "$NEWS_OUTPUT" ]]; then
    echo ""
    echo "=== UNREAD NEWS ==="
    echo "$NEWS_OUTPUT"
    echo "=== END NEWS ==="
  fi
fi

exit 0
