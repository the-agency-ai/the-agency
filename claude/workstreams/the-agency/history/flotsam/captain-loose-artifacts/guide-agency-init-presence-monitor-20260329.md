# Guide: Initialize presence-monitor with Agency 2.0

**For:** Jordan (Principal)
**From:** CoS (monofolk session)
**Date:** 2026-03-29

---

## Steps

### Step 1: Create the repo

```bash
mkdir ~/code/presence-monitor
cd ~/code/presence-monitor
git init
```

### Step 2: Run agency-init

```bash
~/code/the-agency/tools/agency-init --principal jordan --project presence-monitor --timezone Asia/Singapore
```

This copies the Agency 2.0 framework from the-agency, configures it for presence-monitor, scaffolds `usr/jordan/`, and makes the initial commit.

### Step 3: Set up Ghostty (if using Ghostty)

```bash
./tools/ghostty-setup
```

### Step 4: Launch Claude Code

```bash
claude
```

### Step 5: Bootstrap the captain

Paste this prompt:

```
You are the captain of presence-monitor — a new Agency 2.0 project.

Read CLAUDE.md, claude/docs/DEVELOPMENT-METHODOLOGY.md, and claude/config/agency.yaml.
Verify hooks fired on startup (you should see branch-freshness and session-handoff messages).
Write your first handoff at usr/jordan/captain/handoff.md.
Tell me you're ready and ask what we're building.
```

---

## After Bootstrap

The captain is live. You can:
- Start a project with `/discuss`
- Create worktrees with `./tools/worktree-create <name>`
- Quality gates run automatically via the PM agent

---

## Troubleshooting

### agency-init fails with "Not a git repo"
Run `git init` first.

### agency-init fails with "Agency source not found"
Set the source path: `AGENCY_SOURCE=~/code/the-agency ~/code/the-agency/tools/agency-init`

### Hooks not firing
Check `.claude/settings.json` is present and has hooks wired.

### Hookify rules not active
Verify `"hookify@claude-plugins-official": true` in `.claude/settings.json`.
