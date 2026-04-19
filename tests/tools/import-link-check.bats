#!/usr/bin/env bats
#
# BATS: import-link-check (v46.0 reset — Phase 0b)
#
# Required min-test-count: 10 (per Plan v4 §3 Phase 0b)
# Actual tests: 11

setup() {
    REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
    TOOL="$REPO_ROOT/claude/tools/import-link-check"

    TMP_REPO="$(mktemp -d -t ilc.XXXXXX)"
    cd "$TMP_REPO"
    git init -q .
    git config user.email "test@test"
    git config user.name "test"
}

teardown() {
    cd /
    rm -rf "$TMP_REPO"
}

@test "--help prints usage" {
    run "$TOOL" --help
    [ "$status" -eq 0 ]
}

@test "--version prints version" {
    run "$TOOL" --version
    [ "$status" -eq 0 ]
}

@test "resolves a valid @import path" {
    mkdir -p agency
    touch agency/target.md
    echo "@import @agency/target.md" > CLAUDE.md
    git add .; git commit -q -m seed
    run "$TOOL"
    [ "$status" -eq 0 ]
}

@test "orphan @import path reports ORPHAN + exits 1" {
    echo "@import @agency/does-not-exist.md" > CLAUDE.md
    git add .; git commit -q -m seed
    run "$TOOL"
    [ "$status" -eq 1 ]
    [[ "$output" == *"ORPHAN"* ]]
    [[ "$output" == *"does-not-exist.md"* ]]
}

@test "required_reading orphan is caught" {
    mkdir -p .claude/skills/foo
    cat > .claude/skills/foo/SKILL.md <<'EOF'
---
required_reading: agency/gone.md
---
# foo
EOF
    git add .; git commit -q -m seed
    run "$TOOL"
    [ "$status" -eq 1 ]
    [[ "$output" == *"required_reading"* ]]
}

@test "required_reading list form (- <path>) orphan caught" {
    mkdir -p .claude/skills/foo
    cat > .claude/skills/foo/SKILL.md <<'EOF'
---
required_reading:
  - agency/missing.md
---
EOF
    git add .; git commit -q -m seed
    run "$TOOL"
    [ "$status" -eq 1 ]
    [[ "$output" == *"missing.md"* ]]
}

@test "agent cross-class @import (agency/agents/.../agent.md) resolves" {
    mkdir -p agency/agents/class-foo .claude/agents/jordan
    echo "hi" > agency/agents/class-foo/agent.md
    cat > .claude/agents/jordan/foo.md <<'EOF'
@import @agency/agents/class-foo/agent.md
EOF
    git add .; git commit -q -m seed
    run "$TOOL"
    [ "$status" -eq 0 ]
}

@test "inline HTML comment @import is parsed" {
    mkdir -p agency
    touch agency/target.md
    echo '<!-- @import @agency/target.md -->' > README.md
    # Note: the default scopes are .claude/, agency/, claude/, CLAUDE.md.
    # To scope to README.md we use --scope.
    git add .; git commit -q -m seed
    run "$TOOL" --scope README.md
    [ "$status" -eq 0 ]
}

@test "ignores URL http:// targets" {
    echo "@import http://example.com/ignore.md" > CLAUDE.md
    git add .; git commit -q -m seed
    run "$TOOL"
    [ "$status" -eq 0 ]
}

@test "--json emits machine-readable output" {
    echo "@import @agency/missing.md" > CLAUDE.md
    git add .; git commit -q -m seed
    run "$TOOL" --json
    [ "$status" -eq 1 ]
    [[ "$output" == *'"kind":"@import"'* ]]
    [[ "$output" == *'"target":"@agency/missing.md"'* ]]
}

@test "--scope accepts additional globs" {
    mkdir -p docs
    touch agency/target.md || mkdir -p agency && touch agency/target.md
    echo "@import @agency/target.md" > docs/notes.md
    git add .; git commit -q -m seed
    run "$TOOL" --scope "docs/*.md"
    [ "$status" -eq 0 ]
}
