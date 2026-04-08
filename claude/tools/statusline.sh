#!/bin/bash
#
# statusline.sh — Claude Code status line with usage tracking
#
# Format:
#   2.1.87 with Opus 4.6 (1M context) | monofolk (master) ✎4 "captain" | ctx: 61% | 5h: 33% → 19:00 7d: 3% → Mon 14:00 | $432.07 · 66h38m
#
# Reads JSON from stdin (Claude Code status line input).
# Usage data (5h/7d) comes from Claude Code's native rate_limits field.
#
# Install: In settings.json or settings.local.json:
#   "statusLine": { "type": "command", "command": "bash /path/to/statusline.sh" }

input=$(cat)

# --- Parse input JSON ---
cwd=$(echo "$input" | jq -r '.workspace.current_dir')
version=$(echo "$input" | jq -r '.version // empty')
model=$(echo "$input" | jq -r '.model.display_name')
remaining=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty')
total_cost=$(echo "$input" | jq -r '.cost.total_cost_usd // empty')
duration_ms=$(echo "$input" | jq -r '.cost.total_duration_ms // empty')
session_name=$(echo "$input" | jq -r '.session_name // empty')
worktree_name=$(echo "$input" | jq -r '.worktree.name // empty')
vim_mode=$(echo "$input" | jq -r '.vim.mode // empty')
output_style=$(echo "$input" | jq -r '.output_style.name')

# --- Rate limits (native from Claude Code) ---
five_h_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
five_h_reset=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
seven_d_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
seven_d_reset=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')

# --- Repo + branch + dirty ---
dir_name=$(basename "$cwd")
branch=""
git_dirty=""

if git -C "$cwd" --no-optional-locks rev-parse --git-dir > /dev/null 2>&1; then
    branch=$(git -C "$cwd" --no-optional-locks branch --show-current 2>/dev/null)

    staged=$(git -C "$cwd" --no-optional-locks diff --cached --numstat 2>/dev/null | wc -l | tr -d ' ')
    modified=$(git -C "$cwd" --no-optional-locks diff --numstat 2>/dev/null | wc -l | tr -d ' ')

    if [ "$staged" -gt 0 ] 2>/dev/null; then
        git_dirty=" ●${staged}"
    fi
    if [ "$modified" -gt 0 ] 2>/dev/null; then
        git_dirty="${git_dirty} ✎${modified}"
    fi
fi

# --- Location: repo (branch) dirty "session" ---
if [ -n "$worktree_name" ]; then
    location="${dir_name} (${worktree_name})"
elif [ -n "$branch" ]; then
    location="${dir_name} (${branch})"
else
    location="${dir_name}"
fi
location="${location}${git_dirty}"

if [ -n "$session_name" ]; then
    location="${location} \"${session_name}\""
fi

# --- Version + model ---
if [ -n "$version" ]; then
    version_model="${version} with ${model}"
else
    version_model="${model}"
fi

# --- Context ---
ctx_label=""
if [ -n "$remaining" ]; then
    remaining_int=${remaining%.*}
    if [ -n "$remaining_int" ] && [ "$remaining_int" -le 20 ] 2>/dev/null; then
        ctx_label="ctx: ${remaining}% (!)"
    else
        ctx_label="ctx: ${remaining}%"
    fi
fi

# --- Usage windows (5h + 7d) ---
usage_info=""

# Format reset timestamp to human-readable ETA
# Supports both macOS (date -r) and Linux (date -d @)
format_reset() {
    local reset_ts="$1"
    if [ -z "$reset_ts" ]; then
        return
    fi
    local now_date
    now_date=$(date +%Y-%m-%d)

    # Try macOS first, then Linux
    local reset_date
    reset_date=$(date -r "$reset_ts" +%Y-%m-%d 2>/dev/null) \
        || reset_date=$(date -d "@$reset_ts" +%Y-%m-%d 2>/dev/null) \
        || return

    if [ "$reset_date" = "$now_date" ]; then
        date -r "$reset_ts" +%H:%M 2>/dev/null \
            || date -d "@$reset_ts" +%H:%M 2>/dev/null
    else
        date -r "$reset_ts" +"%a %H:%M" 2>/dev/null \
            || date -d "@$reset_ts" +"%a %H:%M" 2>/dev/null
    fi
}

if [ -n "$five_h_pct" ]; then
    five_h_int=${five_h_pct%.*}
    h5="5h: ${five_h_int}%"
    five_h_eta=$(format_reset "$five_h_reset")
    if [ -n "$five_h_eta" ]; then
        h5="${h5} → ${five_h_eta}"
    fi
    usage_info="${h5}"
fi

if [ -n "$seven_d_pct" ]; then
    seven_d_int=${seven_d_pct%.*}
    d7="7d: ${seven_d_int}%"
    seven_d_eta=$(format_reset "$seven_d_reset")
    if [ -n "$seven_d_eta" ]; then
        d7="${d7} → ${seven_d_eta}"
    fi
    if [ -n "$usage_info" ]; then
        usage_info="${usage_info} ${d7}"
    else
        usage_info="${d7}"
    fi
fi

# --- Cost + duration ---
cost_dur=""
if [ -n "$total_cost" ]; then
    cost_fmt=$(printf '%.2f' "$total_cost" 2>/dev/null)
    cost_dur="\$$cost_fmt"
fi
if [ -n "$duration_ms" ] && [ "$duration_ms" != "0" ]; then
    total_sec=$((duration_ms / 1000))
    if [ "$total_sec" -ge 3600 ] 2>/dev/null; then
        hrs=$((total_sec / 3600))
        mins=$(( (total_sec % 3600) / 60 ))
        dur="${hrs}h${mins}m"
    elif [ "$total_sec" -ge 60 ] 2>/dev/null; then
        mins=$((total_sec / 60))
        dur="${mins}m"
    else
        dur="${total_sec}s"
    fi
    if [ -n "$cost_dur" ]; then
        cost_dur="${cost_dur} · ${dur}"
    else
        cost_dur="${dur}"
    fi
fi

# --- Output style ---
style_info=""
if [ "$output_style" != "default" ] && [ -n "$output_style" ]; then
    style_info=" [${output_style}]"
fi

# --- Vim mode ---
vim_info=""
if [ -n "$vim_mode" ]; then
    vim_info=" [${vim_mode}]"
fi

# --- ISCP mail indicator ---
# Silent periodic polling via status line — shows unread dispatch/flag count
# in the footer bar without touching the transcript. See iscp-check --statusline.
# Fast (<50ms typical); graceful on failure (empty output).
iscp_script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
iscp_mail=""
if [ -x "$iscp_script_dir/iscp-check" ]; then
    iscp_mail=$("$iscp_script_dir/iscp-check" --statusline 2>/dev/null || true)
fi
iscp_info=""
if [ -n "$iscp_mail" ]; then
    iscp_info=" | ${iscp_mail}"
fi

# --- Assemble ---
status_line="${version_model} | ${location}"
if [ -n "$ctx_label" ]; then
    status_line="${status_line} | ${ctx_label}"
fi
if [ -n "$usage_info" ]; then
    status_line="${status_line} | ${usage_info}"
fi
if [ -n "$cost_dur" ]; then
    status_line="${status_line} | ${cost_dur}"
fi
status_line="${status_line}${iscp_info}${style_info}${vim_info}"

printf "%s" "$status_line"
