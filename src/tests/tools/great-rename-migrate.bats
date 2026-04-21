#!/usr/bin/env bats
#
# great-rename-migrate tests — Bucket G.1 fleet-unblock tool.
#
# Tests operate on ISOLATED temp git worktrees to avoid polluting the repo
# (lesson from test-pollution incident #387/#390). setup() creates the
# temp dir, teardown() removes it.
#

setup() {
    REPO_ROOT="$(cd "$(dirname "${BATS_TEST_DIRNAME}")/../.." && pwd)"
    TOOL="${REPO_ROOT}/agency/tools/great-rename-migrate"

    [[ -x "$TOOL" ]] || {
        echo "tool not executable: $TOOL" >&2
        return 1
    }

    # Isolated temp dir per test — critical per test-isolation discipline.
    TMPDIR_TEST="$(mktemp -d "${BATS_TMPDIR:-/tmp}/grm-test.XXXXXX")"
    cd "$TMPDIR_TEST"
    git init -q -b main 2>/dev/null || git init -q
    git config user.email test@test
    git config user.name "test"
}

teardown() {
    cd /
    rm -rf "$TMPDIR_TEST"
}

# Helper: seed the temp repo with files at old paths, commit, branch off.
seed_branch() {
    mkdir -p claude/tools claude/hookify tests/tools
    echo "old tool" > claude/tools/X
    echo "old hookify" > claude/hookify/rule.md
    echo "old test" > tests/tools/test.bats
    git add -A
    git commit -q -m "seed"
    git checkout -q -b feature
}

@test "great-rename-migrate: --version prints version" {
    run bash "$TOOL" --version
    [ "$status" -eq 0 ]
    [[ "$output" == great-rename-migrate\ * ]]
    [[ "$output" == *"1.0.0"* ]]
}

@test "great-rename-migrate: --help explains purpose + defaults" {
    run bash "$TOOL" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"v1→v2 path rename"* ]]
    [[ "$output" == *"--dry-run"* ]]
    [[ "$output" == *"--apply"* ]]
    [[ "$output" == *"claude/"* ]]
    [[ "$output" == *"agency/"* ]]
    [[ "$output" == *"tests/"* ]]
    [[ "$output" == *"src/tests/"* ]]
}

@test "great-rename-migrate: rejects unknown flag" {
    seed_branch
    run bash "$TOOL" --not-a-flag
    [ "$status" -ne 0 ]
    [[ "$output" == *"Unknown argument"* ]]
}

@test "great-rename-migrate: refuses to run on main" {
    mkdir -p claude/tools
    echo "x" > claude/tools/X
    git add -A
    git commit -q -m "seed"
    # stay on main (don't branch off)
    run bash "$TOOL" --dry-run
    [ "$status" -ne 0 ]
    [[ "$output" == *"Refusing to run on 'main'"* ]]
}

@test "great-rename-migrate: refuses to run on master" {
    git checkout -q -b master
    mkdir -p claude/tools
    echo "x" > claude/tools/X
    git add -A
    git commit -q -m "seed"
    run bash "$TOOL" --dry-run
    [ "$status" -ne 0 ]
    [[ "$output" == *"Refusing to run on 'master'"* ]]
}

@test "great-rename-migrate: dry-run shows rename plan without executing" {
    seed_branch
    run bash "$TOOL" --dry-run
    [ "$status" -eq 0 ]
    [[ "$output" == *"Rename plan"* ]]
    [[ "$output" == *"claude/tools/X"* ]]
    [[ "$output" == *"agency/tools/X"* ]]
    [[ "$output" == *"DRY RUN"* ]]

    # Verify nothing actually moved
    [[ -f "claude/tools/X" ]]
    [[ ! -f "agency/tools/X" ]]
}

@test "great-rename-migrate: dry-run is the default (no flag)" {
    seed_branch
    run bash "$TOOL"
    [ "$status" -eq 0 ]
    [[ "$output" == *"DRY RUN"* ]]

    [[ -f "claude/tools/X" ]]
    [[ ! -f "agency/tools/X" ]]
}

@test "great-rename-migrate: --apply executes renames via git mv" {
    seed_branch
    run bash "$TOOL" --apply
    [ "$status" -eq 0 ]
    # Strict match: the count MUST be 3 for these three seeded files
    [[ "$output" == *"Renamed 3 file(s). 0 failure(s)."* ]]

    # Old paths are gone (unstaged removals), new paths exist (staged adds)
    [[ ! -f "claude/tools/X" ]]
    [[ -f "agency/tools/X" ]]
    [[ ! -f "claude/hookify/rule.md" ]]
    [[ -f "agency/hookify/rule.md" ]]
    [[ ! -f "tests/tools/test.bats" ]]
    [[ -f "src/tests/tools/test.bats" ]]

    # Git sees these as renames (strict — the 'R' porcelain marker MUST appear)
    run git status --porcelain
    [[ "$output" == *"R "* ]]
}

