#!/usr/bin/env bats
# Integration tests for ./agency/tools/test-monitor — Iter 1 (BATS only).
#
# Runs test-monitor as a subprocess against fixture BATS suites.
# Verifies: [TEST …] event sequence, exit codes, error paths, --timeout,
# --trigger-on cross-validation, framework-unknown error.

setup() {
    REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
    # Invoke via python3.13 explicitly: on this adopter machine,
    # `python3` resolves to Apple 3.9 (flag #175). Shebang + guard
    # correctly errors in that case, but we need the tool to actually
    # run for these tests. Bypass the shebang.
    TOOL="python3.13 $REPO_ROOT/agency/tools/test-monitor"
    FIXT="$REPO_ROOT/src/tests/tools/fixtures/test-monitor"
    # Isolated agency.yaml for these tests
    TMP_REPO="$(mktemp -d)"
    mkdir -p "$TMP_REPO/agency/config"
}

teardown() {
    if [[ -n "${TMP_REPO:-}" && -d "$TMP_REPO" ]]; then
        rm -rf "$TMP_REPO"
    fi
}

@test "test-monitor --version prints version and exits 0" {
    run $TOOL --version
    [ "$status" -eq 0 ]
    [[ "$output" == *"test-monitor"* ]]
    [[ "$output" == *"1.0.0-iter1"* ]]
}

@test "test-monitor --help exits 0" {
    run $TOOL --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"test-monitor"* ]]
    [[ "$output" == *"--timeout"* ]]
    [[ "$output" == *"--trigger-on"* ]]
    [[ "$output" == *"--trigger-to"* ]]
}

@test "test-monitor --trigger-on red without --trigger-to errors at argparse" {
    run $TOOL --trigger-on red
    [ "$status" -ne 0 ]
}

@test "test-monitor --trigger-on without implementation fails cleanly in Iter 1" {
    # --trigger-on is declared in CLI but not implemented until Iter 3
    run $TOOL --trigger-on red --trigger-to captain
    [ "$status" -eq 2 ]
    [[ "$output" == *"[TEST ERROR]"* ]]
    [[ "$output" == *"Iter 1"* ]]
}

@test "test-monitor --timeout negative errors" {
    run $TOOL --timeout -1
    [ "$status" -ne 0 ]
}

@test "test-monitor --suite <unknown> emits [TEST ERROR] and exits 2" {
    run $TOOL --suite definitely_not_a_real_suite
    [ "$status" -eq 2 ]
    [[ "$output" == *"[TEST ERROR]"* ]]
    [[ "$output" == *"not found"* ]]
}

@test "test-monitor runs the passing fixture BATS suite end-to-end" {
    local workdir="$TMP_REPO/work"
    mkdir -p "$workdir/agency/config" "$workdir/tests/monitor-fixt"
    cp "$FIXT/passing.bats" "$workdir/tests/monitor-fixt/"
    cat > "$workdir/agency/config/agency.yaml" <<EOF
testing:
  suites:
    mfxt:
      command: "bats tests/monitor-fixt/passing.bats"
      description: "monitor fixture — passing"
EOF
    cd "$workdir"
    git init -q
    run $TOOL --suite mfxt
    [ "$status" -eq 0 ]
    [[ "$output" == *"[TEST mfxt] suite started (bats)"* ]]
    [[ "$output" == *"[TEST mfxt] suite done — 3 pass, 0 fail"* ]]
    [[ "$output" == *"[TEST] run complete — 3 pass, 0 fail"* ]]
    [[ "$output" == *"exit 0"* ]]
}

@test "test-monitor runs the failing fixture BATS suite, emits FAIL, exits 1" {
    local workdir="$TMP_REPO/work"
    mkdir -p "$workdir/agency/config" "$workdir/tests/monitor-fixt"
    cp "$FIXT/failing.bats" "$workdir/tests/monitor-fixt/"
    cat > "$workdir/agency/config/agency.yaml" <<EOF
testing:
  suites:
    mfxt:
      command: "bats tests/monitor-fixt/failing.bats"
      description: "monitor fixture — failing"
EOF
    cd "$workdir"
    git init -q
    run $TOOL --suite mfxt
    [ "$status" -eq 1 ]
    [[ "$output" == *"[TEST mfxt] FAIL"* ]]
    [[ "$output" == *"[TEST mfxt] suite done —"* ]]
    [[ "$output" == *"2 pass, 1 fail"* ]]
    [[ "$output" == *"[TEST] run complete"* ]]
    [[ "$output" == *"exit 1"* ]]
    [[ "$output" == *"agent: investigate failures"* ]]
}

@test "test-monitor errors when agency.yaml is missing" {
    local workdir="$TMP_REPO/work"
    mkdir -p "$workdir/agency/config"
    cd "$workdir"
    git init -q
    run $TOOL --suite anything
    [ "$status" -eq 2 ]
    [[ "$output" == *"[TEST ERROR]"* ]]
}

@test "test-monitor errors on empty testing.suites" {
    local workdir="$TMP_REPO/work"
    mkdir -p "$workdir/agency/config"
    cat > "$workdir/agency/config/agency.yaml" <<EOF
# no suites
EOF
    cd "$workdir"
    git init -q
    run $TOOL
    [ "$status" -eq 2 ]
    [[ "$output" == *"no suites configured"* ]]
}

@test "test-monitor errors on unknown framework in command" {
    local workdir="$TMP_REPO/work"
    mkdir -p "$workdir/agency/config"
    cat > "$workdir/agency/config/agency.yaml" <<EOF
testing:
  suites:
    weird:
      command: "make test-weird"
      description: "unknown framework"
EOF
    cd "$workdir"
    git init -q
    run $TOOL --suite weird
    [ "$status" -eq 2 ]
    [[ "$output" == *"[TEST ERROR]"* ]]
    [[ "$output" == *"cannot detect framework"* ]]
}

@test "test-monitor --timeout kills a hung subprocess and exits 2" {
    local workdir="$TMP_REPO/work"
    mkdir -p "$workdir/agency/config" "$workdir/tests/monitor-fixt"
    # A BATS suite with a long sleep — --timeout should kill it
    cat > "$workdir/tests/monitor-fixt/hang.bats" <<'EOF'
@test "hangs" {
    sleep 30
}
EOF
    cat > "$workdir/agency/config/agency.yaml" <<EOF
testing:
  suites:
    hang:
      command: "bats tests/monitor-fixt/hang.bats"
      description: "hang"
EOF
    cd "$workdir"
    git init -q
    local start=$(date +%s)
    run $TOOL --suite hang --timeout 2
    local elapsed=$(( $(date +%s) - start ))
    [ "$status" -eq 2 ]
    [[ "$output" == *"[TEST ERROR]"* ]]
    [[ "$output" == *"timed out"* ]]
    # Should have killed within a few seconds, not 30
    [ "$elapsed" -lt 10 ]
}
