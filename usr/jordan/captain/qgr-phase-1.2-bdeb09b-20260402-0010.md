---
boundary: phase-complete
phase: "1+2"
slug: "agency-cli-handoff-types"
date: 2026-04-02 00:10
commit: bdeb09b
---

# Quality Gate Report — Phase 1+2: Agency CLI + Handoff Types

## Issues Found

| # | Severity | Finding | Status |
|---|----------|---------|--------|
| B1 | Bug | `git add -A` in _agency-init stages unintended user files | Fixed: explicit path list |
| B6 | Bug | `--principal`/`--project`/`--timezone` missing $2 validation | Fixed: added guards |
| S1 | Security | sed with `/` delimiter breaks on project names with `/` | Fixed: `\|` delimiter |
| S2 | Low | YAML heredoc unescaped — special chars in names break YAML | Accepted: realistic names won't trigger |
| S3 | Low | JSON fallback without jq escaping | Accepted: controlled strings only |
| B4 | Nit | Archive name computed twice (display race) | Accepted: display-only |
| s1 | Style | Duplicated local-save in _agency-feedback | Deferred |
| s2 | Style | Log functions shadowed in _agency-init | Accepted: intentional per-subcommand |
| s3 | Style | `set --` in sourced file | Accepted: _agency-init only |
| s4 | Style | sed frontmatter parser matches greedily | Accepted: forgiving-read handles |

## Accountability

| Check | Result |
|-------|--------|
| BATS tests (77) | All pass |
| JSON validation | All valid |
| Shell syntax (bash -n) | All pass |
| Bash 3.2 compat | Verified — no 4+ features |

## Coverage

| Area | Status |
|------|--------|
| agency CLI dispatcher | Tested (13 BATS) |
| agency verify | Tested (9 BATS) |
| agency whoami/version/help | Tested (4 BATS) |
| handoff --type flag | Manually tested |
| session-handoff.sh type parsing | Code reviewed |
| Bootstrap handoff content | Code reviewed |
| Old tool deletion | Verified (5 deleted) |
| Settings.json permissions | Validated |

## Checks

- [x] 77 BATS tests pass
- [x] JSON configs valid
- [x] Shell syntax clean
- [x] 3 findings fixed (B1, B6, S1)
- [x] No regressions introduced
