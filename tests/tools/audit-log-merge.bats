#!/usr/bin/env bats
#
# BATS: audit-log-merge (v46.0 reset — Phase 0b)
# Required min-test-count: 4 (per Plan v4 §3 Phase 0b)
# Actual tests: 5

setup() {
    REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
    TOOL="$REPO_ROOT/agency/tools/audit-log-merge"
    TMP="$(mktemp -d -t alm.XXXXXX)"
    cd "$TMP"

    cat > a.jsonl <<'EOF'
{"ts":"2026-04-19T10:00:00Z","tool":"x","cmd":"git mv","src":"a","dst":"b"}
{"ts":"2026-04-19T10:02:00Z","tool":"x","cmd":"git mv","src":"c","dst":"d"}
EOF
    cat > b.jsonl <<'EOF'
{"ts":"2026-04-19T10:01:00Z","tool":"y","cmd":"git rm","src":"e"}
{"ts":"2026-04-19T10:03:00Z","tool":"y","cmd":"git rm","src":"f"}
EOF
}

teardown() {
    cd /
    rm -rf "$TMP"
}

@test "--help prints usage" {
    run "$TOOL" --help
    [ "$status" -eq 0 ]
}

@test "merges two logs sorted by ts" {
    run "$TOOL" a.jsonl b.jsonl --output sorted.jsonl
    [ "$status" -eq 0 ]
    first_line="$(head -1 sorted.jsonl)"
    [[ "$first_line" == *'"ts":"2026-04-19T10:00:00Z"'* ]]
    last_line="$(tail -1 sorted.jsonl)"
    [[ "$last_line" == *'"ts":"2026-04-19T10:03:00Z"'* ]]
}

@test "--output writes to file" {
    run "$TOOL" a.jsonl b.jsonl --output merged.jsonl
    [ "$status" -eq 0 ]
    [ -f merged.jsonl ]
    [ "$(wc -l < merged.jsonl)" -eq 4 ]
}

@test "detects duplicate events" {
    cp a.jsonl c.jsonl  # c is identical to a
    run "$TOOL" a.jsonl c.jsonl
    [ "$status" -eq 0 ]
    # stderr (merged into output under `run`) includes duplicate warnings
    [[ "$output" == *"duplicate"* ]]
}

@test "handles missing file gracefully" {
    run "$TOOL" a.jsonl nonexistent.jsonl
    [ "$status" -eq 2 ]
}
