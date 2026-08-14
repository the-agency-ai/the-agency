# Principals Guide

Principals are the human stakeholders who direct work in The Agency. This guide covers principal management, setup, and tooling.

## What is a Principal?

A principal is a human identity in The Agency. Each principal has:
- A unique name (lowercase, alphanumeric with hyphens/underscores)
- A sandbox under `usr/{principal}/{agent}/`
- Work requests (`REQUEST-{name}-XXXX`)
- Artifacts produced by agents
- Configuration preferences

Principals direct work by creating requests and receiving artifacts from agents.

## Quick Reference

| Task | Command |
|------|---------|
| First-time setup / create a project | `./agency/tools/agency init` |
| Add yourself to / join an existing project | `./agency/tools/principal-onboard <name> --user <u> --display-name "..."` |
| Create principal programmatically (bare scaffold) | `./agency/tools/principal-create <name>` |
| Get current principal | `./agency/tools/principal` |
| Check principal env var | `echo $AGENCY_PRINCIPAL` |

## First-Time Setup

When you create a new Agency project in a git repo, run `agency init` before your first Claude Code session:

```bash
./agency/tools/agency init
```

This tool:
1. Initializes Agency in the current git repo
2. Detects (or lets you override) your principal name
3. Scaffolds configuration under `agency/config/`
4. Wires the project so Claude Code can discover skills, agents, and tools

**Options:**
- `--principal <name>` — override the detected principal name
- `--project <name>` — set the project name
- `--timezone <tz>` — set the timezone (default: UTC)
- `--from-github [ref]` — shallow-clone the-agency from GitHub as the source (optional tag/branch/commit; `@latest` for the latest release tag)

**Example:**
```bash
cd ~/code/my-project
./agency/tools/agency init --principal alice --project my-project
```

## Joining an Existing Project

When you clone an existing Agency project, run `principal-onboard` to add yourself as
a principal. It scaffolds your `usr/{name}/` sandbox, mutates `agency/config/agency.yaml`
with your entry, writes your captain agent registration, and bootstraps a captain
handoff — end to end, without reinitializing the project:

```bash
./agency/tools/principal-onboard alice --user alice --display-name "Alice"
```

Required arguments:
- `<name>` — your principal slug (lowercase, alphanumeric + hyphen/underscore)
- `--user <sysuser>` — the system `$USER` value to map this principal to
- `--display-name "..."` — your display name (quote it)

Optional:
- `--email <addr>` — email (repeat the flag for multiple)
- `--github-user <handle>` — GitHub username
- `--repo-name <name>` — repo name for templates (default: auto-detect from git)
- `--force` — overwrite an existing `usr/{name}/`
- `--dry-run` — show what would be done without writing

**Example with full details:**
```bash
./agency/tools/principal-onboard peter --user pyg --display-name "Peter Gao" \
  --email peter@example.com --github-user pgao
```

For a bare, scripted scaffold that only creates the directory (no yaml/agent/handoff
wiring), use `principal-create` (see below).

## Creating Principals Programmatically

For scripts or automation, use `principal-create`:

```bash
./agency/tools/principal-create alice [projectname] [--verbose]
```

Arguments:
- `principalname` - Name for the principal (required)
- `projectname` - Optional: project name for iCloud setup
- `--verbose` - Show detailed logging

This tool creates the directory structure but does NOT:
- Set environment variables
- Modify shell profiles
- Initialize the vault

Use `agency init` for first-time project setup, or `principal-onboard` to add yourself
to an existing project — both do the full config/agent/handoff wiring that
`principal-create` skips.

## Getting the Current Principal

The `principal` tool returns the current principal name:

```bash
./agency/tools/principal
# Output: alice
```

It checks (in order):
1. `PRINCIPAL` environment variable
2. Config lookup via `./agency/tools/config get-principal`

### In Scripts

```bash
PRINCIPAL=$(./agency/tools/principal)
echo "Current principal: $PRINCIPAL"
```

