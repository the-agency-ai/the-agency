#!/usr/bin/env bats
#
# Tests for agency/tools/lib/_docker-heal — Docker socket reachability helper
#
# What Problem: Bug-expose GH issue #58 — on macOS, Docker Desktop exposes its
# socket at $HOME/.docker/run/docker.sock rather than /var/run/docker.sock,
# and the CLI fails with "dial unix ...: no such file or directory" even
# though Docker Desktop is running. These tests verify docker_heal detects
# the reachable socket, sets DOCKER_HOST, and prints remediation when nothing
# works.
#
# How the tests work: DOCKER_HEAL_TEST_MODE=1 activates injection hooks —
# DOCKER_HEAL_STUB provides a fake `docker` binary and
# DOCKER_HEAL_SOCKET_CANDIDATES provides a colon-separated list of candidate
# socket paths (bypassing real socket file checks).
#
# Written: 2026-04-09 — fix for GH #58 / dispatch #174

load test_helper

setup() {
    test_isolation_setup
    export TEST_REPO="${BATS_TEST_TMPDIR}/test-repo"
    mkdir -p "$TEST_REPO/bin"
    cd "$TEST_REPO"

    # Enable test mode in the lib
    export DOCKER_HEAL_TEST_MODE=1

    # Path to the lib being tested (from the real repo, sourced under test)
    export DOCKER_HEAL_LIB="$REPO_ROOT/agency/tools/lib/_docker-heal"
}

teardown() {
    test_isolation_teardown
    unset DOCKER_HEAL_TEST_MODE DOCKER_HEAL_STUB DOCKER_HEAL_SOCKET_CANDIDATES DOCKER_HOST
}

# Helper: create a stub `docker` script at TEST_REPO/bin/docker-<name> and
# return its path. The stub accepts `docker info` and succeeds or fails
# depending on DOCKER_HOST matching the stub's "good" socket path.
_make_stub() {
    local name="$1"
    local good_host="$2"
    local stub="$TEST_REPO/bin/docker-$name"
    cat > "$stub" <<STUB
#!/bin/bash
# Stub docker that succeeds if DOCKER_HOST matches its configured good host,
# or if no DOCKER_HOST is set and the "default" mode is on.
if [[ "\$1" != "info" ]]; then
    exit 0
fi
if [[ -z "${good_host}" ]]; then
    # No good host = always fail
    exit 1
fi
if [[ "\${DOCKER_HOST:-}" == "${good_host}" ]]; then
    exit 0
fi
if [[ "${good_host}" == "DEFAULT" && -z "\${DOCKER_HOST:-}" ]]; then
    exit 0
fi
exit 1
STUB
    chmod +x "$stub"
    echo "$stub"
}

# ─────────────────────────────────────────────────────────────────────────────
# Default reachable — no heal needed
# ─────────────────────────────────────────────────────────────────────────────

@test "docker_heal: returns 0 when docker already reachable (default path)" {
    DOCKER_HEAL_STUB=$(_make_stub "default-ok" "DEFAULT")
    run bash -c "
        export DOCKER_HEAL_STUB=$DOCKER_HEAL_STUB
        export DOCKER_HEAL_TEST_MODE=1
        source '$DOCKER_HEAL_LIB'
        docker_heal
    "
    [ "$status" -eq 0 ]
}

@test "docker_heal: does NOT set DOCKER_HOST when default already works" {
    DOCKER_HEAL_STUB=$(_make_stub "default-ok" "DEFAULT")
    run bash -c "
        export DOCKER_HEAL_STUB=$DOCKER_HEAL_STUB
        export DOCKER_HEAL_TEST_MODE=1
        source '$DOCKER_HEAL_LIB'
        docker_heal
        echo \"DOCKER_HOST=\${DOCKER_HOST:-unset}\"
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"DOCKER_HOST=unset"* ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Bug-exposing: default broken, macOS Desktop socket works
# ─────────────────────────────────────────────────────────────────────────────

@test "docker_heal: recovers via macOS Desktop socket (GH #58)" {
    # The scenario: default docker.sock broken, DOCKER_HOST pointing at
    # Desktop alt socket works
    local desktop_host="unix:///fake/home/.docker/run/docker.sock"
    DOCKER_HEAL_STUB=$(_make_stub "desktop-only" "$desktop_host")
    run bash -c "
        export DOCKER_HEAL_STUB=$DOCKER_HEAL_STUB
        export DOCKER_HEAL_TEST_MODE=1
        export DOCKER_HEAL_SOCKET_CANDIDATES='/fake/home/.docker/run/docker.sock'
        source '$DOCKER_HEAL_LIB'
        docker_heal
        echo \"DOCKER_HOST=\${DOCKER_HOST:-unset}\"
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"DOCKER_HOST=$desktop_host"* ]]
}

