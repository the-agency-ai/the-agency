#!/bin/bash
# What Problem: Agents persistently use raw shell commands (cat, grep, find,
# sed, awk, head, tail) instead of Claude Code's built-in tools (Read, Grep,
# Glob, Edit). Markdown-based hookify warn rules were ignored — agents kept
# reaching for the shell commands. Monofolk observed this pattern and escalated
# from warn to block. This hook enforces at the code level.
#
# How & Why: PreToolUse hook on Bash matcher. Reads the command from stdin,
# checks against a blocklist of raw commands that have superior built-in
# alternatives. Returns exit 2 (block) with an educative message pointing
# to the correct tool. Allows exceptions: commands inside framework tools
# (./claude/tools/*), git subcommands (git grep, git log), and explicit
# opt-out via AGENCY_ALLOW_RAW=1.
#
# This is the Enforcement Triangle at full strength: code enforcement,
# not instruction enforcement. Hookify markdown rules couldn't change
# behavior; this hook blocks it mechanically.
#
# Written: 2026-04-10 during captain session (35.3 — upstream from monofolk)

set -euo pipefail

[ -d /opt/homebrew/bin ] && export PATH="/opt/homebrew/bin:$PATH"
command -v jq >/dev/null 2>&1 || { printf '{}'; exit 0; }

# Read tool input from stdin
INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)

# No command = nothing to check
if [[ -z "$COMMAND" ]]; then
    printf '{}'
    exit 0
fi

# Allow framework tools to use whatever they need internally
# (e.g., dispatch-monitor uses grep internally, that's fine)
if [[ "$COMMAND" =~ ^\./claude/tools/ ]] || [[ "$COMMAND" =~ ^\"?\$CLAUDE_PROJECT_DIR ]]; then
    printf '{}'
    exit 0
fi

# Allow explicit opt-out (for legitimate edge cases)
if [[ "${AGENCY_ALLOW_RAW:-}" == "1" ]]; then
    printf '{}'
    exit 0
fi

# Strip leading whitespace for matching
TRIMMED=$(echo "$COMMAND" | sed 's/^[[:space:]]*//')

# Block raw cat — use Read tool
if [[ "$TRIMMED" =~ ^cat[[:space:]] ]] || [[ "$TRIMMED" == "cat" ]]; then
    printf '{"decision":"block","reason":"🐱 BLOCKED: Use the Read tool instead of `cat`. Read provides line numbers, offset/limit for large files, and image/PDF support. If Read genuinely cannot do what you need, file a bug via /agency-bug explaining why. — OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!"}'
    exit 2
fi

# Block raw grep/rg — use Grep tool
if [[ "$TRIMMED" =~ ^(grep|rg|egrep|fgrep)[[:space:]] ]] || [[ "$TRIMMED" =~ ^(grep|rg|egrep|fgrep)$ ]]; then
    printf '{"decision":"block","reason":"🔍 BLOCKED: Use the Grep tool instead of `grep`/`rg`. Grep has optimized permissions, regex support, glob filtering, and multiple output modes. If Grep genuinely cannot do what you need, file a bug via /agency-bug explaining why. — OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!"}'
    exit 2
fi

# Block raw find — use Glob tool
if [[ "$TRIMMED" =~ ^find[[:space:]] ]] || [[ "$TRIMMED" == "find" ]]; then
    printf '{"decision":"block","reason":"📁 BLOCKED: Use the Glob tool instead of `find`. Glob is fast, supports patterns like **/*.ts, and returns results sorted by modification time. If Glob genuinely cannot do what you need, file a bug via /agency-bug explaining why. — OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!"}'
    exit 2
fi

# Block raw sed/awk — use Edit tool
if [[ "$TRIMMED" =~ ^(sed|awk|gawk)[[:space:]] ]] || [[ "$TRIMMED" =~ ^(sed|awk|gawk)$ ]]; then
    printf '{"decision":"block","reason":"✏️ BLOCKED: Use the Edit tool instead of `sed`/`awk`. Edit performs exact string replacements with verification and supports replace_all for bulk changes. If Edit genuinely cannot do what you need, file a bug via /agency-bug explaining why. — OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!"}'
    exit 2
fi

# Block raw head/tail — use Read with offset/limit
if [[ "$TRIMMED" =~ ^(head|tail)[[:space:]] ]] || [[ "$TRIMMED" =~ ^(head|tail)$ ]]; then
    printf '{"decision":"block","reason":"📄 BLOCKED: Use the Read tool with offset and limit parameters instead of `head`/`tail`. Read(file, offset=N, limit=M) gives you exactly the lines you need. If Read genuinely cannot do what you need, file a bug via /agency-bug explaining why. — OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!"}'
    exit 2
fi

# NOTE: echo/printf/tee redirect rule removed — too many false positives.
# echo is used legitimately for piping to stdin, testing, etc.
# The Write tool instruction remains in CLAUDE.md as behavioral guidance.
# Revisit when we can reliably distinguish echo-to-file from echo-to-pipe.

# All clear
printf '{}'
exit 0
