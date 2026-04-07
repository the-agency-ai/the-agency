# Getting Started with The Agency

## Prerequisites

- **Claude Code** CLI installed and authenticated
- **Git** initialized repo
- Familiarity with Claude Code basics (sessions, tools, skills)

## Install

> **Note:** `agency init` is not yet available as a standalone command. Manual setup below.

### Manual Setup

1. Clone or copy the `claude/` directory into your project root
2. Copy `.claude/settings.json` from the template:
   ```bash
   cp claude/config/settings-template.json .claude/settings.json
   ```
3. Create your root `CLAUDE.md` with the framework import:
   ```markdown
   @claude/CLAUDE-THEAGENCY.md
   ```
4. Configure your principal in `claude/config/agency.yaml`:
   ```yaml
   principals:
     your_username:          # $USER on your machine
       name: yourname        # principal slug
       display_name: "Your Name"
   ```
5. Create your sandbox: `mkdir -p usr/yourname/`

### What You Get

- `claude/` — framework tools, docs, agent classes, hooks, and methodology
- `claude/tools/` — CLI tools with built-in logging and telemetry
- `claude/hookify/` — behavioral rules (warn/block) enforced mechanically
- `.claude/skills/` — framework skills (auto-discovered by Claude Code, invoke via `/`)
- `.claude/agents/` — agent registrations (launch via `claude --agent <name>`)
- `CLAUDE.md` — your project's agent-facing instructions (imports methodology via `@claude/CLAUDE-THEAGENCY.md`)
- `usr/yourname/` — your sandbox (handoffs, dispatches, transcripts, tools)

### Permissions

The settings template ships with broad permissions:
```json
{
  "permissions": {
    "allow": ["Bash(*)", "Read(**)", "Edit(**)", "Write(**)"]
  }
}
```
Behavioral enforcement is handled by hookify rules, not the permission system. The project boundary is the security boundary.

## Verify Setup

```bash
# Check tools are accessible
./claude/tools/agent-identity

# Check ISCP database initializes
./claude/tools/dispatch list

# Check settings are loaded
claude --print-settings | head
```

## Next Steps

1. Explore skills: type `/` in Claude Code to see the skill list
2. Start a discussion: `/discuss`
3. When ready to build: `/define` to create a Product Vision & Requirements (PVR)
4. Read the methodology: `claude/README-THEAGENCY.md` for the full orientation

## Key Concepts

- **Valueflow** — the development lifecycle: Seed → Define (PVR) → Design (A&D) → Plan → Implement → Ship
- **ISCP** — inter-session communication: dispatches (structured messages) and flags (quick-capture observations)
- **Quality Gates** — tiered gates at every commit boundary (T1 iteration → T4 pre-PR)
- **Enforcement Triangle** — every capability has a tool + skill + hookify rule
- **Handoffs** — session continuity files that bootstrap context across sessions

## House Rules

TheAgency has rules. We enforce them mechanically — hooks, hookify rules, quality gates. Not suggestions. Not guidelines. Rules.

Why? Because agents forget prose. Humans forget prose. Mechanical enforcement doesn't forget.

*OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*
