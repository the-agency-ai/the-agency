# Captain Handoff

**Agent:** captain (housekeeping)
**Principal:** jordan
**Updated:** 2026-03-29 (session 2)

## This Session Summary

Long operational session. Transitioned captain to Agency 2.0, set up three project workstreams, launched two agents, and filed 10 issues.

### What Was Done

1. **Ghostty terminal** — fixed recurring color issue (ISS-001). Switched to GitHub Light Default + JetBrains Mono 14. `ghostty-setup` updated by monofolk CoS.
2. **Read all CoS briefing files** — transition guide, tools unification review (106 tools audited), /secret skill design, full session briefing (7-step plan, decisions, next steps).
3. **Created 3 workstreams + agents:**
   - `markdown-pal` : `markdown-pal` — section-oriented Markdown review tool (Swift/SwiftUI)
   - `mock-and-mark` : `mock-and-mark` — iPad-native visual communication tool for Claude Code
   - `gtm` : `gtm` — Go To Market strategy for Agency 2.0
4. **Filled in all agent definitions** — purpose, responsibilities, seed file references in agent.md and KNOWLEDGE.md for all three.
5. **Registered agents with Claude Code** — created `.claude/agents/{name}.md` files so `claude --agent` works.
6. **Fixed `commit-precheck`** — npm "Missing script" noise eliminated by checking package.json before invoking scripts.
7. **Filed 10 issues** in `usr/jordan/captain/issues-agency2-setup-20260329.md` (shared with monofolk CoS).
8. **PR #7 created** — remove `source/apps/agency-bench/` (ISS-008 dispatch, 12 Dependabot alerts).
9. **Launched markdown-pal and mock-and-mark agents** in worktrees via `claude --agent {name} --name {name}`.
10. **zsh compaudit fix** — chowned `/opt/homebrew/share/zsh` from `jordan_of` to `jdm`. Docker completions still flagged (deferred).

### Open Issues (from issues-agency2-setup-20260329.md)

| Issue | Severity | Status |
|-------|----------|--------|
| ISS-007 | Medium | Open — agent-create must register in .claude/settings.json |
| ISS-008 | High | PR #7 open — remove agency-bench for Dependabot alerts |
| ISS-009 | Low | Open — status line redundant worktree naming |
| ISS-010 | Medium | Open — agent name not in terminal tabs (`tab-status` reads `$AGENTNAME` which myclaude set; `claude --agent` and `--name` don't flow through to hooks) |

### Agents Currently Running

- **markdown-pal** — launched in worktree, PVR/A&D discussion in progress
- **mock-and-mark** — launched in worktree, PVR/A&D discussion in progress

Launch commands:
```bash
claude --agent markdown-pal --name markdown-pal
claude --agent mock-and-mark --name mock-and-mark
```

### Git State

- Branch: `main` (up to date with origin after rebase)
- PR branch `fix/remove-agency-bench` pushed, PR #7 open
- Working tree: clean
- `.claude/agents/` directory with 3 agent files (uncommitted — created after last commit)

## Key Context

### 7-Step Tools Unification Plan
1. Review (done), 2. Extract + formalize (next), 3. Gap analysis, 4. Update existing, 5. Fill gaps, 6. Port next-gen, 7. Leave legacy alone.

### Key Files
- `usr/jordan/captain/issues-agency2-setup-20260329.md` — all issues
- `usr/jordan/captain/transcript-workstream-setup-20260329.md` — session transcript
- `usr/jordan/captain/dispatch-remove-agency-bench-20260329.md` — dispatch (in progress, PR #7)
- `usr/jordan/captain/guide-cos-session-briefing-20260329.md` — full CoS context

### Pending / Next Steps

1. **ISS-010 investigation** — what env vars does Claude Code expose to hooks? Need to fix `tab-status` agent name detection.
2. **Merge PR #7** — agency-bench removal, should clear Dependabot alerts.
3. **Commit `.claude/agents/`** — the 3 agent definition files need to be committed.
4. **Push issues + transcript + handoff** to origin.
5. **Tools unification step 2** — extract + formalize the framework spec.
6. **Migrate principals** — `claude/principals/jordan/` → `usr/jordan/`.
7. **Agency init/update design** — 7 scenarios, needs 1B1 session.
8. **GTM agent** — ready to launch when scope is defined.
