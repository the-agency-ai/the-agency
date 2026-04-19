---
title: "Plan: Plugin Provider Framework"
slug: plan-plugin-provider-framework
path: docs/plans/20260330-plan-plugin-provider-framework.md
date: 2026-03-30
status: draft
branch: main
authors:
  - Jordan Dea-Mattson (principal)
  - Claude Code
session: ee9d2ca8-7d2c-47e3-bc99-932128feb706
tags: [Infra]
---

# Plan: Plugin Provider Framework

**Branch:** `feat/plugin-framework`
**Dispatch:** `dispatch-plugin-framework-20260330.md`

## Context

Agency 2.0 needs a pluggable provider model for external service integrations. Some providers already exist (`secret-vault`, `secret-doppler`, `ghostty-setup`, `mac-setup`, `linux-setup`, `figma-diff`, `figma-extract`) but aren't wired through dispatchers. This PR builds the resolution infrastructure, wires dispatchers for 3 of 4 patterns (secrets, terminal, platform), and renames providers to follow convention. Design providers deferred pending Figma MCP evaluation.

## Phases

### Phase 1: Infrastructure
Create `agency/tools/lib/` and build `_provider-resolve`.

**Create: `agency/tools/lib/_provider-resolve`** (~80 lines)
- Sourceable bash lib, follows `_path-resolve` pattern exactly
- Sources `_path-resolve` internally for `AGENCY_PROJECT_ROOT` and `_pr_yaml_get`
- `resolve_provider "secrets"` → reads `secrets.provider` from agency.yaml → returns full tool path
- Naming convention map via case statement (bash 3 safe):
  - `secrets` → `secret-{provider}`
  - `terminal` → `terminal-setup-{provider}`
  - `platform` → `platform-setup-{provider}`
  - `design` → `design-{verb}-{provider}` (verb as $2)
  - default → `{section}-{provider}`
- Validates tool exists, returns path on stdout, exits 1 if not found
- Exports `AGENCY_PROVIDER` and `AGENCY_PROVIDER_TOOL`

**Modify: `agency/config/agency.yaml`**
- Add `terminal.provider: "ghostty"`, `platform.provider: "auto"`, `design.provider: "figma"`

### Phase 2: Secrets Dispatcher
Wire `/secret` skill to existing providers.

**Create: `.claude/commands/secret.md`** (~40 lines)
- Skill instructs Claude to read `secrets.provider` from agency.yaml
- Maps verb to `./tools/secret-{provider} {verb} {args}`
- Handles verb translation: `set` → `create` for vault provider
- Documents available verbs and providers

No changes to `secret-vault` or `secret-doppler` — they already work.

### Phase 3: Terminal Provider
Rename + dispatcher.

**Create: `tools/terminal-setup-ghostty`** (copy from `tools/ghostty-setup`, update tool name/version strings)
**Create: `tools/terminal-setup`** (~50 lines)
- Sources `_provider-resolve`, resolves terminal provider
- Auto-detect fallback from `$TERM_PROGRAM` if provider is unset
- `exec "$PROVIDER_TOOL" "$@"`

**Modify: `tools/ghostty-setup`** → replace with 5-line deprecation shim

### Phase 4: Platform Provider
Rename + dispatcher.

**Create: `tools/platform-setup-macos`** (copy from `tools/mac-setup`, update names)
**Create: `tools/platform-setup-linux`** (copy from `tools/linux-setup`, update names)
**Create: `tools/platform-setup`** (~60 lines)
- Sources `_provider-resolve`, resolves platform provider
- If provider is "auto", detect from `uname -s` (Darwin→macos, Linux→linux)
- `exec "$PROVIDER_TOOL" "$@"`

**Modify: `tools/mac-setup`** → deprecation shim
**Modify: `tools/linux-setup`** → deprecation shim

### Phase 5: Scaffolding & Verification

**Create: `agency/templates/PROVIDER.sh`** (~100 lines)
- Provider template with standard verb interface skeleton
- Sources `_log-helper`, token-conservative output
- Case statement for standard verbs

**Modify: `tools/tool-new`** — add `--provider=<pattern>` flag
- Uses `PROVIDER.sh` template
- Auto-names tool per convention

**Create: `tools/agency-verify`** (~80 lines)
- Iterates secrets, terminal, platform, design sections
- Checks each provider tool exists and is executable
- Token-conservative output: `agency-verify [run: X] / N/N providers valid / ✓`

### Phase 6: agency-init Updates

**Modify: `tools/agency-init`**
- Copy `agency/tools/lib/_provider-resolve` to target
- Add dispatchers to tools copy list: `terminal-setup`, `platform-setup`, `agency-verify`
- Add providers to copy list: `terminal-setup-ghostty`, `platform-setup-macos`, `platform-setup-linux`
- Do NOT copy deprecation shims
- Updated agency.yaml template already includes provider sections

### Phase 7: Permissions & Cleanup

**Modify: `.claude/settings.json`**
- Add permissions for new tools: `terminal-setup*`, `platform-setup*`, `agency-verify*`

## Deferred

- **Design providers** — Figma MCP overlap needs evaluation. `figma-diff`/`figma-extract` stay as-is.
- **New providers** — `secret-aws`, `terminal-setup-kitty`, etc. are future.
- **secret-vault refactor** — 1045 lines, works fine, don't touch it.
- **Verb normalization** — vault `create` vs doppler `set`. Document both, alias later.

## Key Files Reference

- `tools/_path-resolve` (123 lines) — pattern to follow for `_provider-resolve`
- `tools/_log-helper` (212 lines) — logging pattern all tools use
- `agency/config/agency.yaml` (53 lines) — config schema
- `tools/ghostty-setup` (231 lines) → becomes `terminal-setup-ghostty`
- `tools/mac-setup` (171 lines) → becomes `platform-setup-macos`
- `tools/linux-setup` (exists) → becomes `platform-setup-linux`
- `tools/secret-vault` (1045 lines) — leave as-is
- `tools/secret-doppler` (468 lines) — leave as-is
- `tools/tool-new` (176 lines) — add `--provider` flag
- `tools/agency-init` (~420 lines) — ship new files

## Verification

1. `source agency/tools/lib/_provider-resolve && resolve_provider "secrets"` → returns `tools/secret-vault`
2. `./tools/terminal-setup --help` → dispatches to `terminal-setup-ghostty`
3. `./tools/platform-setup --help` → auto-detects OS, dispatches to macos/linux
4. `./tools/ghostty-setup` → prints deprecation, delegates to `terminal-setup-ghostty`
5. `./tools/agency-verify` → reports 4/4 providers valid (or 3/4 if design tool missing)
6. `/secret list` → skill dispatches to `secret-vault list`
7. `./tools/tool-new --provider=secrets test-provider "Test"` → creates `tools/secret-test-provider`
