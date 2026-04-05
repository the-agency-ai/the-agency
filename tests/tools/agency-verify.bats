#!/usr/bin/env bats
#
# Tests for agency verify (via agency CLI)
#
# Tests provider configuration validation, directory checks,
# pass/fail/warn counting, and exit codes.
#

load 'test_helper'

# Helper: run agency subcommand
run_agency() {
    run "${TOOLS_DIR}/agency" "$@"
}

# ─────────────────────────────────────────────────────────────────────────────
# CLI flags
# ─────────────────────────────────────────────────────────────────────────────

@test "agency verify: --help shows usage" {
    run_agency verify --help
    assert_success
    assert_output_contains "Usage"
}

# ─────────────────────────────────────────────────────────────────────────────
# Against real project
# ─────────────────────────────────────────────────────────────────────────────

@test "agency verify: passes on the-agency repo" {
    run_agency verify
    assert_success
    assert_output_contains "checks passed"
    assert_output_contains "✓"
}

@test "agency verify: verbose shows individual checks" {
    run_agency verify --verbose
    assert_success
    assert_output_contains "agency.yaml exists"
    assert_output_contains "_provider-resolve loaded"
}

@test "agency verify: reports secrets provider" {
    run_agency verify --verbose
    assert_success
    assert_output_contains "secrets: secret-vault"
}

@test "agency verify: reports terminal provider" {
    run_agency verify --verbose
    assert_success
    assert_output_contains "terminal: terminal-setup-ghostty"
}

@test "agency verify: reports platform provider (auto-detected)" {
    run_agency verify --verbose
    assert_success
    assert_output_contains "platform: platform-setup-"
}

@test "agency verify: reports design providers as deferred warnings" {
    run_agency verify --verbose
    assert_success
    assert_output_contains "design.diff"
    assert_output_contains "deferred"
}

@test "agency verify: checks required directories" {
    run_agency verify --verbose
    assert_success
    assert_output_contains "directory: claude/config/"
    assert_output_contains "directory: claude/agents/"
    assert_output_contains "directory: claude/docs/"
    assert_output_contains "directory: claude/hooks/"
}

@test "agency verify: checks agency CLI exists" {
    run_agency verify --verbose
    assert_success
    assert_output_contains "agency CLI"
}

# ─────────────────────────────────────────────────────────────────────────────
# Other subcommands
# ─────────────────────────────────────────────────────────────────────────────

@test "agency help: shows usage" {
    run_agency help
    assert_success
    assert_output_contains "agency"
    assert_output_contains "Commands"
}

@test "agency version: shows version" {
    run_agency version
    assert_success
    assert_output_contains "agency"
}

@test "agency whoami: returns agent name" {
    run_agency whoami
    assert_success
}

@test "agency: unknown subcommand fails" {
    run_agency nonexistent
    assert_failure
    assert_output_contains "Unknown command"
}

# ─────────────────────────────────────────────────────────────────────────────
# Path integrity — prevent stale claude/usr/ references (usr/ is at project root)
# ─────────────────────────────────────────────────────────────────────────────

@test "path integrity: no claude/usr/ references in live tools" {
    # usr/ lives at project root, not under claude/
    # Legacy patterns in upstream-port (for backward compat with old upstream repos) are excluded
    local stale
    stale=$(grep -rn 'claude/usr/' "${TOOLS_DIR}/" \
        --include='*' \
        | grep -v 'upstream-port:.*legacy path' \
        | grep -v 'upstream-port:.*claude/usr/\*/' \
        || true)

    if [[ -n "$stale" ]]; then
        echo "ERROR: Stale claude/usr/ references found in tools (usr/ is at project root):"
        echo "$stale"
        return 1
    fi
}
