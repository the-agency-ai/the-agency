#!/bin/bash
# quality-check.sh — Scoped, cached, worktree-aware quality gate
#
# Wired as: Stop hook (fires when Claude finishes a turn)
#
# Behavior:
#   1. Caches git state — skips if nothing changed since last successful run
#   2. Scopes format/lint to changed code files only (not project-wide)
#   3. Optionally runs typecheck and tests (configurable)
#   4. Worktree-aware — uses git show-toplevel, not CLAUDE_PROJECT_DIR
#   5. Blocks (exit 2) if checks fail, with failure reason -> Claude must fix
#
# IMPORTANT: stdout must contain ONLY the final JSON object.
# All tool output goes to /dev/null — stdout is reserved for Claude Code.
#
# Config: quality-check.config.json in the same directory as this hook.
# The config file controls which checks run and which commands to use.
#
# Config schema:
# {
#   "run_format": true,
#   "run_lint": true,
#   "run_typecheck": false,
#   "run_tests": false,
#   "format_cmd": "npx prettier --write",
#   "format_check_cmd": "npx prettier --check",
#   "lint_cmd": "npx eslint --fix",
#   "lint_check_cmd": "npx eslint",
#   "typecheck_cmd": "npx tsc --noEmit",
#   "test_cmd": "npm test",
#   "code_extensions": "ts|tsx|js|jsx"
# }

# ERR trap: skip gracefully instead of blocking
trap 'printf "{}"; exit 0' ERR

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../tools/lib/_path-resolve
source "$SCRIPT_DIR/../tools/lib/_path-resolve" 2>/dev/null || true

# --- PATH resolution (for non-login shells) ---
[ -d /opt/homebrew/bin ] && export PATH="/opt/homebrew/bin:$PATH"
[ -d "$HOME/.asdf/shims" ] && export PATH="$HOME/.asdf/shims:$PATH"

# --- Worktree-aware root detection ---
PROJECT_DIR=$(git rev-parse --show-toplevel 2>/dev/null || echo "${CLAUDE_PROJECT_DIR:-$(pwd)}")
cd "$PROJECT_DIR" || exit 0

# Add node_modules/.bin for local tooling
[ -d "$PROJECT_DIR/node_modules/.bin" ] && export PATH="$PROJECT_DIR/node_modules/.bin:$PATH"

# Resolve through symlink to find the real hook directory (not the symlink location)
REAL_SCRIPT=$(readlink -f "$0" 2>/dev/null || echo "$0")
HOOKS_DIR="$(dirname "$REAL_SCRIPT")"
CONFIG_FILE="$HOOKS_DIR/quality-check.config.json"

# --- Config defaults ---
RUN_FORMAT=true
RUN_LINT=true
RUN_TYPECHECK=false
RUN_TESTS=false
FORMAT_CMD=""
FORMAT_CHECK_CMD=""
LINT_CMD=""
LINT_CHECK_CMD=""
TYPECHECK_CMD=""
TEST_CMD=""
CODE_EXTENSIONS="ts|tsx|js|jsx"

# --- jq guard ---
if ! command -v jq >/dev/null 2>&1; then
  exit 0
fi

if [ -f "$CONFIG_FILE" ]; then
  RUN_FORMAT=$(jq -r 'if has("run_format") then .run_format else true end' "$CONFIG_FILE")
  RUN_LINT=$(jq -r 'if has("run_lint") then .run_lint else true end' "$CONFIG_FILE")
  RUN_TYPECHECK=$(jq -r 'if has("run_typecheck") then .run_typecheck else false end' "$CONFIG_FILE")
  RUN_TESTS=$(jq -r 'if has("run_tests") then .run_tests else false end' "$CONFIG_FILE")
  FORMAT_CMD=$(jq -r '.format_cmd // empty' "$CONFIG_FILE")
  FORMAT_CHECK_CMD=$(jq -r '.format_check_cmd // empty' "$CONFIG_FILE")
  LINT_CMD=$(jq -r '.lint_cmd // empty' "$CONFIG_FILE")
  LINT_CHECK_CMD=$(jq -r '.lint_check_cmd // empty' "$CONFIG_FILE")
  TYPECHECK_CMD=$(jq -r '.typecheck_cmd // empty' "$CONFIG_FILE")
  TEST_CMD=$(jq -r '.test_cmd // empty' "$CONFIG_FILE")
  CODE_EXTENSIONS=$(jq -r '.code_extensions // "ts|tsx|js|jsx"' "$CONFIG_FILE")
fi

# --- Read stdin (hook input) ---
INPUT=$(cat)

# --- Guard: prevent infinite loops on retry ---
STOP_HOOK_ACTIVE=$(printf '%s' "$INPUT" | jq -r '.stop_hook_active // false' 2>/dev/null || echo "false")
if [ "$STOP_HOOK_ACTIVE" = "true" ]; then
  exit 0
fi

# --- Collect dirty files (unstaged + staged + untracked) ---
CHANGED_FILES=$(git diff --name-only HEAD 2>/dev/null || true)
STAGED_FILES=$(git diff --name-only --cached HEAD 2>/dev/null || true)
UNTRACKED_FILES=$(git ls-files --others --exclude-standard 2>/dev/null || true)

