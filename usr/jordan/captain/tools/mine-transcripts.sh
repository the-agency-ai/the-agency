#!/usr/bin/env bash
set -euo pipefail

# What Problem: I need to mine session transcripts for patterns, bugs, friction
# points, and decisions across multiple projects. This was being done inline by
# subagents every time — session 17 mining, mdpal mining, presence-detect mining —
# each costing 20+ tool calls to read JSONL chunks.
#
# How & Why: Extract user messages from JSONL session files and output as readable
# markdown for agent analysis. Chose grep+jq streaming over full JSON parsing
# because session files are 50MB+ and line-by-line is the only approach that
# doesn't blow memory. Shell script because it needs to run in any repo without
# dependencies. The output format is markdown so agents can analyze it directly.
#
# Written: 2026-04-04 during captain session 18 (ISCP workstream creation)

# Usage: mine-transcripts.sh <project-path-pattern> [--since YYYY-MM-DD]
#
# Examples:
#   mine-transcripts.sh the-agency
#   mine-transcripts.sh presence-detect --since 2026-04-01
#   mine-transcripts.sh monofolk
#
# Searches ~/.claude/projects/ for session JSONL files matching the pattern.
# Extracts user messages with timestamps, outputs as readable markdown.

PATTERN="${1:-}"
SINCE="${3:-}"

if [[ -z "$PATTERN" ]]; then
    echo "Usage: mine-transcripts.sh <project-path-pattern> [--since YYYY-MM-DD]"
    echo ""
    echo "Extracts user messages from Claude Code session JSONL files."
    echo "Output is markdown-formatted for agent analysis."
    exit 1
fi

# Parse --since flag
if [[ "${2:-}" == "--since" ]] && [[ -n "$SINCE" ]]; then
    SINCE_EPOCH=$(date -j -f "%Y-%m-%d" "$SINCE" "+%s" 2>/dev/null || date -d "$SINCE" "+%s" 2>/dev/null || echo "0")
else
    SINCE_EPOCH=0
fi

# Find matching session directories
SESSIONS_DIR="$HOME/.claude/projects"
if [[ ! -d "$SESSIONS_DIR" ]]; then
    echo "No sessions directory found at $SESSIONS_DIR" >&2
    exit 1
fi

# Find JSONL files in directories matching the pattern
FOUND=0
while IFS= read -r -d '' jsonl; do
    # Skip subagent files
    [[ "$jsonl" == *"/subagents/"* ]] && continue

    # Check date filter
    if [[ "$SINCE_EPOCH" -gt 0 ]]; then
        FILE_EPOCH=$(stat -f "%m" "$jsonl" 2>/dev/null || stat -c "%Y" "$jsonl" 2>/dev/null || echo "0")
        [[ "$FILE_EPOCH" -lt "$SINCE_EPOCH" ]] && continue
    fi

    SIZE=$(stat -f "%z" "$jsonl" 2>/dev/null || stat -c "%s" "$jsonl" 2>/dev/null || echo "?")
    SIZE_MB=$(echo "scale=1; $SIZE / 1048576" | bc 2>/dev/null || echo "?")

    SESSION_ID=$(basename "$jsonl" .jsonl)
    DIR_NAME=$(basename "$(dirname "$jsonl")")

    echo "# Session: $SESSION_ID"
    echo "**Path:** $jsonl"
    echo "**Size:** ${SIZE_MB}MB"
    echo "**Directory:** $DIR_NAME"
    echo ""

    # Extract user messages with timestamps
    echo "## User Messages"
    echo ""
    grep '"type":"user"' "$jsonl" 2>/dev/null | while IFS= read -r line; do
        TS=$(echo "$line" | jq -r '.timestamp // "?"' 2>/dev/null)
        # Extract text content - handle both string and array formats
        MSG=$(echo "$line" | jq -r '
            if .message.content | type == "string" then .message.content
            elif .message.content | type == "array" then
                [.message.content[] | select(.type == "text") | .text] | join("\n")
            else "?"
            end
        ' 2>/dev/null | head -c 2000)
        BRANCH=$(echo "$line" | jq -r '.gitBranch // ""' 2>/dev/null)

        echo "### [$TS] (branch: $BRANCH)"
        echo "$MSG"
        echo ""
    done

    echo "---"
    echo ""
    FOUND=$((FOUND + 1))
done < <(find "$SESSIONS_DIR" -path "*${PATTERN}*" -name "*.jsonl" -type f -print0 2>/dev/null | sort -z)

if [[ "$FOUND" -eq 0 ]]; then
    echo "No sessions found matching pattern: $PATTERN" >&2
    exit 1
fi

echo "Found $FOUND session(s)."
