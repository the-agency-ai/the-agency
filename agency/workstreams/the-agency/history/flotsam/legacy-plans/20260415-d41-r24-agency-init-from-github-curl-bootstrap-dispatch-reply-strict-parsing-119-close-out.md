---
title: "D41-R24 — agency init --from-github + curl bootstrap + dispatch reply strict parsing + #119 close-out"
slug: d41-r24-agency-init-from-github-curl-bootstrap-dispatch-reply-strict-parsing-119-close-out
path: docs/plans/20260415-d41-r24-agency-init-from-github-curl-bootstrap-dispatch-reply-strict-parsing-119-close-out.md
date: 2026-04-15
status: draft
branch: main
authors:
  - Jordan Dea-Mattson (principal)
  - Claude Code
session: 996153b6-ab38-4aca-aebd-728d2af55af5
---

# D41-R24 — agency init --from-github + curl bootstrap + dispatch reply strict parsing + #119 close-out

## Context

Principal directive: `agency init --from-github` would be cleaner than the two-step clone+init dance. "It can be a curl." One-liner bootstrap for bare repos.

Also bundling:
- **Issue #119 bug 4** — `dispatch reply` silently accepts `--subject`/`--body` flags and ships them as literal body text. Trivial fix, same family as init strictness. Principal caught it by pattern recognition — the exact "silent accept" anti-pattern.
- **Issue #119 bugs 2 and 3** — Phase-1 audit (see plan exploration) found BOTH already correct in current source. Bug 2 already handles missing-frontmatter-as-unread (D41-R3 refactor). Bug 3 uses `git add -A` which stages both inbound and outbound. Close on #119 with verification-only BATS anchors to prevent regression.
- **Issue #119 bug 1** — sandbox skill-discovery duplicate (`/usr-jordan.discuss`). Explore agent flagged as harness-level (Claude Code load-time dedup) or sandbox-activate rework. **Splitting to R25** — too much scope for this release.

Deferred to future releases: #121 (workstream content codification — R25), #122 (release.version tracks framework not adopter — R25).

## Approach

### Part A — `agency init --from-github [ref]`

Replicate the `_agency-update --from-github` pattern (lines 159–200 of `agency/tools/lib/_agency-update`) into `agency/tools/lib/_agency-init`. Accept same flag shape: no ref = `main`, `@latest` = latest release tag, literal ref = tag/branch/commit. Shallow-clone to a temp dir, use as source, cleanup on exit.

### Part B — curl bootstrap one-liner

Ship a tiny `agency/tools/agency-bootstrap.sh` script that (a) downloads the latest `the-agency/agency/tools/agency` from GitHub raw, (b) invokes it with `init --from-github` + any extra flags. Document the one-liner in README / docs. Principal wanted this — makes bare-repo onboarding truly single-command.

One-liner shape:
```
curl -sL https://raw.githubusercontent.com/the-agency-ai/the-agency/main/agency/tools/agency-bootstrap.sh | bash
```

### Part C — `dispatch reply` strict flag rejection

`agency/tools/dispatch` → `cmd_reply`: parse args, reject any `-*` flag that isn't `--help`. Keep positional interface (`dispatch reply <id> "message"`) but fail loud on `--subject`/`--body`/any unknown.

### Part D — Regression anchors for #119 bugs 2 and 3

New BATS cases proving:
- `collaboration check` treats a file with no `status:` frontmatter as unread (surface `[COLLAB] unread: N` output)
- `collaboration push` stages inbound status changes (not just outbound) — commit diff includes both dirs

## File-level changes

### 1. `agency/tools/lib/_agency-init` — add `--from-github [ref]`

- Parse `--from-github` flag (mirror lines 71–81 of `_agency-update`)
- Shallow-clone block (mirror lines 159–200 of `_agency-update`) populating `SOURCE_DIR=$TMP_SOURCE_DIR`
- Help text update: document the new flag
- Trap for temp dir cleanup

### 2. `agency/tools/agency-bootstrap.sh` (new)

~30 lines. Accepts same args as `agency init`. Body:
```bash
#!/bin/bash
set -euo pipefail
TMP=$(mktemp -d -t agency-bootstrap-XXXXXX)
trap 'rm -rf "$TMP"' EXIT
git clone --depth 1 https://github.com/the-agency-ai/the-agency.git "$TMP" >/dev/null 2>&1
exec "$TMP/agency/tools/agency" init --from-github "$@"
```

