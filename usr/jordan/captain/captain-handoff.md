---
type: handoff
agent: the-agency/jordan/captain
workstream: housekeeping
date: 2026-04-16
trigger: session-compact
---

## Continue — D42-R5 Cleanup (execute immediately)

Branch `jordandm-d42-r5-cleanup` cut from main (121c351, post-v42.4 merge). Tree has minor stale state from branch switching — `AGENCY_ALLOW_RAW=1 git checkout -- .` to clean before starting.

## D42-R5 Full Scope (all items principal-approved via 1B1)

### Delete v1 tools (15 tools)

```
claude/tools/myclaude
claude/tools/request
claude/tools/request-complete
claude/tools/observe
claude/tools/browser
claude/tools/session-archive
claude/tools/instruction-show
claude/tools/instruction-list
claude/tools/instruction-index-update
claude/tools/instruction-capture
claude/tools/instruction-complete
claude/tools/add-principal
claude/tools/proposal-capture
claude/tools/designsystem-validate
claude/tools/secret-migrate
```

**DO NOT delete:** `figma-extract`, `designsystem-add` (claimed by designex, dispatch #474/#475)

### Delete v1 agent templates (3)

```
claude/agents/templates/design-system/
claude/agents/templates/ux-dev/
claude/agents/templates/services/
```

### Retire commands (2), update 1

- Delete: `.claude/commands/agency-request.md`, `.claude/commands/agency-tutorial.md`
- Update: `.claude/commands/agency-welcome.md` (new paths)

### Move dirs to flotsam (after tool deletion unblocks)

- `claude/principals/` → `claude/workstreams/the-agency/history/flotsam/legacy-principals/`
- `claude/proposals/` → `claude/workstreams/the-agency/history/flotsam/proposals/`

### Update plan-capture.py

- Workstream-aware: resolve {W} from branch/agent context
- Write to `claude/workstreams/{W}/plan-{W}-{slug}-{YYYYMMDD}.md`
- Superseded plans → `history/` with `{HHMM}` timestamp
- Proper slug generation
- Then move `claude/plans/` → `claude/workstreams/the-agency/history/flotsam/legacy-plans/`
- Also move `docs/plans/` (18 files) → same flotsam location

### Root cleanup

- Delete: `agency` (v1 CLI file), `tools/` (dead TS stage-hash), `VERSION`, `EXTENDING.md`, `registry.json`, `package.json`, `package-lock.json`
- Delete: `test/test-agency-project/` (v1 starter snapshot, no tests reference it)
- Delete: `dist/` from disk (not tracked, add to .gitignore)
- Move: `mock-and-mark/` → `apps/mock-and-mark/`
- Move: `source/` → `claude/workstreams/the-agency/history/flotsam/legacy-source/`
- Move: `services/` → `claude/workstreams/the-agency/history/flotsam/legacy-services/`
- Move: `history/` → `claude/workstreams/the-agency/history/flotsam/legacy-history/`
- Move: `docs/plans/` → flotsam (18 files)
- Extract "Building Tools" from `EXTENDING.md` → `claude/REFERENCE-TOOL-BUILDING.md`, then delete `EXTENDING.md`

### Documentation cleanup

- Audit + merge `claude/README-*.md` (5 files) into corresponding `REFERENCE-*.md`, delete READMEs
- Update `CLAUDE.md` root bootloader (remove stale refs)
- Update `.gitignore` (stale principals exclusion + add dist/)

### Agent sandbox cleanup

- Move `usr/jordan/mdslidepal/qgr-*` → `claude/workstreams/mdslidepal/qgr/`
- Move `usr/jordan/reports/` → flotsam
- `claude/workstream-agent-nits.md` → flotsam
- `claude/CHANGELOG-*.md` (4 files) → flotsam
- `claude/YOUR-FIRST-RELEASE.md` → `claude/templates/`

### Stale DBs

- Delete: `claude/data/bug.db`, `bugs.db`, `idea.db`, `messages.db`, `observation.db`, `product.db`, `queue.db`, `request.db`, `test.db` (+ WAL/SHM files)
- Keep: `agency.db`, `dispatch.db`, `log.db`, `secret.db`

### Test fixture updates

- Update `release-plan.bats`, `iscp-migrate.bats`, `test-worktree-sync.sh` fixture paths

### Update tool-create + TOOL.sh template

- Current conventions: provenance headers, `_colors`, `_log-helper` v2

### Manifest bump

42.4 → 42.5

## Session releases

| Release | PR | What |
|---------|-----|------|
| v42.1 | #129 | stage-hash bash + reset-soft + stash + hookify (closes #126 #128) |
| v42.2 | #131 | hookify block-raw-gh-release + /secret dedup |
| v42.3 | #132 | workstream content split — registrations, receipts, git-safe mv (closes #121 #130) |
| v42.4 | #133 | migrate the-agency artifacts |

## Issues filed this session

- #135 — dependencies manifest (post-cleanup)

## Fleet status

All 8 agents dispatched on v42.3. Designex, ISCP, Devex confirmed. Monofolk dispatched via collaboration.

---

*OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*
