#!/usr/bin/env bats
#
# Regression tests for cross-platform bugs found while running the suite on
# Linux as a user other than the maintainer.
#
# What Problem: Four defects that are not Linux-specific but never showed on
# the maintainer's macOS account:
#   - dependencies-check / dependencies-install abort silently under `set -e`
#     on their first `((count++))` (the expression returns 1 when count is 0)
#   - agent-create --description used BSD-only `sed -i ''`
#   - `agency init` did not ship dependencies.yaml, so `agency deps` failed in
#     every fresh install
#   - principal lookup: `agency init` writes the username key quoted, which
#     _pr_yaml_get could not match; the "default: unknown" fallback then came
#     back as "unknown " (trailing space), slipping past the != "unknown" guard
#     and producing paths like "usr/unknown /captain/"; and `principal` printed
#     a Python dict for nested entries
#
# How & Why: One test per behaviour, no network, no sudo, platform-neutral.
#
# Written: 2026-11-24

load 'test_helper'

LIB="${REPO_ROOT}/agency/tools/lib"

@test "portability: no unguarded BSD-only 'sed -i \"\"' in framework tools" {
    # Every remaining occurrence must sit inside a Darwin branch or be the
    # fallback half of a `sed -i.bak ... || sed -i '' ...` pair.
    local hits
    hits=$(grep -rnE "sed -i ''" "${REPO_ROOT}/agency/tools" | grep -vE '^\S+:[0-9]+:\s*#' || true)
    while IFS= read -r hit; do
        [ -z "$hit" ] && continue
        local file line
        file="${hit%%:*}"; line="${hit#*:}"; line="${line%%:*}"
        run bash -c "sed -n '$((line > 4 ? line - 4 : 1)),${line}p' '$file' | grep -qE 'Darwin|sed -i\.bak'"
        if [ "$status" -ne 0 ]; then
            echo "unguarded: $hit"
            return 1
        fi
    done <<< "$hits"
}

@test "portability: no ((var++)) statements in set -e dependency tools" {
    # ((x++)) returns 1 when x was 0, which aborts a `set -e` script.
    run grep -nE '^\s*\(\(\w+(\+\+|--)\)\)' \
        "${REPO_ROOT}/agency/tools/dependencies-check" \
        "${REPO_ROOT}/agency/tools/dependencies-install"
    assert_failure
}

@test "dependencies-check: runs to completion and prints a verdict" {
    command -v yq >/dev/null 2>&1 || skip "yq not installed"
    run "${REPO_ROOT}/agency/tools/dependencies-check"
    [[ "$output" == *"dependencies installed"* || "$output" == *"dependencies missing"* ]]
}

@test "agent-create: --description is substituted with GNU or BSD sed" {
    local work="$BATS_TEST_TMPDIR/agent.md"
    printf 'role: [Description of this agent'"'"'s role]\n' > "$work"
    # The exact command form agent-create uses.
    sed "s/\[Description of this agent's role\]/does things/" "$work" > "$work.tmp" && mv "$work.tmp" "$work"
    run cat "$work"
    [ "$output" = "role: does things" ]
    run grep -c "agent.md.tmp" "${REPO_ROOT}/agency/tools/agent-create"
    [ "$output" -ge 1 ]
}


@test "principal: default entry with inline comment resolves without trailing space" {
    local yaml="$BATS_TEST_TMPDIR/agency.yaml"
    cat > "$yaml" <<'EOF'
principals:
  jdm:
    name: jordan
  default:
    name: unknown  # Fallback if username not found
EOF
    run bash -c "source '$LIB/_path-resolve'; printf '[%s]' \"\$(_pr_yaml_get principals default '$yaml')\""
    assert_success
    [ "$output" = "[unknown]" ]
}

@test "principal: flat entry with trailing comment and padding is trimmed" {
    local yaml="$BATS_TEST_TMPDIR/agency.yaml"
    printf 'principals:\n  lars:   lars    # me\n' > "$yaml"
    run bash -c "source '$LIB/_path-resolve'; printf '[%s]' \"\$(_pr_yaml_get principals lars '$yaml')\""
    assert_success
    [ "$output" = "[lars]" ]
}

@test "principal: tool prints a name, never a Python dict" {
    run env -u PRINCIPAL USER="no-such-user-$$" "${REPO_ROOT}/agency/tools/principal"
    assert_success
    [[ "$output" != *"{"* ]]
    [[ "$output" != *" " ]]
}

@test "principal: quoted key as written by agency init is matched" {
    local yaml="$BATS_TEST_TMPDIR/agency.yaml"
    cat > "$yaml" <<'YAML'
principals:
  "lars":
    name: "lars"
  default:
    name: unknown
YAML
    run bash -c "source '$LIB/_path-resolve'; printf '[%s]' \"\$(_pr_yaml_get principals lars '$yaml')\""
    assert_success
    [ "$output" = "[lars]" ]
}

@test "agency init: ships the dependency manifests agency deps needs" {
    run grep -c 'dependencies.yaml agency-dependencies.yaml' "${REPO_ROOT}/agency/tools/lib/_agency-init"
    [ "$output" -ge 1 ]
}
