#!/usr/bin/env bats
#
# Tests for principal management tools:
#   - principal
#   - principal-create
#   - (setup-agency removed — see notes inline at lines 110, 187, 228)
#   - (principal-add tool removed — retired D42-R5)
#
# Tests CLI argument parsing, validation, flag handling, and security.
#

load 'test_helper'

# ─────────────────────────────────────────────────────────────────────────────
# principal - Version and Help
# ─────────────────────────────────────────────────────────────────────────────

@test "principal: --version shows version" {
    run_tool principal --version
    assert_success
    assert_output_contains "principal"
}

@test "principal: -v shows version" {
    run_tool principal -v
    assert_success
    assert_output_contains "principal"
}

@test "principal: --help shows usage" {
    run_tool principal --help
    assert_success
    assert_output_contains "Usage:"
    assert_output_contains "principal"
}

@test "principal: -h shows usage" {
    run_tool principal -h
    assert_success
    assert_output_contains "Usage:"
}

# ─────────────────────────────────────────────────────────────────────────────
# principal - Flag Recognition
# ─────────────────────────────────────────────────────────────────────────────

@test "principal: --verbose flag is recognized" {
    run_tool principal --verbose
    # Should succeed (returns principal name or 'unknown')
    [[ ! "$output" =~ "unknown option" ]] && [[ ! "$output" =~ "invalid flag" ]]
}

