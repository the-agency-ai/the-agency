# Getting Started with The Agency

## Prerequisites

- **Claude Code** CLI installed and authenticated
- **Git** repo initialized (`git init`)
- The Agency framework cloned alongside your project (e.g., `~/code/the-agency/`)

## Install

```bash
cd ~/code/my-project
~/code/the-agency/claude/tools/agency init
```

This installs the framework into your repo:
- `claude/` — tools, docs, agent classes, hooks, hookify rules, and methodology
- `.claude/` — settings, skills, agent registrations (Claude Code discovery location)
- `CLAUDE.md` — your project's agent-facing instructions (imports `@claude/CLAUDE-THEAGENCY.md`)

### Options

```bash
# Override principal name (defaults to $USER mapping in agency.yaml)
agency init --principal jordan

# Set project name explicitly
agency init --project my-project

# Initialize a different directory
agency init ~/code/other-project
```

## Verify

```bash
./claude/tools/agency verify
```

Checks provider configuration, required files, and directories. Use `--verbose` for detailed output.

## Update

```bash
./claude/tools/agency update
```

Syncs framework files to the latest version from the source repo. Your project-specific files are preserved — protected paths (from the registry) are never overwritten. Settings are merged via array union (new permissions added, existing kept).

Preview changes without applying:
```bash
./claude/tools/agency update --dry-run
```

## What You Get

| Directory | What | Example |
|-----------|------|---------|
| `claude/tools/` | CLI tools with logging and telemetry | `dispatch`, `flag`, `handoff`, `git-commit` |
| `claude/hookify/` | Behavioral rules (warn/block) | `hookify.block-git-commit.md` |
| `claude/docs/` | Reference docs (injected on demand by hooks) | `QUALITY-GATE.md`, `ISCP-PROTOCOL.md` |
| `claude/agents/` | Agent class definitions | `captain/agent.md`, `tech-lead/agent.md` |
| `claude/hooks/` | Session lifecycle hooks | `ref-injector.sh`, `quality-check.sh` |
| `.claude/skills/` | Skills (auto-discovered, invoke via `/`) | `/handoff`, `/discuss`, `/define` |
| `.claude/agents/` | Agent registrations (launch via `claude --agent`) | `captain.md`, `devex.md` |
| `usr/{principal}/` | Your sandbox (handoffs, dispatches, transcripts) | `usr/jordan/captain/` |

### Permissions

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

Behavioral enforcement is handled by hookify rules, not the permission system. The project boundary is the security boundary.

## First Session

1. Launch Claude Code: `claude`
2. Explore skills: type `/` to see the skill list
3. Start a discussion: `/discuss`
4. When ready to build: `/define` to create a Product Vision & Requirements (PVR)
5. Read the methodology: `claude/README-THEAGENCY.md` for the full orientation

## Key Concepts

- **Valueflow** — the development lifecycle: Seed → Define (PVR) → Design (A&D) → Plan → Implement → Ship → Value
- **ISCP** — inter-session communication: dispatches (structured messages) and flags (quick-capture observations)
- **Quality Gates** — tiered gates at every commit boundary (T1 iteration → T4 pre-PR)
- **Three-Bucket Pattern** — feedback triage: Disagree, Autonomous, Collaborative
- **Enforcement Triangle** — every capability has a tool + skill + hookify rule
- **Handoffs** — session continuity files that bootstrap context across sessions

## House Rules

TheAgency has rules. We enforce them mechanically — hooks, hookify rules, quality gates. Not suggestions. Not guidelines. Rules.

Why? Because agents forget prose. Humans forget prose. Mechanical enforcement doesn't forget.

*OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*
