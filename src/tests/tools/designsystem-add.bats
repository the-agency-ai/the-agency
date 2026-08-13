#!/usr/bin/env bats
#
# Tests for ./agency/tools/designsystem-add
#
# designsystem-add scaffolds a design-system documentation structure by
# copying a `_template/` directory and substituting placeholders. It resolves
# PROJECT_ROOT from its own script location, so hermetic tests copy the tool
# into a throwaway project tree (BATS_TEST_TMPDIR/proj) that carries its own
# fixture template. Nothing here touches the live repo, the network, or ISCP.
#
# Coverage: --help / --version, arg-count validation, brand-name + version
# validation, structure creation, placeholder substitution, AGENT env var,
# idempotency (refuses-if-exists), and missing-template handling.
#

load 'test_helper'

# ─────────────────────────────────────────────────────────────────────────────
# Hermetic scaffold — copy the tool + a fixture template into a temp project
# ─────────────────────────────────────────────────────────────────────────────

setup() {
    export BATS_TEST_TMPDIR="$(mktemp -d)"
    test_isolation_setup

    PROJ="${BATS_TEST_TMPDIR}/proj"
    mkdir -p "$PROJ/agency/tools/lib"

    cp "${REPO_ROOT}/agency/tools/designsystem-add" "$PROJ/agency/tools/designsystem-add"
    chmod +x "$PROJ/agency/tools/designsystem-add"
    cp "${REPO_ROOT}/agency/tools/lib/_colors" "$PROJ/agency/tools/lib/_colors" 2>/dev/null || true

    DS_TOOL="$PROJ/agency/tools/designsystem-add"
    DS_DIR="$PROJ/agency/knowledge/design-systems"

    # Fixture template with every placeholder the tool substitutes.
    TPL="$DS_DIR/_template"
    mkdir -p "$TPL"

    cat > "$TPL/INDEX.md" <<'TEOF'
# {{BRAND_NAME}} Design System v{{VERSION}}

**Last Updated:** {{DATE}}
**Primary Application:** {{APPLICATION}}
**Font:** {{FONT_FAMILY}}

**Maintainer:** {{AGENT}}
TEOF

    cat > "$TPL/colors.md" <<'TEOF'
# Colors — {{BRAND_NAME}} v{{VERSION}}

**Maintainer:** {{AGENT}}
TEOF

    cat > "$TPL/GAPS.md" <<'TEOF'
# Gaps for {{BRAND_NAME}} v{{VERSION}}
TEOF

    # A non-.md file the loop must ignore.
    echo "ignore me" > "$TPL/notes.txt"
}

teardown() {
    test_isolation_teardown
    [[ -d "${BATS_TEST_TMPDIR}" ]] && rm -rf "${BATS_TEST_TMPDIR}"
}

# ─────────────────────────────────────────────────────────────────────────────
# Help and version
# ─────────────────────────────────────────────────────────────────────────────

@test "designsystem-add: --help shows usage" {
    run "$DS_TOOL" --help
    assert_success
    assert_output_contains "Usage:"
    assert_output_contains "brand-name"
}

@test "designsystem-add: -h shows usage" {
    run "$DS_TOOL" -h
    assert_success
    assert_output_contains "Usage:"
}

@test "designsystem-add: --version shows version string" {
    run "$DS_TOOL" --version
    assert_success
    assert_output_contains "designsystem-add"
}

@test "designsystem-add: -v shows version string" {
    run "$DS_TOOL" -v
    assert_success
    assert_output_contains "designsystem-add"
}

# ─────────────────────────────────────────────────────────────────────────────
# Argument validation
# ─────────────────────────────────────────────────────────────────────────────

@test "designsystem-add: no arguments fails with missing-args error" {
    run "$DS_TOOL"
    assert_failure
    assert_output_contains "Missing required arguments"
}

@test "designsystem-add: single argument fails (needs brand + version)" {
    run "$DS_TOOL" acme
    assert_failure
    assert_output_contains "Missing required arguments"
}

@test "designsystem-add: uppercase brand name is rejected" {
    run "$DS_TOOL" Acme 001
    assert_failure
    assert_output_contains "lowercase"
    [ ! -d "$DS_DIR/Acme-001" ]
}

@test "designsystem-add: brand name starting with a digit is rejected" {
    run "$DS_TOOL" 1acme 001
    assert_failure
    assert_output_contains "lowercase"
}

@test "designsystem-add: brand name with an underscore is rejected" {
    run "$DS_TOOL" acme_brand 001
    assert_failure
    assert_output_contains "lowercase"
}

@test "designsystem-add: hyphenated lowercase brand name is accepted" {
    run "$DS_TOOL" my-brand 002
    assert_success
    [ -d "$DS_DIR/my-brand-002" ]
}

@test "designsystem-add: non-numeric version is rejected" {
    run "$DS_TOOL" acme abc
    assert_failure
    assert_output_contains "Version must be a number"
    [ ! -d "$DS_DIR/acme-abc" ]
}

