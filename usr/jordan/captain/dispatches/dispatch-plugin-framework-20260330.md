# Dispatch: Build Plugin Provider Framework

**Date:** 2026-03-30
**From:** CoS (monofolk)
**To:** Captain (the-agency)
**Priority:** High — ASAP

---

## Directive

Build the pluggable provider framework and implement the four provider patterns. This is foundational infrastructure — other work depends on it.

## The Pattern

Every external service integration follows the same model:
- A **dispatcher** (skill or tool) that reads config from `agency.yaml` and delegates
- **Providers** named `{noun}-{provider}` that implement the actual integration
- Config in `agency.yaml` selects the active provider
- Bundled defaults ship with every Agency installation
- Additional providers are plug-in (starter packs, community, custom)

```yaml
# agency.yaml
secrets:
  provider: vault         # default, swap to doppler/aws/1password
terminal:
  provider: ghostty       # default, swap to kitty/wezterm
platform:
  provider: macos         # auto-detected or configured
design:
  provider: figma         # swap to sketch/adobe
```

## Scope of Work

### 1. Secrets (highest priority — already partially built)

**Dispatcher:** `/secret` skill (interactive front-end, 6 verbs: set, get, list, delete, rotate, scan)

**Providers:**
- `secret-vault` — bundled default, zero external deps. Already exists, needs refactor.
- `secret-doppler` — Doppler provider. Already exists, needs refactor.
- Future: `secret-aws`, `secret-1password`, `secret-bitwarden`

**Integration:** `secrets-scan` folds into QG at iteration/phase/PR boundaries.

**Existing work:** `/secret` skill built in monofolk (`usr/jordan/claude/commands/secret.md`). `secret-vault` and `secret-doppler` tools exist in the-agency. Need to wire dispatcher to providers via agency.yaml config.

### 2. Terminal (partially built)

**Dispatcher:** `terminal-setup` tool — detects or asks which terminal, delegates to provider.

**Providers:**
- `terminal-setup-ghostty` — Ghostty provider. Already exists as `ghostty-setup`, needs rename and refactor.
- Future: `terminal-setup-kitty`, `terminal-setup-wezterm`, `terminal-setup-iterm`

**Existing work:** `ghostty-setup` tool exists. `ghostty-status.sh` hook exists. Rename and wire to dispatcher.

### 3. Platform (needs building)

**Dispatcher:** `platform-setup` tool — auto-detects OS, delegates to provider.

**Providers:**
- `platform-setup-macos` — macOS (Homebrew, CLI tools). Exists as `mac-setup`, needs rename and refactor.
- `platform-setup-linux` — Linux (apt/yum, CLI tools). **Needs building — coming soon.**
- `platform-setup-windows` — Windows/PowerShell. **Needs building — coming soon.**

**Existing work:** `mac-setup` exists. Rename, refactor, add OS detection dispatcher.

### 4. Design (needs building)

**Dispatcher:** `design-diff` tool, `design-extract` tool — delegates to provider.

**Providers:**
- `design-diff-figma` — Figma visual diff. Exists as `figma-diff`, needs refactor. Note: Figma MCP now exists — evaluate whether MCP replaces the custom tool.
- `design-extract-figma` — Figma asset/spec extraction. Exists as `figma-extract`, needs refactor.
- Future: Sketch, Adobe XD providers.

**Existing work:** `figma-diff` and `figma-extract` exist. Evaluate Figma MCP overlap first.

## Framework Infrastructure Needed

1. **Provider resolution** — `_path-resolve` or new `_provider-resolve` lib that reads agency.yaml and returns the correct provider tool path
2. **Provider template** — `tool-create` should have a `--provider` flag that scaffolds a provider with the right interface
3. **Validation** — `agency-verify` should check that configured providers exist and are functional
4. **Documentation** — `claude/tools/CLAUDE.md` should explain the plugin pattern for contributors

## Order of Operations

1. Build provider resolution infrastructure (`_provider-resolve` in `claude/tools/lib/`)
2. Secrets — wire dispatcher to existing providers via agency.yaml
3. Terminal — rename `ghostty-setup`, wire dispatcher
4. Platform — rename `mac-setup`, build dispatcher, prioritize Linux provider
5. Design — evaluate Figma MCP overlap, then decide build vs defer

## Acceptance Criteria

- Each dispatcher reads provider from agency.yaml
- Each provider follows the token-conservation wrapper pattern (3-line stdout)
- `agency-init` sets sensible defaults in agency.yaml for all four
- `agency-verify` validates all configured providers
- `tool-create --provider {pattern}` scaffolds new providers with the right interface
