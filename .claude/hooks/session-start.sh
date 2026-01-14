#!/bin/bash
# SessionStart hook: Restore context from previous session

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
AGENTNAME="${AGENTNAME:-captain}"
CONTEXT_FILE="$REPO_ROOT/claude/agents/$AGENTNAME/backups/latest/context.jsonl"
GIT_STATUS_FILE="$REPO_ROOT/claude/agents/$AGENTNAME/backups/latest/status.txt"

# Set tab status
"$REPO_ROOT/tools/tab-status" available 2>/dev/null || true

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

exit 0
