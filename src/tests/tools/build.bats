#!/usr/bin/env bats
#
# src/tools/build — V5 Phase 5a minimal build tool tests
#
# Each test runs in an isolated mktemp'd fake repo (per test-pollution
# discipline from #387/#390). The tool walks from CWD up to find .git,
# so we stage a fake repo with .git marker + src/ tree.
#

setup() {
    REPO_ROOT="$(cd "$(dirname "${BATS_TEST_DIRNAME}")/../.." && pwd)"
    BUILD="${REPO_ROOT}/src/tools/build"

    [[ -x "$BUILD" ]] || {
        echo "build tool not executable: $BUILD" >&2
        return 1
    }

    # Isolated fake repo per test
    TMPDIR_TEST="$(mktemp -d "${BATS_TMPDIR:-/tmp}/build-test.XXXXXX")"
    cd "$TMPDIR_TEST"
    mkdir .git  # just the marker is enough; tool uses .git existence for repo-root detection
}

teardown() {
    cd /
    rm -rf "$TMPDIR_TEST"
}

@test "build: --version prints version" {
    run "$BUILD" --version
    [ "$status" -eq 0 ]
    [[ "$output" =~ ^build\ [0-9]+\.[0-9]+\.[0-9]+$ ]]
}

@test "build: --help shows usage" {
    run "$BUILD" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"V5 Phase 5a"* ]]
    [[ "$output" == *"src/agency/"* ]]
    [[ "$output" == *"src/claude/"* ]]
}

@test "build: rejects unknown flag" {
    run "$BUILD" --not-a-flag
    [ "$status" -ne 0 ]
    [[ "$output" == *"Unknown argument"* ]]
}

@test "build: fails when neither src/agency/ nor src/claude/ exists" {
    run "$BUILD"
    [ "$status" -ne 0 ]
    [[ "$output" == *"Neither src/agency/ nor src/claude/"* ]]
}

@test "build: fails when not inside a git repository" {
    rm -rf .git
    run "$BUILD"
    [ "$status" -ne 0 ]
    [[ "$output" == *"Not inside a git repository"* ]]
}

@test "build: mirrors a single file from src/agency/ to agency/" {
    mkdir -p src/agency/tools
    echo "tool content" > src/agency/tools/foo
    run "$BUILD"
    [ "$status" -eq 0 ]
    [[ -f "agency/tools/foo" ]]
    run cat agency/tools/foo
    [ "$output" = "tool content" ]
}

@test "build: mirrors a single file from src/claude/ to .claude/" {
    mkdir -p src/claude/skills/foo
    echo "skill md" > src/claude/skills/foo/SKILL.md
    run "$BUILD"
    [ "$status" -eq 0 ]
    [[ -f ".claude/skills/foo/SKILL.md" ]]
    run cat .claude/skills/foo/SKILL.md
    [ "$output" = "skill md" ]
}

@test "build: mirrors nested subdirectories" {
    mkdir -p src/agency/tools/lib/nested/deep
    echo "deeply nested" > src/agency/tools/lib/nested/deep/helper
    run "$BUILD"
    [ "$status" -eq 0 ]
    [[ -f "agency/tools/lib/nested/deep/helper" ]]
}

@test "build: preserves executable mode" {
    mkdir -p src/agency/tools
    cat > src/agency/tools/exec-script <<'EOF'
#!/bin/bash
echo "hello"
EOF
    chmod +x src/agency/tools/exec-script

    run "$BUILD"
    [ "$status" -eq 0 ]
    [[ -x "agency/tools/exec-script" ]]
    run agency/tools/exec-script
    [ "$output" = "hello" ]
}

@test "build: preserves non-executable mode" {
    mkdir -p src/agency/config
    echo "{}" > src/agency/config/data.json
    chmod 644 src/agency/config/data.json

    run "$BUILD"
    [ "$status" -eq 0 ]
    [[ -f "agency/config/data.json" ]]
    [[ ! -x "agency/config/data.json" ]]
}

@test "build: reports correct counts in stdout" {
    mkdir -p src/agency/tools src/claude/hooks
    echo "a" > src/agency/tools/a
    echo "b" > src/agency/tools/b
    echo "c" > src/claude/hooks/c
    run "$BUILD"
    [ "$status" -eq 0 ]
    [[ "$output" == *"src/agency/ → agency/     2 file(s)"* ]]
    [[ "$output" == *"src/claude/ → .claude/    1 file(s)"* ]]
    [[ "$output" == *"total 3 file(s) mirrored"* ]]
}

@test "build: overwrites existing destination files" {
    mkdir -p src/agency/tools agency/tools
    echo "new content" > src/agency/tools/foo
    echo "old content" > agency/tools/foo

    run "$BUILD"
    [ "$status" -eq 0 ]
    run cat agency/tools/foo
    [ "$output" = "new content" ]
}

@test "build: handles empty src/agency/ gracefully (0 files reported)" {
    mkdir -p src/agency src/claude/skills
    echo "x" > src/claude/skills/only
    run "$BUILD"
    [ "$status" -eq 0 ]
    [[ "$output" == *"src/agency/ → agency/     0 file(s)"* ]]
    [[ "$output" == *"src/claude/ → .claude/    1 file(s)"* ]]
}

@test "build: --verbose prints mirror paths" {
    mkdir -p src/agency/tools
    echo "x" > src/agency/tools/t
    run "$BUILD" --verbose
    [ "$status" -eq 0 ]
    [[ "$output" == *"src/agency"* ]]
    [[ "$output" == *"→"* ]]
    [[ "$output" == *"agency"* ]]
}

@test "build: is idempotent — second run produces identical output" {
    mkdir -p src/agency/tools
    echo "stable" > src/agency/tools/file

    run "$BUILD"
    [ "$status" -eq 0 ]
    first_output="$output"

    run "$BUILD"
    [ "$status" -eq 0 ]
    [ "$output" = "$first_output" ]
    run cat agency/tools/file
    [ "$output" = "stable" ]
}

@test "build: handles files with spaces in names" {
    mkdir -p src/agency/tools
    echo "spaced" > "src/agency/tools/name with space"
    run "$BUILD"
    [ "$status" -eq 0 ]
    [[ -f "agency/tools/name with space" ]]
}

@test "build: handles non-ASCII filenames" {
    mkdir -p src/agency/tools
    echo "unicode" > "src/agency/tools/café.md"
    run "$BUILD"
    [ "$status" -eq 0 ]
    [[ -f "agency/tools/café.md" ]]
}

@test "build: works from a subdirectory of the repo (walks up to .git)" {
    mkdir -p src/agency/tools sub/dir
    echo "x" > src/agency/tools/t
    cd sub/dir
    run "$BUILD"
    [ "$status" -eq 0 ]
    [[ -f "$TMPDIR_TEST/agency/tools/t" ]]
}
