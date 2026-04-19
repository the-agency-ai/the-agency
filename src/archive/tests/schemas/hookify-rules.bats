#!/usr/bin/env bats
#
# Validates all hookify rules have valid YAML frontmatter.
#
# Checks:
#   - Each .md file in agency/hookify/ has YAML frontmatter delimiters
#   - Required field: name
#   - Required field: event (one of: bash, file, stop, prompt, all)
#   - bash-event rules require: action (one of: warn, block)
#

load '../tools/test_helper'

HOOKIFY_DIR="${REPO_ROOT}/claude/hookify"

# ─────────────────────────────────────────────────────────────────────────────
# Frontmatter Presence
# ─────────────────────────────────────────────────────────────────────────────

@test "hookify: all rules have YAML frontmatter" {
    local failures=()
    for file in "${HOOKIFY_DIR}"/*.md; do
        [[ -f "$file" ]] || continue
        local first_line
        first_line="$(head -1 "$file")"
        if [[ "$first_line" != "---" ]]; then
            failures+=("$(basename "$file"): missing opening ---")
        fi
    done
    if [[ ${#failures[@]} -gt 0 ]]; then
        printf '%s\n' "${failures[@]}" >&2
        return 1
    fi
}

@test "hookify: all rules have closing frontmatter delimiter" {
    local failures=()
    for file in "${HOOKIFY_DIR}"/*.md; do
        [[ -f "$file" ]] || continue
        # Count --- lines; need at least 2 (opening + closing)
        local count
        count="$(grep -c '^---$' "$file")"
        if [[ "$count" -lt 2 ]]; then
            failures+=("$(basename "$file"): missing closing ---")
        fi
    done
    if [[ ${#failures[@]} -gt 0 ]]; then
        printf '%s\n' "${failures[@]}" >&2
        return 1
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# Required Fields
# ─────────────────────────────────────────────────────────────────────────────

@test "hookify: all rules have 'name' field" {
    local failures=()
    for file in "${HOOKIFY_DIR}"/*.md; do
        [[ -f "$file" ]] || continue
        if ! grep -q '^name:' "$file"; then
            failures+=("$(basename "$file"): missing name field")
        fi
    done
    if [[ ${#failures[@]} -gt 0 ]]; then
        printf '%s\n' "${failures[@]}" >&2
        return 1
    fi
}

@test "hookify: all rules have 'event' field" {
    local failures=()
    for file in "${HOOKIFY_DIR}"/*.md; do
        [[ -f "$file" ]] || continue
        if ! grep -q '^event:' "$file"; then
            failures+=("$(basename "$file"): missing event field")
        fi
    done
    if [[ ${#failures[@]} -gt 0 ]]; then
        printf '%s\n' "${failures[@]}" >&2
        return 1
    fi
}

@test "hookify: bash-event rules have 'action' field" {
    local failures=()
    for file in "${HOOKIFY_DIR}"/*.md; do
        [[ -f "$file" ]] || continue
        # Only check bash-event rules (file-event rules use conditions instead)
        if grep -q '^event: bash' "$file"; then
            if ! grep -q '^action:' "$file"; then
                failures+=("$(basename "$file"): bash event missing action field")
            fi
        fi
    done
    if [[ ${#failures[@]} -gt 0 ]]; then
        printf '%s\n' "${failures[@]}" >&2
        return 1
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# Enum Validation
# ─────────────────────────────────────────────────────────────────────────────

@test "hookify: event field is a valid type" {
    local valid_events="bash file stop prompt all"
    local failures=()
    for file in "${HOOKIFY_DIR}"/*.md; do
        [[ -f "$file" ]] || continue
        local event
        event="$(grep '^event:' "$file" | head -1 | sed 's/^event:[[:space:]]*//' | sed "s/['\"]//g")"
        local found=false
        for valid in $valid_events; do
            if [[ "$event" == "$valid" ]]; then
                found=true
                break
            fi
        done
        if [[ "$found" != "true" ]]; then
            failures+=("$(basename "$file"): invalid event '$event'")
        fi
    done
    if [[ ${#failures[@]} -gt 0 ]]; then
        printf '%s\n' "${failures[@]}" >&2
        return 1
    fi
}

@test "hookify: action field is warn or block when present" {
    local failures=()
    for file in "${HOOKIFY_DIR}"/*.md; do
        [[ -f "$file" ]] || continue
        if grep -q '^action:' "$file"; then
            local action
            action="$(grep '^action:' "$file" | head -1 | sed 's/^action:[[:space:]]*//' | sed "s/['\"]//g")"
            if [[ "$action" != "warn" ]] && [[ "$action" != "block" ]]; then
                failures+=("$(basename "$file"): invalid action '$action' (expected warn or block)")
            fi
        fi
    done
    if [[ ${#failures[@]} -gt 0 ]]; then
        printf '%s\n' "${failures[@]}" >&2
        return 1
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# Count Validation
# ─────────────────────────────────────────────────────────────────────────────

@test "hookify: at least 10 rules exist" {
    local count=0
    for file in "${HOOKIFY_DIR}"/*.md; do
        [[ -f "$file" ]] || continue
        count=$((count + 1))
    done
    if [[ "$count" -lt 10 ]]; then
        echo "Expected at least 10 hookify rules, found $count" >&2
        return 1
    fi
}
