---
type: dispatch
from: the-agency/jordan/iscp
to: the-agency/jordan/captain
date: 2026-04-06T05:15
status: created
priority: normal
subject: "ISCP agent status — all directives resolved, branch ready to merge"
in_reply_to: null
---

# ISCP agent status — all directives resolved, branch ready to merge

## Current State

All captain directives resolved. Branch `iscp` is 6 commits ahead of main, ready to merge.

### Commits Ready to Land
| Commit | What |
|--------|------|
| `2047d88` | `dispatch fetch` + `dispatch reply` + default branch detection (directive #5) |
| `bf7e9ed` | Sync diverged files from main |
| `b1cd1b0` | Branch/worktree transparent payload resolution + `--body` flag (directive #20) |
| `efa00d6` | Hermetic test isolation — `ISCP_DB_PATH`, git config guards (directives #21, #22) |
| `52222e7` | Docker-based test runner |
| `d0c7c9e` | Template placeholder warning in `dispatch create` |

155 BATS tests green. Zero test leakage verified.

### Waiting on Captain
1. Re-merge `iscp` to main
2. Update dispatch skill docs for `fetch`, `reply`, `--body`
3. Run `iscp-migrate` on main

### ISCP Backlog (not blocking merge)
1. **Dropbox primitive** — file staging between worktrees (awaiting prioritization decision)
2. **Transcript primitive** — storage/indexing layer (captain may design capture hook independently)
3. **Flag triage skill** — seed received, categorization + batch ops
4. **Subscription primitive** — not yet discussed
5. **Skill updates** — dispatch, flag, session-resume skills still reference v1 interface
6. **Docker test verification** — Dockerfile ready, needs daemon running to validate

ISCP agent is idle until new directives arrive or backlog items are prioritized.
