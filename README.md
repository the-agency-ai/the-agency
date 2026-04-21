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

## Getting Started

Install the framework into any git repo:

```bash
cd your-project
git init                                      # if not already a repo
curl -sL https://raw.githubusercontent.com/the-agency-ai/the-agency/main/agency/tools/agency-bootstrap.sh \
  | bash -s -- --principal <your-name> --project <project-name>
```

Use angle-bracket placeholders literally — the bootstrap refuses them, forcing you to supply real values instead of copy-pasting example identities.

See `agency/README-GETTINGSTARTED.md` (shipped to the adopter install) for detailed setup instructions, and `agency/CLAUDE-THEAGENCY.md` for the methodology.

## Repository Structure

This is the framework-dev repo. A fresh `agency init` install in your own project produces a subset of this layout (no `src/`, no framework-dev tooling).

```
the-agency/
├── .agency/                      # install-state metadata
├── .agency-setup-complete        # init sentinel
├── .claude/                      # Claude Code harness dir
│   ├── agents/                   # agent registrations (per-instance)
│   ├── commands/                 # /slash commands
│   ├── hooks/                    # SessionStart/PreToolUse/etc. hooks
│   ├── settings.json             # harness config (hooks, permissions)
│   └── skills/                   # skill bodies (+ sidecars)
├── agency/                       # framework install (dual-tracked build output)
│   ├── CLAUDE-THEAGENCY.md       # methodology constitution
│   ├── LICENSE.md                # framework license (MIT)
│   ├── README/                   # framework README docs (ENFORCEMENT, SAFE-TOOLS, …)
│   ├── REFERENCE/                # ~32 customer-facing REFERENCE-*.md docs
│   ├── agents/                   # 10 canonical agent classes (captain, tech-lead, reviewers, …)
│   ├── config/                   # manifest.json, agency.yaml, registry.json, settings-template.json
│   ├── hooks/                    # bash hook scripts (block-raw-tools, etc.)
│   ├── hookify/                  # declarative hook rules (.md)
│   ├── templates/                # scaffold templates (CLAUDE-PROJECT, HANDOFF-BOOTSTRAP, …)
│   ├── tools/                    # 60+ runtime tools (agency, session-pause, dispatch, …)
│   └── workstreams/              # per-workstream artifacts (PVR/A&D/Plan/QGR/history)
├── src/                          # framework-dev sources (NOT shipped to adopter)
│   ├── apps/                     # {mdpal, mdpal-app, mdslidepal-mac, mdslidepal-web, mock-and-mark}
│   ├── archive/                  # retired code preserved for provenance
│   ├── assets/                   # brand assets
│   ├── integrations/             # external-tool integrations (claude-desktop, …)
│   ├── REFERENCE/                # framework-dev-only REFERENCE docs
│   ├── tests/                    # BATS + vitest suites (tools/, skills/, agents/, docs/)
│   ├── tools/                    # framework-dev-only tools (build, release-cut, sweep, …)
│   └── tools-developer/          # dev-side tooling (skill-audit, upstream-port, …)
├── usr/                          # principal sandboxes
│   └── {principal}/              # handoffs, dispatches, transcripts, flashcards, tools
├── CLAUDE.md                     # bootloader @import of agency/CLAUDE-THEAGENCY.md
├── CHANGELOG.md
├── CODE_OF_CONDUCT.md
├── CONTRIBUTING.md
├── LICENSE                       # repo-level MIT (framework open core)
├── README.md                     # this file
├── package.json                  # pnpm workspace declaration for src/apps/* services
└── .github/                      # CI + release automation
```

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