## Environment Variable

The `AGENCY_PRINCIPAL` environment variable identifies you across sessions:

```bash
# Add to your shell profile — principal-onboard prints this export line when it finishes
export AGENCY_PRINCIPAL="alice"
```

Add this to your shell profile (`.zshrc`, `.bashrc`, or `.bash_profile`); `principal-onboard` prints the exact export line at the end of onboarding.

**Reload your shell after setup:**
```bash
source ~/.zshrc  # or ~/.bashrc
```

## Principal Directory Structure

```
usr/{principal}/{agent}/
├── tmp/                # Scratch space (gitignored)
├── tools/              # Agent scripts and ad hoc automation
├── history/            # Archived handoffs and artifacts
│   └── flotsam/        # Discarded drafts and experiments
```

## Configuration Mapping

The `agency/config/agency.yaml` file maps system usernames to principal names:

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

1. **Is this an Agency project?** - Looks for `agency/config/agency.yaml`
2. **Is this the starter template?** - Checks for `.agency-starter` marker
3. **Is setup complete?** - Checks for `.agency-setup-complete`
4. **Is AGENCY_PRINCIPAL set?** - Checks environment variable
5. **Does principal directory exist?** - Checks `usr/$AGENCY_PRINCIPAL/`

If any check fails, `myclaude` guides you through the appropriate setup.

## Troubleshooting

### "AGENCY_PRINCIPAL not set"

Your shell profile wasn't updated or you haven't reloaded it:

```bash
# Check if set
echo $AGENCY_PRINCIPAL

# If empty, either:
# 1. Re-run onboarding (re-prints the export line, re-wires config)
./agency/tools/principal-onboard yourname --user "$USER" --display-name "Your Name"

# 2. Or manually add to your profile
echo 'export AGENCY_PRINCIPAL="yourname"' >> ~/.zshrc
source ~/.zshrc
```

### "Principal directory doesn't exist"

The environment variable is set but the directory is missing:

```bash
./agency/tools/principal-onboard "$AGENCY_PRINCIPAL" --user "$USER" --display-name "$AGENCY_PRINCIPAL"
```

### "This is the starter template"

You're trying to set up directly in the-agency-starter. Create a project first:

```bash
./agency/tools/project-create my-project
cd ../my-project
./agency/tools/agency init
```

## Tool Reference

### agency init

Initialize Agency in a git repo (first-time project setup).

```
Usage: agency init [target-dir] [options]

Options:
  --principal <name>   Override the detected principal name
  --project <name>     Set the project name
  --timezone <tz>      Set timezone (default: UTC)
  --from-github [ref]  Shallow-clone the-agency from GitHub as source
                       (optional tag/branch/commit; @latest = latest release tag)
  --verbose            Show detailed output
  --help, -h           Show help
```

### principal-onboard

End-to-end principal onboarding for an existing project — scaffolds the sandbox,
mutates `agency.yaml`, writes the captain agent registration, and bootstraps a
captain handoff.

```
Usage: principal-onboard <name> --user <sysuser> --display-name "Display" [options]

Required:
  <name>                principal slug (lowercase, alphanum + hyphen/underscore)
  --user <sysuser>      system $USER value to map this principal to
  --display-name "..."  display name (quote it)

Options:
  --email <addr>        email (repeat for multiple)
  --github-user <h>     GitHub username
  --repo-name <name>    repo name for templates (default: auto-detect from git)
  --no-yaml             skip agency.yaml mutation
  --no-agent-reg        skip .claude/agents/<name>-captain.md
  --no-handoff          skip bootstrap captain handoff
  --force               overwrite existing usr/{name}/
  --dry-run             show what would be done
  --verbose             detailed logging
  --version             show version
  --help                show help
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
- [TERMINAL-INTEGRATION.md](TERMINAL-INTEGRATION.md) - Ghostty terminal integration
- `agency/templates/principal/` - Principal directory template