# ─────────────────────────────────────────────────────────────────────────────
# Structure creation
# ─────────────────────────────────────────────────────────────────────────────

@test "designsystem-add: creates the expected directory structure" {
    run "$DS_TOOL" acme 001
    assert_success
    [ -d "$DS_DIR/acme-001" ]
    [ -d "$DS_DIR/acme-001/source" ]
    assert_file_exists "$DS_DIR/acme-001/INDEX.md"
    assert_file_exists "$DS_DIR/acme-001/colors.md"
    assert_file_exists "$DS_DIR/acme-001/GAPS.md"
    assert_file_exists "$DS_DIR/acme-001/source/.gitkeep"
}

@test "designsystem-add: reports success and target location" {
    run "$DS_TOOL" acme 001
    assert_success
    assert_output_contains "created successfully"
    assert_output_contains "acme-001"
}

@test "designsystem-add: non-.md template files are not copied" {
    run "$DS_TOOL" acme 001
    assert_success
    [ ! -f "$DS_DIR/acme-001/notes.txt" ]
}

# ─────────────────────────────────────────────────────────────────────────────
# Placeholder substitution
# ─────────────────────────────────────────────────────────────────────────────

@test "designsystem-add: substitutes brand name and version placeholders" {
    run "$DS_TOOL" acme 007
    assert_success
    grep -qF "acme" "$DS_DIR/acme-007/INDEX.md"
    grep -qF "v007" "$DS_DIR/acme-007/INDEX.md"
    # No raw placeholders should survive.
    ! grep -qF '{{BRAND_NAME}}' "$DS_DIR/acme-007/INDEX.md"
    ! grep -qF '{{VERSION}}' "$DS_DIR/acme-007/INDEX.md"
}

@test "designsystem-add: substitutes date placeholder with today's date" {
    local today
    today="$(date +%Y-%m-%d)"
    run "$DS_TOOL" acme 001
    assert_success
    grep -qF "$today" "$DS_DIR/acme-001/INDEX.md"
    ! grep -qF '{{DATE}}' "$DS_DIR/acme-001/INDEX.md"
}

@test "designsystem-add: substitutes FONT_FAMILY and APPLICATION placeholders" {
    run "$DS_TOOL" acme 001
    assert_success
    grep -qF "[Font Family]" "$DS_DIR/acme-001/INDEX.md"
    grep -qF "[Application Name]" "$DS_DIR/acme-001/INDEX.md"
    ! grep -qF '{{FONT_FAMILY}}' "$DS_DIR/acme-001/INDEX.md"
    ! grep -qF '{{APPLICATION}}' "$DS_DIR/acme-001/INDEX.md"
}

@test "designsystem-add: AGENT defaults to housekeeping when AGENTNAME unset" {
    unset AGENTNAME
    run "$DS_TOOL" acme 001
    assert_success
    grep -qF "Maintainer:** housekeeping" "$DS_DIR/acme-001/INDEX.md"
}

@test "designsystem-add: AGENT honors AGENTNAME env var" {
    AGENTNAME="designex" run "$DS_TOOL" acme 001
    assert_success
    grep -qF "Maintainer:** designex" "$DS_DIR/acme-001/INDEX.md"
}

# ─────────────────────────────────────────────────────────────────────────────
# Idempotency and template handling
# ─────────────────────────────────────────────────────────────────────────────

@test "designsystem-add: refuses to overwrite an existing design system" {
    run "$DS_TOOL" acme 001
    assert_success
    run "$DS_TOOL" acme 001
    assert_failure
    assert_output_contains "already exists"
}

@test "designsystem-add: fails clearly when the template directory is missing" {
    rm -rf "$TPL"
    run "$DS_TOOL" acme 001
    assert_failure
    assert_output_contains "Template directory not found"
    [ ! -d "$DS_DIR/acme-001" ]
}

# ─────────────────────────────────────────────────────────────────────────────
# Coverage — verbose logging and empty-template handling
# ─────────────────────────────────────────────────────────────────────────────

@test "designsystem-add: --verbose reports each file it creates" {
    # Positional args come first; the tool reads $1/$2 without shifting flags out.
    run "$DS_TOOL" acme 001 --verbose
    assert_success
    assert_output_contains "Creating INDEX.md"
    assert_output_contains "Creating colors.md"
}

@test "designsystem-add: empty template still scaffolds the directory + source marker" {
    # Template dir exists but has no .md files: the copy loop matches nothing,
    # yet the structure and source/.gitkeep must still be created.
    rm -f "$TPL"/*.md
    run "$DS_TOOL" acme 001
    assert_success
    [ -d "$DS_DIR/acme-001/source" ]
    assert_file_exists "$DS_DIR/acme-001/source/.gitkeep"
    [ ! -f "$DS_DIR/acme-001/INDEX.md" ]
}
