#!/bin/bash
# plan-capture.sh — Capture plan as artifact when exiting plan mode
#
# Wired today as: PreToolUse -> ExitPlanMode
# Future:         PlanCompleted event (swap hooks.json only)
#
# Behavior:
#   1. Extracts plan content from tool_input.plan (primary) or transcript (fallback)
#   2. Saves as timestamped markdown in docs/plans/
#   3. Optionally opens in editor for review/markup
#   4. Approves exit (never blocks — that's the quality gate's job)
#
# Config: plan-capture.config.json in the same directory as this hook.
# Config schema:
# {
#   "open_in_editor": false,
#   "editor": "code",
#   "plan_dir": "docs/plans",
#   "scope_tags": {
#     "apps/backend|nestjs|prisma": "BE",
#     "apps/frontend|react|next": "FE",
#     "packages/|monorepo|turborepo": "Mono"
#   }
# }

# ERR trap: if anything unexpected fails, skip gracefully instead of blocking
trap 'exit 0' ERR

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../tools/_path-resolve
source "$SCRIPT_DIR/../tools/_path-resolve" 2>/dev/null || true

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
# Resolve through symlink to find the real hook directory
REAL_SCRIPT=$(readlink -f "$0" 2>/dev/null || echo "$0")
HOOKS_DIR="$(dirname "$REAL_SCRIPT")"
CONFIG_FILE="$HOOKS_DIR/plan-capture.config.json"
PLAN_DIR="$PROJECT_DIR/docs/plans"

# --- Config defaults ---
OPEN_IN_EDITOR=false
EDITOR_CMD="${EDITOR:-code}"

# --- jq guard ---
command -v jq >/dev/null 2>&1 || { printf '{}'; exit 0; }

if [ -f "$CONFIG_FILE" ]; then
  OPEN_IN_EDITOR=$(jq -r '.open_in_editor // false' "$CONFIG_FILE")
  EDITOR_CMD=$(jq -r '.editor // env.EDITOR // "code"' "$CONFIG_FILE")
  CONFIGURED_PLAN_DIR=$(jq -r '.plan_dir // empty' "$CONFIG_FILE")
  if [ -n "$CONFIGURED_PLAN_DIR" ]; then
    PLAN_DIR="$PROJECT_DIR/$CONFIGURED_PLAN_DIR"
  fi
fi

# --- Read stdin (hook input) ---
INPUT=$(cat)

# --- Try to extract plan content directly from tool_input.plan ---
PLAN_CONTENT=$(echo "$INPUT" | jq -r '.tool_input.plan // empty')

# --- Fallback: parse transcript if tool_input.plan is empty ---
if [ -z "$PLAN_CONTENT" ]; then
  TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path // empty')
  if [ -z "$TRANSCRIPT_PATH" ] || [ ! -f "$TRANSCRIPT_PATH" ]; then
    exit 0
  fi

  PLAN_CONTENT=$(python3 - "$TRANSCRIPT_PATH" <<'PYTHON'
import json
import sys

transcript_path = sys.argv[1]

messages = []
with open(transcript_path, 'r') as f:
    for line in f:
        line = line.strip()
        if not line:
            continue
        try:
            messages.append(json.loads(line))
        except json.JSONDecodeError:
            continue

# Transcript JSONL format: each line has top-level "type" (user/assistant/progress/etc.)
# Assistant messages have message.content[] with blocks of type "text" or "tool_use"
# Tool use blocks have "name" (e.g. "EnterPlanMode") — these are nested, not top-level.

in_plan = False
plan_blocks = []
current_plan = []

for msg in messages:
    msg_type = msg.get('type', '')
    role = msg.get('message', {}).get('role', '') if isinstance(msg.get('message'), dict) else ''
    content = msg.get('message', {}).get('content', []) if isinstance(msg.get('message'), dict) else []

    if msg_type == 'assistant' and isinstance(content, list):
        for block in content:
            if not isinstance(block, dict):
                continue

            # Detect plan mode entry/exit via tool_use blocks
            if block.get('type') == 'tool_use':
                if block.get('name') == 'EnterPlanMode':
                    in_plan = True
                    current_plan = []
                elif block.get('name') == 'ExitPlanMode':
                    if current_plan:
                        plan_blocks.append('\n'.join(current_plan))
                    in_plan = False
                continue

            # Capture text blocks while in plan mode
            if in_plan and block.get('type') == 'text':
                text = block.get('text', '').strip()
                if text:
                    current_plan.append(text)

# If still in plan mode (about to exit), capture current
if in_plan and current_plan:
    plan_blocks.append('\n'.join(current_plan))

if plan_blocks:
    print('\n\n'.join(plan_blocks))
PYTHON
  )
fi

if [ -z "$PLAN_CONTENT" ]; then
  exit 0
fi

mkdir -p "$PLAN_DIR"
DATE=$(date +%Y-%m-%d)
DATE_COMPACT=$(date +%Y%m%d)

# --- Gather metadata from stdin JSON and environment ---
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')
BRANCH=$(git -C "$PROJECT_DIR" branch --show-current 2>/dev/null || echo "")

# Detect worktree (if cwd is under .worktrees/, extract prototype name)
WORKTREE=""
case "$PROJECT_DIR" in
  */.worktrees/*)
    WORKTREE=$(echo "$PROJECT_DIR" | sed 's|.*/.worktrees/||' | cut -d/ -f1)
    ;;
