#!/bin/bash
# UserPromptSubmit hook: Notify agent of unread messages
#
# If agent has unread messages, notify them. Agent can:
# 1. Read messages with ./tools/read-messages
# 2. Ask the principal if they should read them first

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

# Read hook input
INPUT=$(cat)

# Get unread count
UNREAD=$("$REPO_ROOT/tools/read-messages" --count 2>/dev/null || echo "0")

if [ "$UNREAD" -gt 0 ]; then
  echo "📬 You have $UNREAD unread message(s). Run ./tools/read-messages to read, or ask the principal if you should prioritize them."
fi

exit 0
