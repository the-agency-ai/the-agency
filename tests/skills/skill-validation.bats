#!/usr/bin/env bats
#
# Skill validation tests — static tier testing for all framework skills
#
# Validates:
#   - Every skill has a SKILL.md that exists and is non-empty
#   - No skill contains monofolk-specific residue
#   - No skill references non-existent tools
#   - Skill count matches expected
#   - Valid SKILL.md frontmatter (has allowed-tools line)
#

REPO_ROOT="$(cd "$(dirname "${BATS_TEST_DIRNAME}")/.." && pwd)"
SKILLS_DIR="${REPO_ROOT}/.claude/skills"

# Expected framework skills (34 total)
EXPECTED_SKILL_COUNT=55

# ─────────────────────────────────────────────────────────────────────────────
# Skill existence and count
# ─────────────────────────────────────────────────────────────────────────────

@test "skills: directory exists" {
    [ -d "$SKILLS_DIR" ]
}

@test "skills: expected count ($EXPECTED_SKILL_COUNT)" {
    local count
    count=$(find "$SKILLS_DIR" -maxdepth 1 -mindepth 1 -type d | wc -l | tr -d ' ')
    [ "$count" -eq "$EXPECTED_SKILL_COUNT" ]
}

@test "skills: every skill has a non-empty SKILL.md" {
    local failures=""
    for skill_dir in "$SKILLS_DIR"/*/; do
        local name
        name=$(basename "$skill_dir")
        local skill_file="$skill_dir/SKILL.md"
        if [ ! -f "$skill_file" ]; then
            failures="${failures}MISSING: $name\n"
        elif [ ! -s "$skill_file" ]; then
            failures="${failures}EMPTY: $name\n"
        fi
    done
    if [ -n "$failures" ]; then
        echo -e "$failures" >&2
        return 1
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# Frontmatter validation
# ─────────────────────────────────────────────────────────────────────────────

@test "skills: no SKILL.md has allowed-tools in frontmatter (flag #62/#63 — removed)" {
    # Flag #62/#63: allowed-tools was removed from all skills because restricting
    # to specific subcommand patterns silently blocks agents on permission prompts
    # they cannot see. Skills inherit from .claude/settings.json instead.
    local failures=""
    for skill_dir in "$SKILLS_DIR"/*/; do
        local name
        name=$(basename "$skill_dir")
        if head -5 "$skill_dir/SKILL.md" | grep -q "allowed-tools:"; then
            failures="${failures}$name\n"
        fi
    done
    if [ -n "$failures" ]; then
        echo -e "Skills still have allowed-tools (should be removed per flag #62/#63):\n$failures" >&2
        return 1
    fi
}

@test "skills: every SKILL.md has description in frontmatter" {
    local failures=""
    for skill_dir in "$SKILLS_DIR"/*/; do
        local name
        name=$(basename "$skill_dir")
        if ! head -10 "$skill_dir/SKILL.md" | grep -q "description:"; then
            failures="${failures}$name\n"
        fi
    done
    if [ -n "$failures" ]; then
        echo -e "Missing description:\n$failures" >&2
        return 1
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# No monofolk residue
# ─────────────────────────────────────────────────────────────────────────────

@test "skills: no hardcoded usr/jordan/" {
    local hits
    hits=$(grep -rl "usr/jordan/" "$SKILLS_DIR" 2>/dev/null || true)
    if [ -n "$hits" ]; then
        echo "Found usr/jordan/ in:" >&2
        echo "$hits" >&2
        return 1
    fi
}

@test "skills: no monofolk references" {
    local hits
    hits=$(grep -rli "monofolk" "$SKILLS_DIR" 2>/dev/null || true)
    if [ -n "$hits" ]; then
        echo "Found monofolk in:" >&2
        echo "$hits" >&2
        return 1
    fi
}

@test "skills: no hardcoded doppler references" {
    local hits
    hits=$(grep -rli "doppler" "$SKILLS_DIR" 2>/dev/null || true)
    if [ -n "$hits" ]; then
        echo "Found doppler in:" >&2
        echo "$hits" >&2
        return 1
    fi
}

@test "skills: no hardcoded prisma references" {
    local hits
    hits=$(grep -rli "prisma" "$SKILLS_DIR" 2>/dev/null || true)
    if [ -n "$hits" ]; then
        echo "Found prisma in:" >&2
        echo "$hits" >&2
        return 1
    fi
}

@test "skills: no hardcoded pnpm references (use configurable test/lint commands)" {
    local hits
    # Exclude comments that mention pnpm as an example
    hits=$(grep -rl '\bpnpm\b' "$SKILLS_DIR" 2>/dev/null | while read -r f; do
        if grep -v '^#\|^<!--\|example\|e\.g\.' "$f" | grep -q '\bpnpm\b'; then
            echo "$f"
        fi
    done || true)
    if [ -n "$hits" ]; then
        echo "Found hardcoded pnpm in:" >&2
        echo "$hits" >&2
        return 1
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# Tool reference validation
# ─────────────────────────────────────────────────────────────────────────────

@test "skills: tool references in allowed-tools point to existing tools" {
    local failures=""
    for skill_dir in "$SKILLS_DIR"/*/; do
        local name
        name=$(basename "$skill_dir")
        # Extract tool names from Bash(./claude/tools/{name}*) patterns
        local tools
        tools=$(grep -o 'Bash(\./claude/tools/[a-z_-]*' "$skill_dir/SKILL.md" 2>/dev/null | sed 's|Bash(\./claude/tools/||' || true)
        for tool in $tools; do
            # Provider-dispatch tools use wildcards (e.g., deploy-*) — check for any matching tool
            if echo "$tool" | grep -q -- '-$'; then
                # Tool name ends with hyphen — it's a provider-dispatch prefix (e.g., "deploy-")
                # Skip validation — actual tool depends on configured provider
                continue
            fi
            if [ ! -f "$REPO_ROOT/claude/tools/$tool" ]; then
                failures="${failures}$name references missing tool: $tool\n"
            fi
        done
    done
    if [ -n "$failures" ]; then
        echo -e "$failures" >&2
        return 1
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# Ref-injector security
# ─────────────────────────────────────────────────────────────────────────────

@test "ref-injector: uses exact skill name matching (no substring leakage)" {
    local ref_injector="$REPO_ROOT/claude/hooks/ref-injector.sh"
    [ -f "$ref_injector" ] || skip "ref-injector.sh not found"
    # Should NOT contain wildcard patterns like *quality-gate*
    if grep -q '\*[a-z-]*\*' "$ref_injector"; then
        echo "ref-injector.sh contains substring wildcard patterns — use exact matching" >&2
        grep '\*[a-z-]*\*' "$ref_injector" >&2
        return 1
    fi
}
