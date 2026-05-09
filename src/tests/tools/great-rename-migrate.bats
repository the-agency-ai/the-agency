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
    [[ "$output" == *"1.2.0"* ]]
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
    # v1.1.0 default-map additions (Wave 2 — v46.1 src/ split)
    [[ "$output" == *"apps/"* ]]
    [[ "$output" == *"src/apps/"* ]]
    [[ "$output" == *"starter-packs/"* ]]
    [[ "$output" == *"src/spec-provider/starter-packs/"* ]]
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

@test "great-rename-migrate: version string matches 1.2.0 convention" {
    run bash "$TOOL" --version
    [ "$status" -eq 0 ]
    # Strict match: 'great-rename-migrate 1.2.0' (no bucket/date suffix)
    [ "$output" = "great-rename-migrate 1.2.0" ]
}

# --- v1.1.0 DEFAULT-MAP ADDITIONS (Wave 2 — v46.1 src/ split) ---
#
# Filed: 2026-05-09. mdpal-app dispatch #866 + mdpal-cli dispatch #865 both
# blocked because pre-Phase-4 worktrees cannot mechanically migrate v46.1
# moves (apps/ → src/apps/, starter-packs/ → src/spec-provider/starter-packs/)
# without a custom map. v1.1.0 adds these to the default map so the next
# pre-Phase-4 worktree (designex / devex / iscp / future) does not re-hit
# the same gap.

@test "great-rename-migrate: default map renames apps/ → src/apps/" {
    mkdir -p apps/mdpal-app/Sources
    echo "swift" > apps/mdpal-app/Sources/Foo.swift
    git add -A
    git commit -q -m "seed"
    git checkout -q -b feature
    run bash "$TOOL" --apply
    [ "$status" -eq 0 ]
    [[ ! -f "apps/mdpal-app/Sources/Foo.swift" ]]
    [[ -f "src/apps/mdpal-app/Sources/Foo.swift" ]]
    run cat src/apps/mdpal-app/Sources/Foo.swift
    [ "$output" = "swift" ]
}

@test "great-rename-migrate: default map renames starter-packs/ → src/spec-provider/starter-packs/" {
    mkdir -p starter-packs/nest-prototype
    echo "yaml" > starter-packs/nest-prototype/manifest.yaml
    git add -A
    git commit -q -m "seed"
    git checkout -q -b feature
    run bash "$TOOL" --apply
    [ "$status" -eq 0 ]
    [[ ! -f "starter-packs/nest-prototype/manifest.yaml" ]]
    [[ -f "src/spec-provider/starter-packs/nest-prototype/manifest.yaml" ]]
    run cat src/spec-provider/starter-packs/nest-prototype/manifest.yaml
    [ "$output" = "yaml" ]
}

@test "great-rename-migrate: default map handles all four waves in one run" {
    # Realistic pre-Phase-4 worktree fixture: claude/, tests/, apps/, and
    # starter-packs/ all coexist (the actual condition mdpal-app/cli faced).
    mkdir -p claude/tools tests/tools apps/mdpal/Sources starter-packs/nest
    echo "tool" > claude/tools/X
    echo "bats" > tests/tools/X.bats
    echo "swift" > apps/mdpal/Sources/Foo.swift
    echo "yaml" > starter-packs/nest/manifest.yaml
    git add -A
    git commit -q -m "seed"
    git checkout -q -b feature
    run bash "$TOOL" --apply
    [ "$status" -eq 0 ]
    [[ "$output" == *"Renamed 4 file(s). 0 failure(s)."* ]]
    [[ -f "agency/tools/X" ]]
    [[ -f "src/tests/tools/X.bats" ]]
    [[ -f "src/apps/mdpal/Sources/Foo.swift" ]]
    [[ -f "src/spec-provider/starter-packs/nest/manifest.yaml" ]]
}

@test "great-rename-migrate: starter-packs/ not gobbled by apps/ rule (longest-prefix)" {
    # Both apps/ and starter-packs/ are prefixes; longest-first sort must
    # ensure starter-packs/ files map to src/spec-provider/starter-packs/,
    # NOT to src/apps/...starter-packs/... by accident.
    mkdir -p apps/foo starter-packs/bar
    echo "a" > apps/foo/file
    echo "b" > starter-packs/bar/file
    git add -A
    git commit -q -m "seed"
    git checkout -q -b feature
    run bash "$TOOL" --apply
    [ "$status" -eq 0 ]
    [[ -f "src/apps/foo/file" ]]
    [[ -f "src/spec-provider/starter-packs/bar/file" ]]
    # Negative: apps/ rule must NOT have eaten the starter-packs/ files
    [[ ! -f "src/apps/starter-packs/bar/file" ]]
}

