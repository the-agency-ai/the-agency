#!/usr/bin/env bats
#
# Tests for tools/lib/_address-parse
#
# Tests address parsing, resolution, formatting, validation,
# repo/org URL detection, and principal resolution.
#

load 'test_helper'

LIB_DIR="${REPO_ROOT}/claude/tools/lib"

# ─────────────────────────────────────────────────────────────────────────────
# Sourcing
# ─────────────────────────────────────────────────────────────────────────────

@test "_address-parse: sources without error" {
    run bash -c "source '${LIB_DIR}/_address-parse'"
    assert_success
}

@test "_address-parse: functions are available after sourcing" {
    run bash -c "
        source '${LIB_DIR}/_address-parse'
        type address_parse | head -1
        type address_resolve | head -1
        type address_format | head -1
        type address_validate_component | head -1
    "
    assert_success
}

# ─────────────────────────────────────────────────────────────────────────────
# address_parse — all 4 input forms
# ─────────────────────────────────────────────────────────────────────────────

@test "address_parse: bare (1 segment)" {
    run bash -c "
        source '${LIB_DIR}/_address-parse'
        address_parse 'captain'
        echo \"org=\$ADDR_ORG repo=\$ADDR_REPO principal=\$ADDR_PRINCIPAL agent=\$ADDR_AGENT\"
    "
    assert_success
    assert_output_contains "org= repo= principal= agent=captain"
}

@test "address_parse: principal/agent (2 segments)" {
    run bash -c "
        source '${LIB_DIR}/_address-parse'
        address_parse 'jordan/captain'
        echo \"org=\$ADDR_ORG repo=\$ADDR_REPO principal=\$ADDR_PRINCIPAL agent=\$ADDR_AGENT\"
    "
    assert_success
    assert_output_contains "org= repo= principal=jordan agent=captain"
}

@test "address_parse: repo/principal/agent (3 segments)" {
    run bash -c "
        source '${LIB_DIR}/_address-parse'
        address_parse 'the-agency/jordan/captain'
        echo \"org=\$ADDR_ORG repo=\$ADDR_REPO principal=\$ADDR_PRINCIPAL agent=\$ADDR_AGENT\"
    "
    assert_success
    assert_output_contains "org= repo=the-agency principal=jordan agent=captain"
}

@test "address_parse: org/repo/principal/agent (4 segments)" {
    run bash -c "
        source '${LIB_DIR}/_address-parse'
        address_parse 'OrdinaryFolk/monofolk/jordan/captain'
        echo \"org=\$ADDR_ORG repo=\$ADDR_REPO principal=\$ADDR_PRINCIPAL agent=\$ADDR_AGENT\"
    "
    assert_success
    assert_output_contains "org=OrdinaryFolk repo=monofolk principal=jordan agent=captain"
}

# ─────────────────────────────────────────────────────────────────────────────
# address_parse — rejection cases
# ─────────────────────────────────────────────────────────────────────────────

@test "address_parse: rejects empty" {
    run bash -c "source '${LIB_DIR}/_address-parse'; address_parse ''"
    assert_failure
    assert_output_contains "empty"
}

@test "address_parse: rejects path traversal" {
    run bash -c "source '${LIB_DIR}/_address-parse'; address_parse '../etc/passwd'"
    assert_failure
    assert_output_contains "traversal"
}

@test "address_parse: rejects leading slash" {
    run bash -c "source '${LIB_DIR}/_address-parse'; address_parse '/absolute'"
    assert_failure
    assert_output_contains "start or end"
}

@test "address_parse: rejects trailing slash" {
    run bash -c "source '${LIB_DIR}/_address-parse'; address_parse 'trailing/'"
    assert_failure
    assert_output_contains "start or end"
}

@test "address_parse: rejects double slash" {
    run bash -c "source '${LIB_DIR}/_address-parse'; address_parse 'a//b'"
    assert_failure
    assert_output_contains "empty segment"
}

@test "address_parse: rejects too many segments (5+)" {
    run bash -c "source '${LIB_DIR}/_address-parse'; address_parse 'a/b/c/d/e'"
    assert_failure
    assert_output_contains "too many segments"
}

# ─────────────────────────────────────────────────────────────────────────────
# address_validate_component
# ─────────────────────────────────────────────────────────────────────────────

@test "validate_component: valid principal" {
    run bash -c "source '${LIB_DIR}/_address-parse'; address_validate_component 'jordan' --level principal"
    assert_success
}

@test "validate_component: valid agent with digits and hyphens" {
    run bash -c "source '${LIB_DIR}/_address-parse'; address_validate_component '3d-renderer' --level agent"
    assert_success
}

