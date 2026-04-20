---
description: Port files from a source repo to the-agency — auto path mapping, PR creation
---

<!--
  Flag #62/#63: allowed-tools removed. Inherits Bash(*) from
  .claude/settings.json. Restricting to specific subcommand patterns at the
  skill level silently blocks agents on permission prompts the agent cannot
  see — see dispatch #171 for the devex incident that surfaced this trap.
-->

# Upstream Port

Port tools, skills, hookify rules, and docs from a source repo to the-agency framework repo. Auto-maps paths between the two repos.

## Arguments

- `$ARGUMENTS`: Source file path (relative to repo root), plus optional flags.

## Instructions

### Step 1: Run the tool

```
bash $CLAUDE_PROJECT_DIR/agency/tools/upstream-port $ARGUMENTS
```

Common patterns:
```
# Port a tool
bash $CLAUDE_PROJECT_DIR/agency/tools/upstream-port agency/tools/flag

# Port a skill (auto-maps commands/X.md → .claude/skills/X/SKILL.md)
bash $CLAUDE_PROJECT_DIR/agency/tools/upstream-port usr/{principal}/commands/flag.md

# Port with auto-merge
bash $CLAUDE_PROJECT_DIR/agency/tools/upstream-port agency/tools/flag --auto-merge

# Port to custom path
bash $CLAUDE_PROJECT_DIR/agency/tools/upstream-port docs/design.md --target claude/docs/design/design.md
```

### Step 2: Verify

The tool creates a PR in the-agency. If `--auto-merge` was used, it merges immediately. Otherwise, report the PR URL to the user.

### Step 3: Create dispatch (optional)

If porting significant work, create a dispatch for the-agency to review:
```
/dispatch create captain port-<name>
```

*OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*
