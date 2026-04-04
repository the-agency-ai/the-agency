#!/usr/bin/env bats
#
# Tests for tools/settings-merge — key-based hook merge
#
# Tests that framework hooks are replaced from template,
# project-specific hooks are preserved, permissions are
# array-unioned, and other keys survive the merge.
#

load 'test_helper'

setup() {
    # Create temp directory for test artifacts
    export BATS_TEST_TMPDIR="$(mktemp -d)"

    # Create a minimal project structure
    mkdir -p "${BATS_TEST_TMPDIR}/.claude"
    mkdir -p "${BATS_TEST_TMPDIR}/claude/config"
    mkdir -p "${BATS_TEST_TMPDIR}/claude/tools/lib"

    # Copy the tools we need
    cp "${TOOLS_DIR}/settings-merge" "${BATS_TEST_TMPDIR}/claude/tools/settings-merge"
    cp "${TOOLS_DIR}/lib/_log-helper" "${BATS_TEST_TMPDIR}/claude/tools/lib/_log-helper"
    chmod +x "${BATS_TEST_TMPDIR}/claude/tools/settings-merge"

    cd "${BATS_TEST_TMPDIR}"
}

teardown() {
    if [[ -d "${BATS_TEST_TMPDIR}" ]]; then
        rm -rf "${BATS_TEST_TMPDIR}"
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# Framework hook replacement
# ─────────────────────────────────────────────────────────────────────────────

@test "settings-merge: framework hook updated when template changes" {
    cat > .claude/settings.json << 'JSON'
{
  "hooks": {
    "PreToolUse": [
      {"matcher": "Skill", "hooks": [{"type": "command", "command": "old-version.sh"}]}
    ]
  },
  "permissions": {"allow": []}
}
JSON
    cat > claude/config/settings-template.json << 'JSON'
{
  "hooks": {
    "PreToolUse": [
      {"matcher": "Skill", "hooks": [{"type": "command", "command": "new-version.sh"}]}
    ]
  },
  "permissions": {"allow": []}
}
JSON

    run ./claude/tools/settings-merge
    assert_success

    # Verify the hook was replaced
    local command
    command=$(jq -r '.hooks.PreToolUse[] | select(.matcher == "Skill") | .hooks[0].command' .claude/settings.json)
    [[ "$command" == "new-version.sh" ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Project hook preservation
# ─────────────────────────────────────────────────────────────────────────────

@test "settings-merge: project-specific hook preserved across merge" {
    cat > .claude/settings.json << 'JSON'
{
  "hooks": {
    "PreToolUse": [
      {"matcher": "Skill", "hooks": [{"type": "command", "command": "old-ref-injector.sh"}]},
      {"matcher": "Edit", "hooks": [{"type": "command", "command": "my-project-edit-hook.sh"}]}
    ]
  },
  "permissions": {"allow": []}
}
JSON
    cat > claude/config/settings-template.json << 'JSON'
{
  "hooks": {
    "PreToolUse": [
      {"matcher": "Skill", "hooks": [{"type": "command", "command": "new-ref-injector.sh"}]}
    ]
  },
  "permissions": {"allow": []}
}
JSON

    run ./claude/tools/settings-merge
    assert_success

    # Framework hook replaced
    local skill_cmd
    skill_cmd=$(jq -r '.hooks.PreToolUse[] | select(.matcher == "Skill") | .hooks[0].command' .claude/settings.json)
    [[ "$skill_cmd" == "new-ref-injector.sh" ]]

    # Project hook preserved
    local edit_cmd
    edit_cmd=$(jq -r '.hooks.PreToolUse[] | select(.matcher == "Edit") | .hooks[0].command' .claude/settings.json)
    [[ "$edit_cmd" == "my-project-edit-hook.sh" ]]
}

@test "settings-merge: hooks from non-template event types preserved" {
    cat > .claude/settings.json << 'JSON'
{
  "hooks": {
    "PreToolUse": [
      {"matcher": "Skill", "hooks": [{"type": "command", "command": "old.sh"}]}
    ],
    "SessionStart": [
      {"hooks": [{"type": "command", "command": "my-session-hook.sh"}]}
    ]
  },
  "permissions": {"allow": []}
}
JSON
    cat > claude/config/settings-template.json << 'JSON'
{
  "hooks": {
    "PreToolUse": [
      {"matcher": "Skill", "hooks": [{"type": "command", "command": "new.sh"}]}
    ]
  },
  "permissions": {"allow": []}
}
JSON

    run ./claude/tools/settings-merge
    assert_success

    # SessionStart hook preserved (not in template)
    local session_cmd
    session_cmd=$(jq -r '.hooks.SessionStart[0].hooks[0].command' .claude/settings.json)
    [[ "$session_cmd" == "my-session-hook.sh" ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Permissions
# ─────────────────────────────────────────────────────────────────────────────

@test "settings-merge: permissions.deny preserved (F2 regression)" {
    cat > .claude/settings.json << 'JSON'
{
  "hooks": {},
  "permissions": {
    "allow": ["Bash(./tools/*:*)"],
    "deny": ["Bash(rm -rf *)"]
  }
}
JSON
    cat > claude/config/settings-template.json << 'JSON'
{
  "hooks": {},
  "permissions": {
    "allow": ["Bash(./claude/tools/*:*)"]
  }
}
JSON

    run ./claude/tools/settings-merge
    assert_success

    # deny preserved
    local deny
    deny=$(jq -r '.permissions.deny[0]' .claude/settings.json)
    [[ "$deny" == "Bash(rm -rf *)" ]]

    # allow merged (union)
    local allow_count
    allow_count=$(jq '.permissions.allow | length' .claude/settings.json)
    [[ "$allow_count" -eq 2 ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Other keys
# ─────────────────────────────────────────────────────────────────────────────

@test "settings-merge: enabledPlugins preserved" {
    cat > .claude/settings.json << 'JSON'
{
  "hooks": {},
  "permissions": {"allow": []},
  "enabledPlugins": ["my-plugin"]
}
JSON
    cat > claude/config/settings-template.json << 'JSON'
{
  "hooks": {},
  "permissions": {"allow": []}
}
JSON

    run ./claude/tools/settings-merge
    assert_success

    local plugin
    plugin=$(jq -r '.enabledPlugins[0]' .claude/settings.json)
    [[ "$plugin" == "my-plugin" ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Edge cases
# ─────────────────────────────────────────────────────────────────────────────

@test "settings-merge: creates settings.json from template when missing" {
    rm -f .claude/settings.json
    cat > claude/config/settings-template.json << 'JSON'
{
  "hooks": {},
  "permissions": {"allow": ["Bash(./claude/tools/*:*)"]}
}
JSON

    run ./claude/tools/settings-merge
    assert_success
    assert_file_exists .claude/settings.json
}

@test "settings-merge: --dry-run does not modify files" {
    cat > .claude/settings.json << 'JSON'
{
  "hooks": {},
  "permissions": {"allow": ["existing"]}
}
JSON
    cat > claude/config/settings-template.json << 'JSON'
{
  "hooks": {},
  "permissions": {"allow": ["new-perm"]}
}
JSON

    local before
    before=$(cat .claude/settings.json)

    run ./claude/tools/settings-merge --dry-run
    assert_success

    local after
    after=$(cat .claude/settings.json)
    [[ "$before" == "$after" ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Permission assertions (Plan 5.4)
# ─────────────────────────────────────────────────────────────────────────────

@test "settings-merge: scoped unzip permission present after merge" {
    cat > .claude/settings.json << 'JSON'
{
  "hooks": {},
  "permissions": {"allow": []}
}
JSON
    cat > claude/config/settings-template.json << 'JSON'
{
  "hooks": {},
  "permissions": {"allow": ["Bash(unzip -d usr/*:*)", "Bash(./claude/tools/*:*)"]}
}
JSON

    run ./claude/tools/settings-merge
    assert_success
    jq -e '.permissions.allow | index("Bash(unzip -d usr/*:*)")' .claude/settings.json > /dev/null
}

@test "settings-merge: unzip wildcard NOT present" {
    cat > .claude/settings.json << 'JSON'
{
  "hooks": {},
  "permissions": {"allow": ["Bash(unzip:*)"]}
}
JSON
    cat > claude/config/settings-template.json << 'JSON'
{
  "hooks": {},
  "permissions": {"allow": ["Bash(unzip -d usr/*:*)"]}
}
JSON

    run ./claude/tools/settings-merge
    assert_success
    # The wildcard should survive (union), but it should NOT be in the template
    ! jq -e '.permissions.allow | index("Bash(unzip:*)")' claude/config/settings-template.json > /dev/null
}

@test "settings-merge: Read(usr/**) permission present" {
    cat > .claude/settings.json << 'JSON'
{
  "hooks": {},
  "permissions": {"allow": []}
}
JSON
    cat > claude/config/settings-template.json << 'JSON'
{
  "hooks": {},
  "permissions": {"allow": ["Read(usr/**)", "Glob(usr/**)"]}
}
JSON

    run ./claude/tools/settings-merge
    assert_success
    jq -e '.permissions.allow | index("Read(usr/**)")' .claude/settings.json > /dev/null
    jq -e '.permissions.allow | index("Glob(usr/**)")' .claude/settings.json > /dev/null
}

@test "settings-merge: idempotent — merge twice, no duplicates" {
    cat > .claude/settings.json << 'JSON'
{
  "hooks": {},
  "permissions": {"allow": []}
}
JSON
    cat > claude/config/settings-template.json << 'JSON'
{
  "hooks": {},
  "permissions": {"allow": ["Bash(unzip -d usr/*:*)", "Bash(./claude/tools/*:*)"]}
}
JSON

    run ./claude/tools/settings-merge
    assert_success
    run ./claude/tools/settings-merge
    assert_success

    # Count occurrences of unzip permission — should be exactly 1
    local count
    count=$(jq '[.permissions.allow[] | select(. == "Bash(unzip -d usr/*:*)")] | length' .claude/settings.json)
    [[ "$count" -eq 1 ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Edge cases (continued)
# ─────────────────────────────────────────────────────────────────────────────

@test "settings-merge: hook with no matcher uses empty string as key" {
    cat > .claude/settings.json << 'JSON'
{
  "hooks": {
    "SessionEnd": [
      {"hooks": [{"type": "command", "command": "old-session-end.sh"}]}
    ]
  },
  "permissions": {"allow": []}
}
JSON
    cat > claude/config/settings-template.json << 'JSON'
{
  "hooks": {
    "SessionEnd": [
      {"hooks": [{"type": "command", "command": "new-session-end.sh"}]}
    ]
  },
  "permissions": {"allow": []}
}
JSON

    run ./claude/tools/settings-merge
    assert_success

    # Hook without matcher should be replaced (matched by empty matcher)
    local cmd
    cmd=$(jq -r '.hooks.SessionEnd[0].hooks[0].command' .claude/settings.json)
    [[ "$cmd" == "new-session-end.sh" ]]
}
