# Guide: Transition the-agency Captain to Agency 2.0

**For:** Jordan (Principal)
**From:** CoS (monofolk session)
**Date:** 2026-03-29

---

## Background

PR #1 and PR #2 merged Agency 2.0 innovations into the-agency's main branch. This includes new agents, hooks, tools, docs, hookify rules, Ghostty integration, secret provider tools, and the `usr/jordan/` principal directory structure.

The captain in the-agency doesn't know about any of this. It needs to be briefed and transitioned. There's no CoS in the-agency yet, so this is a manual bootstrap.

---

## Steps

### Step 1: Go to the-agency repo on the-agency laptop

Open a terminal on the machine where `jordandm` is the GitHub identity and the-agency is cloned.

```bash
cd ~/code/the-agency
```

### Step 2: Pull main

```bash
git pull origin main
```

This brings in the Agency 2.0 contribution (PR #1) and the tests/tools/Ghostty work (PR #2).

### Step 3: Launch a captain session

```bash
./tools/myclaude housekeeping captain
```

### Step 4: Give the captain this prompt

Copy and paste the following into the captain session:

```
Agency 2.0 has landed on main. Two PRs merged today from the monofolk CoS session:

PR #1: Agency 2.0 contribution — 69 files including new agents (PM, 5 reviewers, CoS),
6 hooks (ref-injector, session-handoff, quality-check, plan-capture, branch-freshness,
tool-telemetry), worktree tools, _path-resolve, 15 hookify rules, /discuss skill,
CLAUDE templates, and reference docs.

PR #2: 58 bats tests, secret-doppler provider, secret-vault rename, Ghostty integration,
CHANGELOG.

Key changes you need to know:
1. usr/jordan/ is the new principal directory (v2). Your handoff is at usr/jordan/captain/handoff.md — read it.
2. tools/secret is now tools/secret-vault. tools/secret-doppler is new.
3. Hookify plugin is enabled in settings.json. 15 behavioral rules in agency/hookify/.
4. 6 new hooks wired in settings.json (SessionStart, PreToolUse[Skill], PreToolUse[ExitPlanMode], PostToolUse, Stop).
5. Development methodology docs are in claude/docs/ (QUALITY-GATE.md, DEVELOPMENT-METHODOLOGY.md, etc.)
6. /discuss skill is available for structured 1B1 discussions.

Please:
1. Read usr/jordan/captain/handoff.md for full context.
2. Read CHANGELOG.md for the complete list of changes.
3. Verify the new hooks and tools are working (run a quick check).
4. Run tools/ghostty-setup if this terminal is Ghostty.
5. Write a new handoff reflecting your updated understanding.
6. Tell me what questions you have or what seems off.
```

### Step 5: Let the captain process

The captain will read the handoff, CHANGELOG, and familiarize itself with the new structure. It may ask questions — answer them.

### Step 6: Ask the captain to do a handoff

```
Write your handoff now, then I'll exit and resume to verify it loads cleanly.
```

### Step 7: Exit and resume

```
/exit
```

Then relaunch:

```bash
./tools/myclaude housekeeping captain
```

The session-handoff hook should inject the captain's new handoff. Verify it loaded. If anything is broken, the captain will tell you.

### Step 8: Come back with issues

If anything fails (hooks not firing, tools not found, permissions errors), note the error and bring it back to the monofolk CoS session. We'll fix it from here.

---

## After Transition

Once the captain is running Agency 2.0, the next steps are:

1. **MarkdownPal PVR/A&D session** — use `/discuss` with the seeds at `usr/jordan/markdown-pal/`
2. **MockAndMark PVR/A&D session** — use `/discuss` with the seeds at `usr/jordan/mock-and-mark/`
3. **Set up CoS** — optional but recommended for fleet management

---

## Troubleshooting

### "Unknown skill: discuss"
The `/discuss` skill is at `.claude/commands/discuss.md`. If it's not found, check:
```bash
ls -la .claude/commands/discuss.md
```

### Hookify rules not firing
Verify the plugin is enabled:
```bash
grep hookify .claude/settings.json
```
Should show `"hookify@claude-plugins-official": true`.

### tools/secret not found
It was renamed to `tools/secret-vault`. If other scripts reference the old name, update them.

### Ghostty setup fails
Requires Ghostty to be installed. Check:
```bash
ls /Applications/Ghostty.app
```
If not installed, skip this step — iTerm2 integration still works via `tools/tab-status`.
