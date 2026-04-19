#!/usr/bin/env bats
#
# BATS: agency-verify-v46 (v46.0 reset — Phase 0b)
# Required min-test-count: 10 (per Plan v4 §3 Phase 0b)
# Actual tests: 10

setup() {
    REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
    TOOL="$REPO_ROOT/claude/tools/agency-verify-v46"

    TMP_REPO="$(mktemp -d -t avv.XXXXXX)"
    cd "$TMP_REPO"
    git init -q .
    git config user.email "test@test"
    git config user.name "test"
}

teardown() {
    cd /
    rm -rf "$TMP_REPO"
}

make_v46_tree() {
    mkdir -p agency/hooks agency/tools .claude/agents/jordan
    # agency is present; claude/ is not
    cat > .claude/settings.json <<'EOF'
{"hooks": {"PreToolUse": [{"hooks": [{"command": "$CLAUDE_PROJECT_DIR/agency/hooks/test.sh"}]}]}}
EOF
    echo "#!/bin/bash" > agency/hooks/test.sh
    chmod +x agency/hooks/test.sh
    cat > .claude/agents/jordan/captain.md <<'EOF'
@import @agency/agents/captain/agent.md
EOF
    git add -A; git commit -q -m seed
}

@test "--help prints usage" {
    run "$TOOL" --help
    [ "$status" -eq 0 ]
}

@test "requires --customer or --internal" {
    run "$TOOL"
    [ "$status" -eq 2 ]
}

@test "customer happy path on valid v46 tree" {
    make_v46_tree
    run "$TOOL" --customer
    [ "$status" -eq 0 ]
    [[ "$output" == *"all-checks"* ]]
}

@test "detects tree-shape mismatch: claude/ still present (exit 10)" {
    make_v46_tree
    mkdir -p claude/hooks
    run "$TOOL" --customer
    [ "$status" -eq 10 ]
    [[ "$output" == *"tree-shape"* ]]
}

@test "detects missing agency/ (exit 10)" {
    mkdir -p .claude
    echo '{}' > .claude/settings.json
    git add .; git commit -q -m seed
    run "$TOOL" --customer
    [ "$status" -eq 10 ]
}

@test "detects stale claude/hooks/ in settings.json (exit 11)" {
    make_v46_tree
    # Corrupt settings to reference old path
    cat > .claude/settings.json <<'EOF'
{"hooks": {"PreToolUse": [{"hooks": [{"command": "$CLAUDE_PROJECT_DIR/claude/hooks/test.sh"}]}]}}
EOF
    git add -A; git commit -q -m update
    run "$TOOL" --customer
    [ "$status" -eq 11 ]
}

@test "detects invalid JSON in settings (exit 11)" {
    make_v46_tree
    echo "INVALID {" > .claude/settings.json
    git add -A; git commit -q -m update
    run "$TOOL" --customer
    [ "$status" -eq 11 ]
}

@test "detects stale @claude/agents/ in registration (exit 12)" {
    make_v46_tree
    cat > .claude/agents/jordan/captain.md <<'EOF'
@import @claude/agents/captain/agent.md
EOF
    git add -A; git commit -q -m update
    run "$TOOL" --customer
    [ "$status" -eq 12 ]
}

@test "detects hook ENOENT (exit 14)" {
    make_v46_tree
    # Hook path missing
    rm agency/hooks/test.sh
    run "$TOOL" --customer
    [ "$status" -eq 14 ]
}

@test "--json emits structured output" {
    make_v46_tree
    run "$TOOL" --customer --json
    [ "$status" -eq 0 ]
    [[ "$output" == *'"severity":"OK"'* ]]
}