ALL_DIRTY=$(printf '%s\n%s\n%s' "$CHANGED_FILES" "$STAGED_FILES" "$UNTRACKED_FILES" | sort -u | sed '/^$/d')

if [ -z "$ALL_DIRTY" ]; then
  exit 0
fi

# --- Git state caching ---
DIFF_CONTENT=$(git diff HEAD 2>/dev/null || true)
STAGED_CONTENT=$(git diff --cached HEAD 2>/dev/null || true)
STATE_HASH=$(printf '%s\n%s\n%s' "$DIFF_CONTENT" "$STAGED_CONTENT" "$UNTRACKED_FILES" | shasum -a 256 | cut -d' ' -f1)
CACHE_KEY=$(printf '%s' "$PROJECT_DIR" | shasum -a 256 | cut -d' ' -f1)
CACHE_FILE="/tmp/quality-check-${CACHE_KEY}.state"

if [ -f "$CACHE_FILE" ] && [ "$(cat "$CACHE_FILE")" = "$STATE_HASH" ]; then
  exit 0
fi

# --- Filter to code files ---
CODE_FILES=$(printf '%s\n' "$ALL_DIRTY" | grep -E "\.(${CODE_EXTENSIONS})$" || true)

if [ -z "$CODE_FILES" ]; then
  exit 0
fi

# --- Filter to files that exist on disk (exclude deletions) ---
CODE_FILE_LIST=$(mktemp)
trap "rm -f '$CODE_FILE_LIST'" EXIT

FILE_COUNT=0
while IFS= read -r f; do
  if [ -f "$f" ]; then
    printf '%s\0' "$f" >> "$CODE_FILE_LIST"
    FILE_COUNT=$((FILE_COUNT + 1))
  fi
done <<< "$CODE_FILES"

if [ "$FILE_COUNT" -eq 0 ]; then
  rm -f "$CODE_FILE_LIST"
  exit 0
fi

# --- Collect failures ---
FAILURES=()
SKIPPED=""

# --- Stage 1: Format (file-level, auto-fix then verify) ---

if [ "$RUN_FORMAT" = "true" ]; then
  if [ -n "$FORMAT_CMD" ]; then
    xargs -0 $FORMAT_CMD < "$CODE_FILE_LIST" >/dev/null 2>&1 || true
    if [ -n "$FORMAT_CHECK_CMD" ]; then
      if ! xargs -0 $FORMAT_CHECK_CMD < "$CODE_FILE_LIST" >/dev/null 2>&1; then
        FAILURES+=("Format check still failing after auto-fix — manual intervention needed")
      fi
    fi
  else
    SKIPPED="${SKIPPED}Skipped format (no format_cmd configured). "
  fi
fi

# --- Stage 2: Lint (file-level, auto-fix then verify) ---

if [ "$RUN_LINT" = "true" ]; then
  if [ -n "$LINT_CMD" ]; then
    xargs -0 $LINT_CMD < "$CODE_FILE_LIST" >/dev/null 2>&1 || true
    if [ -n "$LINT_CHECK_CMD" ]; then
      if ! xargs -0 $LINT_CHECK_CMD < "$CODE_FILE_LIST" >/dev/null 2>&1; then
        FAILURES+=("Lint errors remain after auto-fix — resolve manually")
      fi
    fi
  else
    SKIPPED="${SKIPPED}Skipped lint (no lint_cmd configured). "
  fi
fi

# --- Stage 3: Typecheck (project-level) ---

if [ "$RUN_TYPECHECK" = "true" ]; then
  if [ -n "$TYPECHECK_CMD" ]; then
    if ! $TYPECHECK_CMD >/dev/null 2>&1; then
      FAILURES+=("TypeScript type errors — fix before completing")
    fi
  else
    SKIPPED="${SKIPPED}Skipped typecheck (no typecheck_cmd configured). "
  fi
fi

# --- Stage 4: Tests (project-level, opt-in) ---

if [ "$RUN_TESTS" = "true" ]; then
  if [ -n "$TEST_CMD" ]; then
    if ! $TEST_CMD >/dev/null 2>&1; then
      FAILURES+=("Tests failed — fix failing tests before completing")
    fi
  else
    SKIPPED="${SKIPPED}Skipped tests (no test_cmd configured). "
  fi
fi

# --- Block if any checks failed ---

if [ ${#FAILURES[@]} -gt 0 ]; then
  REASON=$(printf '%s\n' "${FAILURES[@]}" | jq -Rs '.')
  printf '{"decision":"block","reason":%s}' "$REASON"
  exit 2
fi

# --- Cache state on success ---
printf '%s' "$STATE_HASH" > "$CACHE_FILE"

# --- Clean up temp file ---
rm -f "$CODE_FILE_LIST"

# --- Success message ---
MSG="${SKIPPED}Quality checks passed (${FILE_COUNT} file(s) checked). Ready for commit."
printf '{"systemMessage":%s}' "$(printf '%s' "$MSG" | jq -Rs '.')"
exit 0
