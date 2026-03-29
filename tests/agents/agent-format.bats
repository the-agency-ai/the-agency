#!/usr/bin/env bats
#
# Validates agent file format and structure.
#
# Some agents use YAML frontmatter (newer format), others use markdown
# headers (legacy format). Tests validate:
#   - Agents with frontmatter have required fields: name, description
#   - All agent.md files exist and are non-empty
#   - Agents with frontmatter have valid model values when specified
#

load '../tools/test_helper'

AGENTS_DIR="${REPO_ROOT}/claude/agents"

# ─────────────────────────────────────────────────────────────────────────────
# Agent File Existence
# ─────────────────────────────────────────────────────────────────────────────

@test "agents: at least 10 agent directories exist" {
    local count=0
    for file in "${AGENTS_DIR}"/*/agent.md; do
        [[ -f "$file" ]] || continue
        count=$((count + 1))
    done
    if [[ "$count" -lt 10 ]]; then
        echo "Expected at least 10 agents, found $count" >&2
        return 1
    fi
}

@test "agents: all agent.md files are non-empty" {
    local failures=()
    for file in "${AGENTS_DIR}"/*/agent.md; do
        [[ -f "$file" ]] || continue
        if [[ ! -s "$file" ]]; then
            local agent_name
            agent_name="$(basename "$(dirname "$file")")"
            failures+=("${agent_name}/agent.md: empty file")
        fi
    done
    if [[ ${#failures[@]} -gt 0 ]]; then
        printf '%s\n' "${failures[@]}" >&2
        return 1
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# Frontmatter Validation (for agents that have it)
# ─────────────────────────────────────────────────────────────────────────────

@test "agents: frontmatter agents have 'name' field" {
    local failures=()
    for file in "${AGENTS_DIR}"/*/agent.md; do
        [[ -f "$file" ]] || continue
        local first_line
        first_line="$(head -1 "$file")"
        # Only check agents with frontmatter
        [[ "$first_line" == "---" ]] || continue
        if ! grep -q '^name:' "$file"; then
            local agent_name
            agent_name="$(basename "$(dirname "$file")")"
            failures+=("${agent_name}/agent.md: has frontmatter but missing name field")
        fi
    done
    if [[ ${#failures[@]} -gt 0 ]]; then
        printf '%s\n' "${failures[@]}" >&2
        return 1
    fi
}

@test "agents: frontmatter agents have 'description' field" {
    local failures=()
    for file in "${AGENTS_DIR}"/*/agent.md; do
        [[ -f "$file" ]] || continue
        local first_line
        first_line="$(head -1 "$file")"
        [[ "$first_line" == "---" ]] || continue
        if ! grep -q '^description:' "$file"; then
            local agent_name
            agent_name="$(basename "$(dirname "$file")")"
            failures+=("${agent_name}/agent.md: has frontmatter but missing description field")
        fi
    done
    if [[ ${#failures[@]} -gt 0 ]]; then
        printf '%s\n' "${failures[@]}" >&2
        return 1
    fi
}

@test "agents: frontmatter agents have closing delimiter" {
    local failures=()
    for file in "${AGENTS_DIR}"/*/agent.md; do
        [[ -f "$file" ]] || continue
        local first_line
        first_line="$(head -1 "$file")"
        [[ "$first_line" == "---" ]] || continue
        local count
        count="$(grep -c '^---$' "$file" || true)"
        if [[ "$count" -lt 2 ]]; then
            local agent_name
            agent_name="$(basename "$(dirname "$file")")"
            failures+=("${agent_name}/agent.md: frontmatter missing closing ---")
        fi
    done
    if [[ ${#failures[@]} -gt 0 ]]; then
        printf '%s\n' "${failures[@]}" >&2
        return 1
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# Model Field Validation
# ─────────────────────────────────────────────────────────────────────────────

@test "agents: model field values are valid when present" {
    local valid_models="opus sonnet haiku"
    local failures=()
    for file in "${AGENTS_DIR}"/*/agent.md; do
        [[ -f "$file" ]] || continue
        if grep -q '^model:' "$file"; then
            local model
            model="$(grep '^model:' "$file" | head -1 | sed 's/^model:[[:space:]]*//' | sed "s/['\"]//g")"
            local found=false
            for valid in $valid_models; do
                if [[ "$model" == "$valid" ]]; then
                    found=true
                    break
                fi
            done
            if [[ "$found" != "true" ]]; then
                local agent_name
                agent_name="$(basename "$(dirname "$file")")"
                failures+=("${agent_name}/agent.md: invalid model '$model' (expected: opus, sonnet, haiku)")
            fi
        fi
    done
    if [[ ${#failures[@]} -gt 0 ]]; then
        printf '%s\n' "${failures[@]}" >&2
        return 1
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# Legacy Format Validation (markdown-header agents)
# ─────────────────────────────────────────────────────────────────────────────

@test "agents: non-frontmatter agents start with a markdown heading" {
    local failures=()
    for file in "${AGENTS_DIR}"/*/agent.md; do
        [[ -f "$file" ]] || continue
        local first_line
        first_line="$(head -1 "$file")"
        # Skip frontmatter agents and templates
        [[ "$first_line" == "---" ]] && continue
        local dir_name
        dir_name="$(basename "$(dirname "$file")")"
        [[ "$dir_name" == "templates" ]] && continue
        if [[ ! "$first_line" =~ ^# ]]; then
            failures+=("${dir_name}/agent.md: expected to start with # heading, got: $first_line")
        fi
    done
    if [[ ${#failures[@]} -gt 0 ]]; then
        printf '%s\n' "${failures[@]}" >&2
        return 1
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# Name Consistency (frontmatter agents)
# ─────────────────────────────────────────────────────────────────────────────

@test "agents: frontmatter name field is non-empty" {
    local failures=()
    for file in "${AGENTS_DIR}"/*/agent.md; do
        [[ -f "$file" ]] || continue
        local first_line
        first_line="$(head -1 "$file")"
        [[ "$first_line" == "---" ]] || continue
        local name_value
        name_value="$(grep '^name:' "$file" | head -1 | sed 's/^name:[[:space:]]*//' | sed "s/['\"]//g")"
        if [[ -z "$name_value" ]]; then
            local agent_name
            agent_name="$(basename "$(dirname "$file")")"
            failures+=("${agent_name}: empty name field in frontmatter")
        fi
    done
    if [[ ${#failures[@]} -gt 0 ]]; then
        printf '%s\n' "${failures[@]}" >&2
        return 1
    fi
}
