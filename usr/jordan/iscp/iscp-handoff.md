---
type: handoff
agent: the-agency/jordan/iscp
workstream: iscp
date: 2026-04-06
trigger: reboot
---

## Identity

`the-agency/jordan/iscp` — ISCP workstream agent. I build and maintain the Inter-Session Communication Protocol: the notification, dispatch, and flag infrastructure that connects all agents.

## Current State

ISCP v1 is complete and hardened. 174 BATS tests green. Branch `iscp` is ~15 commits ahead of main. Captain has merged earlier work into main but this session's commits (a4f7f2b, 41fb5cf) are not yet merged.

Last two commits this session:
- `a4f7f2b` — settings-template: ISCP hooks + permissions + version test fixes
- `41fb5cf` — structured commit dispatch payloads (commit_hash, branch, files_changed, stage_hash in body)

Full tool suite operational: `agent-identity`, `dispatch` (create/list/read/check/resolve/status/reply), `flag` (capture/list/count/discuss/clear/resolve), `iscp-check` (hook notification), `iscp-migrate` (legacy migration).

## Valueflow Context

- PVR: `claude/workstreams/agency/valueflow-pvr-20260406.md`
- A&D: `claude/workstreams/agency/valueflow-ad-20260406.md`
- MAR dispositions: `claude/workstreams/agency/reviews/`

Read the A&D on startup — it defines how ISCP tools work and the architectural decisions behind them.

## Active Work

Was working the backlog when reboot was called. Two items completed this session:
1. Settings-template updated with ISCP hooks (SessionStart/UserPromptSubmit/Stop) and tool permissions
2. Dispatch-on-commit enhanced with structured YAML metadata body

Uncommitted file: `claude/tools/git-commit` (structured commit dispatch) — already committed as `41fb5cf`.
Untracked: ~20 dispatch payload files in `usr/jordan/iscp/dispatches/`, history archives.

## Key Decisions

- `dispatch create` requires `--body` or explicit `--template`. No silent empty payloads.
- `agent-identity` checks `.agency-agent` file before branch detection. PR branches (`captain/*`, `pr/*`, `release/*`) resolve to captain.
- `CLAUDE_PROJECT_DIR` is authoritative over `SCRIPT_DIR` for project root in all ISCP tools — fixes identity when agents cd to main checkout.
- Symlink-based dispatch payload resolution: `~/.agency/{repo}/dispatches/dispatch-{id}.md` symlinks to absolute filesystem paths. Falls back to legacy 4-strategy ladder.
- Commit dispatches carry structured metadata: commit_hash, branch, files_changed, stage_hash, work_item.

## Open Items

1. **DB schema versioning** — version column exists (PRAGMA user_version), but no migration framework for schema changes. Next item in backlog.
2. **Flag categories** (`--friction`, `--idea`, `--bug`) — A&D Section 10. Not started.
3. **Dispatch retention** — archive resolved dispatches after 30 days. Not started.
4. **Dropbox primitive** — file staging between worktrees. Not started.
5. **BUG 2** — `dispatch list --all` shows other agents' unread mail. Acknowledged, not fixed. Design question: should --all filter by principal?
6. **SMS-style dispatches** — short string stored in DB, no payload file. Like flag but agent-addressable with dispatch lifecycle (unread/read/resolved). `dispatch create --sms "quick message"`. Most dispatches today were short enough for this. Principal requested.

## Need Help?

If you're stuck or have a question, send a dispatch to captain: `dispatch create --to captain --subject "Question: ..." --body "..."`

## Startup Actions

1. Set dispatch loop: `/loop 5m dispatch check`
2. Process unread dispatches: `dispatch list`
3. Process unread flags: `flag list`
4. Read the valueflow A&D: `claude/workstreams/agency/valueflow-ad-20260406.md`
5. Merge main to pick up any cross-agent changes: `git merge main`
6. Resume backlog: DB schema versioning, then flag categories
