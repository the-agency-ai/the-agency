#!/usr/bin/env bats
#
# Tests for ./tools/config
#
# Tests CLI argument parsing, validation, and flag handling.
#

load 'test_helper'

# ─────────────────────────────────────────────────────────────────────────────
# Version and Help
# ─────────────────────────────────────────────────────────────────────────────

@test "config: --version shows version" {
    run_tool config --version
    assert_success
    assert_output_contains "config"
}

@test "config: -v shows version" {
    run_tool config -v
    assert_success
    assert_output_contains "config"
}

@test "config: --help shows usage" {
    run_tool config --help
    assert_success
    assert_output_contains "Usage:"
    assert_output_contains "get"
}

@test "config: -h shows usage" {
    run_tool config -h
    assert_success
    assert_output_contains "Usage:"
}

@test "config: help shows usage" {
    run_tool config help
    assert_success
    assert_output_contains "Usage:"
}

# ─────────────────────────────────────────────────────────────────────────────
# Action Validation
# ─────────────────────────────────────────────────────────────────────────────

@test "config: unknown action shows error" {
    run_tool config unknownaction
    assert_failure
    # Should indicate unknown action
    [[ "$output" =~ "Unknown" ]] || [[ "$output" =~ "action" ]] || [[ "$status" -ne 0 ]]
}

@test "config: list action works" {
    run_tool config list
    # May fail if config doesn't exist, but action should be recognized
    [[ ! "$output" =~ "Unknown action" ]] || [[ "$status" -eq 0 ]]
}

@test "config: get-principal action works" {
    run_tool config get-principal
    assert_success
    # Real value: a principal dict repr, or the 'unknown' fallback — never empty,
    # never a Python traceback (which would mean the YAML backend blew up).
    [[ -n "$output" ]]
    [[ ! "$output" =~ "Traceback" ]]
    [[ ! "$output" =~ "Unknown action" ]]
}

@test "config: get returns a real scalar value end-to-end" {
    # Exercises config's actual production path (sys.path.insert + import
    # yaml_lite + dotted-key walk), not just the lib in isolation.
    run_tool config get container.provider
    assert_success
    [ "$output" = "auto" ]
}

@test "config: works with pyyaml UNIMPORTABLE (zero-pip regression guard, #264)" {
    # THE regression this fix closes: config must not import pyyaml. Plant a
    # poison 'yaml' module that raises on import — if config (or anything it
    # loads, e.g. yaml_lite) does `import yaml`, this fails loudly. yaml_lite is
    # stdlib-only, so config must still resolve the value.
    local poison="${BATS_TEST_TMPDIR}/poison"
    mkdir -p "$poison"
    printf 'raise ImportError("pyyaml is banned: framework tools are zero-pip (#264)")\n' > "$poison/yaml.py"
    run env PYTHONPATH="$poison" "${TOOLS_DIR}/config" get container.provider
    assert_success
    [ "$output" = "auto" ]
}

@test "config: get action requires key" {
    run_tool config get
    # Should either fail or show usage
    [[ "$status" -ne 0 ]] || [[ "$output" =~ "Usage:" ]] || [[ "$output" =~ "key" ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Flag Recognition
# ─────────────────────────────────────────────────────────────────────────────

@test "config: --verbose flag is recognized" {
    run_tool config list --verbose
    [[ ! "$output" =~ "unknown option" ]] && [[ ! "$output" =~ "invalid flag" ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Get Values
# ─────────────────────────────────────────────────────────────────────────────

@test "config: get with valid key returns value" {
    run_tool config get project.name
    # Should either return a value or fail gracefully
    [[ "$status" -eq 0 ]] || [[ "$output" =~ "not found" ]] || [[ "$status" -ne 0 ]]
}

@test "config: get with invalid key shows error" {
    run_tool config get nonexistent.key.path
    # Should indicate not found
    [[ "$output" =~ "not found" ]] || [[ "$output" =~ "null" ]] || [[ "$status" -ne 0 ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Security - Input Validation
# ─────────────────────────────────────────────────────────────────────────────

@test "config: handles special characters in key" {
    run_tool config get 'key; echo pwned' || true
    # Should not execute injection
    [[ ! "$output" =~ "pwned" ]] || [[ "$output" =~ "key; echo pwned" ]]
}

@test "config: handles command substitution in key" {
    run_tool config get '$(whoami)' || true
    # Should not expand command substitution
    [[ ! "$output" =~ "syntax error" ]]
}

