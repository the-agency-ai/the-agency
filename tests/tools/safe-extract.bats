#!/usr/bin/env bats
#
# Tests for safe-extract tool — archive validation and extraction
#
# Phase 5.5: Tests from Agent Workspace & Bootstrap Quality plan
#

load 'test_helper'

setup() {
    export BATS_TEST_TMPDIR="$(mktemp -d)"
    cd "${BATS_TEST_TMPDIR}"
    mkdir -p usr/testuser/project/seeds
    mkdir -p usr/testuser/project/tmp
}

teardown() {
    if [[ -d "${BATS_TEST_TMPDIR}" ]]; then
        rm -rf "${BATS_TEST_TMPDIR}"
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# Help and version
# ─────────────────────────────────────────────────────────────────────────────

@test "safe-extract: --version shows version" {
    run_tool safe-extract --version
    assert_success
    assert_output_contains "safe-extract"
}

@test "safe-extract: --help shows usage" {
    run_tool safe-extract --help
    assert_success
    assert_output_contains "Usage:"
}

@test "safe-extract: no args shows help" {
    run_tool safe-extract
    assert_success
    assert_output_contains "Usage:"
}

# ─────────────────────────────────────────────────────────────────────────────
# Destination validation
# ─────────────────────────────────────────────────────────────────────────────

@test "safe-extract: rejects non-usr/ destination" {
    cd "${BATS_TEST_TMPDIR}"
    # Create a clean zip
    echo "test" > testfile.txt
    zip clean.zip testfile.txt > /dev/null

    run_tool safe-extract clean.zip /tmp/output
    assert_failure
    assert_output_contains "must be under usr/"
}

@test "safe-extract: rejects nonexistent archive" {
    run_tool safe-extract nonexistent.zip usr/testuser/project/seeds/
    assert_failure
    assert_output_contains "not found"
}

# ─────────────────────────────────────────────────────────────────────────────
# Clean archive extraction
# ─────────────────────────────────────────────────────────────────────────────

@test "safe-extract: extracts clean zip to usr/ path" {
    cd "${BATS_TEST_TMPDIR}"
    # Create a clean zip
    mkdir -p content
    echo "hello" > content/file1.txt
    echo "world" > content/file2.txt
    cd content
    zip -r ../clean.zip . > /dev/null
    cd ..

    run_tool safe-extract clean.zip usr/testuser/project/seeds/
    assert_success
    [[ -f "usr/testuser/project/seeds/file1.txt" ]]
    [[ -f "usr/testuser/project/seeds/file2.txt" ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Path traversal rejection
# ─────────────────────────────────────────────────────────────────────────────

@test "safe-extract: rejects zip with ../ path traversal" {
    cd "${BATS_TEST_TMPDIR}"
    # Create a zip with path traversal entry using python
    python3 -c "
import zipfile
with zipfile.ZipFile('evil.zip', 'w') as zf:
    zf.writestr('../../../etc/passwd', 'pwned')
" 2>/dev/null || skip "python3 not available"

    run_tool safe-extract evil.zip usr/testuser/project/seeds/
    assert_failure
    assert_output_contains "REJECTED"
    [[ ! -f "etc/passwd" ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Symlink rejection
# ─────────────────────────────────────────────────────────────────────────────

@test "safe-extract: rejects zip with symlink entries" {
    cd "${BATS_TEST_TMPDIR}"
    # Create a zip with symlink entry using python
    python3 -c "
import zipfile, os, stat
with zipfile.ZipFile('symlink.zip', 'w') as zf:
    info = zipfile.ZipInfo('link')
    info.create_system = 3  # Unix
    info.external_attr = (stat.S_IFLNK | 0o777) << 16
    zf.writestr(info, '/etc/passwd')
" 2>/dev/null || skip "python3 not available"

    run_tool safe-extract symlink.zip usr/testuser/project/seeds/
    assert_failure
    assert_output_contains "REJECTED"
}

# ─────────────────────────────────────────────────────────────────────────────
# Unsupported formats
# ─────────────────────────────────────────────────────────────────────────────

@test "safe-extract: rejects tar archives with informative message" {
    cd "${BATS_TEST_TMPDIR}"
    touch empty.tar

    run_tool safe-extract empty.tar usr/testuser/project/seeds/
    assert_failure
    assert_output_contains "tar archives not yet supported"
}

@test "safe-extract: rejects unknown formats" {
    cd "${BATS_TEST_TMPDIR}"
    touch unknown.rar

    run_tool safe-extract unknown.rar usr/testuser/project/seeds/
    assert_failure
    assert_output_contains "unsupported"
}