esac

# Detect prototype (from branch proto/<name> or worktree)
PROTOTYPE=""
case "$BRANCH" in
  proto/*)
    PROTOTYPE=$(echo "$BRANCH" | sed 's|^proto/||')
    ;;
esac
if [ -z "$PROTOTYPE" ] && [ -n "$WORKTREE" ]; then
  PROTOTYPE="$WORKTREE"
fi

# Principal (git user = human author)
PRINCIPAL=$(git -C "$PROJECT_DIR" config user.name 2>/dev/null || echo "")

# --- Derive title and slug ---
TITLE=$(echo "$PLAN_CONTENT" | grep -m1 '^# ' | sed 's/^# //')
SLUG=""
NEEDS_RENAME=false

# Slugify from title
if [ -n "$TITLE" ]; then
  SLUG=$(echo "$TITLE" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9 -]//g' | tr ' ' '-' | sed 's/--*/-/g' | sed 's/^-//;s/-$//')
fi

# Fallback: branch name (skip main/master)
if [ -z "$SLUG" ]; then
  if [ -n "$BRANCH" ] && [ "$BRANCH" != "main" ] && [ "$BRANCH" != "master" ]; then
    SLUG=$(echo "$BRANCH" | sed 's|^[^/]*/||' | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
  fi
fi

# Final fallback
if [ -z "$SLUG" ]; then
  SLUG="draft"
  NEEDS_RENAME=true
fi

PLAN_FILE="$PLAN_DIR/${DATE_COMPACT}-${SLUG}.md"

# If file already exists, append a counter
if [ -f "$PLAN_FILE" ]; then
  COUNTER=2
  while [ -f "$PLAN_DIR/${DATE_COMPACT}-${SLUG}-${COUNTER}.md" ]; do
    COUNTER=$((COUNTER + 1))
  done
  PLAN_FILE="$PLAN_DIR/${DATE_COMPACT}-${SLUG}-${COUNTER}.md"
fi

# Relative path from project root
PLAN_PATH=$(echo "$PLAN_FILE" | sed "s|^$PROJECT_DIR/||")

# --- Detect scope tags from config or use defaults ---
TAGS=""
if [ -f "$CONFIG_FILE" ] && jq -e '.scope_tags' "$CONFIG_FILE" >/dev/null 2>&1; then
  # Read scope_tags from config: keys are regex patterns, values are tag names
  while IFS='=' read -r pattern tag; do
    pattern=$(echo "$pattern" | sed 's/^ *//;s/ *$//')
    tag=$(echo "$tag" | sed 's/^ *//;s/ *$//')
    if [ -n "$pattern" ] && echo "$PLAN_CONTENT" | grep -qiE "$pattern"; then
      TAGS="${TAGS:+$TAGS, }$tag"
    fi
  done < <(jq -r '.scope_tags | to_entries[] | "\(.key)=\(.value)"' "$CONFIG_FILE")
else
  # Generic defaults: detect common patterns
  if echo "$PLAN_CONTENT" | grep -qiE 'backend|server|api|database|prisma'; then
    TAGS="${TAGS:+$TAGS, }Backend"
  fi
  if echo "$PLAN_CONTENT" | grep -qiE 'frontend|client|react|next|vue|angular'; then
    TAGS="${TAGS:+$TAGS, }Frontend"
  fi
  if echo "$PLAN_CONTENT" | grep -qiE 'packages/|monorepo|turborepo|workspace|\.claude/|hooks/'; then
    TAGS="${TAGS:+$TAGS, }Infra"
  fi
fi

# --- Build frontmatter ---
{
  echo "---"
  echo "title: \"${TITLE:-$SLUG}\""
  echo "slug: $SLUG"
  echo "path: $PLAN_PATH"
  echo "date: $DATE"
  echo "status: draft"
  echo "branch: ${BRANCH:-detached}"
  if [ -n "$WORKTREE" ]; then
    echo "worktree: $WORKTREE"
  fi
  if [ -n "$PROTOTYPE" ]; then
    echo "prototype: $PROTOTYPE"
  fi
  echo "authors:"
  if [ -n "$PRINCIPAL" ]; then
    echo "  - $PRINCIPAL (principal)"
  fi
  echo "  - Claude Code"
  if [ -n "$SESSION_ID" ]; then
    echo "session: $SESSION_ID"
  fi
  if [ -n "$TAGS" ]; then
    echo "tags: [$TAGS]"
  fi
  echo "---"
  echo ""
  echo "$PLAN_CONTENT"
} > "$PLAN_FILE"

if [ ! -f "$PLAN_FILE" ]; then
  exit 0
fi

# --- Open in editor if configured ---
if [ "$OPEN_IN_EDITOR" = "true" ]; then
  "$EDITOR_CMD" "$PLAN_FILE" &
fi

# --- Approve exit + tell Claude where the plan was saved ---
if [ "$NEEDS_RENAME" = "true" ]; then
  echo "{\"systemMessage\": \"Plan captured to $PLAN_PATH with a temporary name. Ask the user for a short slug to rename it to docs/plans/${DATE_COMPACT}-<slug>.md (e.g. 'auth-refactor', 'cart-flow'). Then rename the file and update the slug/path frontmatter.\"}"
else
  echo "{\"systemMessage\": \"Plan captured to $PLAN_PATH.\"}"
fi
exit 0
