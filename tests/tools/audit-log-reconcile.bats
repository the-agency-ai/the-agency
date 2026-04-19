#!/usr/bin/env bats
#
# BATS: audit-log-reconcile (v46.0 reset — Phase 0b)
# Required min-test-count: 6 (per Plan v4 §3 Phase 0b)
# Actual tests: 6

setup() {
    REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
    TOOL="$REPO_ROOT/claude/tools/audit-log-reconcile"

    TMP_REPO="$(mktemp -d -t alr.XXXXXX)"
    cd "$TMP_REPO"
    git init -q -b main .
    git config user.email "test@test"
    git config user.name "test"
    echo seed > README
    git add .; git commit -q -m "seed"
    BASE="$(git rev-parse HEAD)"
}

teardown() {
    cd /
    rm -rf "$TMP_REPO"
}

@test "--help prints usage" {
    run "$TOOL" --help
    [ "$status" -eq 0 ]
}

@test "requires --log and --range" {
    run "$TOOL"
    [ "$status" -eq 2 ]
}

@test "perfect match exits 0" {
    # Commit: add new file foo.md
    echo "x" > foo.md
    git add foo.md; git commit -q -m "add"
    HEAD_REF="$(git rev-parse HEAD)"

    # Audit says: git-safe add foo.md
    cat > audit.jsonl <<EOF
{"ts":"2026-04-19T10:00:00Z","tool":"git-safe","cmd":"git-safe add","src":"foo.md","dst":""}
EOF

    run "$TOOL" --log audit.jsonl --range "$BASE..HEAD"
    [ "$status" -eq 0 ]
    [[ "$output" == *"audit_only=0"* ]]
    [[ "$output" == *"commit_only=0"* ]]
}

@test "audit entry with no matching commit is reported as AUDIT-ONLY" {
    cat > audit.jsonl <<EOF
{"ts":"2026-04-19T10:00:00Z","tool":"x","cmd":"git-safe add","src":"ghost.md","dst":""}
EOF
    run "$TOOL" --log audit.jsonl --range "$BASE..HEAD"
    [ "$status" -eq 0 ]
    [[ "$output" == *"AUDIT-ONLY"* ]]
}

@test "commit change with no matching audit is reported as COMMIT-ONLY" {
    echo "x" > foo.md
    git add foo.md; git commit -q -m "add"

    cat > audit.jsonl <<EOF
{"ts":"2026-04-19T10:00:00Z","tool":"x","cmd":"git-safe add","src":"somethingelse.md","dst":""}
EOF
    run "$TOOL" --log audit.jsonl --range "$BASE..HEAD"
    [ "$status" -eq 0 ]
    [[ "$output" == *"COMMIT-ONLY"* ]]
}

@test "--exit-nonzero-on-delta exits 1 on delta" {
    cat > audit.jsonl <<EOF
{"ts":"2026-04-19T10:00:00Z","tool":"x","cmd":"git-safe add","src":"ghost.md","dst":""}
EOF
    run "$TOOL" --log audit.jsonl --range "$BASE..HEAD" --exit-nonzero-on-delta
    [ "$status" -eq 1 ]
}
