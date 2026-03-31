# Captain Handoff

**Agent:** captain (housekeeping)
**Principal:** jordan
**Updated:** 2026-03-31 (session 10)

## Current State

On `main` branch. Clean working tree. PR #20 merged (agency-init design).

## Session 10 Work

### Agency-Init Design (COMPLETE — PR #20 merged)

Full redesign of agency-init and agency-update. rsync + manifest model for installing and maintaining the Agency framework in any git repo.

**Multi-agent review:** 3 reviewers (design, code, security) — 18 findings (3C, 7M, 8m). All addressed.

**Key decisions (via /discuss 1B1):**
1. Single namespace — everything under `claude/` (usr/, workstreams/, tools, agents)
2. Trust source for v1 — signed checksums post-v1 (public release)
3. Git is the rollback — `--dry-run` flag, no custom staging
4. Settings merge — `settings-template.json` (framework) + `settings-merge` tool

**Artifacts:**
- Design: `claude/workstreams/agency/seeds/agency-init-design-20260331.md`
- Dispatch: `usr/jordan/captain/dispatches/dispatch-agency-init-design-20260331.md`
- Transcript: `usr/jordan/captain/transcripts/transcript-agency-init-review-20260331.md`

### ADHOC-WORKLOG Fix (COMPLETE — in PR #20)

Removed ADHOC-WORKLOG.md append from `claude/tools/git-commit`. The `--adhoc` flag still works (no work-item required) but no longer writes to a worklog file. Telemetry captures this via `log_end`.

## Dispatch Queue

| # | Dispatch | Status |
|---|----------|--------|
| 1 | Plugin Provider Framework | MERGED |
| 2 | Agency 2.0 Bootstrap | MERGED |
| — | Workstream Bootstrap | MERGED |
| 3 | ISCP Design | NOT STARTED — needs /discuss |
| 4 | Browser Protocol | BLOCKED (bugs filed, no working browser path) |
| 5 | Tool Refactor | DONE (PR #18 merged) |
| 6 | QG Hardening | DONE |
| 7 | Code Survey / Incremental Capture | Needs /discuss |
| 8 | Token Economics Tools | PARTIAL — needs /discuss |
| 9 | Agency-Init Design | DONE (PR #20 merged) |

## Blocked Items

**@bcherny tweet** (`x.com/bcherny/status/2038454336355999749`) — blocked on browser access. Principal needs to paste content.

**Two X/Twitter posts from session 9** — still blocked:
- `https://x.com/trq212/status/2033949937936085378` — CAPTURED (skills article seed)
- `https://x.com/bcherny/status/2038454336355999749` — PENDING

## Open Issues (Internal)

| Issue | Status |
|-------|--------|
| ISS-007 | Open — agent-create must register in settings.json |
| ISS-008 | Open — Dependabot triage |
| ISS-009 | Open — status line redundant worktree naming |
| ISS-012 | Open — worktrees in two locations (noted in agency-init design) |

## Open Issues (GitHub — anthropics/claude-code)

| Issue | Title |
|-------|-------|
| #41363 | `/feedback` fails with HTTP 413 — oversized context, silent drop |
| #41367 | `claude mcp list` stale "Connected" after server crash |
| #41370 | Computer Use tier references nonexistent `mcp__Claude_in_Chrome__*` tools |
| #41371 | Claude in Chrome CSP errors block inline scripts |
| #41099 | `request_access` lacks binary path and actionable guidance |
| #41101 | Permissions reset on every CLI update (version-pinned binary) |
| #41104 | No Safari browser automation support |

Unfiled: Read tool pdftoppm PATH bug (poppler at /opt/homebrew/bin/ not in subprocess PATH).

## CI

Both workflows broken (agency-service deprecation):
- `.github/workflows/test.yml` — references deleted `./tools/agency-service`
- `.github/workflows/starter-verify.yml` — references `tools/myclaude`, `source/services/agency-service`

Fix actions specified in agency-init design document.

## Parked Topics

- **Status line for agent activity** — needs /discuss
- **Token Economics** — compound bash rule done, 4 items remain
- **ISCP** — dispatch #3, not started

## Git State

- Branch: `main`
- HEAD: 7020cf9
- Working tree: clean (except handoff)
- Origin: in sync
