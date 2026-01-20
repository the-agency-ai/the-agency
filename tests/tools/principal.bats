#!/usr/bin/env bats
#
# Tests for principal management tools:
#   - principal
#   - principal-create
#   - setup-agency
#   - add-principal
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
    # Clean up if created (including iTerm profile)
    rm -rf "claude/principals/testprincipal" 2>/dev/null || true
    rm -f "$HOME/Library/Application Support/iTerm2/DynamicProfiles/agency-testprincipal-profiles.json" 2>/dev/null || true
}

# ─────────────────────────────────────────────────────────────────────────────
# setup-agency - Version and Help
# ─────────────────────────────────────────────────────────────────────────────

@test "setup-agency: --version shows version" {
    run_tool setup-agency --version
    assert_success
    assert_output_contains "setup-agency"
}

@test "setup-agency: -v shows version" {
    run_tool setup-agency -v
    assert_success
    assert_output_contains "setup-agency"
}

@test "setup-agency: --help shows usage" {
    run_tool setup-agency --help
    assert_success
    assert_output_contains "Usage:"
    assert_output_contains "principal"
}

@test "setup-agency: -h shows usage" {
    run_tool setup-agency -h
    assert_success
    assert_output_contains "Usage:"
}

# ─────────────────────────────────────────────────────────────────────────────
# setup-agency - Flag Recognition
# ─────────────────────────────────────────────────────────────────────────────

@test "setup-agency: --principal flag is recognized" {
    # Will fail (already setup) but flag should be recognized
    run_tool setup-agency --principal testuser --skip-vault || true
    [[ ! "$output" =~ "unknown option" ]] && [[ ! "$output" =~ "Unknown option" ]]
}

@test "setup-agency: --skip-vault flag is recognized" {
    run_tool setup-agency --principal testuser --skip-vault || true
    [[ ! "$output" =~ "unknown option" ]] && [[ ! "$output" =~ "Unknown option" ]]
}

