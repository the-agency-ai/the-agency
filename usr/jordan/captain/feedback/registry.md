---
type: feedback-registry
principal: jordan
last_updated: 2026-04-17
---

# Feedback Registry — Anthropic / Claude Code

Filed feedback items to Anthropic about Claude Code, SDK, and related products.

## Open

| Date | Feedback ID | Issue | Topic |
|------|-------------|-------|-------|
| 2026-04-17 | `61261384-a937-472e-bb41-a604caf56f0e` | [#49712](https://github.com/anthropics/claude-code/issues/49712) | Session names auto-overwritten, ignoring user-set names |
| 2026-04-12 | `24fe6d3e…` | [#46860](https://github.com/anthropics/claude-code/issues/46860) | `/feedback` attaches all session errors to unrelated filings (triage noise) |
| 2026-04-12 | `b3bb3ef6…` | [#46855](https://github.com/anthropics/claude-code/issues/46855) | Add trusted framework paths for autonomous agent permission bypass |
| 2026-04-11 | `cc00b303-5710-4e23-862e-882d6db8c7e0` | [#46546](https://github.com/anthropics/claude-code/issues/46546) | Content filter returns opaque 400 with zero diagnostic signal |
| 2026-04-11 | `229cbbce-6d28-4390-8eb2-aeaecc192b6c` | [#46538](https://github.com/anthropics/claude-code/issues/46538) | Log `/feedback` network requests and errors to `~/.claude/debug/` |
| 2026-04-11 | `95fe4771-6780-4be7-9e8e-30d7feea3496` | [#46531](https://github.com/anthropics/claude-code/issues/46531) | `/feedback` command silently fails; broken 5+ months |
| 2026-04-08 | `8dd67e96-63ea-4a22-b687-d26a1b2d0add` | [#45017](https://github.com/anthropics/claude-code/issues/45017) | Periodic silent execution primitive for autonomous agents |
| 2026-03-31 | _(pre-tracking)_ | [#41380](https://github.com/anthropics/claude-code/issues/41380) | Computer Use MCP cannot switch between macOS Spaces |
| 2026-03-31 | _(pre-tracking)_ | [#41371](https://github.com/anthropics/claude-code/issues/41371) | Claude in Chrome extension — CSP errors block inline scripts |
| 2026-03-30 | _(pre-tracking)_ | [#41104](https://github.com/anthropics/claude-code/issues/41104) | Add Safari browser automation support |
| 2026-03-30 | _(pre-tracking)_ | [#41099](https://github.com/anthropics/claude-code/issues/41099) | Computer Use MCP request_access lacks binary path and guidance |
| 2026-03-28 | _(pre-tracking)_ | [#40060](https://github.com/anthropics/claude-code/issues/40060) | Auth token missing subscription metadata hides features like remote-control |

## Closed / Resolved

| Date Closed | Feedback ID | Issue | Topic | Resolution |
|-------------|-------------|-------|-------|------------|
| 2026-04-17 | (self-filed in error) | [#49710](https://github.com/anthropics/claude-code/issues/49710) | Session name auto-rename (duplicate) | closed by reporter — superseded by #49712 |
| 2026-04-15 | `48a647ec…` | [#46859](https://github.com/anthropics/claude-code/issues/46859) | macOS accessibility permissions lost on every update | resolved |
| 2026-04-15 | `0894552a…` | [#46858](https://github.com/anthropics/claude-code/issues/46858) | Add `CLAUDE_AGENT_NAME` env var for multi-agent workflows | resolved |
| 2026-04-15 | `ce60ba6d…` | [#46853](https://github.com/anthropics/claude-code/issues/46853) | Session identity broken for multi-agent worktrees | resolved |
| 2026-04-12 | _(duplicate)_ | [#46852](https://github.com/anthropics/claude-code/issues/46852) | Session identity (duplicate of #46853) | closed as duplicate |
| 2026-04-03 | _(pre-tracking)_ | [#43058](https://github.com/anthropics/claude-code/issues/43058) | Session state hook events for multi-tab terminal integration | resolved |
| 2026-04-03 | _(pre-tracking)_ | [#41370](https://github.com/anthropics/claude-code/issues/41370) | Computer Use MCP tier guidance references nonexistent tools | resolved |
| 2026-04-03 | _(pre-tracking)_ | [#41367](https://github.com/anthropics/claude-code/issues/41367) | `claude mcp list` reports stale 'Connected' after MCP crash | resolved |
| 2026-04-03 | _(pre-tracking)_ | [#41363](https://github.com/anthropics/claude-code/issues/41363) | `/feedback` fails with HTTP 413 — oversized context | resolved |
| 2026-04-03 | _(pre-tracking)_ | [#41101](https://github.com/anthropics/claude-code/issues/41101) | Computer Use MCP permissions reset on every CLI update | resolved |
| 2026-01-21 | _(pre-tracking)_ | [#18952](https://github.com/anthropics/claude-code/issues/18952) | Claude Code rewrites .mcp.json and strips env configuration | resolved |
| 2025-12-29 | _(pre-tracking)_ | [#15407](https://github.com/anthropics/claude-code/issues/15407) | Allow toggling permissions mid-session without restart | resolved |
| 2025-12-26 | _(pre-tracking)_ | [#15132](https://github.com/anthropics/claude-code/issues/15132) | Hard Crash | resolved |

## Notes

- **Pre-tracking entries:** Feedback IDs weren't consistently captured before 2026-04-08. Where prior captain-reports have the Feedback ID archived at `claude/workstreams/the-agency/history/flotsam/captain-reports/`, link from the per-item detail file (not the registry).
- **Pattern:** many filings cluster around `/feedback` reliability, Computer Use MCP permissions, and multi-agent/multi-session identity. These are known pain points.

## Conventions

- Status transitions: `open` → `acknowledged` → `in-progress` → `resolved` / `wontfix`
- Check issue state periodically via `gh issue list --repo anthropics/claude-code --author jordandm --state all`
- When Anthropic responds, move row Open → Closed with resolution note
- Per-item detail files for newer feedback live alongside this registry as `feedback-{YYYYMMDD}-{slug}.md`
- Historical detail files live in `claude/workstreams/the-agency/history/flotsam/captain-reports/`
