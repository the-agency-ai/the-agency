# Transcript: Dispatch Execution Planning & Execution

**Date:** 2026-03-30
**Agent:** captain
**Principal:** jordan
**Session:** Dispatch execution (post-PR#8 merge)

---

## Context

PR #8 merged — Agency 2.0 CLAUDE.md v2, tech-lead class, captain alignment, iTerm removal. Four dispatches from CoS now need execution.

## Session Start

Captain resumed session. Read PR #8 body from GitHub. Read all 4 dispatches in `usr/jordan/captain/dispatches/`.

### Dispatches (priority order per CoS):

1. **Plugin Framework** (High/ASAP) — `dispatch-plugin-framework-20260330.md`
   - Build provider resolution infra, wire secrets, terminal, platform, design
2. **Agency 2.0 Bootstrap** (High) — `dispatch-agency2-bootstrap-20260330.md`
   - Kill dead agents, build class definitions, re-point live agents
3. **ISCP Design** (High) — `dispatch-iscp-design-20260330.md`
   - File-based real-time agent-to-agent messaging
4. **Browser Protocol** (Medium) — `dispatch-browser-protocol-20260330.md`
   - Escalation ladder: WebFetch → Playwright → screenshot → Docker

## Work Order (agreed with principal)

1. Plan and execute dispatch 1 (plugin framework)
2. Plan and execute dispatch 2 (bootstrap)
3. After 1 & 2: fix worktree/workstream setup for current agents, update handoffs, bootstrap them properly
4. `/discuss` to define and design dispatch 3 (ISCP)
5. `/discuss` to define and design dispatch 4 (browser protocol)

One PR branch per dispatch.

## Decisions

### D-001: Tool location clarification
- `agency/tools/` — tools shipped as part of the-agency framework (copied by agency-init)
- `agency/tools/lib/` — libs those shipped tools use
- `tools/` — internal tools used within this repo only
- Where a tool lives depends on its target audience

**Implication for plugin framework:** `_provider-resolve` goes in `agency/tools/lib/` (it's a lib for shipped tools). Dispatchers and providers that ship with the framework go in `agency/tools/`. Internal-only tools stay in `tools/`.

### D-002: PR strategy
- One branch per dispatch
- `feat/plugin-framework` for dispatch 1
- `feat/agency2-bootstrap` for dispatch 2

---

## Dispatch 1 Plan: Plugin Provider Framework

**Branch:** `feat/plugin-framework`
**Plan file:** `.claude/plans/transient-questing-meerkat.md`

### Phases

1. **Infrastructure** — Create `agency/tools/lib/_provider-resolve` (sourceable bash lib, follows `_path-resolve` pattern). Add terminal/platform/design provider sections to agency.yaml.
2. **Secrets Dispatcher** — Create `.claude/commands/secret.md` skill. Thin dispatcher: reads `secrets.provider` from agency.yaml, delegates to `./tools/secret-{provider}`.
3. **Terminal Provider** — Copy `ghostty-setup` → `terminal-setup-ghostty`. Create `terminal-setup` dispatcher (auto-detects from `$TERM_PROGRAM`). Old name becomes deprecation shim.
4. **Platform Provider** — Copy `mac-setup` → `platform-setup-macos`, `linux-setup` → `platform-setup-linux`. Create `platform-setup` dispatcher (auto-detects from `uname -s`). Old names become shims.
5. **Scaffolding & Verification** — Create `agency/templates/PROVIDER.sh`, add `--provider` flag to `tool-new`, create `tools/agency-verify`.
6. **agency-init Updates** — Ship new files: `_provider-resolve`, dispatchers, providers. Don't ship deprecation shims.
7. **Permissions** — Add new tool permissions to settings.json.

### Deferred
- Design providers (Figma MCP overlap needs evaluation)
- New providers (secret-aws, terminal-setup-kitty, etc.)
- secret-vault refactor (works fine as-is)
- Verb normalization (vault `create` vs doppler `set`)

### Key Design Decisions
- `_provider-resolve` sources `_path-resolve` internally, reuses `_pr_yaml_get` for config parsing
- Naming convention: `secret-{provider}`, `terminal-setup-{provider}`, `platform-setup-{provider}`, `design-{verb}-{provider}`
- Platform supports `"auto"` provider value — detects OS at runtime
- Dispatchers are bash tools (not skills) except `/secret` which is conversational
- Deprecation shims: 5-line scripts that warn and delegate (not symlinks — symlinks break in agency-init copies)

---

## Execution Log

*(Updated as work proceeds)*