@test "principal: returns a value" {
    run_tool principal
    assert_success
    # Should return something (even if 'unknown')
    [[ -n "$output" ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# principal-create - Version and Help
# ─────────────────────────────────────────────────────────────────────────────

@test "principal-create: --version shows version" {
    run_tool principal-create --version
    assert_success
    assert_output_contains "principal-create"
}

@test "principal-create: -v shows version" {
    run_tool principal-create -v
    assert_success
    assert_output_contains "principal-create"
}

@test "principal-create: no args shows usage" {
    run_tool principal-create
    assert_failure
    assert_output_contains "Usage:"
}

# ─────────────────────────────────────────────────────────────────────────────
# principal-create - Argument Validation
# ─────────────────────────────────────────────────────────────────────────────

@test "principal-create: requires principal name" {
    run_tool principal-create
    assert_failure
    assert_output_contains "Usage:"
}

@test "principal-create: existing principal shows error" {
    # 'jordan' exists in the test environment
    run_tool principal-create jordan
    assert_failure
    assert_output_contains "already exists"
}

# ─────────────────────────────────────────────────────────────────────────────
# principal-create - Flag Recognition
# ─────────────────────────────────────────────────────────────────────────────

@test "principal-create: --verbose flag is recognized" {
    run_tool principal-create testprincipal --verbose || true
    [[ ! "$output" =~ "unknown option" ]] && [[ ! "$output" =~ "invalid flag" ]]
    # Clean up if created
    rm -rf "usr/testprincipal" "claude/principals/testprincipal" 2>/dev/null || true
}

# NOTE: setup-agency tests removed 2026-04-07 (devex maintenance pass).
# The setup-agency tool was deleted/renamed; the agency-init flow replaces it.

# ─────────────────────────────────────────────────────────────────────────────
# Security - Input Validation (principal-create)
# ─────────────────────────────────────────────────────────────────────────────

@test "principal-create: handles special characters in name" {
    run_tool principal-create 'test$principal' || true
    # Should not crash on special characters
    [[ ! "$output" =~ "syntax error" ]]
}

@test "principal-create: handles path traversal in name" {
    run_tool principal-create '../../../etc/passwd' || true
    # Should fail safely, not create files outside expected directory
    [[ ! -f "etc/passwd" ]]
    [[ ! -d "../../../etc/passwd" ]]
}

@test "principal-create: handles command injection in name" {
    run_tool principal-create 'test; rm -rf /' || true
    # Should not execute injection
    [[ ! "$output" =~ "syntax error" ]]
}

@test "principal-create: handles backtick injection" {
    run_tool principal-create '`whoami`' || true
    # Should not execute backticks
    [[ ! "$output" =~ "syntax error" ]]
}

# NOTE: setup-agency security tests removed 2026-04-07 — tool deleted,
# security coverage now lives in tests/tools/agency-init.bats.

# ─────────────────────────────────────────────────────────────────────────────
# Log Service Integration
# ─────────────────────────────────────────────────────────────────────────────

@test "principal: sources log helper" {
    # Check that the tool sources _log-helper
    grep -q "_log-helper" "${TOOLS_DIR}/principal"
}

@test "principal-create: sources log helper" {
    grep -q "_log-helper" "${TOOLS_DIR}/principal-create"
}

@test "principal: calls log_start" {
    grep -q "log_start" "${TOOLS_DIR}/principal"
}

@test "principal-create: calls log_start" {
    grep -q "log_start" "${TOOLS_DIR}/principal-create"
}

@test "principal: calls log_end" {
    grep -q "log_end" "${TOOLS_DIR}/principal"
}

@test "principal-create: calls log_end" {
    grep -q "log_end" "${TOOLS_DIR}/principal-create"
}

# ─────────────────────────────────────────────────────────────────────────────
# Functional Tests - principal
# ─────────────────────────────────────────────────────────────────────────────

@test "principal: PRINCIPAL env var takes precedence" {
    PRINCIPAL="envtest" run_tool principal
    assert_success
    assert_output_contains "envtest"
}

# ─────────────────────────────────────────────────────────────────────────────
# Functional Tests - principal-create
# ─────────────────────────────────────────────────────────────────────────────

@test "principal-create: -h shows usage" {
    run_tool principal-create -h
    assert_success
    assert_output_contains "Usage:"
}

@test "principal-create: --help shows usage" {
    run_tool principal-create --help
    assert_success
    assert_output_contains "Usage:"
}

@test "principal-create: rejects name starting with number" {
    run_tool principal-create "123invalid"
    assert_failure
    assert_output_contains "Invalid principal name"
}

@test "principal-create: converts uppercase to lowercase" {
    local test_name="UPPERCASETEST"
    run_tool principal-create "$test_name" || true
    # Check if directory was created with lowercase name (v2 path)
    if [[ -d "usr/uppercasetest" ]]; then
        # Verify NOT created at legacy path
        [[ ! -d "claude/principals/uppercasetest" ]]
        # Clean up
        rm -rf "usr/uppercasetest"
        return 0
    fi
    # If already exists or validation failed, that's also fine
    [[ "$output" =~ "already exists" ]] || [[ "$output" =~ "Invalid" ]]
}

@test "principal-create: creates directory structure" {
    local test_name="batsstructtest"
    # Skip if already exists (v2 path)
    if [[ -d "usr/$test_name" ]]; then
        skip "Test principal already exists"
    fi

    run_tool principal-create "$test_name"

    # Verify v2 directory structure created. Assert on README.md, which BOTH
    # code paths produce: the v2-template path copies agency/templates/principal-v2/*
    # (top-level template files + README.md, no scripts/ subdir), and the fallback
    # path writes its own README.md. The old `scripts/ || claude/` assertion only
    # matched the fallback path, so it stale-failed whenever the template exists. (#42)
    [[ -d "usr/$test_name" ]]
    [[ -f "usr/$test_name/README.md" ]]
    # Verify NOT created at legacy path
    [[ ! -d "claude/principals/$test_name" ]]

    # Clean up
    rm -rf "usr/$test_name"
}

@test "principal-create: creates README.md" {
    local test_name="batsreadmetest"
    # Skip if already exists (v2 path)
    if [[ -d "usr/$test_name" ]]; then
        skip "Test principal already exists"
    fi

    run_tool principal-create "$test_name"

    # Verify README.md created in v2 location
    [[ -f "usr/$test_name/README.md" ]]

    # Clean up
    rm -rf "usr/$test_name"
}

# ─────────────────────────────────────────────────────────────────────────────
# Security Tests - Additional Input Validation
# ─────────────────────────────────────────────────────────────────────────────

@test "principal-create: rejects name with newline" {
    run_tool principal-create $'test\nmalicious' || true
    # Should fail or handle safely
    [[ ! -d $'claude/principals/test\nmalicious' ]]
}

@test "principal-create: rejects name with null byte" {
    run_tool principal-create $'test\x00malicious' || true
    # Should handle safely
    [[ ! "$output" =~ "syntax error" ]]
}

@test "principal-create: rejects unicode characters" {
    run_tool principal-create "testé" || true
    # Should fail validation or handle safely
    [[ "$status" -ne 0 ]] || [[ "$output" =~ "Invalid" ]]
}

@test "principal-create: handles sed metacharacters safely" {
    # sed metacharacters like & and / could cause issues
    run_tool principal-create "test&whoami" || true
    # Should reject due to & not being alphanumeric
    [[ "$output" =~ "Invalid principal name" ]] || [[ "$status" -ne 0 ]]
    [[ ! -d "claude/principals/test&whoami" ]]
}
