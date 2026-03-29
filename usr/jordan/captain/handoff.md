# Captain Handoff

**Agent:** captain (housekeeping)
**Principal:** jordan
**Updated:** 2026-03-29

## This Session

### Ghostty Terminal Config (Recurring Issue)
- Text was unreadable — bare hex color values (`background = 282828`) were overriding the theme without `#` prefixes, causing Ghostty to render wrong colors
- **Fix:** Removed redundant `background`/`foreground` overrides, let `theme` handle colors
- Switched theme from **Gruvbox Dark** to **GitHub Light Default**
- Changed font from SF Mono 13 to **JetBrains Mono 14**
- Changed `window-theme` from `dark` to `light`
- Ran `tools/ghostty-setup` which appended Agency integration config (shell-integration, clipboard, confirm-close, mouse-hide)
- Saved a feedback memory (`feedback_ghostty_colors.md`) to prevent this from recurring
- **Config location:** `~/.config/ghostty/config`
- **User needs to restart Ghostty** to see changes

### Session Resume
- User mentioned they will start using session resume (Claude Code `--resume` flag)

## Prior State (from previous handoff)

### Infrastructure
- 6 hooks wired in settings.json: ref-injector, session-handoff, quality-check, plan-capture, branch-freshness, tool-telemetry
- 15 hookify rules in `claude/hookify/` — behavioral guardrails
- Worktree tools — worktree-create, worktree-list, worktree-delete
- `_path-resolve` — principal-aware path resolution
- `/discuss` skill — structured 1B1 discussion protocol

### Directory Layout
- Principal v2: `usr/jordan/` (replaces `claude/principals/`)
- Agent dirs: `usr/jordan/captain/`, `usr/jordan/markdown-pal/`, `usr/jordan/mock-and-mark/`

### Recent Completed Work
- Per-service DB isolation (commit 23e75a8) — 28,909 rows migrated, all 10 services healthy
- Plan artifact convention with TaskCompleted hook and REQUEST linkage
- Inline status line replacing statusline.sh
- Agency 2.0 merged into main (hooks, hookify rules, worktree tools, new agents)

## Pending / Next Steps
1. **Restart Ghostty** to apply GitHub Light Default theme + JetBrains Mono 14
2. **MarkdownPal PVR/A&D session** — use `/discuss` with seeds at `usr/jordan/markdown-pal/`
3. **MockAndMark PVR/A&D session** — use `/discuss` with seeds at `usr/jordan/mock-and-mark/`
4. **CoS setup** — optional, for fleet management across agents
5. Untracked files in working tree (changelogs, docs, reviews) — need cleanup or commit

## Untracked Files
- `claude/CHANGELOG-2026-02-28-2.1.17-2.1.63.md`
- `claude/CHANGELOG-2026-03-05-2.1.64-2.1.69.md`
- `claude/CHANGELOG-2026-03-08-2.1.70-2.1.71.md`
- `claude/CHANGELOG-2026-03-17-2.1.60-2.1.77.md`
- `claude/docs/UNUSED-CLAUDE-CODE-FEATURES.md`
- `claude/reviews/`