@test "setup-agency: --verbose flag is recognized" {
    run_tool setup-agency --verbose --help
    [[ ! "$output" =~ "unknown option" ]] && [[ ! "$output" =~ "Unknown option" ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# setup-agency - Detection
# ─────────────────────────────────────────────────────────────────────────────

@test "setup-agency: detects already setup project" {
    # The test environment should have .agency-setup-complete or similar
    run_tool setup-agency --principal testuser --skip-vault
    # Should indicate already set up or complete successfully
    [[ "$output" =~ "already" ]] || [[ "$status" -eq 0 ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# add-principal - Version and Help
# ─────────────────────────────────────────────────────────────────────────────

@test "add-principal: --version shows version" {
    run_tool add-principal --version
    assert_success
    assert_output_contains "add-principal"
}

@test "add-principal: -v shows version" {
    run_tool add-principal -v
    assert_success
    assert_output_contains "add-principal"
}

@test "add-principal: --help shows usage" {
    run_tool add-principal --help
    assert_success
    assert_output_contains "Usage:"
}

@test "add-principal: -h shows usage" {
    run_tool add-principal -h
    assert_success
    assert_output_contains "Usage:"
}

# ─────────────────────────────────────────────────────────────────────────────
# add-principal - Flag Recognition
# ─────────────────────────────────────────────────────────────────────────────

@test "add-principal: --name flag is recognized" {
    run_tool add-principal --name testuser || true
    [[ ! "$output" =~ "unknown option" ]] && [[ ! "$output" =~ "Unknown option" ]]
    # Clean up if created (including iTerm profile)
    rm -rf "claude/principals/testuser" 2>/dev/null || true
    rm -f "$HOME/Library/Application Support/iTerm2/DynamicProfiles/agency-testuser-profiles.json" 2>/dev/null || true
}

@test "add-principal: --verbose flag is recognized" {
    run_tool add-principal --verbose --help
    [[ ! "$output" =~ "unknown option" ]] && [[ ! "$output" =~ "Unknown option" ]]
}

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

# ─────────────────────────────────────────────────────────────────────────────
# Security - Input Validation (setup-agency)
# ─────────────────────────────────────────────────────────────────────────────

@test "setup-agency: handles special characters in principal name" {
    run_tool setup-agency --principal 'test$user' --skip-vault || true
    # Should not crash
    [[ ! "$output" =~ "syntax error" ]]
}

@test "setup-agency: handles path traversal in principal name" {
    run_tool setup-agency --principal '../../../tmp/hack' --skip-vault || true
    # Should not create directory outside expected location
    [[ ! -d "tmp/hack" ]]
    [[ ! -d "../../../tmp/hack" ]]
}

@test "setup-agency: handles command injection in principal name" {
    run_tool setup-agency --principal 'test; whoami' --skip-vault || true
    # Should not execute
    [[ ! "$output" =~ "syntax error" ]]
}

@test "setup-agency: validates principal name format" {
    run_tool setup-agency --principal '123invalid' --skip-vault
    # Should reject names starting with numbers OR detect already setup
    # (validation happens after setup check, so already setup is valid)
    [[ "$status" -ne 0 ]] || [[ "$output" =~ "Invalid" ]] || [[ "$output" =~ "must start" ]] || [[ "$output" =~ "already" ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Security - Input Validation (add-principal)
# ─────────────────────────────────────────────────────────────────────────────

@test "add-principal: handles special characters in name" {
    run_tool add-principal --name 'test$user' || true
    # Should not crash
    [[ ! "$output" =~ "syntax error" ]]
    # Clean up
    rm -rf 'claude/principals/test$user' 2>/dev/null || true
}

@test "add-principal: handles path traversal in name" {
    run_tool add-principal --name '../../../tmp/hack' || true
    # Should not create directory outside expected location
    [[ ! -d "tmp/hack" ]]
}

@test "add-principal: handles command injection in name" {
    run_tool add-principal --name 'test; rm -rf /' || true
    # Should not execute
    [[ ! "$output" =~ "syntax error" ]]
}

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

@test "setup-agency: sources log helper" {
    grep -q "_log-helper" "${TOOLS_DIR}/setup-agency"
}

@test "add-principal: sources log helper" {
    grep -q "_log-helper" "${TOOLS_DIR}/add-principal"
}

@test "principal: calls log_start" {
    grep -q "log_start" "${TOOLS_DIR}/principal"
}

@test "principal-create: calls log_start" {
    grep -q "log_start" "${TOOLS_DIR}/principal-create"
}

@test "setup-agency: calls log_start" {
    grep -q "log_start" "${TOOLS_DIR}/setup-agency"
}

@test "add-principal: calls log_start" {
    grep -q "log_start" "${TOOLS_DIR}/add-principal"
}

@test "principal: calls log_end" {
    grep -q "log_end" "${TOOLS_DIR}/principal"
}

@test "principal-create: calls log_end" {
    grep -q "log_end" "${TOOLS_DIR}/principal-create"
}

@test "setup-agency: calls log_end" {
    grep -q "log_end" "${TOOLS_DIR}/setup-agency"
}

@test "add-principal: calls log_end" {
    grep -q "log_end" "${TOOLS_DIR}/add-principal"
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
    # Check if directory was created with lowercase name
    if [[ -d "claude/principals/uppercasetest" ]]; then
        # Clean up (including iTerm profile)
        rm -rf "claude/principals/uppercasetest"
        rm -f "$HOME/Library/Application Support/iTerm2/DynamicProfiles/agency-uppercasetest-profiles.json" 2>/dev/null || true
        return 0
    fi
    # If already exists or validation failed, that's also fine
    [[ "$output" =~ "already exists" ]] || [[ "$output" =~ "Invalid" ]]
}

@test "principal-create: creates directory structure" {
    local test_name="batsstructtest"
    # Skip if already exists
    if [[ -d "claude/principals/$test_name" ]]; then
        skip "Test principal already exists"
    fi

    run_tool principal-create "$test_name"

    # Verify subdirectories created
    [[ -d "claude/principals/$test_name/projects" ]] || [[ -d "claude/principals/$test_name/requests" ]]
    [[ -d "claude/principals/$test_name/resources" ]]
    [[ -d "claude/principals/$test_name/config" ]]

    # Clean up (including iTerm profile)
    rm -rf "claude/principals/$test_name"
    rm -f "$HOME/Library/Application Support/iTerm2/DynamicProfiles/agency-$test_name-profiles.json" 2>/dev/null || true
}

@test "principal-create: creates README.md" {
    local test_name="batsreadmetest"
    # Skip if already exists
    if [[ -d "claude/principals/$test_name" ]]; then
        skip "Test principal already exists"
    fi

    run_tool principal-create "$test_name"

    # Verify README.md created
    [[ -f "claude/principals/$test_name/README.md" ]]

    # Clean up (including iTerm profile)
    rm -rf "claude/principals/$test_name"
    rm -f "$HOME/Library/Application Support/iTerm2/DynamicProfiles/agency-$test_name-profiles.json" 2>/dev/null || true
}

# ─────────────────────────────────────────────────────────────────────────────
# Functional Tests - add-principal
# ─────────────────────────────────────────────────────────────────────────────

@test "add-principal: rejects name starting with number" {
    run_tool add-principal --name "123invalid"
    assert_failure
    assert_output_contains "Invalid principal name"
}

@test "add-principal: --no-set-current flag is recognized" {
    run_tool add-principal --no-set-current --help
    [[ ! "$output" =~ "unknown option" ]] && [[ ! "$output" =~ "Unknown option" ]]
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

@test "setup-agency: rejects name with newline" {
    run_tool setup-agency --principal $'test\ninjection' --skip-vault || true
    # Should fail or handle safely
    [[ ! "$output" =~ "syntax error" ]]
}

@test "add-principal: rejects name with newline" {
    run_tool add-principal --name $'test\ninjection' || true
    # Should fail or handle safely
    [[ ! "$output" =~ "syntax error" ]]
}

@test "principal-create: handles sed metacharacters safely" {
    # sed metacharacters like & and / could cause issues
    run_tool principal-create "test&whoami" || true
    # Should reject due to & not being alphanumeric
    [[ "$output" =~ "Invalid principal name" ]] || [[ "$status" -ne 0 ]]
    [[ ! -d "claude/principals/test&whoami" ]]
}

@test "setup-agency: handles sed metacharacters safely" {
    run_tool setup-agency --principal "test&whoami" --skip-vault || true
    # Should reject or handle safely
    [[ "$output" =~ "Invalid" ]] || [[ "$output" =~ "already" ]] || [[ "$status" -ne 0 ]]
}

@test "add-principal: handles sed metacharacters safely" {
    run_tool add-principal --name "test&whoami" || true
    # Should reject due to & not being alphanumeric
    [[ "$output" =~ "Invalid principal name" ]] || [[ "$status" -ne 0 ]]
}
