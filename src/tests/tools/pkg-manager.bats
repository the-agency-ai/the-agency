#!/usr/bin/env bats
#
# pkg-manager — the shared JS package-manager resolver.
#
# Extracted so that skills (which ship to adopter repos) never name a package
# manager inline; src/tests/skills/skill-validation.bats enforces that rule and
# pr-captain-land's local validation gate needs the answer.
#
# The contract worth pinning: lockfile decides, installation is checked, and a
# directory with no package.json resolves to nothing (exit 1) rather than a
# plausible-looking guess.

REPO_ROOT="$(cd "$(dirname "${BATS_TEST_DIRNAME}")/../.." && pwd)"
TOOL="${REPO_ROOT}/agency/tools/pkg-manager"

@test "pkg-manager: exists and is executable" {
    [ -x "$TOOL" ]
}

@test "pkg-manager: is syntactically valid bash" {
    bash -n "$TOOL"
}

@test "pkg-manager: --help exits 0" {
    run bash "$TOOL" --help
    [ "$status" -eq 0 ]
}

@test "pkg-manager: unknown flag is a usage error (exit 2)" {
    run bash "$TOOL" --nope
    [ "$status" -eq 2 ]
}

@test "pkg-manager: no package.json → exit 1 and no output" {
    run bash "$TOOL" -C "$BATS_TEST_TMPDIR"
    [ "$status" -eq 1 ]
    [ -z "$output" ]
}

@test "pkg-manager: package.json with no lockfile falls back to npm" {
    if ! command -v npm >/dev/null 2>&1; then skip "npm not installed"; fi
    echo '{}' > "$BATS_TEST_TMPDIR/package.json"
    run bash "$TOOL" -C "$BATS_TEST_TMPDIR"
    [ "$status" -eq 0 ]
    [ "$output" = "npm" ]
}

@test "pkg-manager: package-lock.json resolves to npm" {
    if ! command -v npm >/dev/null 2>&1; then skip "npm not installed"; fi
    echo '{}' > "$BATS_TEST_TMPDIR/package.json"
    echo '{}' > "$BATS_TEST_TMPDIR/package-lock.json"
    run bash "$TOOL" -C "$BATS_TEST_TMPDIR"
    [ "$status" -eq 0 ]
    [ "$output" = "npm" ]
}

@test "pkg-manager: a lockfile for an uninstalled manager does not win" {
    # Naming a manager that is not on PATH would just move the failure to a
    # less legible place, so the resolver skips it and keeps looking.
    if ! command -v npm >/dev/null 2>&1; then skip "npm not installed"; fi
    if command -v yarn >/dev/null 2>&1; then skip "yarn IS installed here"; fi
    echo '{}' > "$BATS_TEST_TMPDIR/package.json"
    touch "$BATS_TEST_TMPDIR/yarn.lock"
    run bash "$TOOL" -C "$BATS_TEST_TMPDIR"
    [ "$status" -eq 0 ]
    [ "$output" = "npm" ]
}

@test "pkg-manager: output is a single bare token" {
    if ! command -v npm >/dev/null 2>&1; then skip "npm not installed"; fi
    echo '{}' > "$BATS_TEST_TMPDIR/package.json"
    run bash "$TOOL" -C "$BATS_TEST_TMPDIR"
    [ "${#lines[@]}" -eq 1 ]
    [[ "$output" =~ ^[a-z]+$ ]]
}