# --- v1.2.0 DEFAULT-MAP ADDITIONS (Wave 3 — V5 Phase 4 src/ split) ---
#
# Filed: 2026-05-09. mdpal-cli dispatch #869: ran v1.1 cleanly (1205 files)
# but worktree-sync produced 618 conflicts because main has had a third
# rename wave since v1.1 shipped. v1.2 adds wave-3:
#   - agency/{workstreams,principals,REFERENCE}/ → src/agency/{...}/
#   - agency/workstreams/the-agency/ → agency/workstreams/agency/ (renamed)
# Map covers BOTH input states: never-migrated branches (claude/-prefixed,
# composed transform in one pass) AND v1.1-applied branches (agency/-prefixed,
# wave-3 incremental). Longest-prefix-first sort routes correctly.

@test "great-rename-migrate v1.2: agency/workstreams/the-agency/ → src/agency/workstreams/agency/ (composed: V5 + workstream-rename)" {
    mkdir -p agency/workstreams/the-agency/research
    echo "txt" > agency/workstreams/the-agency/research/note.md
    git add -A
    git commit -q -m "seed"
    git checkout -q -b feature
    run bash "$TOOL" --apply
    [ "$status" -eq 0 ]
    [[ ! -f "agency/workstreams/the-agency/research/note.md" ]]
    [[ -f "src/agency/workstreams/agency/research/note.md" ]]
}

@test "great-rename-migrate v1.2: agency/workstreams/{other}/ → src/agency/workstreams/{other}/ (V5 only)" {
    mkdir -p agency/workstreams/mdpal/seeds
    echo "seed-text" > agency/workstreams/mdpal/seeds/foo.md
    git add -A
    git commit -q -m "seed"
    git checkout -q -b feature
    run bash "$TOOL" --apply
    [ "$status" -eq 0 ]
    [[ -f "src/agency/workstreams/mdpal/seeds/foo.md" ]]
    # Negative: must not have applied the the-agency-special-case rename
    [[ ! -f "src/agency/workstreams/agency/seeds/foo.md" ]]
}

@test "great-rename-migrate v1.2: agency/principals/ → src/agency/principals/ (V5)" {
    mkdir -p agency/principals/jordan
    echo "id" > agency/principals/jordan/identity.yaml
    git add -A
    git commit -q -m "seed"
    git checkout -q -b feature
    run bash "$TOOL" --apply
    [ "$status" -eq 0 ]
    [[ -f "src/agency/principals/jordan/identity.yaml" ]]
}

@test "great-rename-migrate v1.2: agency/REFERENCE/ → src/agency/REFERENCE/ (V5)" {
    mkdir -p agency/REFERENCE
    echo "ref" > agency/REFERENCE/REFERENCE-EXAMPLE.md
    git add -A
    git commit -q -m "seed"
    git checkout -q -b feature
    run bash "$TOOL" --apply
    [ "$status" -eq 0 ]
    [[ -f "src/agency/REFERENCE/REFERENCE-EXAMPLE.md" ]]
}

@test "great-rename-migrate v1.2: agency/starter-packs/ → src/spec-provider/starter-packs/ (Wave 2c incremental)" {
    mkdir -p agency/starter-packs/nest-prototype
    echo "yaml" > agency/starter-packs/nest-prototype/manifest.yaml
    git add -A
    git commit -q -m "seed"
    git checkout -q -b feature
    run bash "$TOOL" --apply
    [ "$status" -eq 0 ]
    [[ -f "src/spec-provider/starter-packs/nest-prototype/manifest.yaml" ]]
}

@test "great-rename-migrate v1.2: claude/workstreams/the-agency/ → src/agency/workstreams/agency/ (composed one-pass for never-migrated)" {
    mkdir -p claude/workstreams/the-agency/research
    echo "x" > claude/workstreams/the-agency/research/note.md
    git add -A
    git commit -q -m "seed"
    git checkout -q -b feature
    run bash "$TOOL" --apply
    [ "$status" -eq 0 ]
    [[ -f "src/agency/workstreams/agency/research/note.md" ]]
    # Negative: must not have stopped at the agency/ intermediate
    [[ ! -f "agency/workstreams/the-agency/research/note.md" ]]
    [[ ! -f "agency/workstreams/agency/research/note.md" ]]
}

