---
title: "Plan: Tool Refactor + Telemetry Standardization"
slug: plan-tool-refactor-telemetry-standardization
path: docs/plans/20260331-plan-tool-refactor-telemetry-standardization.md
date: 2026-03-31
status: draft
branch: main
authors:
  - Jordan Dea-Mattson (principal)
  - Claude Code
session: ee9d2ca8-7d2c-47e3-bc99-932128feb706
tags: [Infra]
---

# Plan: Tool Refactor + Telemetry Standardization

**Branch:** `feat/tool-refactor`
**Dispatches:** `dispatch-tool-refactor-20260330.md` + `dispatch-qg-hardening-20260331.md`

## Context

All ~120 Agency tools live in `tools/` at repo root with an old HTTP-based logger (`_log-helper` posting to agency-service). The new JSONL-based logger already exists at `agency/tools/lib/_log-helper` (UUID7, append-only, no service dependency). This refactor moves everything to `agency/tools/`, kills the agency-service dependency, renames tools to noun-verb convention, and standardizes all logging. Big-bang on a single branch, no forwarding stubs.

## Decisions

- **No stubs** — update all references in one pass
- **Force new log pattern** — drop `"agency-tool"` type param, use `if type log_start` guard
- **Delete old `_log-helper`** — no coexistence
- **PROJECT_ROOT depth** — changes from `$SCRIPT_DIR/..` to `$SCRIPT_DIR/../..`
- **Ambiguous tools**: DELETE `install-hooks`, `setup-agency`, `agency-service`, `log-tool-use-debug`, `requests-backfill`, `msg`, `dispatch`, `dispatch-request`. KEEP `opportunities`, `launch-project`.
- **Telemetry reader**: Build `agency/tools/telemetry` (reads `telemetry.jsonl`, similar to `tool-log`)

## Commit 1: Delete deprecated tools and clean references

**Delete tools (15 + 6 legacy):**
- Messaging wrappers: `message-read`, `message-send`, `news-post`, `news-read`, `collaborate`, `collaboration-respond`
- All 6 `.legacy` files
- Setup redirects: `ghostty-setup`, `mac-setup`, `linux-setup`
- Superseded: `log-tool-use`, `log-tool-use-debug`
- Dead: `install-hooks`, `setup-agency`, `requests-backfill`
- Agency-service dependent (killed): `agency-service`, `msg`, `dispatch`, `dispatch-request`

**Clean references:**
- `.claude/settings.json`: remove permission entries for deleted tools, remove `log-tool-use` from PostToolUse hook
- `.claude/hooks/messages-check.sh`: delete it (calls deleted `message-read`); remove from settings.json UserPromptSubmit hook
- `.claude/hooks/session-end.sh`: remove `agency-service stop` and `context-save` calls
- `.claude/hooks/session-start.sh`: remove `news-read` and `dispatch` references

## Commit 2: Move libs, move+rename tools, rewrite patterns, update all references

### Move libraries
- Delete `tools/_log-helper` (old HTTP version)
- Move `tools/_path-resolve` → `agency/tools/lib/_path-resolve`
- Fix `agency/tools/lib/_provider-resolve` to source sibling `_path-resolve`

### Move + rename tools
| Current | New |
|---------|-----|
| `tools/commit` | `agency/tools/git-safe-commit` |
| `tools/tag` | `agency/tools/git-tag` |
| `tools/sync` | `agency/tools/git-sync` |
| `tools/whoami` + `tools/agentname` | `agency/tools/agency-whoami` (merge) |
| `tools/tool-new` | `agency/tools/tool-create` |
| All other ~95 tools | `agency/tools/{same-name}` |

**New tools:** `agency/tools/git-fetch`, `agency/tools/telemetry`

**Delete `tools/` directory** after all moves.

### Rewrite source/log patterns in every tool

Old:
```bash
source "$SCRIPT_DIR/_log-helper"
RUN_ID=$(log_start "name" "agency-tool" "$@" 2>/dev/null) || true
```

New:
```bash
if [[ -f "$SCRIPT_DIR/lib/_log-helper" ]]; then
    source "$SCRIPT_DIR/lib/_log-helper"
fi
RUN_ID=""
if type log_start &>/dev/null; then
    RUN_ID=$(log_start "name" "$@")
fi
```

Also fix:
- `PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"` → `"$(cd "$SCRIPT_DIR/../.." && pwd)"`
- `_path-resolve` sourcing: `$SCRIPT_DIR/_path-resolve` → `$SCRIPT_DIR/lib/_path-resolve`
- Cross-tool references: `./tools/X` → `./agency/tools/X` within tool scripts
- `log_end` 6-arg calls → 5-arg (drop output param)

### Update hooks
- `agency/hooks/*.sh` (5 files): `../tools/_path-resolve` → `../tools/lib/_path-resolve`
- `.claude/hooks/session-end.sh`: `$REPO_ROOT/tools/X` → `$REPO_ROOT/claude/tools/X`
- `.claude/hooks/session-start.sh`: same path updates

### Update settings.json
- All 108 `Bash(./tools/...)` → `Bash(./agency/tools/...)`
- Apply renames (commit→git-safe-commit, etc.)
- Add `git-fetch` and `telemetry` permissions
- Update hook paths in SessionEnd

## Commit 3: Update templates, docs, and tests

### Templates
- `agency/templates/TOOL.sh`: rewrite to use new source pattern, fix PROJECT_ROOT depth
- `agency/templates/PROVIDER.sh`: same treatment

### Documentation
- `CLAUDE.md`: update all `./tools/` refs, tool names, project structure diagram
- Other docs referencing `./tools/`

### Tests
- `tests/tools/test_helper.bash`: `TOOLS_DIR` → `claude/tools`
- `tests/tools/log-helper.bats`: rewrite for new JSONL-based `_log-helper`
- All `.bats` files: update tool name references for renames

## Verification

1. `bash -n agency/tools/*` — all tools pass syntax check
2. `bash -n agency/tools/lib/*` — all libs pass syntax check
3. `bash -n agency/hooks/*.sh` — all hooks pass syntax check
4. Every `Bash(./agency/tools/...)` permission in settings.json has a corresponding file
5. No remaining `./tools/` references (grep the repo)
6. `agency/tools/git-safe-commit --help` works
7. `agency/tools/git-fetch` works
8. `agency/tools/telemetry --summary` works
9. `agency/tools/agency-whoami` works
9. Run test suite: `bats tests/tools/`

## Critical Files

- `agency/tools/lib/_log-helper` — new logger (already exists, do not modify)
- `agency/tools/lib/_path-resolve` — moved from `tools/`
- `agency/tools/lib/_provider-resolve` — fix sibling source
- `.claude/settings.json` — 108 permission rewrites + hook path updates
- `agency/templates/TOOL.sh` — template rewrite
- `agency/templates/PROVIDER.sh` — template rewrite
- `CLAUDE.md` — extensive path updates
- `tests/tools/test_helper.bash` — TOOLS_DIR update

## Risks

1. **PROJECT_ROOT depth** — silent breakage if missed. Grep for `SCRIPT_DIR/\.\.` in all moved tools.
2. **Cross-tool calls** — tools that invoke other tools by path. Grep for `tools/` within tool scripts.
3. **log_end arg mismatch** — old 4th arg is `output_size`, new is `duration_ms`. Most pass `0`, but check `commit` which passes `${#COMMIT_OUTPUT}`.
4. **Hooks during refactor** — hooks reference tools that are moving. Branch work won't break main.
