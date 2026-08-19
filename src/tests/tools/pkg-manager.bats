#!/usr/bin/env bats
#
# pkg-manager — the shared JS package-manager resolver.
#
# Extracted so that skills (which ship to adopter repos) never name a package
# manager inline; src/tests/skills/skill-validation.bats enforces that rule and
# pr-captain-land's local validation gate needs the answer.
#
# Every test builds its own PATH out of stubs in BATS_TEST_TMPDIR, so the
# resolution order is exercised deterministically on any machine. An earlier
# version of this suite `skip`ped whenever the developer happened to have yarn
# installed — which meant the only interesting test did not run on half the
# fleet, and pnpm/yarn/bun were never covered at all.

REPO_ROOT="$(cd "$(dirname "${BATS_TEST_DIRNAME}")/../.." && pwd)"
TOOL="${REPO_ROOT}/agency/tools/pkg-manager"

setup() {
    PROJ="$BATS_TEST_TMPDIR/proj"
    STUBS="$BATS_TEST_TMPDIR/bin"
    mkdir -p "$PROJ" "$STUBS"
}

# stub <name>... — put fake executables on a PATH that contains nothing else
# except the system dirs python3 needs.
stub() {
    local n
    for n in "$@"; do
        printf '#!/bin/sh\nexit 0\n' > "$STUBS/$n"
        chmod +x "$STUBS/$n"
    done
}

# resolve — run the tool with ONLY the stubs (plus system bins) on PATH.
resolve() {
    PATH="$STUBS:/usr/bin:/bin:/usr/sbin:/sbin" bash "$TOOL" -C "$PROJ"
}

pkg() {  # pkg [<json body>]
    printf '%s' "${1:-\{\}}" > "$PROJ/package.json"
}

# ─────────────────────────────────────────────────────────────────────────────
# Shape
# ─────────────────────────────────────────────────────────────────────────────

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

@test "pkg-manager: -C with no argument is a usage error, not a silent exit 1" {
    run bash "$TOOL" -C
    [ "$status" -eq 2 ]
    [[ "$output" == *"requires a directory"* ]]
}

@test "pkg-manager: no package.json → exit 1 and no output" {
    run bash "$TOOL" -C "$PROJ"
    [ "$status" -eq 1 ]
    [ -z "$output" ]
}

# ─────────────────────────────────────────────────────────────────────────────
# Lockfile → manager
# ─────────────────────────────────────────────────────────────────────────────

@test "pkg-manager: pnpm-lock.yaml → pnpm" {
    pkg; touch "$PROJ/pnpm-lock.yaml"; stub pnpm npm
    run resolve
    [ "$status" -eq 0 ]
    [ "$output" = "pnpm" ]
}

@test "pkg-manager: yarn.lock → yarn" {
    pkg; touch "$PROJ/yarn.lock"; stub yarn npm
    run resolve
    [ "$status" -eq 0 ]
    [ "$output" = "yarn" ]
}

@test "pkg-manager: bun.lockb → bun" {
    pkg; touch "$PROJ/bun.lockb"; stub bun npm
    run resolve
    [ "$status" -eq 0 ]
    [ "$output" = "bun" ]
}

@test "pkg-manager: bun.lock (text form) → bun" {
    pkg; touch "$PROJ/bun.lock"; stub bun npm
    run resolve
    [ "$status" -eq 0 ]
    [ "$output" = "bun" ]
}

@test "pkg-manager: package-lock.json → npm" {
    pkg; touch "$PROJ/package-lock.json"; stub npm
    run resolve
    [ "$status" -eq 0 ]
    [ "$output" = "npm" ]
}

@test "pkg-manager: package.json with no lockfile falls back to npm" {
    pkg; stub npm
    run resolve
    [ "$status" -eq 0 ]
    [ "$output" = "npm" ]
}

