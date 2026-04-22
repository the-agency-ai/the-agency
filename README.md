# TheAgency

An opinionated multi-agent development framework for Claude Code.

## Overview

TheAgency is a convention-over-configuration system for running multiple Claude Code agents that collaborate on a shared codebase alongside one or more humans (Principals). Built for developers who want to scale their AI-assisted development workflows.

## 📋 Join the Community

[**Register for TheAgency Community**](https://docs.google.com/forms/d/e/1FAIpQLSfkH2bE1LB39u5iU-BamxbVC6jHmyDEE0TB6G2yw7xODdS-1A/viewform?usp=header) - Add yourself to TheAgency community!

## Key Features

- **Multi-Agent Classes** — Specialized Claude Code instances (captain, tech-lead, reviewers, devex, designex, mdpal, mock-and-mark, …) with persistent per-session context
- **Workstreams** — Organized areas of work with shared PVR / A&D / Plan / KNOWLEDGE artifacts
- **ISCP** (Inter-Session Collaboration Protocol) — Dispatches + flags routed through a local SQLite DB so agents coordinate across sessions and worktrees
- **Quality Gates** — Enforced correctness via pre-commit hooks, parallel reviewer agents, and hash-chained QGR/RGR receipts
- **Session Lifecycle** — `session-pause` / `session-pickup` primitives capture PAUSE/PICKUP state so work survives `/compact`, `/exit`, and multi-day gaps
- **Hookify** — Declarative hook rules that warn or block dangerous shell patterns (bare `git`, `rm -rf`, cross-worktree copies, etc.)

## Quick Start — `agency init`

Install TheAgency into any git repo with one curl-bash. No clone needed.

```bash
cd your-project
git init                                          # if not already a repo
curl -sL https://raw.githubusercontent.com/the-agency-ai/the-agency/main/agency/tools/agency-bootstrap.sh \
  | bash -s -- --principal your-name --project your-project-name
```

Pin to a specific release (recommended for reproducible installs):

```bash
curl -sL https://raw.githubusercontent.com/the-agency-ai/the-agency/main/agency/tools/agency-bootstrap.sh \
  | bash -s -- --principal your-name --project your-project-name --from-github v46.19
```

**Do NOT copy-paste angle brackets** — use literal names. The bootstrap refuses `<your-name>` style placeholders on purpose so you don't accidentally install an agent called `<your-name>`.

After install you have a working `agency` CLI at `./agency/tools/agency`, a captain agent registered under `usr/your-name/captain/`, and Claude Code integration wired up in `.claude/`.

See `agency/README-GETTINGSTARTED.md` (shipped to the adopter install) for detailed first-session walkthrough, and `agency/CLAUDE-THEAGENCY.md` for the methodology.

## Staying Up to Date — `agency update`

Once TheAgency is installed in your repo, pull framework updates directly from GitHub — no clone or git-remote management required.

```bash
# Preview what would change (no writes):
./agency/tools/agency update --from-github --dry-run

# Apply latest main:
./agency/tools/agency update --from-github

# Pin to a specific release tag:
./agency/tools/agency update --from-github v46.19

# Aggressive cleanup — remove orphaned framework files (prompts for confirmation):
./agency/tools/agency update --from-github --prune
```

`agency update` is **additive by default** — it adds new files and updates existing framework files, but leaves your `usr/`, workstreams, and any registered `protected_paths` alone. Use `--prune` when you want to clean up files that have been retired upstream.

## What you get — `agency init` vs cloning this repo

There are two audiences, and they get two different trees.

### 1. Adopter install — `agency init` in your project

You get the framework install plus your sandbox. Nothing else.

```
your-project/
├── .agency/                   # install-state metadata
├── .agency-setup-complete     # init sentinel
├── .claude/                   # Claude Code harness (agents, hooks, skills, commands, settings)
├── agency/                    # framework: tools, agent classes, REFERENCE docs, hookify rules,
│                              #           hooks, templates, config, workstreams
├── usr/
│   └── your-name/
│       └── captain/           # your captain sandbox (handoffs, dispatches, …)
├── CLAUDE.md                  # bootloader → @imports agency/CLAUDE-THEAGENCY.md
└── (your existing repo files)
```

Everything under `agency/` is the framework build-product — `agency init` copies it in, `agency update --from-github` keeps it current. You don't edit framework files; you add your own work under `usr/`, `agency/workstreams/`, and your project's own tree.

### 2. Framework-dev clone — `git clone the-agency`

You get all of the adopter install, PLUS the sources and dev tooling needed to **build** the framework.

```
the-agency/
├── .agency/ .agency-setup-complete .claude/ agency/ usr/    # same as adopter install
├── CLAUDE.md LICENSE README.md CHANGELOG.md                  # repo-level files
├── CODE_OF_CONDUCT.md CONTRIBUTING.md                        # contributor-only
├── package.json                                              # pnpm workspace for src/apps/*
├── .github/                                                  # CI + release automation
└── src/                                                      # ← framework-dev only
    ├── agency/                # source-of-truth — builds to agency/
    ├── claude/                # source-of-truth — builds to .claude/ (shippable subset)
    ├── apps/                  # {mdpal, mdpal-app, mdslidepal-mac, mdslidepal-web, mock-and-mark}
    ├── archive/               # retired code preserved for provenance
    ├── assets/                # brand assets (not shipped)
    ├── integrations/          # external-tool integrations (claude-desktop, …)
    ├── REFERENCE/             # framework-dev-only REFERENCE docs
    ├── tests/                 # BATS + vitest suites (tools/, skills/, agents/, docs/)
    ├── tools/                 # framework-dev-only tools (build, release-cut, sweep, …)
    └── tools-developer/       # dev-side tooling (skill-audit, upstream-port, …)
```

The `src/` tree is the source-of-truth. `agency/` and `.claude/` in this repo are build products — regenerated by `src/tools/build` and committed for dual-tracking. **If you're contributing to TheAgency itself**, edit files under `src/` and re-run the build. **If you're building on top of TheAgency**, use `agency init` in your own repo — you don't need `src/` at all.

## Documentation

- [`CLAUDE.md`](CLAUDE.md) — repo bootloader
- [`agency/CLAUDE-THEAGENCY.md`](agency/CLAUDE-THEAGENCY.md) — methodology constitution (the-how)
- [`agency/REFERENCE/`](agency/REFERENCE/) — 32+ `REFERENCE-*.md` specs (ISCP protocol, handoff spec, skill conventions, QG protocol, …)
- [`agency/README-GETTINGSTARTED.md`](agency/README-GETTINGSTARTED.md) — adopter quick-start
- [`agency/README/`](agency/README/) — enforcement, receipt infrastructure, safe-tools surface

## Versioning

`agency_version` in `agency/config/manifest.json` follows `{day}.{release}` (e.g. `46.5` = Day 46 Release 5). Released via daily cron (or ad-hoc via `agency/tools/release-cut`). Tags: `v{day}.{release}` + `agency-v{major}` symbolic.

## For Contributors

See [CONTRIBUTING.md](CONTRIBUTING.md) for how to:
- Submit starter packs (framework templates for new tech stacks)
- Improve core tools (bash + Python stdlib; see `agency/tools/*` + `src/tools/*`)
- Report issues

## Licensing

Open-core model:

- **Framework** (tools, agent classes, methodology, REFERENCE docs, hookify rules) — [MIT License](LICENSE)
- **App workstreams** (Markdown Pal, Mock and Mark, and other apps/services in `src/apps/*`) — Reference Source License per-app (view, contribute, no commercial redistribution)

Each app workstream directory contains its own `LICENSE` file.

---

*TheAgency — Multi-agent development, done right.*
