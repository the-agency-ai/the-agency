#!/bin/bash
# ref-injector.sh — Inject reference content when specific skills are invoked
#
# Wired as: PreToolUse hook on Skill matcher
# Reads tool_input from stdin to determine which skill is being invoked,
# then injects the appropriate reference file content as a systemMessage.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../tools/lib/_path-resolve
source "$SCRIPT_DIR/../tools/lib/_path-resolve" 2>/dev/null || true

[ -d /opt/homebrew/bin ] && export PATH="/opt/homebrew/bin:$PATH"
[ -d "$HOME/.asdf/shims" ] && export PATH="$HOME/.asdf/shims:$PATH"

command -v jq >/dev/null 2>&1 || { printf '{}'; exit 0; }

# Reference docs live at $AGENCY_PROJECT_ROOT/claude/
DOCS_DIR="${AGENCY_PROJECT_ROOT:-.}/claude"

# Read tool input from stdin
INPUT=$(cat)
SKILL=$(echo "$INPUT" | jq -r '.tool_input.skill // empty' 2>/dev/null)

# Map skills to reference files (exact match only — no substring/glob)
REF_FILES=()
case "$SKILL" in
  # Quality gate boundary skills → QG protocol + git discipline (pr-prep pushes)
  iteration-complete|phase-complete|plan-complete|quality-gate|pr-prep)
    REF_FILES+=("$DOCS_DIR/REFERENCE-QUALITY-GATE.md")
    REF_FILES+=("$DOCS_DIR/REFERENCE-QUALITY-DISCIPLINE.md")
    REF_FILES+=("$DOCS_DIR/REFERENCE-GIT-MERGE-NOT-REBASE.md")
    ;;
  # Commit workflow → QG + code review + provenance + git discipline
  git-safe-commit|git-safe|git-captain|ship)
    REF_FILES+=("$DOCS_DIR/REFERENCE-QUALITY-GATE.md")
    REF_FILES+=("$DOCS_DIR/REFERENCE-CODE-REVIEW-LIFECYCLE.md")
    REF_FILES+=("$DOCS_DIR/REFERENCE-PROVENANCE-HEADERS.md")
    REF_FILES+=("$DOCS_DIR/REFERENCE-GIT-MERGE-NOT-REBASE.md")
    REF_FILES+=("$DOCS_DIR/REFERENCE-SAFE-TOOLS.md")
    ;;
  # Planning & design → methodology (Valueflow, MAR, three-bucket)
  pre-phase-review|define|design)
    REF_FILES+=("$DOCS_DIR/REFERENCE-DEVELOPMENT-METHODOLOGY.md")
    ;;
  # Code review skills → review lifecycle
  captain-review|code-review|review-pr|pr-respond|diff-summary)
    REF_FILES+=("$DOCS_DIR/REFERENCE-CODE-REVIEW-LIFECYCLE.md")
    ;;
  # Feedback → format template
  feedback)
    REF_FILES+=("$DOCS_DIR/REFERENCE-FEEDBACK-FORMAT.md")
    ;;
  # Session handoff → handoff spec
  handoff|session-end)
    REF_FILES+=("$DOCS_DIR/REFERENCE-HANDOFF-SPEC.md")
    ;;
  # Session resume → handoff + repo orientation
  session-resume)
    REF_FILES+=("$DOCS_DIR/REFERENCE-HANDOFF-SPEC.md")
    REF_FILES+=("$DOCS_DIR/REFERENCE-REPO-STRUCTURE.md")
    ;;
  # ISCP dispatch/flag skills → protocol + addressing
  dispatch|dispatch-read|flag|flag-triage|monitor-dispatches)
    REF_FILES+=("$DOCS_DIR/REFERENCE-ISCP-PROTOCOL.md")
    REF_FILES+=("$DOCS_DIR/REFERENCE-AGENT-ADDRESSING.md")
    ;;
  # Cross-repo collaboration → protocol + addressing
  collaborate)
    REF_FILES+=("$DOCS_DIR/REFERENCE-ISCP-PROTOCOL.md")
    REF_FILES+=("$DOCS_DIR/REFERENCE-AGENT-ADDRESSING.md")
    ;;
  # Sync and post-merge skills → git discipline + worktree discipline
  sync-all|sync|post-merge)
    REF_FILES+=("$DOCS_DIR/REFERENCE-GIT-MERGE-NOT-REBASE.md")
    REF_FILES+=("$DOCS_DIR/REFERENCE-WORKTREE-DISCIPLINE.md")
    ;;
  # Worktree skills → worktree discipline
  worktree-create|worktree-sync|worktree-list|worktree-delete)
    REF_FILES+=("$DOCS_DIR/REFERENCE-WORKTREE-DISCIPLINE.md")
    ;;
  # Workstream creation → worktree discipline + repo structure
  workstream-create)
    REF_FILES+=("$DOCS_DIR/REFERENCE-WORKTREE-DISCIPLINE.md")
    REF_FILES+=("$DOCS_DIR/REFERENCE-REPO-STRUCTURE.md")
    ;;
  # Sandbox skills → repo structure
  sandbox-create|sandbox-activate|sandbox-adopt|sandbox-try)
    REF_FILES+=("$DOCS_DIR/REFERENCE-REPO-STRUCTURE.md")
    ;;
  # Receipt infrastructure → QG + receipt spec
  quality-gate|pr-prep|iteration-complete|phase-complete)
    REF_FILES+=("$DOCS_DIR/REFERENCE-RECEIPT-INFRASTRUCTURE.md")
    ;;
esac

CONTENT=""
for REF_FILE in "${REF_FILES[@]+"${REF_FILES[@]}"}"; do
  if [ -f "$REF_FILE" ]; then
    CONTENT="${CONTENT}$(cat "$REF_FILE")"$'\n'
  fi
done

if [ -n "$CONTENT" ]; then
  printf '{"systemMessage":%s}' "$(printf '%s' "$CONTENT" | jq -Rs '.')"
fi
# No output when no ref matches — avoids empty system message in context

exit 0
