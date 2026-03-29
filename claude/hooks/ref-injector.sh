#!/bin/bash
# ref-injector.sh — Inject reference content when specific skills are invoked
#
# Wired as: PreToolUse hook on Skill matcher
# Reads tool_input from stdin to determine which skill is being invoked,
# then injects the appropriate reference file content as a systemMessage.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../tools/_path-resolve
source "$SCRIPT_DIR/../tools/_path-resolve" 2>/dev/null || true

[ -d /opt/homebrew/bin ] && export PATH="/opt/homebrew/bin:$PATH"
[ -d "$HOME/.asdf/shims" ] && export PATH="$HOME/.asdf/shims:$PATH"

command -v jq >/dev/null 2>&1 || { printf '{}'; exit 0; }

# Reference docs live at $AGENCY_PROJECT_ROOT/claude/docs/
DOCS_DIR="${AGENCY_PROJECT_ROOT:-.}/claude/docs"

# Read tool input from stdin
INPUT=$(cat)
SKILL=$(echo "$INPUT" | jq -r '.tool_input.skill // empty' 2>/dev/null)

# Map skills to reference files
REF_FILE=""
case "$SKILL" in
  *iteration-complete*|*phase-complete*|*plan-complete*|*quality-gate*)
    REF_FILE="$DOCS_DIR/QUALITY-GATE.md"
    ;;
  *pre-phase-review*)
    REF_FILE="$DOCS_DIR/DEVELOPMENT-METHODOLOGY.md"
    ;;
  *captain-review*|*code-review*|*review-pr*)
    REF_FILE="$DOCS_DIR/CODE-REVIEW-LIFECYCLE.md"
    ;;
  *feedback*)
    REF_FILE="$DOCS_DIR/FEEDBACK-FORMAT.md"
    ;;
esac

if [ -n "$REF_FILE" ] && [ -f "$REF_FILE" ]; then
  CONTENT=$(cat "$REF_FILE")
  printf '{"systemMessage":%s}' "$(printf '%s' "$CONTENT" | jq -Rs '.')"
else
  printf '{}'
fi

exit 0
