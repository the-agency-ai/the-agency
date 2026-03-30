# Captain Handoff

**Agent:** captain (housekeeping)
**Principal:** jordan
**Updated:** 2026-03-30 (session 5)

## Current State

On branch `feat/plugin-framework` with 7 commits ready for PR. Dispatch 1 of 4 complete.

### Dispatch 1: Plugin Provider Framework — DONE

**Branch:** `feat/plugin-framework` (7 commits, not yet pushed/PR'd)

Built:
1. `claude/tools/lib/_provider-resolve` — sourceable bash lib, reads agency.yaml, resolves provider tool paths
2. `.claude/commands/secret.md` — `/secret` skill dispatcher (6 verbs → `secret-{provider}`)
3. `tools/terminal-setup` — dispatcher (auto-detects from `$TERM_PROGRAM`)
4. `tools/terminal-setup-ghostty` — renamed from `ghostty-setup`
5. `tools/platform-setup` — dispatcher (auto-detects from `uname -s`, supports `"auto"` config)
6. `tools/platform-setup-macos` — renamed from `mac-setup`
7. `tools/platform-setup-linux` — renamed from `linux-setup`
8. `claude/templates/PROVIDER.sh` — provider tool template with verb interface
9. `tools/tool-new` — added `--provider=<pattern>` flag
10. `tools/agency-verify` — validates all configured providers (9/11 passing, 2 design warnings deferred)
11. `tools/agency-init` — updated to ship all new files
12. `.claude/settings.json` — added permissions for new tools
13. `claude/config/agency.yaml` — added terminal, platform, design provider sections
14. Old names (`ghostty-setup`, `mac-setup`, `linux-setup`) → 5-line deprecation shims

**Deferred:** Design providers (Figma MCP overlap needs evaluation), new providers, verb normalization.

### Immediate Next Steps

1. **Push `feat/plugin-framework` and create PR** — ready to merge
2. **Dispatch 2: Agency 2.0 Bootstrap** (`feat/agency2-bootstrap`)
   - Kill 7 dead agents: foundation-alpha, foundation-beta, collaboration, unknown, hub, mission-control, research (instance)
   - Build 3 remaining agent classes: marketing-lead, platform-specialist, researcher
   - Re-point live agents to class definitions
3. **After dispatch 1 & 2 merge:** Fix worktree/workstream setup, update agent handoffs, bootstrap agents
4. **Dispatch 3: ISCP** — `/discuss` session to define and design
5. **Dispatch 4: Browser Protocol** — `/discuss` session to define and design

### Key Technical Decisions (this session)

- `_provider-resolve` sources `_path-resolve` internally, reuses `_pr_yaml_get`
- Naming: `secret-{provider}`, `terminal-setup-{provider}`, `platform-setup-{provider}`, `design-{verb}-{provider}`
- Platform `"auto"` detects OS at runtime
- Dispatchers are bash tools; `/secret` is a skill (conversational)
- Deprecation shims (not symlinks) for old tool names
- `_pr_yaml_get` has a quote-stripping bug — `_provider-resolve` cleans residual quotes itself

### Open Issues

| Issue | Status |
|-------|--------|
| ISS-007 | Open — agent-create must register in settings.json |
| ISS-008 | Open — Dependabot triage |
| ISS-009 | Open — status line redundant worktree naming |
| ISS-012 | Open — worktrees in two locations |

### Transcripts

- `usr/jordan/captain/transcripts/transcript-dispatch-execution-20260330.md` — full execution log

### Git State

- Branch: `feat/plugin-framework` (7 commits ahead of main)
- Working tree: clean
- Not yet pushed to origin