@test "great-rename-migrate v1.2: claude/workstreams/{other}/ → src/agency/workstreams/{other}/ (composed for never-migrated)" {
    mkdir -p claude/workstreams/mdpal
    echo "y" > claude/workstreams/mdpal/note.md
    git add -A
    git commit -q -m "seed"
    git checkout -q -b feature
    run bash "$TOOL" --apply
    [ "$status" -eq 0 ]
    [[ -f "src/agency/workstreams/mdpal/note.md" ]]
}

@test "great-rename-migrate v1.2: claude/principals/ → src/agency/principals/ (composed)" {
    mkdir -p claude/principals/jordan
    echo "p" > claude/principals/jordan/file
    git add -A
    git commit -q -m "seed"
    git checkout -q -b feature
    run bash "$TOOL" --apply
    [ "$status" -eq 0 ]
    [[ -f "src/agency/principals/jordan/file" ]]
}

@test "great-rename-migrate v1.2: claude/REFERENCE/ → src/agency/REFERENCE/ (composed)" {
    mkdir -p claude/REFERENCE
    echo "r" > claude/REFERENCE/REFERENCE-X.md
    git add -A
    git commit -q -m "seed"
    git checkout -q -b feature
    run bash "$TOOL" --apply
    [ "$status" -eq 0 ]
    [[ -f "src/agency/REFERENCE/REFERENCE-X.md" ]]
}

@test "great-rename-migrate v1.2: claude/ catch-all (non-V5-moved) still goes to agency/" {
    # claude/tools/, claude/agents/, etc. are NOT in the V5 split — they
    # remain at agency/ (build-output view). The catch-all wave-1 rule
    # must still apply.
    mkdir -p claude/tools claude/agents/captain
    echo "t" > claude/tools/some-tool
    echo "a" > claude/agents/captain/agent.md
    git add -A
    git commit -q -m "seed"
    git checkout -q -b feature
    run bash "$TOOL" --apply
    [ "$status" -eq 0 ]
    [[ -f "agency/tools/some-tool" ]]
    [[ -f "agency/agents/captain/agent.md" ]]
}

@test "great-rename-migrate v1.2: composed mdpal-cli scenario — never-migrated branch with all-waves files in one pass" {
    # Realistic fixture mirroring mdpal-cli's pre-rename state at v45.2
    mkdir -p \
        claude/tools \
        claude/agents/captain \
        claude/workstreams/the-agency/research \
        claude/workstreams/mdpal-cli/seeds \
        claude/principals/jordan \
        claude/REFERENCE \
        claude/starter-packs/nest \
        tests/tools \
        apps/mdpal-cli/Sources
    echo "1" > claude/tools/foo
    echo "2" > claude/agents/captain/agent.md
    echo "3" > claude/workstreams/the-agency/research/x.md
    echo "4" > claude/workstreams/mdpal-cli/seeds/seed.md
    echo "5" > claude/principals/jordan/identity.yaml
    echo "6" > claude/REFERENCE/REFERENCE-Y.md
    echo "7" > claude/starter-packs/nest/manifest.yaml
    echo "8" > tests/tools/x.bats
    echo "9" > apps/mdpal-cli/Sources/Foo.swift
    git add -A
    git commit -q -m "seed"
    git checkout -q -b feature
    run bash "$TOOL" --apply
    [ "$status" -eq 0 ]
    [[ "$output" == *"9 file(s)"* ]]
    # Wave 1 catch-all
    [[ -f "agency/tools/foo" ]]
    [[ -f "agency/agents/captain/agent.md" ]]
    # Wave 1 (tests)
    [[ -f "src/tests/tools/x.bats" ]]
    # Wave 2 (apps)
    [[ -f "src/apps/mdpal-cli/Sources/Foo.swift" ]]
    # Wave 2b (claude/starter-packs/ direct → src/spec-provider/)
    [[ -f "src/spec-provider/starter-packs/nest/manifest.yaml" ]]
    # Wave 3 composed (workstream-rename + V5)
    [[ -f "src/agency/workstreams/agency/research/x.md" ]]
    # Wave 3 composed (V5 only for non-the-agency workstream)
    [[ -f "src/agency/workstreams/mdpal-cli/seeds/seed.md" ]]
    # Wave 3 composed (principals)
    [[ -f "src/agency/principals/jordan/identity.yaml" ]]
    # Wave 3 composed (REFERENCE)
    [[ -f "src/agency/REFERENCE/REFERENCE-Y.md" ]]
}
