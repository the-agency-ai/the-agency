#!/usr/bin/env bats
#
# skill-verify tests (D44-R4 / flag #163).
#
# Verifies the validator accepts current-generation skills (no allowed-tools
# per flag #62/#63) and rejects genuinely malformed skills.

load 'test_helper'

SKILL_VERIFY="${REPO_ROOT}/agency/tools/skill-verify"

# Build an isolated fixture with a .claude/skills/ layout we control.
_fixture() {
    export FIX="${BATS_TEST_TMPDIR}/skill-verify-repo"
    mkdir -p "$FIX/.claude/skills"
    cd "$FIX"
    git init --quiet --initial-branch=main 2>/dev/null || git init --quiet
    git config user.email "t@t.com"
    git config user.name "Test"
    git config commit.gpgsign false
    echo "r" > README.md
    git add -A
    git commit -m "init" --quiet --no-verify
}

_make_skill() {
    local name="$1"
    local content="$2"
    mkdir -p "$FIX/.claude/skills/$name"
    printf '%s' "$content" > "$FIX/.claude/skills/$name/SKILL.md"
}

# ─────────────────────────────────────────────────────────────────────────────

@test "skill-verify: accepts skill with description frontmatter and no allowed-tools" {
    _fixture
    _make_skill my-skill '---
description: Does a thing
---

# My Skill

Body.
'
    run env AGENCY_PROJECT_ROOT="$FIX" "$SKILL_VERIFY"
    [ "$status" -eq 0 ]
    [[ "$output" == *"1 skills verified"* ]]
}

@test "skill-verify: accepts skill WITH allowed-tools (backward compat)" {
    _fixture
    _make_skill legacy-skill '---
description: Legacy skill with explicit tools
allowed-tools: Read, Bash
---

# Legacy
'
    run env AGENCY_PROJECT_ROOT="$FIX" "$SKILL_VERIFY"
    [ "$status" -eq 0 ]
}

@test "skill-verify: rejects skill with no frontmatter (plain markdown)" {
    _fixture
    _make_skill no-frontmatter '# No Frontmatter

Body without frontmatter should fail.
'
    run env AGENCY_PROJECT_ROOT="$FIX" "$SKILL_VERIFY"
    [ "$status" -ne 0 ]
    [[ "$output" == *"missing frontmatter"* ]]
}

@test "skill-verify: rejects skill with empty description" {
    _fixture
    _make_skill empty-desc '---
description:
---

# Empty Desc
'
    run env AGENCY_PROJECT_ROOT="$FIX" "$SKILL_VERIFY"
    [ "$status" -ne 0 ]
    [[ "$output" == *"missing or empty description"* ]]
}

@test "skill-verify: rejects skill with missing description" {
    _fixture
    _make_skill no-desc '---
other-field: Something
---

# No Desc
'
    run env AGENCY_PROJECT_ROOT="$FIX" "$SKILL_VERIFY"
    [ "$status" -ne 0 ]
    [[ "$output" == *"missing or empty description"* ]]
}

@test "skill-verify: rejects empty SKILL.md" {
    _fixture
    _make_skill empty-skill ''
    run env AGENCY_PROJECT_ROOT="$FIX" "$SKILL_VERIFY"
    [ "$status" -ne 0 ]
    [[ "$output" == *"empty"* ]]
}

@test "skill-verify: reports missing SKILL.md file" {
    _fixture
    mkdir -p "$FIX/.claude/skills/no-skill-md"
    run env AGENCY_PROJECT_ROOT="$FIX" "$SKILL_VERIFY"
    [ "$status" -ne 0 ]
    [[ "$output" == *"Missing SKILL.md"* ]] || [[ "$output" == *"no-skill-md"* ]]
}

@test "skill-verify: --quiet suppresses output on success" {
    _fixture
    _make_skill good '---
description: Good
---
'
    run env AGENCY_PROJECT_ROOT="$FIX" "$SKILL_VERIFY" --quiet
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "skill-verify: --quiet still reports failures" {
    _fixture
    _make_skill bad '# No frontmatter
'
    run env AGENCY_PROJECT_ROOT="$FIX" "$SKILL_VERIFY" --quiet
    [ "$status" -ne 0 ]
    [[ -n "$output" ]]
}

@test "skill-verify: --help shows usage" {
    run "$SKILL_VERIFY" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage"* ]]
    [[ "$output" == *"--quiet"* ]]
}

@test "skill-verify: live framework skills pass validation (post flag #62/#63)" {
    # Sanity check against the real repo — the validator must accept every
    # shipping skill, otherwise /quality-gate Step 0 blocks on every run.
    run "$SKILL_VERIFY" --quiet
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}
