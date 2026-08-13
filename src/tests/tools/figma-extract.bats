#!/usr/bin/env bats
#
# Tests for ./agency/tools/figma-extract
#
# figma-extract fetches a Figma file over the network and transforms the
# response into a design-system doc tree. These tests are fully hermetic — the
# live Figma API is NEVER contacted:
#
#   * The tool is copied into a throwaway project (BATS_TEST_TMPDIR/proj) so
#     PROJECT_ROOT resolves there and all writes stay in the temp tree.
#   * `secret-vault` is replaced by a stub that echoes $FAKE_FIGMA_TOKEN (or
#     nothing, to drive the missing-token path).
#   * `curl` is shadowed by a stub earlier on PATH that cats canned JSON
#     fixtures based on the requested endpoint (file vs /styles vs error).
#
# The RGBA->hex conversion, embedded-color/font extraction, dedup, and output
# generation are the REAL code paths exercised against those fixtures.
#
# Coverage: --help / --version, arg + option validation, unknown option,
# missing-token, API-error, --dry-run (no writes), full extraction structure,
# hex transform correctness, font extraction, dedup, summary counts, and
# refuses-if-exists.
#

load 'test_helper'

# ─────────────────────────────────────────────────────────────────────────────
# Hermetic scaffold — tool copy + secret-vault stub + curl stub + fixtures
# ─────────────────────────────────────────────────────────────────────────────

setup() {
    export BATS_TEST_TMPDIR="$(mktemp -d)"
    test_isolation_setup

    PROJ="${BATS_TEST_TMPDIR}/proj"
    mkdir -p "$PROJ/agency/tools/lib"

    cp "${REPO_ROOT}/agency/tools/figma-extract" "$PROJ/agency/tools/figma-extract"
    chmod +x "$PROJ/agency/tools/figma-extract"
    cp "${REPO_ROOT}/agency/tools/lib/_colors" "$PROJ/agency/tools/lib/_colors" 2>/dev/null || true

    FX="$PROJ/agency/tools/figma-extract"
    DS_DIR="$PROJ/agency/knowledge/design-systems"

    # Stub secret-vault: echoes the token from $FAKE_FIGMA_TOKEN, else nothing.
    cat > "$PROJ/agency/tools/secret-vault" <<'SEOF'
#!/usr/bin/env bash
if [[ -n "${FAKE_FIGMA_TOKEN:-}" ]]; then
    echo "$FAKE_FIGMA_TOKEN"
fi
SEOF
    chmod +x "$PROJ/agency/tools/secret-vault"

    # Stub curl: serves fixtures by endpoint. Shadow the real curl via PATH.
    STUB_BIN="$PROJ/stub-bin"
    mkdir -p "$STUB_BIN"
    cat > "$STUB_BIN/curl" <<'CEOF'
#!/usr/bin/env bash
url=""
for a in "$@"; do
    case "$a" in
        http://*|https://*) url="$a" ;;
        "X-Figma-Token: "*)
            # Record the auth header so tests can assert token propagation.
            [[ -n "${CURL_TOKEN_LOG:-}" ]] && printf '%s\n' "${a#X-Figma-Token: }" >> "$CURL_TOKEN_LOG"
            ;;
    esac
done
if [[ "$url" == *"/styles"* ]]; then
    cat "${FIGMA_STYLES_FIXTURE:-/dev/null}"
else
    cat "${FIGMA_FILE_FIXTURE:-/dev/null}"
fi
CEOF
    chmod +x "$STUB_BIN/curl"
    export PATH="$STUB_BIN:$PATH"

    # Fixtures. JSON is compact (no spaces) to match the tool's grep patterns.
    FIX="$PROJ/fixtures"
    mkdir -p "$FIX"

    # file.json: 4 SOLID fills (one duplicate -> 3 unique colors) + 4 fonts
    # (Inter x3, Roboto x1 -> 2 unique fonts). Colors chosen for deterministic
    # hex: 1,1,1 -> #FFFFFF ; 0,0,0 -> #000000 ; 0.2,0.4,0.8 -> #3366CC.
    printf '%s' '{"name":"Test Design File","document":{"children":[{"type":"SOLID","color":{"r":1,"g":1,"b":1,"a":1}},{"type":"SOLID","color":{"r":0,"g":0,"b":0,"a":1}},{"type":"SOLID","color":{"r":0.2,"g":0.4,"b":0.8,"a":1}},{"type":"SOLID","color":{"r":0.2,"g":0.4,"b":0.8,"a":1}}],"text":[{"fontFamily":"Inter"},{"fontFamily":"Inter"},{"fontFamily":"Inter"},{"fontFamily":"Roboto"}]}}' > "$FIX/file.json"

    # styles.json: 2 FILL, 1 TEXT, 1 EFFECT published styles.
    printf '%s' '{"meta":{"styles":[{"style_type":"FILL"},{"style_type":"FILL"},{"style_type":"TEXT"},{"style_type":"EFFECT"}]}}' > "$FIX/styles.json"

    # error.json: an API error envelope.
    printf '%s' '{"status":404,"err":true,"message":"File not found"}' > "$FIX/error.json"

    # empty.json: a valid file with no SOLID fills and no fonts.
    printf '%s' '{"name":"Empty File","document":{"children":[]}}' > "$FIX/empty.json"
    printf '%s' '{"meta":{"styles":[]}}' > "$FIX/empty-styles.json"

    export FIGMA_FILE_FIXTURE="$FIX/file.json"
    export FIGMA_STYLES_FIXTURE="$FIX/styles.json"
    export FAKE_FIGMA_TOKEN="test-token-123"
}

