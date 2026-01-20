# Principals Guide

Principals are the human stakeholders who direct work in The Agency. This guide covers principal management, setup, and tooling.

## What is a Principal?

A principal is a human identity in The Agency. Each principal has:
- A unique name (lowercase, alphanumeric with hyphens/underscores)
- A directory under `claude/principals/{name}/`
- Work requests (`REQUEST-{name}-XXXX`)
- Artifacts produced by agents
- Configuration preferences

Principals direct work by creating requests and receiving artifacts from agents.

## Quick Reference

| Task | Command |
|------|---------|
| First-time setup | `./tools/setup-agency` |
| Add yourself to existing project | `./tools/add-principal` |
| Create principal programmatically | `./tools/principal-create <name>` |
| Get current principal | `./tools/principal` |
| Check principal env var | `echo $AGENCY_PRINCIPAL` |

## First-Time Setup

When you create a new Agency project, run `setup-agency` before your first Claude Code session:

```bash
./tools/setup-agency
```

This interactive tool:
1. Prompts for your principal name
2. Validates the name format
3. Creates your principal directory from template
4. Sets `AGENCY_PRINCIPAL` in your shell profile
5. Initializes the secret vault
6. Creates `.agency-setup-complete` marker

**Example session:**
```
$ ./tools/setup-agency

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  The Agency - First Time Setup
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

What's your name? This will be your principal identity.

Principal name [jdm]: alice

[STEP] Creating principal: alice
[STEP] Updating configuration...
[STEP] Setting up environment...
[STEP] Initializing secret vault...

Set vault passphrase: ********
Confirm passphrase: ********

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Setup Complete!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Welcome, alice!
```

### Non-Interactive Mode

For automation, pass the principal name directly:

```bash
./tools/setup-agency --principal alice --skip-vault
```

## Joining an Existing Project

When you clone an existing Agency project, use `add-principal` to add yourself:

```bash
./tools/add-principal
```

This tool:
1. Prompts for your principal name
2. Creates your principal directory
3. Sets `AGENCY_PRINCIPAL` in your shell profile
4. Does NOT reinitialize the vault (already exists)

### Non-Interactive Mode

```bash
./tools/add-principal --name bob
```

## Creating Principals Programmatically

For scripts or automation, use `principal-create`:

```bash
./tools/principal-create alice [projectname] [--verbose]
```

Arguments:
- `principalname` - Name for the principal (required)
- `projectname` - Optional: project name for iCloud setup
- `--verbose` - Show detailed logging

This tool creates the directory structure but does NOT:
- Set environment variables
- Modify shell profiles
- Initialize the vault

Use `setup-agency` or `add-principal` for interactive setup.

## Getting the Current Principal

The `principal` tool returns the current principal name:

```bash
./tools/principal
# Output: alice
```

It checks (in order):
1. `PRINCIPAL` environment variable
2. Config lookup via `./tools/config get-principal`

### In Scripts

```bash
PRINCIPAL=$(./tools/principal)
echo "Current principal: $PRINCIPAL"
```

## Environment Variable

The `AGENCY_PRINCIPAL` environment variable identifies you across sessions:

```bash
# Set automatically by setup-agency/add-principal in your shell profile
export AGENCY_PRINCIPAL="alice"
```

This is added to your shell profile (`.zshrc`, `.bashrc`, or `.bash_profile`) during setup.

**Reload your shell after setup:**
```bash
source ~/.zshrc  # or ~/.bashrc
```

## Principal Directory Structure

```
claude/principals/{name}/
├── README.md           # Principal overview
├── requests/           # Work requests (REQUEST-{name}-XXXX.md)
├── artifacts/          # Deliverables from agents (ART-XXXX.md)
├── resources/          # Reference materials
│   ├── cloud/          # Symlink to iCloud (if set up)
│   └── secrets/        # Credentials (gitignored)
└── config/             # App configurations
    └── iterm/          # iTerm2 profiles
```

## Configuration Mapping

The `claude/config/agency.yaml` file maps system usernames to principal names:

```yaml
principals:
  jdm: alice       # System user 'jdm' is principal 'alice'
  bob: bob         # System user 'bob' is principal 'bob'
```

This allows multiple people on shared machines to have different principals.

## Name Validation

Principal names must:
- Start with a letter
- Contain only letters, numbers, hyphens, and underscores
- Be converted to lowercase automatically

**Valid:** `alice`, `bob-smith`, `user_123`
**Invalid:** `123user`, `alice!`, `bob@work`

## Integration with myclaude

The `myclaude` launcher checks principal status on every launch:

1. **Is this an Agency project?** - Looks for `claude/config/agency.yaml`
2. **Is this the starter template?** - Checks for `.agency-starter` marker
3. **Is setup complete?** - Checks for `.agency-setup-complete`
4. **Is AGENCY_PRINCIPAL set?** - Checks environment variable
5. **Does principal directory exist?** - Checks `claude/principals/$AGENCY_PRINCIPAL/`

If any check fails, `myclaude` guides you through the appropriate setup.

## Troubleshooting

### "AGENCY_PRINCIPAL not set"

Your shell profile wasn't updated or you haven't reloaded it:

```bash
# Check if set
echo $AGENCY_PRINCIPAL

# If empty, either:
# 1. Re-run setup
./tools/setup-agency

# 2. Or manually add to your profile
echo 'export AGENCY_PRINCIPAL="yourname"' >> ~/.zshrc
source ~/.zshrc
```

### "Principal directory doesn't exist"

The environment variable is set but the directory is missing:

```bash
./tools/add-principal --name $AGENCY_PRINCIPAL
```

### "This is the starter template"

You're trying to set up directly in the-agency-starter. Create a project first:

```bash
./tools/project-create my-project
cd ../my-project
./tools/setup-agency
```

## Tool Reference

### setup-agency

First-time Agency project setup.

```
Usage: setup-agency [options]

Options:
  --principal NAME   Set principal name (skips prompt)
  --skip-vault       Skip vault initialization
  --verbose          Show detailed output
  -v, --version      Show version
  -h, --help         Show help
```

### add-principal

Add yourself to an existing Agency project.

```
Usage: add-principal [options]

Options:
  --name NAME        Set principal name (skips prompt)
  --verbose          Show detailed output
  -v, --version      Show version
  -h, --help         Show help
```

### principal-create

Create a principal directory (non-interactive).

```
Usage: principal-create <name> [projectname] [--verbose]

Arguments:
  name           Principal name (required)
  projectname    Project name for iCloud setup (optional)

Options:
  --verbose      Show detailed logging
  -v, --version  Show version
```

### principal

Get the current principal name.

```
Usage: principal [options]

Options:
  --verbose      Show verbose output
  -v, --version  Show version
  -h, --help     Show help
```

## See Also

- [SECRETS.md](SECRETS.md) - Vault and secrets management
- [TERMINAL-INTEGRATION.md](TERMINAL-INTEGRATION.md) - iTerm setup
- `claude/templates/principal/` - Principal directory template