@test "great-rename-migrate: no-op when branch already uses new paths" {
    mkdir -p agency/tools
    echo "new" > agency/tools/X
    git add -A
    git commit -q -m "seed"
    git checkout -q -b feature
    run bash "$TOOL" --dry-run
    [ "$status" -eq 0 ]
    [[ "$output" == *"No files match"* ]]
    # Verify nothing was moved or staged
    [[ -f "agency/tools/X" ]]
    run git status --porcelain
    [ -z "$output" ]
}

@test "great-rename-migrate: skips files whose target already exists" {
    mkdir -p claude/tools agency/tools
    echo "old" > claude/tools/X
    echo "conflict" > agency/tools/X
    git add -A
    git commit -q -m "seed"
    git checkout -q -b feature
    run bash "$TOOL" --dry-run
    [ "$status" -eq 0 ]
    [[ "$output" == *"Skipped (target already exists"* ]]
    [[ "$output" == *"claude/tools/X"* ]]
}

@test "great-rename-migrate: longest prefix wins on ambiguous map" {
    # Custom map with shorter + longer prefix; longer should match first
    seed_branch
    cat > "${TMPDIR_TEST}/map.txt" <<EOF
claude/tools/ agency/tools/
claude/ other/
EOF
    run bash "$TOOL" --dry-run --map "${TMPDIR_TEST}/map.txt"
    [ "$status" -eq 0 ]
    [[ "$output" == *"claude/tools/X"* ]]
    [[ "$output" == *"agency/tools/X"* ]]
    # claude/hookify/rule.md should match the shorter prefix → other/hookify/rule.md
    [[ "$output" == *"other/hookify/rule.md"* ]]
}

@test "great-rename-migrate: --map reads custom mapping from file" {
    mkdir -p oldname/subdir
    echo "content" > oldname/subdir/file.txt
    git add -A
    git commit -q -m "seed"
    git checkout -q -b feature
    cat > "${TMPDIR_TEST}/custom.map" <<EOF
oldname/ newname/
EOF
    run bash "$TOOL" --apply --map "${TMPDIR_TEST}/custom.map"
    [ "$status" -eq 0 ]
    [[ ! -f "oldname/subdir/file.txt" ]]
    [[ -f "newname/subdir/file.txt" ]]
}

@test "great-rename-migrate: --map rejects missing file" {
    seed_branch
    run bash "$TOOL" --map "${TMPDIR_TEST}/does-not-exist"
    [ "$status" -ne 0 ]
    [[ "$output" == *"not found"* ]]
}

@test "great-rename-migrate: --map requires a file argument" {
    seed_branch
    run bash "$TOOL" --map
    [ "$status" -ne 0 ]
    [[ "$output" == *"requires"* ]] || [[ "$output" == *"--map"* ]]
}

@test "great-rename-migrate: --map ignores comments + blank lines" {
    mkdir -p oldname
    echo "x" > oldname/file
    git add -A
    git commit -q -m "seed"
    git checkout -q -b feature
    cat > "${TMPDIR_TEST}/commented.map" <<EOF
# this is a comment
oldname/ newname/

# another comment
EOF
    run bash "$TOOL" --apply --map "${TMPDIR_TEST}/commented.map"
    [ "$status" -eq 0 ]
    [[ -f "newname/file" ]]
}

@test "great-rename-migrate: refuses on empty map" {
    seed_branch
    cat > "${TMPDIR_TEST}/empty.map" <<EOF
# just comments

EOF
    run bash "$TOOL" --map "${TMPDIR_TEST}/empty.map"
    [ "$status" -ne 0 ]
    [[ "$output" == *"Empty rename map"* ]] || [[ "$output" == *"nothing to do"* ]]
}

@test "great-rename-migrate: does NOT auto-commit (leaves changes staged)" {
    seed_branch
    run bash "$TOOL" --apply
    [ "$status" -eq 0 ]
    # There should be uncommitted staged changes
    run git status --porcelain
    [ -n "$output" ]  # non-empty status = there are staged changes
}

@test "great-rename-migrate: preserves file content after rename" {
    mkdir -p claude/tools
    echo "specific-content-12345" > claude/tools/X
    git add -A
    git commit -q -m "seed"
    git checkout -q -b feature
    run bash "$TOOL" --apply
    [ "$status" -eq 0 ]
    run cat agency/tools/X
    [ "$output" = "specific-content-12345" ]
}

