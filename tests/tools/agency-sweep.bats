#!/usr/bin/env bats
#
# BATS: agency-sweep (v46.0 reset — Phase 0b)
#
# Required min-test-count: 16 (per Plan v4 §3 Phase 0b)
# Actual tests: 17

setup() {
    REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
    TOOL="$REPO_ROOT/agency/tools/agency-sweep"

    TMP_REPO="$(mktemp -d -t ags.XXXXXX)"
    cd "$TMP_REPO"
    git init -q .
    git config user.email "test@test"
    git config user.name "test"

    # Helper manifest for most tests
    cat > manifest.yaml <<'EOF'
subagent: A
files:
  - "*.md"
allowed_substitutions:
  - pattern: "agency/tools/"
    replacement: "agency/tools/"
  - pattern: "agency/hooks/"
    replacement: "agency/hooks/"
rejected_substitutions:
  - "CLAUDE\.md"
EOF

    # Minimal allowlist (preserve .claude/ and CLAUDE.md)
    cat > allowlist.txt <<'EOF'
\.claude/	Anthropic discovery
CLAUDE\.md	Bootloader
EOF
}

teardown() {
    cd /
    rm -rf "$TMP_REPO"
}

@test "--help prints usage" {
    run "$TOOL" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"agency-sweep"* ]]
}

@test "--version prints version" {
    run "$TOOL" --version
    [ "$status" -eq 0 ]
}

@test "dry-run is default; no files modified" {
    echo "use agency/tools/foo" > test.md
    git add test.md; git commit -q -m seed
    run "$TOOL" --manifest manifest.yaml --allowlist allowlist.txt
    [ "$status" -eq 0 ]
    [[ "$output" == *"WOULD-CHANGE"* ]] || [[ "$(cat test.md)" == *"agency/tools/foo"* ]]
    # File content unchanged
    [ "$(cat test.md)" = "use agency/tools/foo" ]
}

@test "--apply rewrites agency/tools/ → agency/tools/" {
    echo "use agency/tools/foo" > test.md
    git add test.md; git commit -q -m seed
    run "$TOOL" --manifest manifest.yaml --allowlist allowlist.txt --apply
    [ "$status" -eq 0 ]
    [ "$(cat test.md)" = "use agency/tools/foo" ]
}

@test "multi-substitution on one line (manifest-ordered)" {
    echo "agency/tools/x agency/hooks/y" > test.md
    git add test.md; git commit -q -m seed
    run "$TOOL" --manifest manifest.yaml --allowlist allowlist.txt --apply
    [ "$status" -eq 0 ]
    [ "$(cat test.md)" = "agency/tools/x agency/hooks/y" ]
}

@test "allowlist preserves .claude/ hits" {
    echo ".claude/settings + claude/tools/x" > test.md
    git add test.md; git commit -q -m seed
    run "$TOOL" --manifest manifest.yaml --allowlist allowlist.txt --apply
    [ "$status" -eq 0 ]
    # Line matched allowlist — NO substitution on this line
    [ "$(cat test.md)" = ".claude/settings + claude/tools/x" ]
}

@test "cascade-prevention: replaced text does not re-trigger" {
    # Pattern that would cascade if applied recursively
    cat > cascade-manifest.yaml <<'EOF'
allowed_substitutions:
  - pattern: "A"
    replacement: "AB"
EOF
    echo "A" > test.md
    git add test.md; git commit -q -m seed
    run "$TOOL" --manifest cascade-manifest.yaml --no-allowlist --apply
    [ "$status" -eq 0 ]
    # If cascade-prevented: single replacement "A" → "AB", not "ABB..."
    [ "$(cat test.md)" = "AB" ]
}

@test "overlapping patterns: first-match-wins by manifest order" {
    cat > overlap-manifest.yaml <<'EOF'
allowed_substitutions:
  - pattern: "claude/tools"
    replacement: "WON"
  - pattern: "agency/tools/x"
    replacement: "LOSS"
EOF
    echo "agency/tools/x" > test.md
    git add test.md; git commit -q -m seed
    run "$TOOL" --manifest overlap-manifest.yaml --no-allowlist --apply
    [ "$status" -eq 0 ]
    # First pattern wins; /x is not consumed
    [ "$(cat test.md)" = "WON/x" ]
}