teardown() {
    test_isolation_teardown
    [[ -d "${BATS_TEST_TMPDIR}" ]] && rm -rf "${BATS_TEST_TMPDIR}"
}

# ─────────────────────────────────────────────────────────────────────────────
# Help and version (exit before any network/validation)
# ─────────────────────────────────────────────────────────────────────────────

@test "figma-extract: --help shows usage" {
    run "$FX" --help
    assert_success
    assert_output_contains "Usage:"
    assert_output_contains "file-key"
}

@test "figma-extract: -h shows usage" {
    run "$FX" -h
    assert_success
    assert_output_contains "Usage:"
}

@test "figma-extract: --version shows version string" {
    run "$FX" --version
    assert_success
    assert_output_contains "figma-extract"
}

@test "figma-extract: -v shows version string" {
    run "$FX" -v
    assert_success
    assert_output_contains "figma-extract"
}

# ─────────────────────────────────────────────────────────────────────────────
# Argument / option validation (all before token fetch and any curl)
# ─────────────────────────────────────────────────────────────────────────────

@test "figma-extract: missing file-key fails" {
    run "$FX" --name=acme --version=001
    assert_failure
    assert_output_contains "Missing required argument: file-key"
}

@test "figma-extract: missing --name fails" {
    run "$FX" abc123 --version=001
    assert_failure
    assert_output_contains "Missing required option: --name"
}

@test "figma-extract: missing --version fails" {
    run "$FX" abc123 --name=acme
    assert_failure
    assert_output_contains "Missing required option: --version"
}

@test "figma-extract: unknown option fails" {
    run "$FX" abc123 --name=acme --version=001 --bogus
    assert_failure
    assert_output_contains "Unknown option"
}

# ─────────────────────────────────────────────────────────────────────────────
# Secret + API error handling
# ─────────────────────────────────────────────────────────────────────────────

@test "figma-extract: missing Figma token fails with guidance" {
    unset FAKE_FIGMA_TOKEN
    run "$FX" abc123 --name=acme --version=001
    assert_failure
    assert_output_contains "Figma token not found"
}

@test "figma-extract: Figma API error is surfaced" {
    export FIGMA_FILE_FIXTURE="$FIX/error.json"
    run "$FX" abc123 --name=acme --version=001
    assert_failure
    assert_output_contains "Figma API error"
    assert_output_contains "File not found"
    # No output tree should be left behind on API failure.
    [ ! -d "$DS_DIR/acme-001" ]
}

# ─────────────────────────────────────────────────────────────────────────────
# Dry run — reports counts, writes nothing
# ─────────────────────────────────────────────────────────────────────────────

@test "figma-extract: --dry-run reports counts and creates no files" {
    # --verbose surfaces the "DRY RUN" banner (emitted via log_warn, which is
    # otherwise quiet); "Would create" is the unconditional dry-run marker.
    run "$FX" abc123 --name=acme --version=001 --dry-run --verbose
    assert_success
    assert_output_contains "DRY RUN"
    assert_output_contains "Would create"
    [ ! -d "$DS_DIR/acme-001" ]
}

@test "figma-extract: --dry-run counts published styles and embedded data" {
    run "$FX" abc123 --name=acme --version=001 --dry-run
    assert_success
    # 2 FILL styles, 3 unique embedded colors, 2 unique fonts.
    assert_output_contains "2 color styles"
    assert_output_contains "3 unique colors"
    assert_output_contains "2 fonts"
}

# ─────────────────────────────────────────────────────────────────────────────
# Full extraction — structure, transforms, counts
# ─────────────────────────────────────────────────────────────────────────────

@test "figma-extract: full run creates the expected doc structure" {
    run "$FX" abc123 --name=acme --version=001
    assert_success
    local out="$DS_DIR/acme-001"
    [ -d "$out" ]
    assert_file_exists "$out/colors.md"
    assert_file_exists "$out/typography.md"
    assert_file_exists "$out/effects.md"
    assert_file_exists "$out/spacing.md"
    assert_file_exists "$out/assets.md"
    assert_file_exists "$out/INDEX.md"
    assert_file_exists "$out/GAPS.md"
    assert_file_exists "$out/GAP-RESOLUTION.md"
    assert_file_exists "$out/tailwind-config.md"
    assert_file_exists "$out/source/figma-file.json"
    assert_file_exists "$out/source/figma-styles.json"
}

