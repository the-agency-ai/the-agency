# Getting Started with The Agency

## Prerequisites

- **Claude Code** CLI installed and authenticated
- **Git** repo initialized (`git init`)
- The Agency framework cloned somewhere on your machine. The default location is `~/code/the-agency/`. The `agency` tool detects its own source location, so any path works — `~/code/the-agency/` is just convention.

## Key Concepts (Read First)

Before installing, here are the terms you'll see throughout the docs:

- **Valueflow** — the development lifecycle: `Gleam → Seed → Research (MARFI) → Define (PVR) → Design (A&D) → Plan → Implement → Ship → Value`
- **PVR** — Product Vision & Requirements (the *what* and *why*)
- **A&D** — Architecture & Design (the *how* and *why*)
- **MARFI** — Multi-Agent Request for Information (research)
- **MAR** — Multi-Agent Review (multiple agents review every artifact)
- **ISCP** — Inter-Session Communication Protocol (dispatches + flags)
- **QGR** — Quality Gate Report (proof a gate ran)
- **Three-Bucket Pattern** — feedback triage: Disagree, Autonomous, Collaborative
- **Enforcement Triangle** — every capability has tool + skill + hookify rule
- **Hookify** — behavioral rules (block/warn) enforced mechanically

For the full methodology, read `claude/README-THEAGENCY.md`.

## Install

```bash
cd ~/code/my-project
~/code/the-agency/claude/tools/agency init
```

This installs the framework into your repo:
- `claude/` — tools, docs, agent classes, hooks, hookify rules, and methodology
- `.claude/` — settings, skills, agent registrations (Claude Code discovery location)
- `CLAUDE.md` — your project's agent-facing instructions (imports `@claude/CLAUDE-THEAGENCY.md`)
- `usr/{principal}/` — your sandbox (handoffs, dispatches, transcripts)

After install, the `agency` tool lives at `./claude/tools/agency` in your project. You can either run it with the relative path or symlink it to your `$PATH`:

```bash
# Run from project (always works)
./claude/tools/agency verify

# Or add to PATH (one-time setup)
ln -s ~/code/my-project/claude/tools/agency ~/.local/bin/agency
agency verify
```

### Install Options

```bash
# Override principal name (defaults to $USER mapping in agency.yaml)
~/code/the-agency/claude/tools/agency init --principal jordan

# Set project name explicitly
~/code/the-agency/claude/tools/agency init --project my-project

# Initialize a different directory
~/code/the-agency/claude/tools/agency init ~/code/other-project
```

## Verify

```bash
./claude/tools/agency verify
```

Checks provider configuration, required files, and directories. Use `--verbose` for detailed output. Run this immediately after install to confirm everything is in place.

## Update

```bash
./claude/tools/agency update
```

Syncs framework files to the latest version from the source repo. Your project-specific files are preserved — protected paths (from the registry) are never overwritten. Settings are merged via array union (new permissions added, existing kept).

Preview changes without applying:
```bash
./claude/tools/agency update --dry-run
```

Run `agency update` periodically (weekly is reasonable). If you've adopted from a collaboration repo (e.g., monofolk), you'll receive release dispatches notifying you of significant changes.

## Permissions Model

The framework ships with broad permissions:
```json
{
  "permissions": {
    "allow": [
      "Bash(*)",
      "Read(**)",
      "Edit(**)",
      "Write(**)"
    ]
  }
}
```

**Why so broad?** The security model is layered:

1. **Project boundary** — agents can read/write within the project, nothing outside it. The project root is the security perimeter.
2. **Hookify rules** — behavioral enforcement happens at the rule layer, not the permission layer. Rules block raw `git commit`, prevent `cd` to the main repo, force the use of skills over raw tools, enforce QGR receipts, etc. See `claude/README-HOOKIFY.md` for the full list (33 rules).
3. **Git** — version control is the audit trail. Anything an agent does is reviewable.

Narrow permission patterns (the old approach) created friction — every new command triggered a prompt, blocked legitimate work, and didn't actually improve security. Hookify rules enforce intent; permissions enforce scope.

## What You Get

| Directory | What | Example |
|-----------|------|---------|
| `claude/tools/` | CLI tools with logging and telemetry | `dispatch`, `flag`, `handoff`, `git-commit` |
| `claude/hookify/` | Behavioral rules (warn/block) | `hookify.block-git-commit.md` |
| `claude/docs/` | Reference docs (injected on demand) | `QUALITY-GATE.md`, `ISCP-PROTOCOL.md` |
| `claude/agents/` | Agent class definitions | `captain/agent.md`, `tech-lead/agent.md` |
| `claude/hooks/` | Session lifecycle hooks | `ref-injector.sh` |
| `claude/config/agency.yaml` | Principal mapping, providers, collaboration repos | configured during init |
| `.claude/skills/` | Skills (invoke via `/`) | `/handoff`, `/discuss`, `/define` |
| `.claude/agents/` | Agent registrations (launch via `claude --agent`) | `captain.md`, `devex.md` |
| `usr/{principal}/` | Your sandbox | `usr/jordan/captain/` |

## First Session — A Walk-Through

Once installed and verified, your first session looks like this:

1. **Launch Claude Code:** `claude` (in your project root)
2. **Capture a seed:** Tell the agent what you want to build. The agent will capture it as a seed in your workstream.
3. **Discuss it:** Use `/discuss` for structured 1B1 (one-by-one) exploration. The agent presents items, you give feedback, the agent confirms understanding before moving to the next.
4. **Define it:** Use `/define` to create a Product Vision & Requirements (PVR). The agent drives toward completeness via a checklist.
5. **Design it:** Use `/design` to create the Architecture & Design (A&D). Same pattern — checklist-driven.
6. **Plan it:** Once PVR and A&D are stable, the agent creates a Plan with phases and iterations.
7. **Implement:** The agent works through iterations, running quality gates at every commit.

Read `claude/README-THEAGENCY.md` for the full methodology — what each stage does and why.

## House Rules

TheAgency has rules. We enforce them mechanically — hooks, hookify rules, quality gates. Not suggestions. Not guidelines. Rules.

Why? Because agents forget prose. Humans forget prose. Mechanical enforcement doesn't forget.

*OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*