@test "pkg-manager: pnpm-lock wins over yarn.lock (precedence, not filesystem order)" {
    pkg; touch "$PROJ/pnpm-lock.yaml" "$PROJ/yarn.lock"; stub pnpm yarn npm
    run resolve
    [ "$status" -eq 0 ]
    [ "$output" = "pnpm" ]
}

# ─────────────────────────────────────────────────────────────────────────────
# The packageManager field — an explicit declaration beats lockfile archaeology
# ─────────────────────────────────────────────────────────────────────────────

@test "pkg-manager: packageManager field is honoured (this repo has no lockfile)" {
    pkg '{"packageManager":"pnpm@9.1.0"}'; stub pnpm npm
    run resolve
    [ "$status" -eq 0 ]
    [ "$output" = "pnpm" ]
}

@test "pkg-manager: packageManager field beats a contradicting lockfile" {
    pkg '{"packageManager":"yarn@4.0.0"}'; touch "$PROJ/pnpm-lock.yaml"; stub pnpm yarn npm
    run resolve
    [ "$status" -eq 0 ]
    [ "$output" = "yarn" ]
}

@test "pkg-manager: an unrecognized packageManager value falls through to lockfiles" {
    pkg '{"packageManager":"cargo@1"}'; touch "$PROJ/pnpm-lock.yaml"; stub pnpm npm
    run resolve
    [ "$status" -eq 0 ]
    [ "$output" = "pnpm" ]
}

@test "pkg-manager: malformed package.json does not crash the resolver" {
    printf 'not json' > "$PROJ/package.json"; stub npm
    run resolve
    [ "$status" -eq 0 ]
    [ "$output" = "npm" ]
}

# ─────────────────────────────────────────────────────────────────────────────
# The declared-but-missing case — must FAIL, not silently substitute npm
# ─────────────────────────────────────────────────────────────────────────────

@test "pkg-manager: a lockfile naming an uninstalled manager fails, not falls back to npm" {
    # Substituting npm here would run `npm run build` against a pnpm
    # workspace: a confusing failure attributed to the wrong thing.
    pkg; touch "$PROJ/pnpm-lock.yaml"; stub npm
    run resolve
    [ "$status" -eq 1 ]
    [[ "$output" == *"declares 'pnpm'"* ]]
}

@test "pkg-manager: a packageManager field naming an uninstalled manager fails" {
    pkg '{"packageManager":"bun@1.0.0"}'; stub npm
    run resolve
    [ "$status" -eq 1 ]
    [[ "$output" == *"declares 'bun'"* ]]
}

@test "pkg-manager: nothing installed at all fails cleanly" {
    # resolve() runs with PATH="$STUBS:/usr/bin:/bin:/usr/sbin:/sbin" — the
    # system bindirs are included for coreutils. That assumes package managers
    # live OUTSIDE them (true on macOS: brew/nvm put npm in /usr/local/bin). On
    # a distro that installs npm to /usr/bin (e.g. alpine apk in the test
    # container), the "nothing installed" premise can't hold with this PATH, so
    # skip rather than false-fail. (#42)
    for d in /usr/bin /bin /usr/sbin /sbin; do
        for m in npm pnpm yarn bun; do
            [[ -x "$d/$m" ]] && skip "a system package manager ($d/$m) is on the resolve PATH; cannot simulate 'nothing installed'"
        done
    done
    pkg
    run resolve
    [ "$status" -eq 1 ]
    [[ "$output" == *"npm not found"* ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Output shape
# ─────────────────────────────────────────────────────────────────────────────

@test "pkg-manager: output is a single bare token" {
    pkg; stub npm
    run resolve
    [ "${#lines[@]}" -eq 1 ]
    [[ "$output" =~ ^[a-z]+$ ]]
}

@test "pkg-manager: resolves this repo without erroring" {
    # Integration smoke against the real checkout — whatever it answers, it
    # must answer something, because pr-captain-land's gate depends on it.
    run bash "$TOOL" -C "$REPO_ROOT"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}
