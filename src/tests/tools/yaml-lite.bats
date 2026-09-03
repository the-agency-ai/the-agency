#!/usr/bin/env bats
#
# Tests for agency/tools/lib/yaml_lite.py — the stdlib-only YAML reader that
# replaced PyYAML in `config` (#264 zero-pip). Two kinds of check:
#   1. Golden value extraction via the CLI (no pyyaml needed) — proves the
#      subset the framework relies on parses correctly on any stdlib python.
#   2. A cross-check against PyYAML when it IS installed (host + the test
#      container ship py3-yaml) — proves structural parity with the real thing.

load 'test_helper'

YL="${REPO_ROOT}/agency/tools/lib/yaml_lite.py"

setup() {
    test_isolation_setup
    FIX="${BATS_TEST_TMPDIR}/f.yaml"
}
teardown() { test_isolation_teardown; }

_write() { printf '%s\n' "$1" > "$FIX"; }

@test "yaml_lite: nested map dotted-key lookup" {
    _write 'a:
  b:
    c: hello'
    run python3 "$YL" "$FIX" a.b.c
    assert_success
    [ "$output" = "hello" ]
}

@test "yaml_lite: quoted string strips quotes" {
    _write 'name: "Jordan Dea-Mattson"'
    run python3 "$YL" "$FIX" name
    [ "$output" = "Jordan Dea-Mattson" ]
}

@test "yaml_lite: single-quoted string" {
    _write "x: 'a b c'"
    run python3 "$YL" "$FIX" x
    [ "$output" = "a b c" ]
}

@test "yaml_lite: true/false become Python bools" {
    _write 'flagon: true
flagoff: false'
    run python3 "$YL" "$FIX" flagon
    [ "$output" = "True" ]
    run python3 "$YL" "$FIX" flagoff
    [ "$output" = "False" ]
}

@test "yaml_lite: block list of scalars" {
    _write 'items:
  - one
  - two
  - three'
    run python3 "$YL" "$FIX" items
    [ "$output" = "['one', 'two', 'three']" ]
}

@test "yaml_lite: flow list" {
    _write 'providers: ["log-helper", "jsonl"]'
    run python3 "$YL" "$FIX" providers
    [ "$output" = "['log-helper', 'jsonl']" ]
}

@test "yaml_lite: empty flow list" {
    _write 'sites: []'
    run python3 "$YL" "$FIX" sites
    [ "$output" = "[]" ]
}

@test "yaml_lite: list of maps (the platforms shape)" {
    _write 'github:
  - username: jordandm
    repos:
      - org: the-agency-ai
        repo: the-agency'
    run python3 "$YL" "$FIX" github
    [ "$output" = "[{'username': 'jordandm', 'repos': [{'org': 'the-agency-ai', 'repo': 'the-agency'}]}]" ]
}

@test "yaml_lite: list scalar with a colon is NOT parsed as a map" {
    # Regression (QG): a list item like `- http://x` has a colon NOT followed by
    # a space, so it is a plain SCALAR, not a mapping. The old detector split on
    # the first ':' unconditionally and produced {'http': '//x'}.
    _write 'items:
  - http://example.com
  - key:value
  - plain'
    run python3 "$YL" "$FIX" items
    [ "$output" = "['http://example.com', 'key:value', 'plain']" ]
}

@test "yaml_lite: map value keeps its colons" {
    _write 'url: http://x:8080/path'
    run python3 "$YL" "$FIX" url
    [ "$output" = "http://x:8080/path" ]
}

@test "yaml_lite: comments and blank lines ignored" {
    _write '# a comment
key: value  # inline comment
'
    run python3 "$YL" "$FIX" key
    [ "$output" = "value" ]
}

@test "yaml_lite: '#' inside a quoted value is not a comment" {
    _write 'msg: "hello # not a comment"'
    run python3 "$YL" "$FIX" msg
    [ "$output" = "hello # not a comment" ]
}

@test "yaml_lite: leading-zero and underscore numerics stay strings (no silent coercion)" {
    _write 'a: 010
b: 1_000
c: 8080'
    run python3 "$YL" "$FIX" a
    [ "$output" = "010" ]
    run python3 "$YL" "$FIX" b
    [ "$output" = "1_000" ]
    run python3 "$YL" "$FIX" c
    [ "$output" = "8080" ]
}

@test "yaml_lite: nested flow sequence with inner commas" {
    _write 'lst: [[a, b], [c]]'
    run python3 "$YL" "$FIX" lst
    [ "$output" = "[['a', 'b'], ['c']]" ]
}

@test "yaml_lite: empty file loads as None" {
    printf '' > "$FIX"
    run python3 "$YL" "$FIX"
    assert_success
    [ "$output" = "None" ]
}

@test "yaml_lite: missing key exits non-zero" {
    _write 'a: 1'
    run python3 "$YL" "$FIX" a.b.c
    assert_failure
}

@test "yaml_lite: parses the real agency.yaml" {
    run python3 "$YL" "${REPO_ROOT}/agency/config/agency.yaml" project.name
    assert_success
    [[ -n "$output" ]]
}

@test "yaml_lite: structural parity with PyYAML on agency.yaml (when pyyaml present)" {
    python3 -c 'import yaml' 2>/dev/null || skip "pyyaml not installed"
    run python3 - "$YL" "${REPO_ROOT}/agency/config/agency.yaml" <<'PY'
import sys, importlib.util, yaml
spec = importlib.util.spec_from_file_location("yaml_lite", sys.argv[1])
yl = importlib.util.module_from_spec(spec); spec.loader.exec_module(yl)
a = yaml.safe_load(open(sys.argv[2]))
b = yl.load(sys.argv[2])
print("MATCH" if a == b else "MISMATCH")
PY
    assert_success
    [ "$output" = "MATCH" ]
}
