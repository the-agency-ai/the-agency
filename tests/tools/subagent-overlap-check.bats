#!/usr/bin/env bats
#
# BATS: subagent-overlap-check (v46.0 reset — Phase 0b)
# Required min-test-count: 5 (per Plan v4 §3 Phase 0b)
# Actual tests: 6

setup() {
    REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
    TOOL="$REPO_ROOT/claude/tools/subagent-overlap-check"

    TMP_REPO="$(mktemp -d -t soc.XXXXXX)"
    cd "$TMP_REPO"
    git init -q .
    git config user.email "test@test"
    git config user.name "test"

    mkdir -p agency/tools agency/docs tests
    echo "x" > agency/tools/a
    echo "y" > agency/tools/shared  # In both A + C scope
    echo "z" > agency/docs/b
    echo "q" > tests/t
    git add .; git commit -q -m "seed"

    # Subagent A manifest — owns agency/tools/
    cat > A.yaml <<'EOF'
subagent: A
ownership_priority: 1
files:
  - agency/tools/*
EOF
    # Subagent B — owns agency/docs/
    cat > B.yaml <<'EOF'
subagent: B
ownership_priority: 2
files:
  - agency/docs/*
EOF
    # Subagent C — owns tests/ AND tries to claim agency/tools/shared
    cat > C-overlap.yaml <<'EOF'
subagent: C
ownership_priority: 3
files:
  - tests/*
  - agency/tools/shared
EOF
    cat > C-disjoint.yaml <<'EOF'
subagent: C
ownership_priority: 3
files:
  - tests/*
EOF
}

teardown() {
    cd /
    rm -rf "$TMP_REPO"
}

@test "--help prints usage" {
    run "$TOOL" --help
    [ "$status" -eq 0 ]
}

@test "requires at least 2 manifests" {
    run "$TOOL" A.yaml
    [ "$status" -eq 2 ]
}

@test "disjoint manifests exit 0 OK" {
    run "$TOOL" A.yaml B.yaml C-disjoint.yaml
    [ "$status" -eq 0 ]
    [[ "$output" == *"no overlap"* ]]
}

@test "overlapping manifests report OVERLAP and exit 1" {
    run "$TOOL" A.yaml C-overlap.yaml
    [ "$status" -eq 1 ]
    [[ "$output" == *"OVERLAP"* ]]
    [[ "$output" == *"agency/tools/shared"* ]]
}

@test "winner tie-break uses ownership_priority (lower wins)" {
    run "$TOOL" A.yaml C-overlap.yaml
    [ "$status" -eq 1 ]
    [[ "$output" == *"winner=A"* ]]
}

@test "--json emits structured output" {
    run "$TOOL" A.yaml C-overlap.yaml --json
    [ "$status" -eq 1 ]
    [[ "$output" == *'"file":"agency/tools/shared"'* ]]
    [[ "$output" == *'"winner":"A"'* ]]
}
