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

# ERR trap: never block on failure — no stdout to avoid injecting system messages
trap 'exit 0' ERR

TELEMETRY_DIR="$HOME/.claude/telemetry"
mkdir -p "$TELEMETRY_DIR"

INPUT=$(cat)

# Extract top-level fields — individual jq calls, no eval
TOOL=$(printf '%s\n' "$INPUT" | jq -r '.tool_name // "unknown"')
SESSION=$(printf '%s\n' "$INPUT" | jq -r '.session_id // "unknown"')
PROJECT=$(printf '%s\n' "$INPUT" | jq -r '.workspace // ""')

# Extract a safe input summary based on tool type
AGENT_SCRIPT_PATH=""
case "$TOOL" in
  Bash)
    # Log only the binary name (first token) to avoid leaking secrets from doppler run --, env vars, etc.
    FULL_CMD=$(printf '%s\n' "$INPUT" | jq -r '.tool_input.command // ""')
    SUMMARY=$(printf '%s\n' "$FULL_CMD" | head -1 | cut -d' ' -f1)
    # Detect agent scripts run from usr/*/tools/ (Phase 3.2 — script discipline telemetry)
    if printf '%s\n' "$FULL_CMD" | grep -qE '(^|/)usr/[^/]+/[^/]+/tools/'; then
        AGENT_SCRIPT_PATH=$(printf '%s\n' "$FULL_CMD" | grep -oE 'usr/[^/]+/[^/]+/tools/[^ ]+' | head -1)
    fi
    ;;
  Edit|Write|Read|MultiEdit)
    SUMMARY=$(printf '%s\n' "$INPUT" | jq -r '.tool_input.file_path // ""')
    ;;
  Glob|Grep)
    SUMMARY=$(printf '%s\n' "$INPUT" | jq -r '.tool_input.pattern // ""')
    ;;
  Agent)
    SUBTYPE=$(printf '%s\n' "$INPUT" | jq -r '.tool_input.subagent_type // "general"')
    DESC=$(printf '%s\n' "$INPUT" | jq -r '.tool_input.description // ""' | tr '\n' ' ')
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
AGENCY=$(basename "$(git -C "${CLAUDE_PROJECT_DIR:-$(pwd)}" rev-parse --show-toplevel 2>/dev/null)" 2>/dev/null || echo "unknown")
AGENT="${CLAUDE_SESSION_NAME:-${AGENTNAME:-unknown}}"
PRINCIPAL="${AGENCY_PRINCIPAL:-${USER:-unknown}}"

DATE=$(date +%Y-%m-%d)
TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# Build JSON line with jq --arg (handles escaping) and write atomically via printf
LINE=$(jq -n -c \
  --arg ts "$TS" \
  --arg agency "$AGENCY" \
  --arg principal "$PRINCIPAL" \
  --arg agent "$AGENT" \
  --arg session "$SESSION" \
  --arg project "$PROJECT" \
  --arg tool "$TOOL" \
  --arg summary "$SUMMARY" \
  --arg branch "$BRANCH" \
  '{ts: $ts, agency: $agency, principal: $principal, agent: $agent, session: $session, project: $project, tool: $tool, input_summary: $summary, branch: $branch}')

# Merge agent-script source if detected
if [[ -n "$AGENT_SCRIPT_PATH" ]]; then
    LINE=$(printf '%s\n' "$LINE" | jq -c --arg src "agent-script" --arg sp "$AGENT_SCRIPT_PATH" '. + {source: $src, script_path: $sp}' 2>/dev/null || echo "$LINE")
fi

printf '%s\n' "$LINE" >> "$TELEMETRY_DIR/$DATE.jsonl"

# No stdout — empty output avoids creating a system message in context
exit 0