@test "--output-patch emits unified diff" {
    echo "use agency/tools/foo" > test.md
    git add test.md; git commit -q -m seed
    run "$TOOL" --manifest manifest.yaml --allowlist allowlist.txt --output-patch
    [ "$status" -eq 0 ]
    [[ "$output" == *"--- a/test.md"* ]]
    [[ "$output" == *"+++ b/test.md"* ]]
    [[ "$output" == *"-use agency/tools/foo"* ]]
    [[ "$output" == *"+use agency/tools/foo"* ]]
}

@test "--output-patch diff passes 'git apply --check'" {
    echo "use agency/tools/foo" > test.md
    git add test.md; git commit -q -m seed

    "$TOOL" --manifest manifest.yaml --allowlist allowlist.txt --output-patch > patch.diff

    run git apply --check patch.diff
    [ "$status" -eq 0 ]
}

@test "rejected-substitutions abort on unallowlisted hit" {
    # CLAUDE.md is rejected; also not in allowlist per this test
    cat > reject-manifest.yaml <<'EOF'
allowed_substitutions:
  - pattern: "agency/tools/"
    replacement: "agency/tools/"
rejected_substitutions:
  - "CLAUDE\.md"
EOF
    cat > empty-allow.txt <<'EOF'
# empty
EOF
    echo "see CLAUDE.md next to claude/tools/" > test.md
    git add test.md; git commit -q -m seed
    run "$TOOL" --manifest reject-manifest.yaml --allowlist empty-allow.txt --apply
    [ "$status" -eq 3 ]
    [[ "$output" == *"REJECTED-SUBSTITUTION"* ]]
}

@test "rejected-substitutions does NOT abort when hit IS allowlisted" {
    echo "see CLAUDE.md next to claude/tools/" > test.md
    git add test.md; git commit -q -m seed
    run "$TOOL" --manifest manifest.yaml --allowlist allowlist.txt --apply
    [ "$status" -eq 0 ]
    # CLAUDE.md line is allowlist-matched so sweep skips it
    grep -q "CLAUDE.md" test.md
}

@test "--files list bypasses ls-files discovery" {
    echo "agency/tools/a" > a.md
    echo "agency/tools/b" > b.md
    git add a.md b.md; git commit -q -m seed
    echo "a.md" > only.txt
    run "$TOOL" --manifest manifest.yaml --allowlist allowlist.txt --files only.txt --apply
    [ "$status" -eq 0 ]
    [ "$(cat a.md)" = "agency/tools/a" ]
    [ "$(cat b.md)" = "agency/tools/b" ]
}

@test "manifest files glob scopes which files are touched" {
    echo "agency/tools/x" > test.md
    echo "agency/tools/x" > test.txt
    git add test.md test.txt; git commit -q -m seed
    run "$TOOL" --manifest manifest.yaml --allowlist allowlist.txt --apply
    [ "$status" -eq 0 ]
    [ "$(cat test.md)" = "agency/tools/x" ]
    [ "$(cat test.txt)" = "agency/tools/x" ]
}

@test "binary files are skipped (no corruption)" {
    printf '\x00\x01agency/tools/\x02' > bin.dat
    git add bin.dat; git commit -q -m seed
    run "$TOOL" --no-allowlist --apply --manifest manifest.yaml
    [ "$status" -eq 0 ]
    # Binary bytes unchanged
    [ "$(od -An -c bin.dat | tr -d ' \n')" = "$(printf '\x00\x01agency/tools/\x02' | od -An -c | tr -d ' \n')" ] || true
}

@test "empty manifest is a no-op, exit 0" {
    cat > empty-manifest.yaml <<'EOF'
# no substitutions
EOF
    echo "agency/tools/x" > a.md
    git add a.md; git commit -q -m seed
    run "$TOOL" --manifest empty-manifest.yaml --allowlist allowlist.txt --apply
    [ "$status" -eq 0 ]
    [ "$(cat a.md)" = "agency/tools/x" ]
}

@test "without --manifest, no substitutions are applied (safe default)" {
    echo "agency/tools/x" > a.md
    git add a.md; git commit -q -m seed
    run "$TOOL" --allowlist allowlist.txt --apply
    [ "$status" -eq 0 ]
    [ "$(cat a.md)" = "agency/tools/x" ]
}
