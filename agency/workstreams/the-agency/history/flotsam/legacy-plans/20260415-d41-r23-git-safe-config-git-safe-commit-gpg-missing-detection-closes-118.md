---
title: "D41-R23 — git-safe config + git-safe-commit gpg-missing detection (closes #118)"
slug: d41-r23-git-safe-config-git-safe-commit-gpg-missing-detection-closes-118
path: docs/plans/20260415-d41-r23-git-safe-config-git-safe-commit-gpg-missing-detection-closes-118.md
date: 2026-04-15
status: draft
branch: main
authors:
  - Jordan Dea-Mattson (principal)
  - Claude Code
session: 996153b6-ab38-4aca-aebd-728d2af55af5
---

# D41-R23 — git-safe config + git-safe-commit gpg-missing detection (closes #118)

## Context

Issue #118 (monofolk/jordan/captain): Peter Gao hit a hard block within his first 5 minutes as a second principal on monofolk. Global git config has `commit.gpgsign=true` but `gpg` isn't installed on his machine — common macOS state from 1Password / `brew install git` / GPG-Suite-uninstalled paths.

`git-safe-commit` exits 128 with no actionable output. Agent retries with `--no-verify` (no help — gpg signing happens at git core level). Agent tries `git-safe config --list` and `git-safe config commit.gpgsign` — `git-safe` has no `config` subcommand. Agent is stuck. Hookify blocks raw `git config`. Principal blocked on first commit.

## Approach

Two changes per the issue's proposed fix:

**Fix 1 — `git-safe-commit` detects gpg-missing**: scan the captured commit output for `cannot run gpg` / `gpg failed`. If matched, print an actionable error block (always — not just verbose) with three concrete remediations: `git-safe config --local commit.gpgsign false`, `git-safe config --global commit.gpgsign false`, or `brew install gnupg`.

**Fix 2 — `git-safe` gains a `config` subcommand** with an allow-list of safe keys. Allowed: `commit.gpgsign`, `commit.verbose`, `user.name`, `user.email`, `pull.rebase`, `init.defaultBranch`, `core.autocrlf`, `core.editor`. Block everything else (especially `remote.*`, `core.hooksPath`, `credential.*`, `core.sshCommand`) with a clear refusal pointing the agent to escalate to principal.

## File-level changes

### 1. `agency/tools/git-safe` — new `cmd_config` + dispatch entry

```bash
SAFE_CONFIG_KEYS=(commit.gpgsign commit.verbose user.name user.email pull.rebase init.defaultBranch core.autocrlf core.editor)

cmd_config() {
    # Forms:
    #   git-safe config --list
    #   git-safe config <key>
    #   git-safe config --local <key> <value>
    #   git-safe config --global <key> <value>
    [[ $# -eq 0 ]] && die "Usage: git-safe config --list | <key> | --local <key> <value> | --global <key> <value>"

    case "$1" in
        --list)
            git config --list
            return
            ;;
        --local|--global)
            local scope="$1"; shift
            [[ $# -ne 2 ]] && die "Usage: git-safe config $scope <key> <value>"
            local key="$1" value="$2"
            _config_assert_allowed "$key"
            git config "$scope" "$key" "$value"
            echo "${GREEN}Set${NC} $scope $key=$value"
            ;;
        -*)
            die "Unknown flag: $1 (use --list, --local, --global, or a bare key)"
            ;;
        *)
            # Read a single key
            git config --get "$1" 2>/dev/null || true
            ;;
    esac
}

_config_assert_allowed() {
    local key="$1"
    for allowed in "${SAFE_CONFIG_KEYS[@]}"; do
        [[ "$key" == "$allowed" ]] && return 0
    done
    die "git-safe config refuses '$key' — not on the safe-keys allow-list (${SAFE_CONFIG_KEYS[*]}). Escalate to principal for other config changes."
}
```

Dispatch entry: `config) shift; cmd_config "$@" ;;`

Help block updated.

### 2. `agency/tools/git-safe-commit` — gpg-missing detection on failure path

Replace lines ~601–604:

