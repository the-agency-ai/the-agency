#!/bin/bash
#
# test-worktree-sync.sh — Tests for claude/tools/worktree-sync
#
# Run: bash claude/tools/tests/test-worktree-sync.sh
#
# Creates temp git repos to test all code paths.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TOOL="$TOOLS_DIR/worktree-sync"

PASS=0
FAIL=0
ERRORS=""
TMPBASE=""

# --- Test harness ---
assert_eq() {
    local test_name="$1" expected="$2" actual="$3"
    if [ "$expected" = "$actual" ]; then
        PASS=$((PASS + 1))
        printf "  ✓ %s\n" "$test_name"
    else
        FAIL=$((FAIL + 1))
        ERRORS="${ERRORS}\n  FAIL: ${test_name}\n    expected: ${expected}\n    actual:   ${actual}"
        printf "  ✗ %s\n" "$test_name"
    fi
}

assert_contains() {
    local test_name="$1" expected="$2" actual="$3"
    if echo "$actual" | grep -qF "$expected"; then
        PASS=$((PASS + 1))
        printf "  ✓ %s\n" "$test_name"
    else
        FAIL=$((FAIL + 1))
        ERRORS="${ERRORS}\n  FAIL: ${test_name}\n    expected to contain: ${expected}\n    actual: ${actual}"
        printf "  ✗ %s\n" "$test_name"
    fi
}

assert_valid_json() {
    local test_name="$1" content="$2"
    if echo "$content" | jq . >/dev/null 2>&1; then
        PASS=$((PASS + 1))
        printf "  ✓ %s\n" "$test_name"
    else
        FAIL=$((FAIL + 1))
        ERRORS="${ERRORS}\n  FAIL: ${test_name}\n    invalid JSON: ${content}"
        printf "  ✗ %s\n" "$test_name"
    fi
}

# --- Setup: create a temp git repo with a worktree ---
setup_repo() {
    TMPBASE=$(mktemp -d)

    # Create main repo with master branch (tool hardcodes "master")
    git init "$TMPBASE/main" --quiet --initial-branch=master
    cd "$TMPBASE/main"
    git config user.email "test@test.com"
    git config user.name "Test"

    # Create initial structure
    mkdir -p claude/tools .claude
    echo '{"permissions":{}}' > .claude/settings.json
    cp "$TOOL" claude/tools/worktree-sync
    chmod +x claude/tools/worktree-sync

    # Don't copy log helper — it uses python3 for UUID generation which can hang in temp repos
    # The tool handles missing _log-helper gracefully (logging is optional)

    # Don't copy sandbox-sync — temp repo doesn't have claude/usr/ structure
    # The tool handles missing sandbox-sync gracefully

    git add -A
    git commit -m "initial" --quiet

    # Create worktree on feature branch
    git branch feature
    git worktree add "$TMPBASE/worktree" feature --quiet 2>/dev/null

    cd "$TMPBASE/worktree"
}

cleanup() {
    if [[ -n "$TMPBASE" ]] && [[ -d "$TMPBASE" ]]; then
        cd /tmp
        # Remove worktree first
        git -C "$TMPBASE/main" worktree remove "$TMPBASE/worktree" --force 2>/dev/null || true
        rm -rf "$TMPBASE"
    fi
}

# ========================================
echo "=== worktree-sync tests ==="
echo ""

# --- Test 1: --version ---
echo "Test: --version"
OUTPUT=$(bash "$TOOL" --version 2>&1)
EXIT=$?
assert_eq "exit code 0" "0" "$EXIT"
assert_contains "prints version" "1.0.0" "$OUTPUT"
echo ""

# --- Test 2: --help ---
echo "Test: --help"
OUTPUT=$(bash "$TOOL" --help 2>&1)
EXIT=$?
assert_eq "exit code 0" "0" "$EXIT"
assert_contains "prints usage" "Usage:" "$OUTPUT"
echo ""

# --- Test 3: unknown arg ---
echo "Test: unknown argument"
OUTPUT=$(bash "$TOOL" --bogus 2>&1 || true)
assert_contains "error message" "unknown argument" "$OUTPUT"
echo ""

# --- Test 4: master guard (manual) ---
echo "Test: master guard — manual mode"
setup_repo
cd "$TMPBASE/main"  # on master
OUTPUT=$(bash claude/tools/worktree-sync 2>&1 || true)
EXIT=${PIPESTATUS[0]:-1}
assert_contains "refuses on master" "use /sync-all instead" "$OUTPUT"
cleanup
echo ""

# --- Test 5: master guard (auto) — soft skip ---
echo "Test: master guard — auto mode (soft skip)"
setup_repo
cd "$TMPBASE/main"
OUTPUT=$(bash claude/tools/worktree-sync --auto 2>&1)
EXIT=$?
assert_eq "exit code 0" "0" "$EXIT"
assert_valid_json "valid JSON output" "$OUTPUT"
assert_contains "skip message" "skipped" "$OUTPUT"
cleanup
echo ""

# --- Test 6: dirty tree (manual) — refuse ---
echo "Test: dirty tree — manual mode"
setup_repo
echo "dirty" > dirty.txt
OUTPUT=$(bash claude/tools/worktree-sync 2>&1 || true)
assert_contains "refuses on dirty" "dirty" "$OUTPUT"
assert_contains "file count" "modified files" "$OUTPUT"
cleanup
echo ""

# --- Test 7: already up to date ---
echo "Test: already up to date"
setup_repo
OUTPUT=$(bash claude/tools/worktree-sync 2>&1)
EXIT=$?
assert_eq "exit code 0" "0" "$EXIT"
assert_contains "up to date" "already up to date" "$OUTPUT"
cleanup
echo ""