@test "great-rename-migrate: preserves git history after rename" {
    mkdir -p claude/tools
    echo "v1" > claude/tools/X
    git add -A
    git commit -q -m "v1 commit"
    echo "v2" >> claude/tools/X
    git add -A
    git commit -q -m "v2 commit"
    git checkout -q -b feature
    run bash "$TOOL" --apply
    [ "$status" -eq 0 ]
    git commit -q -m "migrate"
    # log --follow should show both original commits
    run git log --follow --oneline agency/tools/X
    [[ "$output" == *"v1 commit"* ]]
    [[ "$output" == *"v2 commit"* ]]
}

# --- COVERAGE TESTS ADDED IN QG (pr-prep Bucket G.1) ---

@test "great-rename-migrate: refuses on detached HEAD" {
    mkdir -p claude/tools
    echo "x" > claude/tools/X
    git add -A
    git commit -q -m "seed"
    git checkout -q -b feature
    # Detach at the current commit
    git checkout -q --detach HEAD
    run bash "$TOOL" --dry-run
    [ "$status" -ne 0 ]
    [[ "$output" == *"Detached HEAD"* ]]
}

@test "great-rename-migrate: refuses outside a git worktree" {
    # Escape the git repo into a bare tmp dir
    OUTSIDE_DIR="$(mktemp -d "${BATS_TMPDIR:-/tmp}/grm-outside.XXXXXX")"
    cd "$OUTSIDE_DIR"
    run bash "$TOOL" --dry-run
    [ "$status" -ne 0 ]
    [[ "$output" == *"Not inside a git worktree"* ]]
    rm -rf "$OUTSIDE_DIR"
}

@test "great-rename-migrate: leaves untracked files alone (git mv can only move tracked)" {
    mkdir -p claude/tools
    echo "tracked" > claude/tools/tracked.md
    git add -A
    git commit -q -m "seed"
    git checkout -q -b feature
    # Add an untracked file under claude/
    echo "untracked" > claude/tools/untracked.md
    run bash "$TOOL" --apply
    [ "$status" -eq 0 ]
    # Tracked file renamed; untracked file stayed put
    [[ ! -f "claude/tools/tracked.md" ]]
    [[ -f "agency/tools/tracked.md" ]]
    [[ -f "claude/tools/untracked.md" ]]
    [[ ! -f "agency/tools/untracked.md" ]]
}

@test "great-rename-migrate: --include-untracked is no longer accepted" {
    seed_branch
    run bash "$TOOL" --include-untracked
    [ "$status" -ne 0 ]
    [[ "$output" == *"Unknown argument"* ]]
}

@test "great-rename-migrate: leaves non-matching files alone (NO_MATCH bucket)" {
    mkdir -p claude/tools other/dir
    echo "matched" > claude/tools/X
    echo "ignore me" > other/dir/Y
    echo "readme" > README.md
    git add -A
    git commit -q -m "seed"
    git checkout -q -b feature
    run bash "$TOOL" --apply
    [ "$status" -eq 0 ]
    # Matched file renamed
    [[ -f "agency/tools/X" ]]
    [[ ! -f "claude/tools/X" ]]
    # Non-matched files untouched (same path, same content)
    [[ -f "other/dir/Y" ]]
    [[ -f "README.md" ]]
    run cat other/dir/Y
    [ "$output" = "ignore me" ]
    run cat README.md
    [ "$output" = "readme" ]
}

@test "great-rename-migrate: handles filenames with spaces" {
    mkdir -p "claude/tools"
    echo "spaced" > "claude/tools/name with space.md"
    git add -A
    git commit -q -m "seed"
    git checkout -q -b feature
    run bash "$TOOL" --apply
    [ "$status" -eq 0 ]
    [[ ! -f "claude/tools/name with space.md" ]]
    [[ -f "agency/tools/name with space.md" ]]
    run cat "agency/tools/name with space.md"
    [ "$output" = "spaced" ]
}

@test "great-rename-migrate: handles non-ASCII filenames" {
    mkdir -p "claude/tools"
    echo "unicode" > "claude/tools/café.md"
    git add -A
    git commit -q -m "seed"
    git checkout -q -b feature
    run bash "$TOOL" --apply
    [ "$status" -eq 0 ]
    [[ ! -f "claude/tools/café.md" ]]
    [[ -f "agency/tools/café.md" ]]
    run cat "agency/tools/café.md"
    [ "$output" = "unicode" ]
}

@test "great-rename-migrate: --map rejects absolute new prefix" {
    seed_branch
    cat > "${TMPDIR_TEST}/bad.map" <<EOF
claude/ /etc/evil/
EOF
    run bash "$TOOL" --dry-run --map "${TMPDIR_TEST}/bad.map"
    [ "$status" -ne 0 ]
    [[ "$output" == *"absolute paths forbidden"* ]]
}