@test "validate_component: valid agent with underscore" {
    run bash -c "source '${LIB_DIR}/_address-parse'; address_validate_component 'my_agent' --level agent"
    assert_success
}

@test "validate_component: org preserves case" {
    run bash -c "source '${LIB_DIR}/_address-parse'; address_validate_component 'OrdinaryFolk' --level org"
    assert_success
}

@test "validate_component: org rejects underscore" {
    run bash -c "source '${LIB_DIR}/_address-parse'; address_validate_component 'my_org' --level org"
    assert_failure
}

@test "validate_component: rejects uppercase for principal" {
    run bash -c "source '${LIB_DIR}/_address-parse'; address_validate_component 'UPPER' --level principal"
    assert_failure
    assert_output_contains "lowercase"
}

@test "validate_component: rejects reserved name 'system'" {
    run bash -c "source '${LIB_DIR}/_address-parse'; address_validate_component 'system' --level principal"
    assert_failure
    assert_output_contains "reserved"
}

@test "validate_component: rejects reserved name 'default'" {
    run bash -c "source '${LIB_DIR}/_address-parse'; address_validate_component 'default' --level agent"
    assert_failure
    assert_output_contains "reserved"
}

@test "validate_component: rejects reserved name 'all'" {
    run bash -c "source '${LIB_DIR}/_address-parse'; address_validate_component 'all' --level principal"
    assert_failure
    assert_output_contains "reserved"
}

@test "validate_component: reserved names NOT checked for repo level" {
    run bash -c "source '${LIB_DIR}/_address-parse'; address_validate_component 'system' --level repo"
    assert_success
}

@test "validate_component: rejects empty" {
    run bash -c "source '${LIB_DIR}/_address-parse'; address_validate_component '' --level agent"
    assert_failure
    assert_output_contains "empty"
}

@test "validate_component: rejects path traversal in component" {
    run bash -c "source '${LIB_DIR}/_address-parse'; address_validate_component 'a/b' --level principal"
    assert_failure
    assert_output_contains "traversal"
}

@test "validate_component: rejects name exceeding 32 chars" {
    run bash -c "source '${LIB_DIR}/_address-parse'; address_validate_component 'abcdefghijklmnopqrstuvwxyz1234567' --level principal"
    assert_failure
    assert_output_contains "32 characters"
}

@test "validate_component: accepts name at exactly 32 chars" {
    run bash -c "source '${LIB_DIR}/_address-parse'; address_validate_component 'abcdefghijklmnopqrstuvwxyz123456' --level principal"
    assert_success
}

# ─────────────────────────────────────────────────────────────────────────────
# URL parsing — repo detection
# ─────────────────────────────────────────────────────────────────────────────

@test "URL parse: GitHub SSH" {
    run bash -c "source '${LIB_DIR}/_address-parse'; _address_parse_repo_url 'git@github.com:the-agency-ai/the-agency.git'"
    assert_success
    [[ "$output" == "the-agency" ]]
}

@test "URL parse: GitHub HTTPS with .git" {
    run bash -c "source '${LIB_DIR}/_address-parse'; _address_parse_repo_url 'https://github.com/the-agency-ai/the-agency.git'"
    assert_success
    [[ "$output" == "the-agency" ]]
}

@test "URL parse: GitHub HTTPS without .git" {
    run bash -c "source '${LIB_DIR}/_address-parse'; _address_parse_repo_url 'https://github.com/the-agency-ai/the-agency'"
    assert_success
    [[ "$output" == "the-agency" ]]
}