Provenance header, --help, --version.

### 3. `agency/tools/dispatch` — `cmd_reply` strict flag parsing

Replace:
```bash
cmd_reply() {
    local dispatch_id="$1"; shift
    local message="$*"
    ...
}
```

With:
```bash
cmd_reply() {
    local dispatch_id="" message=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --help|-h) reply_usage; return 0 ;;
            -*) die "dispatch reply does not accept flag: $1
Usage: dispatch reply <id> \"message\"" ;;
            *)
                if [[ -z "$dispatch_id" ]]; then dispatch_id="$1"
                elif [[ -z "$message" ]]; then message="$1"
                else die "Unexpected extra argument: $1" ; fi
                shift
                ;;
        esac
    done
    [[ -z "$dispatch_id" ]] && die "dispatch reply requires an <id>"
    [[ -z "$message" ]] && die "dispatch reply requires a \"message\""
    ...
}
```

### 4. `tests/tools/dispatch.bats` — new cases for strict parsing

- `dispatch reply 5 --subject "x" --body "y"` → fails, error contains "does not accept"
- `dispatch reply 5 --foo` → fails with same error
- `dispatch reply 5 "legit message"` → works
- `dispatch reply` (no args) → requires id

### 5. `tests/tools/collaboration.bats` or `collaboration-frontmatter.bats` — regression anchors

- Seed an inbound file with no `status:` frontmatter → `collaboration check` surfaces it as unread
- Seed an inbound file with `status: unread` → surfaced
- Seed with `status: read` → skipped
- `collaboration push` after `collaboration resolve` stages both inbound status change and outbound new dispatch (verify via git diff)

### 6. `tests/tools/agency-update.bats` or new `agency-init.bats` — `--from-github` cases

- `agency init --help` documents `--from-github [ref]`
- `agency init --from-github` with no ref defaults to `main` (verbose log shows `ref: main`)
- `agency init --from-github @latest` enters release-tag path
- `agency-bootstrap.sh` exists and is executable

### 7. `agency/config/manifest.json`

Bump `agency_version: 41.23 → 41.24`.

## Out of scope

- Issue #119 bug 1 (skill dedup) — harness-level or sandbox-activate rework, moved to R25
- Issue #121 (workstream content split codification) — R25
- Issue #122 (release.version tracks framework not adopter) — R25
- Making the curl one-liner a signed artifact (supply-chain hardening) — separate release

## Critical files

- `/Users/jdm/code/the-agency/agency/tools/lib/_agency-init`
- `/Users/jdm/code/the-agency/agency/tools/agency-bootstrap.sh` (new)
- `/Users/jdm/code/the-agency/agency/tools/dispatch` (cmd_reply ~line 621)
- `/Users/jdm/code/the-agency/tests/tools/dispatch.bats` (extend)
- `/Users/jdm/code/the-agency/tests/tools/collaboration-frontmatter.bats` (extend) or new regression-anchor file
- `/Users/jdm/code/the-agency/tests/tools/agency-update.bats` (extend or new agency-init.bats)
- `/Users/jdm/code/the-agency/agency/config/manifest.json`

## Verification

1. BATS all green (dispatch.bats, collaboration-*.bats, agency-update.bats or agency-init.bats)
2. Manual: `agency init --from-github` in a fresh bare repo succeeds
3. Manual: `agency init --from-github @latest` resolves to latest release tag
4. Manual: `curl -sL https://raw.githubusercontent.com/.../agency-bootstrap.sh | bash` works (deferred to post-merge when the script is on main)
5. Manual: `dispatch reply 5 --subject "foo"` fails with clear error
6. RGR signed, pr-create verifies hash

## Flow

1. Branch `jordandm-d41-r24`
2. Apply changes
3. BATS green
4. Sign RGR + commit + push
5. `/release` opens PR
6. Principal approval → `/pr-merge`
7. `/post-merge` cuts v41.24 (release-tag-check validates)
8. Close #119 on merge with link to R24 + note about Bug 1 deferred to R25
