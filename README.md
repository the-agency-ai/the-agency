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

**Do NOT copy-paste angle brackets** — use literal names. The bootstrap refuses `<your-name>` style placeholders on purpose so you don't accidentally install an agent called `<your-name>`.

You *can* pin to a specific release by appending `--from-github v46.20` (or any release tag) to the command above. But TheAgency is iterating fast right now — **we suggest staying current with `main`**.

After install you have a working `agency` CLI at `./agency/tools/agency`, a captain agent registered under `usr/your-name/captain/`, and Claude Code integration wired up in `.claude/`.

See `agency/README-GETTINGSTARTED.md` (shipped to the adopter install) for detailed first-session walkthrough, and `agency/CLAUDE-THEAGENCY.md` for the methodology.

## What you Get

`agency init` adds the framework to your repo and creates your principal sandbox. Nothing else — your existing files are untouched.

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

Everything under `agency/` is framework build-product — `agency init` copies it in, `agency update --from-github` keeps it current. You don't edit framework files; you add your own work under `usr/`, `agency/workstreams/`, and your project's existing tree.

## Staying Up to Date — `agency update`

Once TheAgency is installed in your repo, pull framework updates directly from GitHub — no clone or git-remote management required. **We're iterating fast right now — staying current with `main` is the suggested path.**

```bash
# Preview what would change (no writes):
./agency/tools/agency update --from-github --dry-run

# Apply latest main (recommended):
./agency/tools/agency update --from-github

# Aggressive cleanup — remove orphaned framework files (prompts for confirmation):
./agency/tools/agency update --from-github --prune
```

`agency update` is **additive by default** — it adds new files and updates existing framework files, but leaves your `usr/`, workstreams, and any registered `protected_paths` alone. Use `--prune` when you want to clean up files that have been retired upstream.

Need to pin to a specific release? `./agency/tools/agency update --from-github v46.20` (or any release tag). Useful if you hit a regression and need to hold — but we're iterating fast, so staying on `main` is the suggested default.

## This Repo Structure

If you're reading this README, you're looking at the-agency framework-dev repo — the one that *produces* what `agency init` ships. It has everything an adopter install has, PLUS the sources and dev tooling needed to build the framework.

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
    ├── apps/                  # {mdpal, mdpal-app, mdslidepal-mac, mdslidepal-web, mock-and-mark, monofolk-ports}
    ├── archive/               # retired code preserved for provenance
    ├── assets/                # brand assets (not shipped)
    ├── integrations/          # external-tool integrations (claude-desktop, …)
    ├── spec-provider/         # SPEC-PROVIDER starter packs (service-add, ui-add scaffolds)
    ├── tests/                 # BATS + vitest suites (tools/, skills/, agents/, docs/)
    ├── tools/                 # framework-dev-only tools (build, release-cut, sweep, …)
    └── tools-developer/       # dev-side tooling (skill-audit, upstream-port, …)
```

**Dual-tracking contract:** `src/` is the source-of-truth. `agency/` and `.claude/` in this repo are build products — regenerated by `src/tools/build` and committed so adopters can `agency init` directly from a tag without running the build. Contributors: edit under `src/`, re-run the build, commit both. Adopters: you never see `src/`, and you don't need to.

## Documentation

- [`CLAUDE.md`](CLAUDE.md) — repo bootloader
- [`agency/CLAUDE-THEAGENCY.md`](agency/CLAUDE-THEAGENCY.md) — methodology constitution (the-how)
- [`agency/REFERENCE/`](agency/REFERENCE/) — 32+ `REFERENCE-*.md` specs (ISCP protocol, handoff spec, skill conventions, QG protocol, …)
- [`agency/README-GETTINGSTARTED.md`](agency/README-GETTINGSTARTED.md) — adopter quick-start
- [`agency/README/`](agency/README/) — enforcement, receipt infrastructure, safe-tools surface

## Versioning

`agency_version` in `agency/config/manifest.json` follows `{day}.{release}` (e.g. `46.20` = Day 46 Release 20). Released via daily cron (or ad-hoc via `agency/tools/release-cut`). Tags: `v{day}.{release}` + `agency-v{major}` symbolic.

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