@test "great-rename-migrate: --map rejects traversal in new prefix" {
    seed_branch
    cat > "${TMPDIR_TEST}/bad.map" <<EOF
claude/ ../evil/
EOF
    run bash "$TOOL" --dry-run --map "${TMPDIR_TEST}/bad.map"
    [ "$status" -ne 0 ]
    [[ "$output" == *"traversal forbidden"* ]]
}

@test "great-rename-migrate: --map rejects glob metacharacters" {
    seed_branch
    cat > "${TMPDIR_TEST}/bad.map" <<EOF
clau*/ agency/
EOF
    run bash "$TOOL" --dry-run --map "${TMPDIR_TEST}/bad.map"
    [ "$status" -ne 0 ]
    [[ "$output" == *"glob metacharacters"* ]]
}

@test "great-rename-migrate: --map rejects single-field entry" {
    seed_branch
    cat > "${TMPDIR_TEST}/bad.map" <<EOF
oldonly
EOF
    run bash "$TOOL" --dry-run --map "${TMPDIR_TEST}/bad.map"
    [ "$status" -ne 0 ]
    [[ "$output" == *"required"* ]] || [[ "$output" == *"Invalid"* ]]
}

@test "great-rename-migrate: --map rejects whitespace-only line as map entry" {
    # A whitespace-only line should be SKIPPED (like blank lines), not parsed.
    mkdir -p oldname
    echo "x" > oldname/file
    git add -A
    git commit -q -m "seed"
    git checkout -q -b feature
    # Map has a valid entry plus whitespace-only lines (spaces + tabs)
    printf 'oldname/ newname/\n   \n\t\t\n' > "${TMPDIR_TEST}/ws.map"
    run bash "$TOOL" --apply --map "${TMPDIR_TEST}/ws.map"
    [ "$status" -eq 0 ]
    [[ -f "newname/file" ]]
    # No corruption — oldname/file should be gone
    [[ ! -f "oldname/file" ]]
}

@test "great-rename-migrate: --map handles tab-delimited entries" {
    mkdir -p oldname
    echo "x" > oldname/file
    git add -A
    git commit -q -m "seed"
    git checkout -q -b feature
    # Tabs between old + new, plus trailing whitespace
    printf 'oldname/\tnewname/\t\n' > "${TMPDIR_TEST}/tab.map"
    run bash "$TOOL" --apply --map "${TMPDIR_TEST}/tab.map"
    [ "$status" -eq 0 ]
    [[ -f "newname/file" ]]
    [[ ! -f "oldname/file" ]]
}

@test "great-rename-migrate: --map handles file without trailing newline" {
    mkdir -p oldname
    echo "x" > oldname/file
    git add -A
    git commit -q -m "seed"
    git checkout -q -b feature
    # printf without \n on final entry
    printf 'oldname/ newname/' > "${TMPDIR_TEST}/no-newline.map"
    run bash "$TOOL" --apply --map "${TMPDIR_TEST}/no-newline.map"
    [ "$status" -eq 0 ]
    [[ -f "newname/file" ]]
}

@test "great-rename-migrate: detects duplicate PLAN_TO targets (two sources, same target)" {
    mkdir -p dir_a dir_b
    echo "a" > dir_a/file.md
    echo "b" > dir_b/file.md
    git add -A
    git commit -q -m "seed"
    git checkout -q -b feature
    # Map both dir_a/ and dir_b/ to the same target merged/
    cat > "${TMPDIR_TEST}/dup.map" <<EOF
dir_a/ merged/
dir_b/ merged/
EOF
    run bash "$TOOL" --dry-run --map "${TMPDIR_TEST}/dup.map"
    [ "$status" -eq 0 ]
    [[ "$output" == *"duplicate target"* ]]
    # First-match wins; second shows up in the dup-skip list
    [[ "$output" == *"Skipped (duplicate target"* ]]
}

@test "great-rename-migrate: exits 1 when all planned git-mv's fail" {
    # Seed a file, then remove it from the working tree but keep it tracked
    # in the index so ls-files still reports it — git mv will then fail
    # because the src isn't on disk.
    mkdir -p claude/tools
    echo "x" > claude/tools/X
    git add -A
    git commit -q -m "seed"
    git checkout -q -b feature
    # Remove from working tree (git still has it tracked).
    rm -f claude/tools/X
    run bash "$TOOL" --apply
    # At least one failure → non-zero exit
    [ "$status" -ne 0 ]
    [[ "$output" == *"failure"* ]]
}

@test "great-rename-migrate: version string matches 1.0.0 convention" {
    run bash "$TOOL" --version
    [ "$status" -eq 0 ]
    # Strict match: 'great-rename-migrate 1.0.0' (no bucket/date suffix)
    [ "$output" = "great-rename-migrate 1.0.0" ]
}
