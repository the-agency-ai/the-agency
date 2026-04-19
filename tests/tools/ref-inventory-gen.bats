#!/usr/bin/env bats
#
# BATS: ref-inventory-gen (v46.0 reset — Phase 0b)
#
# Required min-test-count: 10 (per Plan v4 §3 Phase 0b)
# Actual tests: 11

setup() {
    REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
    TOOL="$REPO_ROOT/agency/tools/ref-inventory-gen"

    TMP_REPO="$(mktemp -d -t rig.XXXXXX)"
    cd "$TMP_REPO"
    git init -q .
    git config user.email "test@test"
    git config user.name "test"
}

teardown() {
    cd /
    rm -rf "$TMP_REPO"
}

seed_basic() {
    # A known rename-target hit
    mkdir -p src
    echo "look at agency/tools/foo" > src/tool-ref.md
    # Allowlisted hit
    echo "see .claude/settings.json" > src/claude-code.md
    # An unknown-classifier hit (bare 'claude' that doesn't map to a known subdir)
    echo "claude/mystery-subdir/bar" > src/unknown.md

    # Seed allowlist
    mkdir -p claude/tools
    cat > agency/tools/ref-sweep-allowlist.txt <<'EOF'
# test allowlist
\.claude/	Anthropic Claude Code discovery dir
test-allow	Test marker
EOF

    git add .
    git commit -q -m "seed"
}

@test "--help prints usage" {
    run "$TOOL" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"ref-inventory-gen"* ]]
}

@test "--version prints version" {
    run "$TOOL" --version
    [ "$status" -eq 0 ]
    [[ "$output" == *"ref-inventory-gen"* ]]
}

@test "pre mode classifies rename-target hits" {
    seed_basic
    run "$TOOL" --pre
    [ "$status" -eq 0 ]
    # src/tool-ref.md should produce a rename-target classification
    [[ "$output" == *"rename-target"*"src/tool-ref.md"* ]]
}

@test "pre mode classifies allowlisted hits" {
    seed_basic
    run "$TOOL" --pre
    [ "$status" -eq 0 ]
    [[ "$output" == *"allowlisted"*"src/claude-code.md"* ]]
}

@test "pre mode classifies unknown hits" {
    seed_basic
    run "$TOOL" --pre
    [ "$status" -eq 0 ]
    [[ "$output" == *"unknown"*"src/unknown.md"* ]]
}

@test "--strict exits nonzero when unknown hits are present" {
    seed_basic
    run "$TOOL" --pre --strict
    [ "$status" -eq 1 ]
}

@test "--strict exits 0 when all hits are rename-target or allowlisted" {
    mkdir -p src claude/tools
    echo "agency/tools/foo" > src/a.md
    echo ".claude/settings" > src/b.md
    cat > agency/tools/ref-sweep-allowlist.txt <<'EOF'
\.claude/	Anthropic
EOF
    git add .
    git commit -q -m "seed"

    run "$TOOL" --pre --strict
    [ "$status" -eq 0 ]
}

@test "--exclude skips matching file glob" {
    seed_basic
    # Exclude the unknown file; strict should now pass
    run "$TOOL" --pre --strict --exclude "src/unknown.md"
    [ "$status" -eq 0 ]
}

@test "--output writes inventory to file" {
    seed_basic
    run "$TOOL" --pre --output "$TMP_REPO/inv.txt"
    [ "$status" -eq 0 ]
    [ -f "$TMP_REPO/inv.txt" ]
    grep -q 'rename-target' "$TMP_REPO/inv.txt"
}

@test "post mode classifies agency/ patterns" {
    mkdir -p src claude/tools
    echo "look at agency/tools/foo" > src/ref.md
    cat > agency/tools/ref-sweep-allowlist.txt <<'EOF'
\.claude/	Anthropic
EOF
    git add .
    git commit -q -m "seed"

    run "$TOOL" --post
    [ "$status" -eq 0 ]
    [[ "$output" == *"rename-target"*"src/ref.md"* ]]
}

@test "binary files are skipped" {
    # Create a tiny binary file
    printf '\x00\x01\x02agency/tools/binary\x03' > binary.bin
    echo "agency/tools/text" > text.txt

    mkdir -p claude/tools
    cat > agency/tools/ref-sweep-allowlist.txt <<'EOF'
\.claude/	Anthropic
EOF
    git add .
    git commit -q -m "seed"

    run "$TOOL" --pre
    [ "$status" -eq 0 ]
    # The binary file's bytes must not appear in the manifest
    [[ "$output" != *"binary.bin"* ]]
    [[ "$output" == *"text.txt"* ]]
}
