#!/usr/bin/env bats
#
# BATS: git-rename-tree (v46.0 reset — Phase 0b)
#
# Required min-test-count: 10 (per Plan v4 §3 Phase 0b)
# Actual tests: 12 (covers all Plan-v4 canaries + audit-log checks)

setup() {
    REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
    TOOL="$REPO_ROOT/claude/tools/git-rename-tree"
    GIT_SAFE="$REPO_ROOT/claude/tools/git-safe"

    # Per-test throwaway git repo
    TMP_REPO="$(mktemp -d -t grtree.XXXXXX)"
    cd "$TMP_REPO"
    git init -q .
    git config user.email "test@test"
    git config user.name "test"

    # Self-contained: the tool uses raw `git ls-files` internally, so no
    # sibling-tool staging is needed. We still copy the tool to the fixture
    # so paths stay test-local.
    export AGENCY_AUDIT_LOG="$TMP_REPO/audit-log.jsonl"
    TOOL_LOCAL="$TOOL"
}

teardown() {
    cd /
    rm -rf "$TMP_REPO"
}

@test "moves a single tracked file" {
    mkdir -p src
    echo "hello" > src/a.txt
    git add src/a.txt
    git commit -q -m "seed"

    run "$TOOL_LOCAL" src/a.txt dst/a.txt
    [ "$status" -eq 0 ]
    [ -f dst/a.txt ]
    [ ! -f src/a.txt ]
}

@test "moves a directory recursively" {
    mkdir -p src/nested/deep
    echo "1" > src/one.txt
    echo "2" > src/nested/two.txt
    echo "3" > src/nested/deep/three.txt
    git add src
    git commit -q -m "seed"

    run "$TOOL_LOCAL" src dst
    [ "$status" -eq 0 ]
    [ -f dst/one.txt ]
    [ -f dst/nested/two.txt ]
    [ -f dst/nested/deep/three.txt ]
    [ ! -f src/one.txt ]
}

@test "canary: moves .gitkeep dotfile" {
    mkdir -p src/empty
    touch src/empty/.gitkeep
    git add src
    git commit -q -m "seed"

    run "$TOOL_LOCAL" src dst
    [ "$status" -eq 0 ]
    [ -f dst/empty/.gitkeep ]
}

@test "canary: moves .gitignore dotfile" {
    mkdir -p src
    echo "*.log" > src/.gitignore
    git add src
    git commit -q -m "seed"

    run "$TOOL_LOCAL" src dst
    [ "$status" -eq 0 ]
    [ -f dst/.gitignore ]
}

@test "canary: moves .hidden-example dotfile" {
    mkdir -p src
    echo "secret=placeholder" > src/.hidden-example
    git add src
    git commit -q -m "seed"

    run "$TOOL_LOCAL" src dst
    [ "$status" -eq 0 ]
    [ -f dst/.hidden-example ]
}

@test "canary: deep-nested path (5 levels)" {
    mkdir -p src/a/b/c/d/e
    echo "deep" > src/a/b/c/d/e/file.txt
    git add src
    git commit -q -m "seed"

    run "$TOOL_LOCAL" src dst
    [ "$status" -eq 0 ]
    [ -f dst/a/b/c/d/e/file.txt ]
}

@test "canary: unicode filename" {
    mkdir -p src
    echo "content" > "src/héllo-世界.txt"
    git add src
    git commit -q -m "seed"

    run "$TOOL_LOCAL" src dst
    [ "$status" -eq 0 ]
    [ -f "dst/héllo-世界.txt" ]
}

@test "canary: embedded-semicolon path 'test; rm -rf /'" {
    # Intentionally evil path; must be moved safely without shell-injection.
    mkdir -p "src/test; rm -rf /"
    echo "evil" > "src/test; rm -rf //file.txt"
    git add src
    git commit -q -m "seed"

    run "$TOOL_LOCAL" src dst
    [ "$status" -eq 0 ]
    [ -f "dst/test; rm -rf /file.txt" ]
    # Confirm / is still intact (if it isn't, BATS itself would be gone)
    [ -d / ]
}

@test "audit log records per-file moves as JSONL" {
    mkdir -p src
    echo "a" > src/a.txt
    echo "b" > src/b.txt
    git add src
    git commit -q -m "seed"

    run "$TOOL_LOCAL" src dst
    [ "$status" -eq 0 ]

    [ -f "$AGENCY_AUDIT_LOG" ]
    # 2 moves expected (one entry per file)
    [ "$(wc -l < "$AGENCY_AUDIT_LOG")" -ge 2 ]
    grep -q '"tool":"git-rename-tree"' "$AGENCY_AUDIT_LOG"
    grep -q '"cmd":"git mv"' "$AGENCY_AUDIT_LOG"
}

@test "rationale flag records in audit entry" {
    mkdir -p src
    echo "x" > src/x.txt
    git add src
    git commit -q -m "seed"

    run "$TOOL_LOCAL" src dst --rationale "phase-1-test"
    [ "$status" -eq 0 ]

    grep -q '"rationale":"phase-1-test"' "$AGENCY_AUDIT_LOG"
}

@test "refuses when src has no tracked files" {
    run "$TOOL_LOCAL" untracked-path dst
    [ "$status" -ne 0 ]
    [[ "$output" == *"No tracked files match"* ]]
}

@test "--version prints version" {
    run "$TOOL_LOCAL" --version
    [ "$status" -eq 0 ]
    [[ "$output" == *"git-rename-tree"* ]]
}