@test "docker_heal: prints auto-detected socket path on recovery" {
    local desktop_host="unix:///fake/home/.docker/run/docker.sock"
    DOCKER_HEAL_STUB=$(_make_stub "desktop-only" "$desktop_host")
    run bash -c "
        export DOCKER_HEAL_STUB=$DOCKER_HEAL_STUB
        export DOCKER_HEAL_TEST_MODE=1
        export DOCKER_HEAL_SOCKET_CANDIDATES='/fake/home/.docker/run/docker.sock'
        source '$DOCKER_HEAL_LIB'
        docker_heal 2>&1
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"auto-detected"* ]]
    [[ "$output" == *"/fake/home/.docker/run/docker.sock"* ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Recovery via second candidate (first in list fails)
# ─────────────────────────────────────────────────────────────────────────────

@test "docker_heal: tries multiple candidates in order" {
    local good_host="unix:///second/candidate.sock"
    DOCKER_HEAL_STUB=$(_make_stub "second-ok" "$good_host")
    run bash -c "
        export DOCKER_HEAL_STUB=$DOCKER_HEAL_STUB
        export DOCKER_HEAL_TEST_MODE=1
        export DOCKER_HEAL_SOCKET_CANDIDATES='/first/broken.sock:/second/candidate.sock:/third/also-broken.sock'
        source '$DOCKER_HEAL_LIB'
        docker_heal
        echo \"DOCKER_HOST=\${DOCKER_HOST:-unset}\"
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"DOCKER_HOST=$good_host"* ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Nothing works — actionable error
# ─────────────────────────────────────────────────────────────────────────────

@test "docker_heal: returns 1 when no candidate works" {
    DOCKER_HEAL_STUB=$(_make_stub "never-ok" "")
    run bash -c "
        export DOCKER_HEAL_STUB=$DOCKER_HEAL_STUB
        export DOCKER_HEAL_TEST_MODE=1
        export DOCKER_HEAL_SOCKET_CANDIDATES='/a.sock:/b.sock'
        source '$DOCKER_HEAL_LIB'
        docker_heal
    "
    [ "$status" -eq 1 ]
}

@test "docker_heal: prints actionable remediation on failure" {
    DOCKER_HEAL_STUB=$(_make_stub "never-ok" "")
    run bash -c "
        export DOCKER_HEAL_STUB=$DOCKER_HEAL_STUB
        export DOCKER_HEAL_TEST_MODE=1
        export DOCKER_HEAL_SOCKET_CANDIDATES='/a.sock'
        source '$DOCKER_HEAL_LIB'
        docker_heal 2>&1
    "
    [ "$status" -eq 1 ]
    [[ "$output" == *"cannot connect"* ]]
    [[ "$output" == *"Remediation"* ]]
}

@test "docker_heal: actionable error includes candidates tried" {
    DOCKER_HEAL_STUB=$(_make_stub "never-ok" "")
    run bash -c "
        export DOCKER_HEAL_STUB=$DOCKER_HEAL_STUB
        export DOCKER_HEAL_TEST_MODE=1
        export DOCKER_HEAL_SOCKET_CANDIDATES='/a.sock:/b.sock:/c.sock'
        source '$DOCKER_HEAL_LIB'
        docker_heal 2>&1
    "
    [ "$status" -eq 1 ]
    [[ "$output" == *"/a.sock"* ]]
    [[ "$output" == *"/b.sock"* ]]
    [[ "$output" == *"/c.sock"* ]]
}

@test "docker_heal: unsets DOCKER_HOST on failure (no broken value leaks)" {
    DOCKER_HEAL_STUB=$(_make_stub "never-ok" "")
    run bash -c "
        export DOCKER_HEAL_STUB=$DOCKER_HEAL_STUB
        export DOCKER_HEAL_TEST_MODE=1
        export DOCKER_HEAL_SOCKET_CANDIDATES='/a.sock:/b.sock'
        source '$DOCKER_HEAL_LIB'
        docker_heal 2>/dev/null || true
        echo \"DOCKER_HOST=\${DOCKER_HOST:-unset}\"
    "
    [[ "$output" == *"DOCKER_HOST=unset"* ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Platform-specific remediation
# ─────────────────────────────────────────────────────────────────────────────

@test "docker_heal: macOS remediation mentions Docker Desktop and context" {
    # Only meaningful on Darwin; skip otherwise
    [[ "$(uname -s)" == "Darwin" ]] || skip "Darwin-specific"
    DOCKER_HEAL_STUB=$(_make_stub "never-ok" "")
    run bash -c "
        export DOCKER_HEAL_STUB=$DOCKER_HEAL_STUB
        export DOCKER_HEAL_TEST_MODE=1
        export DOCKER_HEAL_SOCKET_CANDIDATES='/a.sock'
        source '$DOCKER_HEAL_LIB'
        docker_heal 2>&1
    "
    [ "$status" -eq 1 ]
    [[ "$output" == *"Docker Desktop"* ]]
    [[ "$output" == *"desktop-linux"* ]] || [[ "$output" == *"docker context use"* ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Edge cases
# ─────────────────────────────────────────────────────────────────────────────

@test "docker_heal: empty candidate list → fails cleanly" {
    DOCKER_HEAL_STUB=$(_make_stub "never-ok" "")
    run bash -c "
        export DOCKER_HEAL_STUB=$DOCKER_HEAL_STUB
        export DOCKER_HEAL_TEST_MODE=1
        export DOCKER_HEAL_SOCKET_CANDIDATES=''
        source '$DOCKER_HEAL_LIB'
        docker_heal 2>&1
    "
    [ "$status" -eq 1 ]
    [[ "$output" == *"cannot connect"* ]]
}

@test "docker_heal: lib is sourceable without docker binary" {
    # Just sourcing shouldn't require docker. Sanity check.
    run bash -c "source '$DOCKER_HEAL_LIB' && echo ok"
    [ "$status" -eq 0 ]
    [[ "$output" == *"ok"* ]]
}
