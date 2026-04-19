#!/usr/bin/env bats
# Tests for agency/tools/enforcement-audit
#
# What Problem: enforcement-audit validates the enforcement registry. These tests
# verify it correctly detects valid registries, missing artifacts, and level
# mismatches.
#
# Written: 2026-04-07 during devex Phase 3.4

load test_helper

setup() {
    test_isolation_setup

    export TEST_REPO="${BATS_TEST_TMPDIR}/test-repo"
    mkdir -p "$TEST_REPO/claude/config"
    mkdir -p "$TEST_REPO/claude/tools"
    mkdir -p "$TEST_REPO/claude/docs"
    mkdir -p "$TEST_REPO/.claude/skills/my-skill"
    mkdir -p "$TEST_REPO/.git"

    cd "$TEST_REPO"
    git init --quiet --no-verify 2>/dev/null || git init --quiet

    # Copy the audit tool
    cp "$REPO_ROOT/agency/tools/enforcement-audit" "$TEST_REPO/agency/tools/"
    chmod +x "$TEST_REPO/agency/tools/enforcement-audit"

    # Copy log helper
    if [[ -f "$REPO_ROOT/agency/tools/lib/_log-helper" ]]; then
        mkdir -p "$TEST_REPO/agency/tools/lib"
        cp "$REPO_ROOT/agency/tools/lib/_log-helper" "$TEST_REPO/agency/tools/lib/"
    fi
}

teardown() {
    test_isolation_teardown
}

# ─────────────────────────────────────────────────────────────────────────────
# Valid registry
# ─────────────────────────────────────────────────────────────────────────────

@test "valid: level 1 capability with doc passes" {
    cd "$TEST_REPO"
    echo "# docs" > claude/docs/MY-DOC.md
    cat > agency/config/enforcement.yaml <<'YAML'
version: 1
capabilities:
  my-cap:
    level: 1
    description: "test"
    artifacts:
      doc: "claude/docs/MY-DOC.md"
YAML
    run ./agency/tools/enforcement-audit
    [ "$status" -eq 0 ]
    [[ "$output" == *"All capabilities valid"* ]]
}

@test "valid: level 3 capability with all artifacts passes" {
    cd "$TEST_REPO"
    echo "# docs" > claude/docs/MY-DOC.md
    echo "# skill" > .claude/skills/my-skill/SKILL.md
    echo '#!/bin/bash' > agency/tools/my-tool
    cat > agency/config/enforcement.yaml <<'YAML'
version: 1
capabilities:
  my-cap:
    level: 3
    description: "test"
    artifacts:
      doc: "claude/docs/MY-DOC.md"
      skill: ".claude/skills/my-skill/SKILL.md"
      tool: "agency/tools/my-tool"
YAML
    run ./agency/tools/enforcement-audit
    [ "$status" -eq 0 ]
    [[ "$output" == *"All capabilities valid"* ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Missing artifacts
# ─────────────────────────────────────────────────────────────────────────────

@test "missing: level 2 without skill fails" {
    cd "$TEST_REPO"
    echo "# docs" > claude/docs/MY-DOC.md
    cat > agency/config/enforcement.yaml <<'YAML'
version: 1
capabilities:
  my-cap:
    level: 2
    description: "test"
    artifacts:
      doc: "claude/docs/MY-DOC.md"
YAML
    run ./agency/tools/enforcement-audit
    [ "$status" -eq 1 ]
    [[ "$output" == *"NOT DECLARED"* ]]
}

@test "missing: level 3 with missing tool file fails" {
    cd "$TEST_REPO"
    echo "# docs" > claude/docs/MY-DOC.md
    echo "# skill" > .claude/skills/my-skill/SKILL.md
    cat > agency/config/enforcement.yaml <<'YAML'
version: 1
capabilities:
  my-cap:
    level: 3
    description: "test"
    artifacts:
      doc: "claude/docs/MY-DOC.md"
      skill: ".claude/skills/my-skill/SKILL.md"
      tool: "agency/tools/nonexistent"
YAML
    run ./agency/tools/enforcement-audit
    [ "$status" -eq 1 ]
    [[ "$output" == *"FILE NOT FOUND"* ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Multiple capabilities
# ─────────────────────────────────────────────────────────────────────────────

@test "mixed: reports correct pass/fail count" {
    cd "$TEST_REPO"
    echo "# docs" > claude/docs/MY-DOC.md
    cat > agency/config/enforcement.yaml <<'YAML'
version: 1
capabilities:
  good-cap:
    level: 1
    description: "test"
    artifacts:
      doc: "claude/docs/MY-DOC.md"
  bad-cap:
    level: 2
    description: "test"
    artifacts:
      doc: "claude/docs/MY-DOC.md"
YAML
    run ./agency/tools/enforcement-audit
    [ "$status" -eq 1 ]
    [[ "$output" == *"2 total"* ]]
    [[ "$output" == *"1 passed"* ]]
    [[ "$output" == *"1 failed"* ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Edge cases
# ─────────────────────────────────────────────────────────────────────────────

@test "missing registry file fails" {
    cd "$TEST_REPO"
    rm -f agency/config/enforcement.yaml
    run ./agency/tools/enforcement-audit
    [ "$status" -eq 1 ]
}

@test "version flag works" {
    run ./agency/tools/enforcement-audit --version
    [ "$status" -eq 0 ]
    [[ "$output" == *"enforcement-audit"* ]]
}
