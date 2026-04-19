#!/usr/bin/env bats
#
# BATS: hookify-rule-canary (v46.0 reset — Phase 0b)
# Required min-test-count: 8 (per Plan v4 §3 Phase 0b)
# Actual tests: 8

setup() {
    REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
    TOOL="$REPO_ROOT/claude/tools/hookify-rule-canary"
    TMP="$(mktemp -d -t hrc.XXXXXX)"
    cd "$TMP"
}

teardown() {
    cd /
    rm -rf "$TMP"
}

@test "--help prints usage" {
    run "$TOOL" --help
    [ "$status" -eq 0 ]
}

@test "--mock self-test passes" {
    run "$TOOL" --mock
    [ "$status" -eq 0 ]
    [[ "$output" == *"MOCK-OK"* ]]
}

@test "block canary: rule + canary match → OK" {
    cat > block.md <<'EOF'
# block-raw-tools
pattern: ^git\s+commit$
EOF
    cat > block.canary <<'EOF'
expected_decision: block
expected_match: git commit
---BODY---
git commit
EOF
    run "$TOOL" block.md block.canary
    [ "$status" -eq 0 ]
    [[ "$output" == *"decision=block"* ]]
}

@test "warn canary: pattern in fenced regex block" {
    cat > warn.md <<'EOF'
# destructive-command-safety
## Pattern
```regex
^rm\s+-rf\s+/
```
EOF
    cat > warn.canary <<'EOF'
expected_decision: warn
expected_match: rm -rf
---BODY---
rm -rf /important
EOF
    run "$TOOL" warn.md warn.canary
    [ "$status" -eq 0 ]
}

@test "inform canary: pattern matches" {
    cat > inform.md <<'EOF'
pattern: ^curl\s
EOF
    cat > inform.canary <<'EOF'
expected_decision: inform
expected_match: curl
---BODY---
curl https://example.com
EOF
    run "$TOOL" inform.md inform.canary
    [ "$status" -eq 0 ]
}

@test "rule without pattern fails" {
    cat > nopat.md <<'EOF'
# rule with no pattern
EOF
    cat > nopat.canary <<'EOF'
expected_decision: block
---BODY---
anything
EOF
    run "$TOOL" nopat.md nopat.canary
    [ "$status" -eq 1 ]
}

@test "canary payload that does NOT match pattern fails" {
    cat > p.md <<'EOF'
pattern: ^git\s+rebase
EOF
    cat > p.canary <<'EOF'
expected_decision: block
---BODY---
git commit
EOF
    run "$TOOL" p.md p.canary
    [ "$status" -eq 1 ]
    [[ "$output" == *"did not match"* ]]
}

@test "--all iterates all rules with matching .canary siblings" {
    mkdir rules
    cat > rules/a.md <<'EOF'
pattern: ^foo
EOF
    cat > rules/a.canary <<'EOF'
expected_decision: block
---BODY---
foo bar
EOF
    cat > rules/b.md <<'EOF'
pattern: ^baz
EOF
    cat > rules/b.canary <<'EOF'
expected_decision: warn
---BODY---
baz qux
EOF
    run "$TOOL" --all rules
    [ "$status" -eq 0 ]
    [[ "$output" == *"total=2"* ]]
    [[ "$output" == *"fails=0"* ]]
}