@test "figma-extract: RGBA values are converted to the correct hex codes" {
    run "$FX" abc123 --name=acme --version=001
    assert_success
    local colors="$DS_DIR/acme-001/colors.md"
    grep -qF '#FFFFFF' "$colors"
    grep -qF '#000000' "$colors"
    grep -qF '#3366CC' "$colors"
}

@test "figma-extract: colors.json carries the extracted hex tokens" {
    run "$FX" abc123 --name=acme --version=001
    assert_success
    local cjson="$DS_DIR/acme-001/source/colors.json"
    assert_file_exists "$cjson"
    grep -qF '"hex": "#3366CC"' "$cjson"
    grep -qF '"hex": "#FFFFFF"' "$cjson"
}

@test "figma-extract: duplicate colors are de-duplicated (3 unique of 4 fills)" {
    run "$FX" abc123 --name=acme --version=001
    assert_success
    # colors.json emits one object per unique hex; count the hex keys.
    local n
    n="$(grep -c '"hex":' "$DS_DIR/acme-001/source/colors.json")"
    [ "$n" -eq 3 ]
}

@test "figma-extract: typography extraction records fonts and usage counts" {
    run "$FX" abc123 --name=acme --version=001
    assert_success
    local typ="$DS_DIR/acme-001/typography.md"
    grep -qF 'Inter' "$typ"
    grep -qF 'Roboto' "$typ"
    # Inter appears 3 times in the fixture; the row should carry that count.
    grep -qE '\| Inter \| 3 \|' "$typ"
}

@test "figma-extract: colors.md summarizes published + embedded counts" {
    run "$FX" abc123 --name=acme --version=001
    assert_success
    local colors="$DS_DIR/acme-001/colors.md"
    # Published FILL styles = 2, embedded unique colors = 3.
    grep -qE '\| Published Styles \| 2 \|' "$colors"
    grep -qE '\| Embedded \(document\) \| 3 \|' "$colors"
}

@test "figma-extract: INDEX.md records brand, version, and source file name" {
    run "$FX" abc123 --name=acme --version=001
    assert_success
    local idx="$DS_DIR/acme-001/INDEX.md"
    grep -qF 'acme Design System (v001)' "$idx"
    grep -qF 'Test Design File' "$idx"
    grep -qF 'abc123' "$idx"
}

@test "figma-extract: raw Figma responses are preserved under source/" {
    run "$FX" abc123 --name=acme --version=001
    assert_success
    grep -qF 'Test Design File' "$DS_DIR/acme-001/source/figma-file.json"
    grep -qF 'style_type' "$DS_DIR/acme-001/source/figma-styles.json"
}

@test "figma-extract: refuses to overwrite an existing design system" {
    run "$FX" abc123 --name=acme --version=001
    assert_success
    run "$FX" abc123 --name=acme --version=001
    assert_failure
    assert_output_contains "already exists"
}

# ─────────────────────────────────────────────────────────────────────────────
# Coverage — token propagation, effects content, empty document, dry-run reuse
# ─────────────────────────────────────────────────────────────────────────────

@test "figma-extract: forwards the secret-vault token to the Figma API" {
    export CURL_TOKEN_LOG="${BATS_TEST_TMPDIR}/token.log"
    run "$FX" abc123 --name=acme --version=001
    assert_success
    # The stub records the X-Figma-Token header value on every request.
    assert_file_exists "$CURL_TOKEN_LOG"
    grep -qF "test-token-123" "$CURL_TOKEN_LOG"
}

@test "figma-extract: effects.md records the published effect-style count" {
    run "$FX" abc123 --name=acme --version=001
    assert_success
    # Fixture has 1 EFFECT style; the tool appends a note when count > 0.
    grep -qF "1 effect styles found in Figma" "$DS_DIR/acme-001/effects.md"
}

@test "figma-extract: handles a document with no colors or fonts" {
    export FIGMA_FILE_FIXTURE="$FIX/empty.json"
    export FIGMA_STYLES_FIXTURE="$FIX/empty-styles.json"
    run "$FX" abc123 --name=empty --version=001
    assert_success
    local out="$DS_DIR/empty-001"
    assert_file_exists "$out/colors.md"
    assert_file_exists "$out/typography.md"
    # Zero unique embedded colors -> empty colors.json array (no hex entries).
    local n
    n="$(grep -c '"hex":' "$out/source/colors.json" 2>/dev/null || true)"
    [ "${n:-0}" -eq 0 ]
}

@test "figma-extract: --dry-run is allowed when the design system already exists" {
    run "$FX" abc123 --name=acme --version=001
    assert_success
    [ -d "$DS_DIR/acme-001" ]
    # A dry run against an existing system must NOT error on the exists-check.
    run "$FX" abc123 --name=acme --version=001 --dry-run
    assert_success
    assert_output_contains "Would create"
    # The pre-existing tree is left intact.
    assert_file_exists "$DS_DIR/acme-001/INDEX.md"
}