# --- Test 8: merge master (with changes) ---
echo "Test: merge master with changes"
setup_repo
# Add a commit to master
cd "$TMPBASE/main"
echo "new content" > claude/tools/new-tool
git add claude/tools/new-tool
git commit -m "add new tool" --quiet
# Back to worktree
cd "$TMPBASE/worktree"
OUTPUT=$(bash claude/tools/worktree-sync 2>&1)
EXIT=$?
assert_eq "exit code 0" "0" "$EXIT"
assert_contains "merge report" "merged master" "$OUTPUT"
assert_contains "file in report" "new-tool" "$OUTPUT"
# Verify the file actually arrived
assert_eq "file merged" "new content" "$(cat claude/tools/new-tool 2>/dev/null || echo 'missing')"
cleanup
echo ""

# --- Test 9: settings.json copy ---
echo "Test: settings.json copy from main checkout"
setup_repo
# Update settings in main checkout only (not via git)
echo '{"permissions":{"allow":["new"]}}' > "$TMPBASE/main/.claude/settings.json"
OUTPUT=$(bash claude/tools/worktree-sync 2>&1)
assert_contains "settings copied" "settings.json" "$OUTPUT"
# Verify copy happened
WORKTREE_SETTINGS=$(cat .claude/settings.json)
assert_contains "settings match" '"new"' "$WORKTREE_SETTINGS"
cleanup
echo ""

# --- Test 10: CLAUDE.md change detection ---
echo "Test: CLAUDE.md change detection"
setup_repo
cd "$TMPBASE/main"
echo "updated methodology" > CLAUDE.md
git add CLAUDE.md
git commit -m "update CLAUDE.md" --quiet
cd "$TMPBASE/worktree"
OUTPUT=$(bash claude/tools/worktree-sync 2>&1)
assert_contains "claude.md detected" "re-read recommended" "$OUTPUT"
cleanup
echo ""

# --- Test 11: auto mode — stash and unstash ---
echo "Test: auto mode — stash/merge/unstash"
setup_repo
# Add commit to master
cd "$TMPBASE/main"
echo "master change" > claude/tools/master-file
git add claude/tools/master-file
git commit -m "master commit" --quiet
# Back to worktree with dirty file (different from master's change)
cd "$TMPBASE/worktree"
echo "local work" > local-work.txt
OUTPUT=$(bash claude/tools/worktree-sync --auto 2>&1)
EXIT=$?
assert_eq "exit code 0" "0" "$EXIT"
assert_valid_json "valid JSON" "$OUTPUT"
# Verify local work survived the stash/unstash
assert_eq "local work preserved" "local work" "$(cat local-work.txt 2>/dev/null || echo 'missing')"
# Verify master change arrived
assert_eq "master file merged" "master change" "$(cat claude/tools/master-file 2>/dev/null || echo 'missing')"
cleanup
echo ""

# --- Test 12: merge conflict ---
echo "Test: merge conflict"
setup_repo
# Both master and worktree modify the same file
cd "$TMPBASE/main"
echo "master version" > conflict-file.txt
git add conflict-file.txt
git commit -m "master side" --quiet
cd "$TMPBASE/worktree"
echo "worktree version" > conflict-file.txt
git add conflict-file.txt
git commit -m "worktree side" --quiet
OUTPUT=$(bash claude/tools/worktree-sync 2>&1 || true)
assert_contains "conflict detected" "merge conflict" "$OUTPUT"
# Verify worktree is clean (merge aborted)
MERGE_STATE=$(git rev-parse --verify MERGE_HEAD 2>/dev/null || echo "no-merge")
assert_eq "merge aborted" "no-merge" "$MERGE_STATE"
cleanup
echo ""

# --- Test 13: auto mode conflict produces valid JSON ---
echo "Test: auto mode conflict — valid JSON"
setup_repo
cd "$TMPBASE/main"
echo "master version" > conflict-file.txt
git add conflict-file.txt
git commit -m "master side" --quiet
cd "$TMPBASE/worktree"
echo "worktree version" > conflict-file.txt
git add conflict-file.txt
git commit -m "worktree side" --quiet
OUTPUT=$(bash claude/tools/worktree-sync --auto 2>&1 || true)
# Extract just the JSON line (last line of output)
JSON_LINE=$(echo "$OUTPUT" | grep '{"systemMessage"' || echo "")
if [[ -n "$JSON_LINE" ]]; then
    assert_valid_json "conflict JSON is valid" "$JSON_LINE"
else
    FAIL=$((FAIL + 1))
    ERRORS="${ERRORS}\n  FAIL: conflict JSON is valid\n    no JSON found in output"
    printf "  ✗ %s\n" "conflict JSON is valid"
fi
cleanup
echo ""

# --- Test 14: dispatch detection ---
echo "Test: dispatch detection"
setup_repo
cd "$TMPBASE/main"
mkdir -p claude/usr/jordan/captain/dispatches
echo "dispatch content" > claude/usr/jordan/captain/dispatches/dispatch-test-20260401.md
git add -A
git commit -m "add dispatch" --quiet
cd "$TMPBASE/worktree"
OUTPUT=$(bash claude/tools/worktree-sync 2>&1)
assert_contains "dispatch detected" "dispatch" "$OUTPUT"
cleanup
echo ""

# ========================================
echo ""
echo "=== Results ==="
echo "  Passed: $PASS"
echo "  Failed: $FAIL"

if [ $FAIL -gt 0 ]; then
    echo ""
    echo "Failures:"
    printf "$ERRORS\n"
    exit 1
fi

echo ""
echo "All tests passed."
exit 0
