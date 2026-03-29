#!/bin/bash
# tool-telemetry.sh — Log every tool invocation to JSONL for friction analysis
#
# Wired as: PostToolUse (no matcher — fires for all tools)
#
# Behavior:
#   1. Reads tool_name + tool_input from stdin JSON
#   2. Extracts a safe input_summary (no file content, just paths/commands)
#   3. Appends one JSONL line to ~/.claude/telemetry/<YYYY-MM-DD>.jsonl
#   4. Never blocks, never outputs to stdout (empty JSON)

# ERR trap: never block on failure
trap 'printf "%s\n" "{}" 2>/dev/null; exit 0' ERR

TELEMETRY_DIR="$HOME/.claude/telemetry"
mkdir -p "$TELEMETRY_DIR"

INPUT=$(cat)

# Extract all top-level fields in a single jq call
eval "$(printf '%s\n' "$INPUT" | jq -r '
  @sh "TOOL=\(.tool_name // "unknown")",
  @sh "SESSION=\(.session_id // "unknown")",
  @sh "PROJECT=\(.workspace // "")"
')"

# Extract a safe input summary based on tool type
case "$TOOL" in
  Bash)
    SUMMARY=$(printf '%s\n' "$INPUT" | jq -r '.tool_input.command // ""')
    ;;
  Edit|Write|Read|MultiEdit)
    SUMMARY=$(printf '%s\n' "$INPUT" | jq -r '.tool_input.file_path // ""')
    ;;
  Glob|Grep)
    SUMMARY=$(printf '%s\n' "$INPUT" | jq -r '.tool_input.pattern // ""')
    ;;
  Agent)
    eval "$(printf '%s\n' "$INPUT" | jq -r '
      @sh "SUBTYPE=\(.tool_input.subagent_type // "general")",
      @sh "DESC=\(.tool_input.description // "")"
    ')"
    SUMMARY="$SUBTYPE: $DESC"
    ;;
  Skill)
    SUMMARY=$(printf '%s\n' "$INPUT" | jq -r '.tool_input.skill // ""')
    ;;
  WebFetch|WebSearch)
    SUMMARY=$(printf '%s\n' "$INPUT" | jq -r '.tool_input.url // .tool_input.query // ""')
    ;;
  *)
    SUMMARY=""
    ;;
esac

# Truncate long summaries (max 500 chars)
SUMMARY="${SUMMARY:0:500}"

BRANCH=$(git -C "${CLAUDE_PROJECT_DIR:-$(pwd)}" branch --show-current 2>/dev/null || echo "")

DATE=$(date +%Y-%m-%d)
TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# Build JSON line with jq --arg (handles escaping) and write atomically via printf
LINE=$(jq -n -c \
  --arg ts "$TS" \
  --arg session "$SESSION" \
  --arg project "$PROJECT" \
  --arg tool "$TOOL" \
  --arg summary "$SUMMARY" \
  --arg branch "$BRANCH" \
  '{ts: $ts, session: $session, project: $project, tool: $tool, input_summary: $summary, branch: $branch}')

printf '%s\n' "$LINE" >> "$TELEMETRY_DIR/$DATE.jsonl"

# No stdout — empty output avoids creating a system message in context
exit 0