```bash
log_end "$RUN_ID" "failure" "$COMMIT_EXIT" ${#COMMIT_OUTPUT} "Commit failed: $MESSAGE"

# D41-R23 (issue #118): detect gpg-missing — common macOS friction when
# global commit.gpgsign=true but gpg binary is missing. Without this
# detection, agents see only "Exit code 128" and have no path forward.
if echo "$COMMIT_OUTPUT" | grep -qiE "cannot run gpg|gpg failed|gpg: not found"; then
    cat >&2 <<EOF
${RED}BLOCKED:${NC} git commit failed because commit.gpgsign=true but gpg is missing.

Fix options:
  1. Disable signing for this repo:    ./agency/tools/git-safe config --local commit.gpgsign false
  2. Disable signing globally:         ./agency/tools/git-safe config --global commit.gpgsign false
  3. Install gpg (macOS):              brew install gnupg

Current config:
$(git config --get-all commit.gpgsign 2>/dev/null | sed 's/^/  commit.gpgsign = /')
EOF
else
    # Existing behavior — verbose-only
    [[ "$VERBOSE" == "true" ]] && echo "$COMMIT_OUTPUT"
fi
exit $COMMIT_EXIT
```

### 3. `tests/tools/git-safe.bats` — extend with config subcommand cases

- `git-safe config --list` — succeeds, lists git config
- `git-safe config user.email` — reads single key
- `git-safe config --local commit.gpgsign false` — sets allowed key locally
- `git-safe config --global commit.gpgsign false` — sets allowed key globally (test fixture isolated $HOME)
- `git-safe config --local remote.origin.url evil` — refuses with allow-list message
- `git-safe config --local core.hooksPath bad` — refuses
- `git-safe config --local user.name 'Test'` — allowed key works
- `git-safe config` (no args) — usage error
- `git-safe config --bogus` — unknown flag rejected
- `git-safe --help` mentions config subcommand

### 4. `tests/tools/git-safe-commit.bats` — gpg-missing detection case

- Set `commit.gpgsign=true` in fixture, simulate gpg-missing (override PATH or use a stub `gpg` that exits non-zero), run `git-safe-commit "msg" --no-work-item`, assert:
  - exit code matches commit failure
  - stderr contains `BLOCKED: git commit failed because commit.gpgsign=true but gpg is missing.`
  - stderr contains `git-safe config --local commit.gpgsign false`

If a fixture-friendly gpg-stub is hard, fall back to a unit test that pipes a synthetic COMMIT_OUTPUT into the detection block via shell-source.

### 5. `agency/config/manifest.json`

Bump `agency_version: 41.22 → 41.23`.

## Out of scope

- The other Peter-bootstrap surfaces (raw `git branch` invocation by agent — agent error not framework bug; transcript path resolution — needs separate investigation, may already work post-R19)
- Changing default global `commit.gpgsign` in `principal-onboard` (different surface, larger scope)
- Renaming `git-safe-commit` exit-128 globally (other failure modes can still surface generic 128)

## Critical files

- `/Users/jdm/code/the-agency/agency/tools/git-safe` (new `cmd_config`, dispatch entry, help)
- `/Users/jdm/code/the-agency/agency/tools/git-safe-commit` (lines ~601–604 — failure detection)
- `/Users/jdm/code/the-agency/tests/tools/git-safe.bats` (extend)
- `/Users/jdm/code/the-agency/tests/tools/git-safe-commit.bats` (extend if exists, else new)
- `/Users/jdm/code/the-agency/agency/config/manifest.json`

## Verification

1. `bats tests/tools/git-safe.bats` and `bats tests/tools/git-safe-commit.bats` all green
2. Manual: simulate `commit.gpgsign=true` + gpg-missing → see BLOCKED message with remediation
3. Manual: `git-safe config --local commit.gpgsign false` → succeeds; `git-safe config --local remote.origin.url evil` → refused
4. RGR signed via receipt-sign, pr-create verifies hash
5. After merge: monofolk's Peter retries his blocked commit — `git-safe-commit` shows the BLOCKED message, agent runs `git-safe config --local commit.gpgsign false`, commit succeeds.

## Flow

1. Branch `jordandm-d41-r23`
2. Apply changes
3. BATS — all green
4. Sign RGR + commit + push
5. `/release` opens PR
6. Principal approval → `/pr-merge --principal-approved`
7. `/post-merge` cuts v41.23 (release-tag-check workflow validates)
8. Issue #118 auto-closes via PR `Closes #118`