@test "URL parse: GitLab nested groups (leaf name)" {
    run bash -c "source '${LIB_DIR}/_address-parse'; _address_parse_repo_url 'git@gitlab.com:org/subgroup/deep/repo.git'"
    assert_success
    [[ "$output" == "repo" ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# URL parsing — org detection
# ─────────────────────────────────────────────────────────────────────────────

@test "URL org: GitHub SSH" {
    run bash -c "source '${LIB_DIR}/_address-parse'; _address_parse_org_url 'git@github.com:OrdinaryFolk/monofolk.git'"
    assert_success
    [[ "$output" == "OrdinaryFolk" ]]
}

@test "URL org: GitHub HTTPS" {
    run bash -c "source '${LIB_DIR}/_address-parse'; _address_parse_org_url 'https://github.com/the-agency-ai/the-agency'"
    assert_success
    [[ "$output" == "the-agency-ai" ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# address_resolve — with real git context
# ─────────────────────────────────────────────────────────────────────────────

@test "address_resolve: bare name resolves repo and principal" {
    run bash -c "
        source '${LIB_DIR}/_address-parse'
        address_resolve 'captain'
        echo \"\$ADDR_REPO/\$ADDR_PRINCIPAL/\$ADDR_AGENT\"
    "
    assert_success
    # Should have repo and principal filled in from git/yaml context
    assert_output_contains "/captain"
    # Should not be empty segments
    [[ ! "$output" =~ ^/ ]]
}

@test "address_resolve: 2-segment resolves repo" {
    run bash -c "
        source '${LIB_DIR}/_address-parse'
        address_resolve 'jordan/captain'
        echo \"\$ADDR_REPO/\$ADDR_PRINCIPAL/\$ADDR_AGENT\"
    "
    assert_success
    assert_output_contains "jordan/captain"
    # Repo should be filled in
    [[ ! "$output" =~ ^/ ]]
}

@test "address_resolve: 3-segment passes through" {
    run bash -c "
        source '${LIB_DIR}/_address-parse'
        address_resolve 'the-agency/jordan/captain'
        echo \"\$ADDR_REPO/\$ADDR_PRINCIPAL/\$ADDR_AGENT\"
    "
    assert_success
    [[ "$output" == "the-agency/jordan/captain" ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# address_format
# ─────────────────────────────────────────────────────────────────────────────

@test "address_format: produces fully qualified string" {
    run bash -c "source '${LIB_DIR}/_address-parse'; address_format 'monofolk' 'peter' 'devex'"
    assert_success
    [[ "$output" == "monofolk/peter/devex" ]]
}

@test "address_format: uses ADDR_ globals when args omitted" {
    run bash -c "
        source '${LIB_DIR}/_address-parse'
        address_parse 'the-agency/jordan/captain'
        address_format
    "
    assert_success
    [[ "$output" == "the-agency/jordan/captain" ]]
}

@test "address_format: fails when component missing" {
    run bash -c "source '${LIB_DIR}/_address-parse'; address_format '' 'jordan' 'captain'"
    assert_failure
}

# ─────────────────────────────────────────────────────────────────────────────
# Principal detection — flat and nested agency.yaml
# ─────────────────────────────────────────────────────────────────────────────

@test "principal detection: flat format (jdm: jordan)" {
    run env USER=jdm bash -c "
        AGENCY_PRINCIPAL=
        source '${LIB_DIR}/_address-parse'
        _address_detect_principal
    "
    assert_success
    [[ "$output" == "jordan" ]]
}

@test "principal detection: AGENCY_PRINCIPAL env var is deprecated and ignored" {
    # AGENCY_PRINCIPAL is intentionally ignored per the contract in
    # _address_detect_principal lines 421-424. It leaks from test suites,
    # shell profiles, and old add-principal runs. Detection always resolves
    # from agency.yaml via $USER.
    run bash -c "
        AGENCY_PRINCIPAL=override
        USER=jdm
        source '${LIB_DIR}/_address-parse'
        _address_detect_principal
    "
    assert_success
    # Should NOT output "override" — that env var is deprecated
    [[ "$output" != "override" ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Repo detection — real context
# ─────────────────────────────────────────────────────────────────────────────

@test "repo detection: detects from git remote" {
    run bash -c "source '${LIB_DIR}/_address-parse'; _address_detect_repo"
    assert_success
    [[ -n "$output" ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# YAML with colons in display_name (R1 fragile gate)
# ─────────────────────────────────────────────────────────────────────────────

@test "principal detection: YAML with colon in display_name does not break parsing" {
    # Create a test agency.yaml with colon-containing display_name
    local yaml="${BATS_TEST_TMPDIR}/agency.yaml"
    mkdir -p "${BATS_TEST_TMPDIR}/claude/config"
    cp "$yaml" "${BATS_TEST_TMPDIR}/claude/config/agency.yaml" 2>/dev/null || true
    cat > "${BATS_TEST_TMPDIR}/claude/config/agency.yaml" << 'YAML'
principals:
  testuser:
    name: testprincipal
    display_name: "Dr. Test: The Tester"
  default: unknown
YAML

    run env USER=testuser AGENCY_PRINCIPAL= CLAUDE_PROJECT_DIR="${BATS_TEST_TMPDIR}" SCRIPT_DIR="${BATS_TEST_TMPDIR}" bash -c "
        cd '${BATS_TEST_TMPDIR}'
        source '${LIB_DIR}/_path-resolve'
        _pr_yaml_get 'principals' 'testuser' '${BATS_TEST_TMPDIR}/claude/config/agency.yaml'
    "
    assert_success
    [[ "$output" == "testprincipal" ]]
}
