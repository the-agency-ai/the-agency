#!/usr/bin/env bats
#
# BATS: agency-health-v46 (v46.0 reset — Phase 0b)
# Required min-test-count: 6 (per Plan v4 §3 Phase 0b)
# Actual tests: 6

setup() {
    REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
    TOOL="$REPO_ROOT/agency/tools/agency-health-v46"
    TMP_REPO="$(mktemp -d -t ahv.XXXXXX)"
    cd "$TMP_REPO"
    git init -q .
    git config user.email "t@t"
    git config user.name "t"
    echo seed > README
    git add .; git commit -q -m s
}

teardown() {
    cd /
    rm -rf "$TMP_REPO"
}

@test "--help prints usage" {
    run "$TOOL" --help
    [ "$status" -eq 0 ]
}

@test "healthy empty tree passes" {
    run "$TOOL"
    [ "$status" -eq 0 ]
}

@test "detects half-migrated tree (both claude/ and agency/)" {
    mkdir -p agency claude
    run "$TOOL"
    [ "$status" -eq 1 ]
    [[ "$output" == *"half-migrated"* ]]
}

@test "detects v46 tree with v45 settings.json" {
    mkdir -p agency .claude
    cat > .claude/settings.json <<'EOF'
{"hooks": {"PreToolUse": [{"hooks": [{"command": "$CLAUDE_PROJECT_DIR/claude/hooks/x.sh"}]}]}}
EOF
    run "$TOOL"
    [ "$status" -eq 1 ]
    [[ "$output" == *"claude/hooks"* ]]
}

@test "detects stale @agency/agents/ in registration" {
    mkdir -p .claude/agents/jordan
    cat > .claude/agents/jordan/captain.md <<'EOF'
@import @agency/agents/captain/agent.md
EOF
    run "$TOOL"
    [ "$status" -eq 1 ]
    [[ "$output" == *"@agency/agents"* ]]
}

@test "--json emits structured output" {
    mkdir -p agency claude
    run "$TOOL" --json
    [ "$status" -eq 1 ]
    [[ "$output" == *'"severity":"BROKEN"'* ]]
}
