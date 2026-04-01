---
allowed-tools: Bash(bash $CLAUDE_PROJECT_DIR/claude/tools/upstream-port *)
description: Port files from monofolk to the-agency — auto path mapping, PR creation
---

# Upstream Port

Port tools, skills, hookify rules, and docs from monofolk to the-agency framework repo. Auto-maps paths between the two repos.

## Arguments

- `$ARGUMENTS`: Source file path (relative to repo root), plus optional flags.

## Instructions

### Step 1: Run the tool

```
bash $CLAUDE_PROJECT_DIR/claude/tools/upstream-port $ARGUMENTS
```

Common patterns:
```
# Port a tool
bash $CLAUDE_PROJECT_DIR/claude/tools/upstream-port claude/tools/flag

# Port a skill (auto-maps commands/X.md → .claude/skills/X/SKILL.md)
bash $CLAUDE_PROJECT_DIR/claude/tools/upstream-port claude/usr/jordan/commands/flag.md

# Port with auto-merge
bash $CLAUDE_PROJECT_DIR/claude/tools/upstream-port claude/tools/flag --auto-merge

# Port to custom path
bash $CLAUDE_PROJECT_DIR/claude/tools/upstream-port docs/design.md --target claude/docs/design/design.md
```

### Step 2: Verify

The tool creates a PR in the-agency. If `--auto-merge` was used, it merges immediately. Otherwise, report the PR URL to the user.

### Step 3: Create dispatch (optional)

If porting significant work, create a dispatch for the-agency to review:
```
/dispatch create captain port-<name>
```

*OFFENDERS WILL BE FED TO THE — CUTE — ATTACK KITTENS!*
